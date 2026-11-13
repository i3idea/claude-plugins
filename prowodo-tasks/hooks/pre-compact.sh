#!/bin/sh
# PreCompact hook for the ProWoDo second brain (prowodo-tasks plugin).
# For PreCompact, plain stdout is used as instructions for the compaction
# summary (documented, 10k char cap); it is NOT injected into the conversation
# and cannot make Claude call a tool. So it only asks the summary to keep a list
# of unsaved note candidates; session-start.sh (matcher "compact") then makes
# Claude offer to save them once the session resumes.
cat <<'TXT'
ProWoDo second brain: if the ProWoDo notes tools are in use in this session, end the summary with a short section titled "Unsaved note candidates": one line each for durable, reusable items from this session that have NOT been saved as a ProWoDo note yet (a decision with its why, a gotcha, a verified procedure, a non-obvious fact). Leave the section out if there are none. Do not save anything now.
TXT
