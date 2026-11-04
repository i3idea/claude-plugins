#!/bin/sh
# Session reminder for the ProWoDo second brain (prowodo-tasks plugin).
# Keep it short: it lands in the context of every session. It never calls the
# MCP and never writes anything; it only makes Claude offer to save what is worth keeping.
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"ProWoDo second brain: if the ProWoDo notes tools are available and something durable and reusable comes up while you work (a decision together with its why, a gotcha, a verified procedure, a non-obvious fact about the project), offer in ONE line to save it as a note, replying in the user's language. Never save without an explicit yes, first check whether a note already exists to update (search_knowledge), and do not offer for obvious things, details already in the code or git history, or fast-changing state. Details in references/notes.md of the prowodo-tasks skill."}}
JSON
