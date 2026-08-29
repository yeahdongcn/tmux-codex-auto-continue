# Changelog

## v0.2.10 - 2026-08-29

- Recognize Codex's strict context-window exhaustion notice and route it through
  the guarded two-stage `/compact` then `Continue` recovery flow.
- Require a fresh `Context compacted` confirmation before submitting `Continue`,
  while preserving duplicate, stale-marker, and lookalike protections.

## v0.2.9 - 2026-08-20

- Recognize Codex's exact `stream disconnected before completion: stream
  closed before response.completed` terminal error and submit `Continue` with
  the existing verified bracketed-paste plus real-Enter path.
- Reject missing-glyph, quoted, indented, modified, and unknown-suffix
  lookalikes, with unit and isolated tmux integration coverage.

## v0.2.8 - 2026-08-19

- Recognize Codex's `exceeded retry limit, last status: 429 Too Many Requests`
  terminal state.
- Recover the active pane after a guarded 2-second interval for each newly
  rendered 429 distinguishable within the retained capture window,
  de-duplicating the same line and resetting on another event.
- Re-evaluate the current Goal state after the delay: submit `/goal resume` for
  a recoverable Goal (including `Goal active` paired with the failed turn),
  and submit `Continue` for every other 429, including one paired with a
  terminal Goal label.
- Recognize strict Goal status cells and bottom-pane Goal footer labels without
  borrowing stale Goal text from an older 429.
- Add self-test and isolated tmux integration coverage for strict matching,
  quoted-lookalike rejection, delayed literal `/goal resume` delivery, stale
  Goal rejection, pane-mode/manual-resume deduplication, and fixed-delay reset.
- Resolve the exact current tmux server executable from `TMUX` and `/proc`
  when a long-lived server's background `PATH` cannot find a user-local tmux;
  keep restart failures bounded and add a no-tmux-`PATH` integration case.
- Keep recognizing a still-running Codex pane after an npm upgrade moves its
  native executable under npm's deleted `.codex-<suffix>` staging directory.
- Restrict native process matching to the supported arm64 and x64 executable
  tails, and accept only a dim empty-composer placeholder with cursor `x=2`
  at both pre-send checks.
- Distinguish the daemon's initial server-wide baseline from sessions and panes
  discovered later, so a new pane whose first observed frame is already a
  current 429 still gets the guarded recovery.

## v0.2.7 - 2026-07-30

- Recognize strict overload and request-failure notices emitted while a remote
  compaction task is running, and reuse the existing verified `Continue` plus
  real-Enter submission paths.
- Keep quoted, indented, incomplete, and modified lookalikes excluded.

## v0.2.6 - 2026-07-25

- Extend the guarded context-compaction confirmation window from one minute to
  five minutes so slow compactions can still complete the two-stage recovery.
- Preserve the existing finite timeout and all superseding-event, manual-input,
  process-identity, pane-mode, and live-terminal revalidation safeguards.
- Add regression coverage that keeps the watcher-owned compaction phase active
  at the observed 67-second delay.

## v0.2.5 - 2026-07-25

- Pin Ruff in GitHub Actions and define the repository's stable lint rule set
  so upstream default-rule changes cannot break otherwise unchanged releases.
- Apply Ruff's import ordering with no runtime behavior changes.

## v0.2.4 - 2026-07-25

- Add guarded two-stage recovery for strict context-size 413 diagnostics:
  submit `/compact` with a real Enter, then submit `Continue` only after a new
  column-zero `Context compacted` confirmation from the same pane.
- Ignore standalone or stale compaction confirmations, suppress duplicate
  `/compact` submissions, and preserve the existing foreground-process,
  copy-mode, resize, idle-composer, and live-event revalidation safeguards.

## v0.2.3 - 2026-07-23

- Migrate complete legacy unmarked curl configuration blocks into the current
  managed form while continuing to refuse ambiguous unmarked references.

## v0.2.2 - 2026-07-23

- Make the curl installer rewrite only its marked block, refresh changed
  executable paths and toggle keys, and refuse ambiguous or unmarked config
  matches instead of silently skipping setup.
- Add `TMUX_CODEX_AUTO_CONTINUE_KEY` for curl installs and make `--no-config`
  output accurately describe what was (and was not) configured.
- Clarify the local-only runtime, safety-policy boundary, pinned installer trust
  model, TPM-versus-curl paths, and troubleshooting commands.

## v0.2.1 - 2026-07-23

- Recognize the complete four-line `ⓘ This content can't be shown` Trusted
  Access notice and submit `Continue` plus a real Enter.
- Recognize the complete two-line `■ This content was flagged for possible
  cybersecurity risk` notice and use the same verified submission path.
- Require exact column-zero glyphs, wording, indentation, and official URLs;
  quoted, incomplete, or modified lookalikes fail closed.
- Treat a later `ⓘ` line as Codex output when rejecting stale deferred events.

## v0.2.0 - 2026-07-23

- Remove the normal-completion opt-in path: completed Codex turns are always
  ignored, and only high-confidence interrupted `Worked for` states trigger
  `Continue` plus Enter.
- Distinguish normal final responses from interrupted internal activity blocks
  such as `Ran`, `Explored`, and `Edited`; unknown, distant, and truncated
  layouts fail closed.
- Revalidate interruption evidence from bounded history while still requiring
  the `Worked for` marker and idle composer in the live viewport.
- Remove the obsolete `@codex-auto-continue-worked` status/config surface and
  migrate it out of curl-managed configurations during upgrade.

## v0.1.5 - 2026-07-22

- Recognize the strict column-zero Codex message
  `■ Our servers are currently overloaded. Please try again later.`, including
  its optional displayed `---` suffix.
- Submit `Continue` with bracketed paste followed by a real Enter, while keeping
  quoted and indented lookalikes excluded.

## v0.1.4 - 2026-07-22

- Keep `Worked for ...` continuation disabled in newly generated curl-install
  configurations. Users must opt in explicitly with
  `@codex-auto-continue-worked on`.
- Preserve existing configuration files during upgrades, including an existing
  explicit `on` or `off` choice.

## v0.1.3 - 2026-07-22

- Keep newly observed retry/completion events for up to 30 seconds when a tmux
  pane mode owns the keyboard, then recover only if the event is still the
  current visible terminal state after the mode exits.
- Treat every nonzero `pane_in_mode` depth as active, including nested mode
  stacks reported as `2` or higher.
- Revalidate the exact terminal event, empty composer, Codex process, global
  option, pane mode, and safety menu immediately before submitting input.
- Cancel deferred input after a manual `Continue`, later assistant/tool output,
  a new terminal event, a resize, a safety menu, or the 30-second deadline.
- Extend the isolated tmux integration test with pane-mode recovery and
  manual-recovery deduplication.

## v0.1.2 - 2026-07-21

- Recognize strict column-zero `─ Worked for ... ─` completion separators,
  including durations with an optional hour component.
- Submit `Continue` with bracketed paste followed by a real Enter after a new
  completion event.
- Gate normal-completion continuation behind the explicit
  `@codex-auto-continue-worked` option so existing upgrades remain opted out.
- Add a safe watcher-only restart path so curl and TPM upgrades load the new
  code without restarting tmux sessions or panes.
- Keep quoted and indented lookalikes excluded and add an isolated tmux
  integration test for the completion path.

## v0.1.1 - 2026-07-21

- Recognize the column-zero `■ internal streaming error, please retry` Codex
  error, including the optional displayed `---` separator suffix.
- Reuse the verified bracketed-paste plus real-Enter `Continue` submission.

## v0.1.0 - 2026-07-21

- Detect retryable Codex request errors and model-capacity errors.
- Submit `Continue` with bracketed paste and a real Enter key.
- Detect the live safety-buffering selection view and safely accept
  `Keep waiting`.
- Add foreground-process, copy-mode, viewport, resize, and singleton-daemon
  safeguards.
- Add pinned curl, TPM, manual installation, self-tests, ShellCheck, Ruff, and
  GitHub Actions CI.
