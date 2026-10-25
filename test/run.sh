#!/bin/sh
# Installs into a throwaway prefix and checks the flow, the authors and the hygiene rules.
root=$(cd "$(dirname "$0")/.." && pwd)
project=$(mktemp -d)
trap 'rm -rf "$project"' EXIT
make -s -C "$root" install PREFIX="$project/prefix" || exit 1
unset SQUIRE_AUTHOR TASKRC TASKDATA
export HOME="$project/home" PATH="$project/prefix/bin:$PATH"
mkdir -p "$HOME" "$project/app/.claude" && cd "$project/app" || exit 1
failures=0

check() {
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected '$3', got '$2'"; failures=$((failures + 1)); fi
}
field() { task "$1" export | python3 -c "import json,sys; print(json.load(sys.stdin)[0].get('$2', ''))"; }
comments() { task "$1" export | python3 -c "import json,sys; print(len(json.load(sys.stdin)[0].get('annotations', [])))"; }
claude() { SQUIRE_AUTHOR=claude task "$@" >/dev/null 2>&1; }
codex() { SQUIRE_AUTHOR=codex task "$@" >/dev/null 2>&1; }
human() { task "$@" >/dev/null 2>&1; }

squire init >/dev/null
check "init writes the assistant's env" \
  "$(python3 -c "import json; e=json.load(open('.claude/settings.json'))['env']; import os; print(e['SQUIRE_AUTHOR'], os.path.samefile(e['TASKDATA'], '.'))")" "claude True"
check "init installs the skill" "$(head -2 .claude/skills/taskwarrior-squire/SKILL.md | tail -1)" "name: taskwarrior-squire"
check "the skill reads the installed instructions" \
  "$(TASKRC="$project/prefix/share/taskwarrior-squire/taskrc" sh -c "$(grep '^    cat' .claude/skills/taskwarrior-squire/SKILL.md)" | grep -c '^## The flow$')" 1
squire init >/dev/null
hook() { python3 -c "import json; print(json.load(open('.claude/settings.json'))['hooks']['$1'][0]['hooks'][0]['command'])"; }
check "init adds its hooks once" "$(python3 -c "import json; h=json.load(open('.claude/settings.json'))['hooks']; print(len(h['SessionStart']), len(h['SubagentStart']))")" "1 1"
check "a subagent starts with the instructions" \
  "$(echo '{"hook_event_name": "SubagentStart"}' | sh -c "$(hook SubagentStart)" | python3 -c "import json,sys; o=json.load(sys.stdin)['hookSpecificOutput']; print(o['hookEventName'], '## The flow' in o['additionalContext'])")" "SubagentStart True"
check "init leaves a ~/.taskrc for the include" "$(test -f "$HOME/.taskrc" && echo yes)" yes
export TASKRC="$project/prefix/share/taskwarrior-squire/taskrc" TASKDATA="$PWD"
echo "search.case.sensitive=no" >> "$HOME/.taskrc"
check "the human's own taskrc still applies" "$(task _get rc.search.case.sensitive)" no

claude add "add rubocop" assignee:claude priority:H "body:DONE WHEN: bin/lint runs rubocop"
task=$(task 1 _uuid)
check "a new task is an idea" "$(field "$task" state)" idea
check "the author is recorded" "$(field "$task" author)" claude
claude "$task" modify state:open
check "an assistant cannot approve an idea" "$(field "$task" state)" idea
claude "$task" modify state:rejected
check "an assistant cannot reject an idea" "$(field "$task" state)" idea
claude "$task" delete
check "an assistant cannot delete an idea" "$(field "$task" status)" pending
claude add "skip the approval" state:open
check "an assistant cannot add an approved task" "$(task count)" 1
claude "$task" modify state:doing
check "an assistant cannot work on an idea" "$(field "$task" state)" idea
human add "a vague wish"
vague=$(task /vague/ _uuid)
human "$vague" modify state:open
check "an idea without a definition of done stays an idea" "$(field "$vague" state)" idea
human "$vague" annotate "done when: the wish is granted"
human "$vague" modify state:open
check "a comment can hold the definition of done" "$(field "$vague" state)" open
human "$vague" modify state:postponed
human "$task" modify state:open
check "the human approves an idea" "$(field "$task" state)" open
check "a change records who made it" "$(field "$task" changed_by)" "$USER"

claude "$task" modify state:fixed
check "an assistant cannot skip doing" "$(field "$task" state)" open
claude "$task" done
check "an assistant cannot close an open task" "$(field "$task" state)" open
claude "$task" modify state:doing
claude "$task" annotate "added rubocop, commit 1a2b3c4"
claude "$task" modify state:fixed
check "an assistant walks open, doing, fixed" "$(field "$task" state)" fixed
check "a change by an assistant records it" "$(field "$task" changed_by)" claude
codex "$task" modify state:open
codex "$task" annotate "reopened: the specs are not covered"
check "a second assistant reopens a fixed task" "$(field "$task" state)" open
check "each assistant signs its comments" \
  "$(task "$task" export | python3 -c "import json,sys; print(' '.join(a['description'].split(']')[0] + ']' for a in json.load(sys.stdin)[0]['annotations']))")" \
  "[claude] [codex]"
codex "$task" modify state:doing
codex "$task" modify state:fixed
codex "$task" done
check "a verified task is done" "$(field "$task" state) $(field "$task" status)" "done completed"
codex "$task" modify state:open
check "a done task reopens" "$(field "$task" status) $(field "$task" end)" "pending "
codex "$task" modify state:doing
codex "$task" modify state:fixed
codex "$task" modify state:done
check "state done completes the task" "$(field "$task" status) $(field "$task" end | cut -c1-2)" "completed 20"

codex add "a typo in the README" +bug state:open assignee:codex
check "a bug needs a definition of done" "$(task /typo/ count)" 0
codex add "a typo in the README" +bug state:open assignee:codex "body:DONE WHEN: the README spells it right"
bug=$(task /typo/ _uuid)
check "an assistant adds a bug as open" "$(field "$bug" state)" open
codex add "a fixed typo" +bug state:fixed
check "an assistant cannot add a bug past open" "$(task /fixed.typo/ count)" 0
codex "$bug" annotate "cannot reproduce on main"
codex "$bug" modify state:rejected
check "rejected closes the task" "$(field "$bug" status) $(field "$bug" end | cut -c1-2)" "deleted 20"
claude add "flaky spec" +bug state:open assignee:claude "body:DONE WHEN: 100 runs pass"
flaky=$(task /flaky/ _uuid)
claude "$flaky" modify state:doing
claude "$flaky" modify assignee:"$USER"
check "an assistant does not hand over a task in doing" "$(field "$flaky" assignee)" claude
claude "$flaky" modify state:open assignee:"$USER"
check "an assistant hands over a task in open" "$(field "$flaky" assignee)" "$USER"
human "$flaky" modify assignee:claude
claude "$flaky" delete
check "a deleted task is rejected" "$(field "$flaky" state)" rejected

long=$(python3 -c "print('x' * 501)")
human add "long comments" assignee:"$USER"
mine=$(task /long.comments/ _uuid)
human "$mine" annotate "$long"
check "the limits bind the human too" "$(comments "$mine")" 0
claude "$mine" annotate "$long"
check "the limits bind an assistant" "$(comments "$mine")" 0
human "$mine" modify tags:0.6
check "a tag starts with a letter" "$(field "$mine" tags)" ""
human "$mine" modify "body:first line
second line"
check "the body keeps line breaks" "$(field "$mine" body)" "first line
second line"
claude "$mine" modify state:bogus
check "an unknown state is refused" "$(field "$mine" state)" idea

claude add "pick the cops" assignee:"$USER" "body:all, or enabled only?"
asked=$(task /cops/ _uuid)
claude add "run them on the specs too" assignee:claude
question=$(task /run.them.on/ _uuid)
claude "$question" annotate "on the specs as well?"
claude "$question" modify assignee:"$USER"
claude "$question" annotate "built the specs part meanwhile"
check "an assistant does not comment on a task that waits for the human" "$(comments "$question")" 1
claude add "later" assignee:"$USER" depends:"$asked"
codex add "codex's own work" +bug state:open assignee:codex "body:DONE WHEN: it works"
human "$mine" modify state:postponed
list=$(task mine)
check "mine lists the human's live, unblocked tasks" "$(echo "$list" | grep -c '^## ')" 2
human add "for a later version" version:0.10 priority:H assignee:"$USER" "body:DONE WHEN: later"
human add "for the next version" version:0.9 assignee:"$USER" "body:DONE WHEN: next"
check "mine puts tasks with no version first, then by version" \
  "$(task mine | grep '^## ' | tail -2 | cut -d' ' -f4- | tr '\n' '|')" "for the next version|for a later version|"
check "mine shows the question" "$(echo "$list" | grep -c '^\[claude\] on the specs as well?$')" 1
check "mine shows the body when nobody asked" "$(echo "$list" | grep -c '^all, or enabled only?$')" 1
check "each assistant sees only its own work" "$(SQUIRE_AUTHOR=codex task mine | grep -c '^## ')" 1
check "mine shows the tags" "$(SQUIRE_AUTHOR=codex task mine | grep -c '^open · +bug$')" 1
claude add "a long title that wraps when the terminal is eighty columns wide" +bug state:open "body:DONE WHEN: it fits"
check "board shows the tags" "$(task /wraps.when/ board | grep -c ' bug ')" 1
check "board puts tasks with no version first, then by version" \
  "$(task board | grep -oE '(later|for the next version|for a later version)$' | tr '\n' '|')" "later|for the next version|for a later version|"
check "board shows one line per live task" "$(task board | wc -l | tr -d ' ')" "$(task status:pending count)"

human rc.recurrence=off add "monthly scan" recur:monthly due:tomorrow state:open assignee:claude "body:DONE WHEN: the scan is filed"
SQUIRE_AUTHOR=claude task list >/dev/null 2>&1
check "an assistant's command adds the instance" "$?" 0
check "a recurring task stays a template" "$(task export | python3 -c "import json,sys; print(sum(t['status'] == 'recurring' for t in json.load(sys.stdin)))")" 1
check "the instance keeps the template's author" \
  "$(task status:pending /monthly/ export | python3 -c "import json,sys; t=json.load(sys.stdin)[0]; print(t['state'], t['author'], 'parent' in t)")" "open $USER True"

for n in 1 2 3 4; do human rc.hooks=off add "old task $n"; done  # more than rc.bulk asks about
human rc.hooks=off add "written before the version order" version:0.9
squire init >/dev/null
check "init gives older tasks the version order" "$(field "$(task /before.the.version.order/ _uuid)" version_order)" "000000.000009"
check "init gives the order to many tasks at once" "$(task /old.task/ export | python3 -c "import json,sys; print(sorted({t.get('version_order') for t in json.load(sys.stdin)}))")" "['0']"

human add "answer me" assignee:claude "body:DONE WHEN: answered"
answered=$(task /answer.me/ _uuid)
human "$answered" annotate "the answer"
claude "$answered" annotate "my note"
check "mine shows the newest comment by someone else" "$(SQUIRE_AUTHOR=claude task mine /answer.me/ | grep -c "^\[$USER\] the answer$")" 1

[ "$failures" -eq 0 ]
