#!/bin/sh
set -eu
umask 077

VERSION=v0.2.2
REPO_RAW_BASE=${TMUX_CODEX_AUTO_CONTINUE_RAW_BASE:-"https://raw.githubusercontent.com/yeahdongcn/tmux-codex-auto-continue/$VERSION"}
WATCHER_SHA256=771cd59b6f55e662d460a28eba78a53da77840697783c9838c4efa336def02ae
BIN_DIR=${TMUX_CODEX_AUTO_CONTINUE_BIN_DIR:-"$HOME/.local/bin"}
TMUX_CONF=${TMUX_CODEX_AUTO_CONTINUE_TMUX_CONF:-"$HOME/.tmux.conf"}
TOGGLE_KEY=${TMUX_CODEX_AUTO_CONTINUE_KEY:-A}
INSTALL_CONFIG=1

usage() {
    printf '%s\n' 'Usage: install.sh [--no-config]'
    printf '%s\n' ''
    printf '%s\n' 'Environment overrides:'
    printf '%s\n' '  TMUX_CODEX_AUTO_CONTINUE_BIN_DIR   install directory (default: ~/.local/bin)'
    printf '%s\n' '  TMUX_CODEX_AUTO_CONTINUE_TMUX_CONF tmux config path (default: ~/.tmux.conf)'
    printf '%s\n' '  TMUX_CODEX_AUTO_CONTINUE_KEY        toggle key (default: A; e.g. C-a)'
    printf '%s\n' '  TMUX_CODEX_AUTO_CONTINUE_RAW_BASE  raw file base URL for mirrors/forks'
}

for arg in "$@"; do
    case "$arg" in
        --no-config) INSTALL_CONFIG=0 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
    esac
done

if [ "$(uname -s)" != Linux ] || [ ! -r /proc/self/stat ]; then
    printf '%s\n' 'tmux-codex-auto-continue currently requires Linux with /proc.' >&2
    exit 1
fi
case "$TOGGLE_KEY" in
    ''|*[!A-Za-z0-9._:+-]*)
        printf '%s\n' 'TMUX_CODEX_AUTO_CONTINUE_KEY must be one tmux key token using letters, numbers, or . _ : + -.' >&2
        exit 2
        ;;
esac
for command in curl install python3 sha256sum tmux; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'required command not found: %s\n' "$command" >&2
        exit 1
    fi
done
if ! python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 10))'; then
    printf '%s\n' 'Python 3.10 or newer is required.' >&2
    exit 1
fi

mkdir -p "$BIN_DIR" "$HOME/.cache"
tmp=$(mktemp "${TMPDIR:-/tmp}/tmux-codex-auto-continue.XXXXXX")
config_tmp=
trap 'rm -f "$tmp" "${config_tmp:-}"' EXIT HUP INT TERM
curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    "$REPO_RAW_BASE/bin/tmux-codex-auto-continue" \
    --output "$tmp"
printf '%s  %s\n' "$WATCHER_SHA256" "$tmp" | sha256sum --check --status
python3 "$tmp" --self-test
install -m 0755 "$tmp" "$BIN_DIR/tmux-codex-auto-continue"

if [ "$INSTALL_CONFIG" -eq 1 ]; then
    mkdir -p "$(dirname "$TMUX_CONF")"
    touch "$TMUX_CONF"
    start_marker='# >>> tmux-codex-auto-continue >>>'
    end_marker='# <<< tmux-codex-auto-continue <<<'
    start_count=$(grep -Fxc "$start_marker" "$TMUX_CONF" 2>/dev/null || true)
    end_count=$(grep -Fxc "$end_marker" "$TMUX_CONF" 2>/dev/null || true)
    if [ "$start_count" -ne "$end_count" ] || [ "$start_count" -gt 1 ]; then
        printf 'Malformed tmux-codex-auto-continue managed block in %s; refusing to edit it.\n' "$TMUX_CONF" >&2
        exit 1
    fi
    config_updated=1
    if [ "$start_count" -eq 1 ]; then
        config_tmp=$(mktemp "${TMPDIR:-/tmp}/tmux-codex-config.XXXXXX")
        awk -v start="$start_marker" -v end="$end_marker" '
            $0 == start { managed = 1; next }
            managed && $0 == end { managed = 0; next }
            !managed { print }
        ' "$TMUX_CONF" > "$config_tmp"
        chmod --reference="$TMUX_CONF" "$config_tmp"
        mv "$config_tmp" "$TMUX_CONF"
        config_tmp=
    elif grep -Fq 'tmux-codex-auto-continue' "$TMUX_CONF" 2>/dev/null; then
        config_updated=0
        printf 'Unmanaged tmux-codex-auto-continue text detected in %s; no config was added.\n' "$TMUX_CONF" >&2
        printf '%s\n' 'Remove or convert that block to the marked form, then rerun install.sh.' >&2
    fi
    if [ "$config_updated" -eq 1 ]; then
        script="$BIN_DIR/tmux-codex-auto-continue"
        {
            printf '\n%s\n' "$start_marker"
            printf '%s\n' '# Recover interrupted Codex turns and recognized retry/wait prompts.'
            printf '%s\n' 'set -goq @codex-auto-continue on'
            printf "bind-key %s run-shell -b '\"%s\" --socket \"#{socket_path}\" --toggle'\n" "$TOGGLE_KEY" "$script"
            printf "run-shell -b 'mkdir -p \"%s/.cache\" && \"%s\" --socket \"#{socket_path}\" >> \"%s/.cache/tmux-codex-auto-continue.log\" 2>&1'\n" "$HOME" "$script" "$HOME"
            printf '%s\n' "$end_marker"
        } >> "$TMUX_CONF"
        printf 'Added/updated the managed configuration block in %s\n' "$TMUX_CONF"
    else
        printf '%s\n' 'Configuration was left unchanged.'
    fi

    if [ "$config_updated" -eq 1 ] && tmux source-file "$TMUX_CONF" 2>/dev/null; then
        tmux set-option -gu @codex-auto-continue-worked 2>/dev/null || true
        socket=$(tmux display-message -p '#{socket_path}')
        "$BIN_DIR/tmux-codex-auto-continue" \
            --socket "$socket" --restart
        printf 'Sourced %s and refreshed the watcher without restarting tmux.\n' "$TMUX_CONF"
    elif [ "$config_updated" -eq 1 ]; then
        printf 'Start tmux (or source %s) to activate the watcher.\n' "$TMUX_CONF"
    fi
fi

printf 'Installed %s/tmux-codex-auto-continue\n' "$BIN_DIR"
if [ "$INSTALL_CONFIG" -eq 1 ] && [ "${config_updated:-0}" -eq 1 ]; then
    printf 'Use tmux prefix+%s to toggle it on the current tmux server.\n' "$TOGGLE_KEY"
else
    printf '%s\n' 'Configuration was not changed; source your tmux config or start the watcher manually.'
fi
