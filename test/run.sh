#!/bin/sh
# Runs squire against a throwaway project and checks the flow and hygiene rules.
squire=$(cd "$(dirname "$0")/.." && pwd)/squire
project=$(mktemp -d)
trap 'rm -rf "$project"' EXIT
cd "$project" || exit 1
failures=0

check() {
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected '$3', got '$2'"; failures=$((failures + 1)); fi
}
field() { "$squire" "$1" export | python3 -c "import json,sys; print(json.load(sys.stdin)[0].get('$2', ''))"; }
uuid() { "$squire" "$1" _uuid; }

"$squire" init >/dev/null

SQUIRE_AUTHOR=claude "$squire" add "add rubocop" assignee:claude priority:H >/dev/null
task=$(uuid 1)
check "a new task is an idea" "$(field "$task" state)" idea
check "the author is recorded" "$(field "$task" author)" claude

SQUIRE_AUTHOR=claude "$squire" "$task" modify state:open >/dev/null 2>&1
check "an agent cannot approve an idea" "$(field "$task" state)" idea
SQUIRE_AUTHOR=claude "$squire" add "skip the approval" state:open >/dev/null 2>&1
check "an agent cannot add an approved task" "$("$squire" count)" 1

"$squire" "$task" modify state:open >/dev/null
check "a human approves an idea" "$(field "$task" state)" open
check "the change records who made it" "$(field "$task" changed_by)" "$USER"

SQUIRE_AUTHOR=claude "$squire" "$task" annotate "which cops?" >/dev/null
check "a comment carries its author" \
  "$("$squire" "$task" export | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['annotations'][-1]['description'])")" \
  "[claude] which cops?"

long=$(python3 -c "print('x' * 501)")
SQUIRE_AUTHOR=claude "$squire" "$task" annotate "$long" >/dev/null 2>&1
check "a long comment is refused" \
  "$("$squire" "$task" export | python3 -c "import json,sys; print(len(json.load(sys.stdin)[0]['annotations']))")" 1

"$squire" "$task" modify "body:first line
second line" >/dev/null
check "the body keeps line breaks" "$(field "$task" body)" "first line
second line"

"$squire" "$task" annotate "$long" >/dev/null 2>&1
check "the limits bind the human too" \
  "$("$squire" "$task" export | python3 -c "import json,sys; print(len(json.load(sys.stdin)[0]['annotations']))")" 1

SQUIRE_AUTHOR=claude "$squire" add "add a CI job for rubocop" assignee:claude depends:"$task" >/dev/null
"$squire" 2 modify state:open >/dev/null
check "the inbox lists unblocked work only" "$(SQUIRE_AUTHOR=claude "$squire" | grep -c '^## ')" 1

SQUIRE_AUTHOR=claude "$squire" add "pick the cops" assignee:"$USER" "body:all, or enabled only?" >/dev/null
SQUIRE_AUTHOR=claude "$squire" "$task" annotate "run them on the specs too?" >/dev/null
SQUIRE_AUTHOR=claude "$squire" "$task" modify assignee:"$USER" >/dev/null
inbox=$("$squire")
check "the human's inbox holds what waits for them" "$(echo "$inbox" | grep -c '^## ')" 2
check "the inbox shows the newest question" "$(echo "$inbox" | grep -c '^\[claude\] run them on the specs too?$')" 1
check "the inbox shows the body when nobody asked" "$(echo "$inbox" | grep -c '^all, or enabled only?$')" 1

[ "$failures" -eq 0 ]
