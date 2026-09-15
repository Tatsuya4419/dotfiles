---
name: curl-install-drift
description: Check whether the curl-pipe-bash installers in install/user.sh (AWS CLI, Claude Code, Codex, mq, uv, Starship) still match what each vendor currently documents. Always use this when asked to check for drift/updates in dotfiles' curl-installed tools, or before hand-editing one of those blocks in install/user.sh.
---

# curl-install drift check

Covers the tools anchored with `# curl-install: id=<id> doc=<url>` comments in
`install/user.sh` (currently `aws-cli`, `claude-code`, `codex`, `mq`, `uv`,
`starship`). Those anchors are the source of truth for which tools are in
scope — adding or removing one there is enough to change scope, no edit to
this skill needed. `fisher` is intentionally not anchored: it already has a
native `fisher update` upgrade path and doesn't need drift detection.

## Step 1 — Generate the manifest (deterministic, no judgment)

Run from the repo root:

```bash
python3 install/tools/extract_curl_installs.py
```

Capture stdout as the manifest JSON. If the exit code is non-zero, still
continue to Step 2+ for every entry with `extraction_status: "ok"`. Report
every non-`ok` entry as its own row with status `EXTRACT_ERROR` in the final
report — never drop it silently, and never treat a parser failure as vendor
drift.

## Step 2 — WebFetch each `ok` entry's `doc_url`

Use this fixed prompt so the step stays non-interactive:

> Extract the exact shell command this page currently documents for
> installing this tool via curl-pipe-to-shell (a curl one-liner piped into
> bash/sh), if the page shows one as its primary/recommended method. Return
> only the literal command text on its own, or NONE if the page does not
> present one confident single curl one-liner install command.

## Step 3 — Compare and classify

Normalize whitespace on both `current_cmd` (from the manifest) and the
fetched command, then classify:

- **Equal after normalization** → `OK`
- **`current_cmd` starts with** the fetched command (i.e. the manifest
  command is the vendor's base command plus extra local flags, e.g.
  Starship's `--bin-dir "$HOME/.local/bin"`) → `OK (base match, local flags)`
- **Fetched result is `NONE`**, or the page didn't yield one confident
  command → `UNSURE`, with a short note of what the page actually showed
- **Otherwise** → `DRIFT`, showing both strings

Entries with `extraction_status != "ok"` skip WebFetch entirely and are
reported as `EXTRACT_ERROR`.

Use prefix-tolerant comparison, not naive equality — a naive exact-string
compare would wrongly flag Starship as `DRIFT` just because the local
`--bin-dir` flag isn't on the vendor's page.

## Step 4 — Structured report

Emit both a human-readable table and one machine-parseable fenced block per
tool, e.g.:

````markdown
## curl-install drift report — <date>

| id | status | doc |
|---|---|---|
| aws-cli | OK | docs.aws.amazon.com/... |
| starship | OK (base match, local flags) | starship.rs/... |
| mq | UNSURE | mqlang.org |

```curl-drift-tool
{"id": "mq", "status": "UNSURE", "doc_url": "https://mqlang.org/", "manifest_cmd": "curl -sSL https://mqlang.org/install.sh | bash", "fetched_cmd": null, "note": "vendor page did not present a single install command block"}
```
````

The `curl-drift-tool` fenced blocks (one tool, one line of JSON each) are the
unit a future CI step would split on to build a per-tool PR body.

## Dry-run by default

The default (and only non-interactive) behavior is the report above. Never
call `git`, never edit `install/user.sh`, never open a PR on your own.

Only enter apply-fix mode if the same invocation explicitly asks to apply a
fix for a named tool (e.g. "apply the aws-cli fix"). In that case: show the
exact one-line diff for that tool's `elif ! ...; then` line, then use
AskUserQuestion to get explicit confirmation before editing — curl-pipe-bash
installer lines are supply-chain-sensitive and must stay human-reviewed.
Even in apply mode, stop after the file edit; do not commit or push. That's a
separate, explicit instruction.

This split matters for future automation: the report path (Steps 1-4) never
calls AskUserQuestion, so it's safe to run headless on a schedule. The apply
path is the only place it can appear, and a CI job would never invoke it.

## Future CI note

If this is ever wired into a scheduled job, branch naming for per-tool PRs
would be `chore/curl-drift-<id>` (e.g. `chore/curl-drift-starship`). Not
implemented — this skill only produces the report.
