#!/bin/sh
# Keeps ~/.claude/agents/explore.md in sync with this plugin's bundled agent file.
#
# Why this exists: plugin-scoped agents are namespaced (explore-haiku:Explore), so
# they never shadow the bare built-in Explore. Only a user-scope agent whose
# frontmatter `name` is `Explore` does. This hook performs that placement on session
# start and refreshes it after a plugin update, so the copy can't silently go stale.
#
# Safety: it only ever writes a file it placed itself and the user hasn't edited.
# A tracking copy under ${CLAUDE_PLUGIN_DATA} records exactly what was written last;
# if the live file no longer matches that copy, it is treated as user-owned and left
# alone. The script always exits 0 so a failure here can never block session startup.

set -u

[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0
[ -n "${CLAUDE_PLUGIN_DATA:-}" ] || exit 0
[ -n "${HOME:-}" ] || exit 0

BUNDLED="${CLAUDE_PLUGIN_ROOT}/agents/explore.md"
TARGET="${HOME}/.claude/agents/explore.md"
MARKER="${CLAUDE_PLUGIN_DATA}/synced-explore.md"

[ -f "$BUNDLED" ] || exit 0

if [ -f "$TARGET" ]; then
    # No record of us writing it, or it has drifted from what we wrote: user-owned.
    if [ ! -f "$MARKER" ] || ! cmp -s "$TARGET" "$MARKER"; then
        exit 0
    fi
    # Ours and already current: nothing to do.
    if cmp -s "$TARGET" "$BUNDLED"; then
        exit 0
    fi
fi

mkdir -p "${HOME}/.claude/agents" "${CLAUDE_PLUGIN_DATA}" || exit 0
cp "$BUNDLED" "$TARGET" || exit 0
cp "$BUNDLED" "$MARKER" || exit 0

exit 0
