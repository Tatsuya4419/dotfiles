---
name: markdownlint-cli2
description: Lint or fix Markdown files with markdownlint-cli2. Always use this when running markdownlint-cli2 on any .md file, regardless of which directory the command is run from.
---

# markdownlint-cli2 with global config

The user keeps a personal `markdownlint-cli2` base config at `~/.markdownlint-cli2.jsonc`
(actual file lives in `~/dotfiles/.markdownlint-cli2.jsonc`, symlinked into place).
It currently disables `MD013` (line-length).

`markdownlint-cli2` only auto-discovers `.markdownlint-cli2.jsonc` files between the
current working directory and the file being linted — it never walks up past the
directory the command was invoked from. So when linting a file inside a project that
has no config of its own, the home directory config is silently skipped and default
rules (including `MD013`) apply.

**Always invoke it with the base config explicit:**

```bash
markdownlint-cli2 --config ~/.markdownlint-cli2.jsonc <globs...>
```

Any project-local `.markdownlint-cli2.jsonc` (if present) still merges on top of this
base config as normal — passing `--config` only sets the base, it does not disable
per-directory discovery.
