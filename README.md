## taskwarrior-squire

Frustrated with a 1.4 MB `TODO.md` whose longest line ran to 66 KB, and failing to resist the urge, built a new tool: `taskwarrior-squire`, a task tracker for one human and the AI assistants who work for them.

It is [taskwarrior](https://taskwarrior.org) carrying three extra things: a flow, an author, and rules of hygiene. No new binary: a configuration, one hook, one command. Every warrior needs a squire.

### Why

- Priorities survive when the assistant's context is cleared. They live in the database, not in its head.
- The assistant asks a question by assigning the task to you. You answer in a comment and assign it back.
- Nothing starts until you approve it.
- No task grows into an essay. Long text is refused at the door, and the details go in the commit message.

### Flow

    idea ──(you approve)──▶ open ──▶ doing ──▶ fixed ──(verified)──▶ done
                                                       postponed

| Situation | state | assignee |
|---|---|---|
| The assistant found something, waits for you | `idea` | you |
| A question to you | unchanged | you; the answer goes in a comment |
| Work | `open` → `doing` | assistant |
| Verification, or your manual test | `fixed` | assistant, or you |
| Done | `task <uuid> done` | — |
| Blocked | follows from `depends:` | — |

Only a human moves a task out of `idea`. An assistant adds ideas, and bugs: a task tagged `+bug` may start in any state. The human is whoever runs `task` without `SQUIRE_AUTHOR`, or with it set to `$USER`.

### What waits for you

    task mine

prints every live task assigned to you, most urgent first: one section each, with the question or the request on top. For an assistant it is the work queue. You answer with `task <uuid> annotate`, or let the assistant carry your answers in from wherever you write them: a review tool, a chat. squire only keeps them.

### Rules of hygiene

The limits bind everyone, the human too.

| Field | Limit |
|---|---|
| Title (`description`) | 80 characters |
| `body` | 800 characters, line breaks allowed |
| Comment (`annotate`) | 500 characters, one comment per event |

Each comment gets an `[author]` prefix. Each task records its `author`, and each change records who made it in `changed_by`.

### Cheat sheet

    task add "Add rubocop to the demos" priority:H version:0.5
    task 469e1a60 modify "body:Add rubocop, rubocop-rails and rubocop-rspec.
    One follow-up task per class of offence."
    task 469e1a60 modify state:open assignee:claude
    task mine
    task 469e1a60 annotate "Added to all demos; follow-ups 9c1e0f2a, 77ab31d0"
    task 469e1a60 modify state:fixed
    task 469e1a60 done
    task 9c1e0f2a modify depends:469e1a60
    task state:idea assignee:$USER list
    task 469e1a60 info

Use the UUID prefix in references. taskwarrior renumbers its short numeric IDs as tasks close. All of it: `man taskwarrior-squire`.

### Assistants

The assistant writes as itself through one line in `.claude/settings.json`:

    { "env": { "SQUIRE_AUTHOR": "claude" } }

If its shell does not load `mise.toml`, set `TASKRC` and `TASKDATA` there as well.

Then tell it in `CLAUDE.md` or `AGENTS.md`: use `task` for tasks, and read `man taskwarrior-squire`.

### Architecture

`taskrc` declares the fields, the hooks directory, and `mine` as an `execute` alias. The rules are a hook in Python. The project points taskwarrior at itself with two variables, so there is no wrapper to find it.

Yes, you commit the SQLite file to git with every change. This is a known issue. The way out is known as well: TaskChampion's storage is pluggable, and [DoltLite](https://www.dolthub.com/blog/2026-03-25-doltlite/) is a SQLite with commits and merges. YAGNI (yet).

### Why not

- **taskwarrior alone**: no flow, no author on a comment, no limits. That is what this adds.
- **[beads](https://github.com/gastownhall/beads)**: `bd init` wrote 19 files into the repository, among them other assistants' configs and five git hooks. It also tells your assistant to stop using its own memory.
- **[Backlog.md](https://github.com/MrLesk/Backlog.md)**: markdown files again. We are escaping from those.
- **[git-bug](https://github.com/git-bug/git-bug)**: open or closed, and nothing in between.
- **GitHub Issues**: needs the network, and the assistant writes with your token, so everyone is you.
- **Jira**: no.

### Install

    brew install task        # taskwarrior 3
    git clone https://github.com/pirj/taskwarrior-squire
    make -C taskwarrior-squire install        # into ~/.local; PREFIX=... for elsewhere

Then, in the project's `mise.toml`:

    [env]
    TASKRC = "{{env.HOME}}/.local/share/taskwarrior-squire/taskrc"
    TASKDATA = "{{config_root}}"

`taskchampion.sqlite3` appears in the project root. Needs `python3`. Tests: `make test`.

## License

taskwarrior-squire is released under the [MIT License](https://opensource.org/licenses/MIT).
