# Global rules

## Precedence

If rules conflict across AGENTS.md, CLAUDE.md, or any other rule file, the one
deeper in the directory tree (closer to the file being worked on) wins. This
file is the shallowest, so it always loses a conflict.

## References and primary sources

- For any fact about a third-party library, SDK, CLI, or API (signatures,
  flags, config, versions), the SSoT is a trusted source, not memory. Order:
  context7 MCP, then official docs or source, then the tool's own `--help` or
  man page.
- If no trusted source is reachable, say the answer is unverified instead of
  guessing.
- Cite the source (context7 library ID or URL) alongside the answer.
- Prefer deterministic operations over inference: pass a known
  `/org/project` ID straight to context7, read the installed version from
  `--version` or the package manager, and run the tool instead of predicting
  its output.
