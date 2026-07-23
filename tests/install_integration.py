#!/usr/bin/env python3
"""Verify fresh installation and legacy Worked-option migration."""

from __future__ import annotations

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / "install.sh"
WATCHER = ROOT / "bin" / "tmux-codex-auto-continue"
WORKED_OPTION = "set -goq @codex-auto-continue-worked"


def main() -> int:
    real_tmux = shutil.which("tmux")
    assert real_tmux is not None, "tmux is required"

    with tempfile.TemporaryDirectory(prefix="tmux-codex-install-test-") as raw_root:
        root = Path(raw_root)
        home = root / "home"
        bin_dir = root / "bin"
        fake_bin = root / "fake-bin"
        runtime = root / "runtime"
        home.mkdir(mode=0o700)
        bin_dir.mkdir(mode=0o700)
        fake_bin.mkdir(mode=0o700)
        runtime.mkdir(mode=0o700)

        socket = f"/tmp/tmux-codex-install-test-{os.getpid()}"
        fake_tmux = fake_bin / "tmux"
        fake_tmux.write_text(
            "#!/bin/sh\n"
            f"exec {shlex.quote(real_tmux)} -S {shlex.quote(socket)} \"$@\"\n",
            encoding="utf-8",
        )
        fake_tmux.chmod(0o755)

        fake_curl = fake_bin / "curl"
        fake_curl.write_text(
            "#!/bin/sh\n"
            "set -eu\n"
            "output=\n"
            "while [ \"$#\" -gt 0 ]; do\n"
            "    case \"$1\" in\n"
            "        --output) output=$2; shift 2 ;;\n"
            "        *) shift ;;\n"
            "    esac\n"
            "done\n"
            "[ -n \"$output\" ]\n"
            f"cp {shlex.quote(str(WATCHER))} \"$output\"\n",
            encoding="utf-8",
        )
        fake_curl.chmod(0o755)

        environment = os.environ.copy()
        environment.update(
            {
                "HOME": str(home),
                "PATH": f"{fake_bin}:{environment['PATH']}",
                "XDG_RUNTIME_DIR": str(runtime),
                "TMUX_CODEX_AUTO_CONTINUE_BIN_DIR": str(bin_dir),
                "TMUX_CODEX_AUTO_CONTINUE_TMUX_CONF": str(home / ".tmux.conf"),
                "TMUX_CODEX_AUTO_CONTINUE_KEY": "C-a",
            }
        )

        def tmux(*arguments: str) -> subprocess.CompletedProcess[str]:
            return subprocess.run(
                [real_tmux, "-S", socket, *arguments],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                encoding="utf-8",
                errors="replace",
                check=False,
                env=environment,
            )

        def run_installer(*arguments: str) -> subprocess.CompletedProcess[str]:
            return subprocess.run(
                ["sh", str(INSTALLER), *arguments],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                encoding="utf-8",
                errors="replace",
                check=False,
                env=environment,
            )

        try:
            created = subprocess.run(
                [
                    real_tmux,
                    "-f",
                    "/dev/null",
                    "-S",
                    socket,
                    "new-session",
                    "-d",
                    "-x",
                    "80",
                    "-y",
                    "20",
                    "sleep",
                    "300",
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                encoding="utf-8",
                errors="replace",
                check=False,
                env=environment,
            )
            assert created.returncode == 0, created.stderr

            installed = run_installer()
            assert installed.returncode == 0, installed.stdout
            config = home / ".tmux.conf"
            config_text = config.read_text(encoding="utf-8")
            assert WORKED_OPTION not in config_text
            assert "bind-key C-a " in config_text
            assert "prefix+C-a" in installed.stdout
            assert tmux("show-options", "-gqv", "@codex-auto-continue").stdout.strip() == "on"
            assert not tmux(
                "show-options", "-gqv", "@codex-auto-continue-worked"
            ).stdout.strip()

            # Upgrade a v0.1.x managed block and live tmux option. The removed
            # mechanism must not remain in either surface.
            config.write_text(
                config_text.replace(
                    "set -goq @codex-auto-continue on",
                    "set -goq @codex-auto-continue on\n"
                    f"{WORKED_OPTION} on",
                ),
                encoding="utf-8",
            )
            tmux(
                "set-option", "-g", "@codex-auto-continue-worked", "on"
            )
            upgraded = run_installer()
            assert upgraded.returncode == 0, upgraded.stdout
            upgraded_text = config.read_text(encoding="utf-8")
            assert WORKED_OPTION not in upgraded_text
            assert not tmux(
                "show-options", "-gqv", "@codex-auto-continue-worked"
            ).stdout.strip()
            assert upgraded_text.count("# >>> tmux-codex-auto-continue >>>") == 1

            # A changed toggle key rewrites the managed block instead of
            # leaving a stale binding behind.
            environment["TMUX_CODEX_AUTO_CONTINUE_KEY"] = "C-b"
            rebound = run_installer()
            assert rebound.returncode == 0, rebound.stdout
            rebound_text = config.read_text(encoding="utf-8")
            assert "bind-key C-b " in rebound_text
            assert "bind-key C-a " not in rebound_text
            assert rebound_text.count("# >>> tmux-codex-auto-continue >>>") == 1

            # --no-config installs the executable without claiming that a
            # toggle binding was configured or changing the existing file.
            before_no_config = config.read_text(encoding="utf-8")
            no_config = run_installer("--no-config")
            assert no_config.returncode == 0, no_config.stdout
            assert "prefix+" not in no_config.stdout
            assert config.read_text(encoding="utf-8") == before_no_config

            # An unmarked reference is reported explicitly instead of being
            # mistaken for an active managed installation.
            config.write_text(
                "# see tmux-codex-auto-continue documentation\n",
                encoding="utf-8",
            )
            unmanaged = run_installer()
            assert unmanaged.returncode == 0, unmanaged.stdout
            assert "Unmanaged tmux-codex-auto-continue text detected" in unmanaged.stdout
            assert "# >>> tmux-codex-auto-continue >>>" not in config.read_text(
                encoding="utf-8"
            )
            print("install-integration: PASS")
            return 0
        finally:
            tmux("kill-server")
            time.sleep(0.6)


if __name__ == "__main__":
    raise SystemExit(main())
