## taskwarrior-squire

Frustrated with a 1.4 MB `TODO.md` whose longest line ran to 66 KB, and failing to resist the urge, built a new tool: `taskwarrior-squire`, a task tracker for one human and the AI assistants who work for them.

It is [taskwarrior](https://taskwarrior.org) carrying a working agreement between you and your assistants, and a hook that enforces it. Every warrior needs a squire.

### What it adds to taskwarrior

- **A flow.** `state` is `idea`, `open`, `doing`, `fixed`, `postponed` or `rejected`. Only you approve an idea; an assistant files a broken thing with an obvious remedy as a `+bug` and gets on with it. The flow comes from a project where assistants found and fixed about two thousand discrepancies, and asked only about the rest.
- **Hand-offs.** `assignee` says who acts next. A question, an approval, a manual test, a push to production: the assistant assigns the task to you and says what it needs. Your comment is the answer, and the task goes back.
- **`task mine`.** The live, unblocked tasks assigned to you, most urgent first, each with what you are asked on top. For an assistant, it is the work queue.
- **Authors.** Every task, change and comment records who made it. taskwarrior's comments carry no author; an assistant using your account would be you.
- **Hygiene.** A title is at most 80 characters, a body 800, a comment 500, for everyone. The details go in the commit message.
- **A skill** that teaches an assistant all of the above.

Everything else (dependencies, priorities, tags, urgency, search, history, undo) is plain taskwarrior.

### Why

- Priorities survive when the assistant's context is cleared. They live in the database, not in its head.
- The assistant asks a question by assigning the task to you, and keeps working on something else.
- Nothing new starts until you approve it.
- No task grows into an essay. Long text is refused at the door.

### Install

    brew install pirj/tap/taskwarrior-squire

Then, in the project:

    squire init

It sets `TASKRC` and `TASKDATA` for you (in `mise.toml`, else `.envrc`, else it prints them). For Claude Code it also writes the env into `.claude/settings.json` and copies the skill into `.claude/skills/`. Your `~/.taskrc` still applies; the squire taskrc includes it. The database, `taskchampion.sqlite3`, appears in the project root on first use. Commit it.

### Flow

    idea ──(you approve)──▶ open ──▶ doing ──▶ fixed ──(verified)──▶ done
                                                 postponed · rejected

| Situation | state | assignee |
|---|---|---|
| New scope, waits for you | `idea` | you |
| Broken, obvious remedy | `open`, tagged `+bug` | assistant |
| A question or a request to you | unchanged | you; the answer goes in a comment |
| Work | `open` → `doing` | assistant |
| Verification, or your manual test | `fixed` | assistant, or you |
| Done | `task <uuid> done` | — |
| Won't fix, can't reproduce, YAGNI | `rejected`, or `task <uuid> delete` | — |
| Blocked | follows from `depends:` | — |

The human is `$USER`. An assistant sets `SQUIRE_AUTHOR` to its own name.

### Cheat sheet

    task add "Add rubocop to the demos" priority:H version:0.5 assignee:$USER
    task 469e1a60 modify state:open assignee:claude
    task mine
    task 469e1a60 annotate "Added to all demos; follow-ups 9c1e0f2a, 77ab31d0"
    task 469e1a60 modify state:fixed
    task 469e1a60 done
    task 9c1e0f2a annotate "YAGNI: no demo needs it" && task 9c1e0f2a modify state:rejected
    task 77ab31d0 modify depends:469e1a60
    task state:idea assignee:$USER list
    task 469e1a60 info

Use the UUID prefix in references; taskwarrior renumbers its short numeric IDs. All of it: `man taskwarrior-squire`.

### Assistants

The assistant needs three variables: `TASKRC`, `TASKDATA`, and `SQUIRE_AUTHOR` set to its name (`claude`, `codex`, anything). `squire init` writes them for Claude Code. For another assistant, put them in its environment, and point it at the skill: `$(brew --prefix)/share/taskwarrior-squire/SKILL.md`, or tell it in `AGENTS.md` to read `man taskwarrior-squire`.

### Architecture

The taskrc declares the fields, the hooks directory, and `mine` as an `execute` alias. The rules are one hook in Python. `squire init` only writes the environment; after that, there is no squire binary between you and `task`.

Yes, you commit the SQLite file to git with every change. This is a known issue. The way out is known as well: TaskChampion's storage is pluggable, and [DoltLite](https://www.dolthub.com/blog/2026-03-25-doltlite/) is a SQLite with commits and merges. YAGNI (yet).

Tests: `make test`.

### Why not

- **taskwarrior alone**: no flow, no author on a comment, no limits. That is what this adds.
- **[beads](https://github.com/gastownhall/beads)**: `bd init` wrote 19 files into the repository, among them other assistants' configs and five git hooks. It also tells your assistant to stop using its own memory.
- **[Backlog.md](https://github.com/MrLesk/Backlog.md)**: markdown files again. We are escaping from those.
- **[git-bug](https://github.com/git-bug/git-bug)**: open or closed, and nothing in between.
- **GitHub Issues**: needs the network, and the assistant writes with your token, so everyone is you.
- **Jira**: no.

## License

taskwarrior-squire is released under the [MIT License](https://opensource.org/licenses/MIT).
