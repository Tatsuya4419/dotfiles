#!/usr/bin/env python3
"""Deterministic extractor for the curl-pipe-bash installers in install/user.sh.

Parses `# curl-install: id=<tool-id> doc=<vendor-doc-url>` anchor comments and
the `if has <bin>; then / elif ! <cmd>; then / fi` block that follows each one,
then emits a JSON manifest describing each tool's id, doc URL, and the literal
install command as currently written in the code. The code in user.sh is the
canonical source; this script only derives a snapshot of it -- the manifest is
never hand-edited and is not meant to be committed to git.

Known limitation: assumes each `elif ! <cmd>; then` fits on one logical line.
A backslash-continued command would currently fail closed as
"no_command_found" rather than being mis-parsed.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ANCHOR_RE = re.compile(r"^#\s*curl-install:\s*id=(\S+)\s+doc=(\S+)\s*$")
IF_OPEN_RE = re.compile(r"^\s*if\b")
FI_CLOSE_RE = re.compile(r"^\s*fi\b")
ELIF_CMD_RE = re.compile(r"^\s*elif\s*!\s*(.+?)\s*;\s*then\s*$")

MAX_LOOKAHEAD = 15


def default_user_sh() -> Path:
    return Path(__file__).resolve().parent.parent / "user.sh"


def find_next(pattern: re.Pattern[str], lines: list[str], start: int, limit: int) -> int | None:
    for i in range(start, min(start + limit, len(lines))):
        if pattern.match(lines[i]):
            return i
    return None


def extract_block(lines: list[str], if_line: int) -> list[str]:
    """Return the lines strictly between if_line and its matching `fi`, tracking nesting depth."""
    depth = 1
    block: list[str] = []
    k = if_line + 1
    while k < len(lines) and depth > 0:
        if IF_OPEN_RE.match(lines[k]):
            depth += 1
        elif FI_CLOSE_RE.match(lines[k]):
            depth -= 1
            if depth == 0:
                return block
        block.append(lines[k])
        k += 1
    return block  # ran off the end of the file without closing -- caller treats as "no fi found"


def git_short_head(repo_dir: Path) -> str | None:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=repo_dir,
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def relative_source_path(file_path: Path) -> str:
    try:
        return str(file_path.resolve().relative_to(Path.cwd().resolve()))
    except ValueError:
        return str(file_path)


def extract(file_path: Path) -> dict:
    lines = file_path.read_text().splitlines()
    tools: list[dict] = []
    seen_ids: set[str] = set()

    for i, raw_line in enumerate(lines):
        m = ANCHOR_RE.match(raw_line.strip())
        if not m:
            continue
        tool_id, doc_url = m.group(1), m.group(2)

        entry = {
            "id": tool_id,
            "doc_url": doc_url,
            "current_cmd": None,
            "anchor_line": i + 1,
            "block_start_line": None,
            "block_end_line": None,
            "extraction_status": None,
        }

        if tool_id in seen_ids:
            entry["extraction_status"] = "duplicate_id"
            tools.append(entry)
            continue
        seen_ids.add(tool_id)

        if_line = find_next(IF_OPEN_RE, lines, i + 1, MAX_LOOKAHEAD)
        if if_line is None:
            entry["extraction_status"] = "no_block_found"
            tools.append(entry)
            continue

        block = extract_block(lines, if_line)
        fi_line = if_line + len(block) + 1
        entry["block_start_line"] = if_line + 1
        entry["block_end_line"] = fi_line + 1

        cmd_matches = [ELIF_CMD_RE.match(line) for line in block]
        cmd_matches = [match for match in cmd_matches if match]

        if len(cmd_matches) == 0:
            entry["extraction_status"] = "no_command_found"
        elif len(cmd_matches) > 1:
            entry["extraction_status"] = "ambiguous_multiple_commands"
        else:
            entry["current_cmd"] = cmd_matches[0].group(1)
            entry["extraction_status"] = "ok"

        tools.append(entry)

    manifest = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source_file": relative_source_path(file_path),
        "source_commit": git_short_head(file_path.resolve().parent),
        "tools": tools,
    }
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--file",
        type=Path,
        default=default_user_sh(),
        help="path to user.sh to parse (default: install/user.sh next to this script)",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help="write JSON to this file instead of stdout (for local inspection only; "
        "the manifest is not meant to be committed)",
    )
    args = parser.parse_args()

    manifest = extract(args.file)

    output = json.dumps(manifest, indent=2, ensure_ascii=False)
    if args.out:
        args.out.write_text(output + "\n")
    else:
        print(output)

    ok = True
    for tool in manifest["tools"]:
        if tool["extraction_status"] != "ok":
            ok = False
            print(f"WARN: {tool['id']}: {tool['extraction_status']}", file=sys.stderr)

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
