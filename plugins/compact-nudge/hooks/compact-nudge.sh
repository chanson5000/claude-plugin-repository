#!/bin/sh
# Locates a Python 3 interpreter and hands the hook payload to compact-nudge.py.
#
# Why a wrapper: hooks.json can only name one command, but the interpreter is
# `python3` on most systems and `python` on a stock Windows install. Failing to
# find either must be silent — a hook that errors on every prompt is worse than
# a budget that goes unenforced.

set -u

[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0

SCRIPT="${CLAUDE_PLUGIN_ROOT}/hooks/compact-nudge.py"
[ -f "$SCRIPT" ] || exit 0

# `command -v` is not enough on Windows: the Microsoft Store ships a `python3.exe`
# app-execution-alias stub that resolves but is not an interpreter. Probe each
# candidate by actually running it, so a stub falls through to the real one.
for candidate in python3 python py; do
    command -v "$candidate" >/dev/null 2>&1 || continue
    "$candidate" -c "import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)" >/dev/null 2>&1 || continue
    exec "$candidate" "$SCRIPT"
done

exit 0
