# Security policy

This plugin injects input only into a pane whose foreground process group has
been verified as a native npm-installed Codex CLI process. Please do not submit
changes that weaken this to pane titles, `pane_current_command`, arbitrary
regular expressions, or shell-configured commands.

To report a vulnerability, use GitHub's private security-advisory flow for this
repository. Include the Codex version, tmux version, terminal width/height, the
rendered prompt structure, and whether copy mode was active. Do not include
credentials, request contents, or other private pane output.

The supported surface for v0.2.3 is Linux, Python 3.10+, an English Codex UI,
and the npm `@openai/codex` native binary layout. Unsupported environments fail
closed or are ignored.

Normal completed turns never trigger input. Interrupted `Worked for` recovery
requires a recent recognized Codex activity block without the final-response
boundary; unknown or truncated layouts fail closed. The obsolete v0.1.x
`@codex-auto-continue-worked` option is ignored and removed from managed curl
configurations during upgrade.

Cybersecurity notices are actionable only when every logical line, glyph,
sentence, indentation level, and official URL matches the supported Codex UI
block. Header-only, quoted, indented, or altered copies fail closed.
Submitting `Continue` does not bypass Codex/OpenAI safety controls or grant
Trusted Access; a repeated refusal can cause another retry until the watcher is
disabled.
