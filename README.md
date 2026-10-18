## squire

Frustrated with a 1.4 MB `TODO.md` whose longest line ran to 66 KB, and failing to resist the urge, built a new tool: `squire`, a task tracker for one human and the AI assistants who work for them.

It is [taskwarrior](https://taskwarrior.org) carrying three extra things: a flow, an author, and rules of hygiene. Every warrior needs a squire.

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
| Done | `squire <uuid> done` | — |
| Blocked | follows from `depends:` | — |

Only a human moves a task out of `idea`. The human is whoever runs `squire` without `SQUIRE_AUTHOR`, or with it set to `$USER`.

### Answering

    squire questions                 # .squire/questions.md: everything assigned to you
    cd .squire && tuicr --file questions.md
    squire answers                   # each comment becomes your answer on its task

[tuicr](https://github.com/agavra/tuicr) is a review tool: comment on any line of a task's section. `squire answers` stores the comment as yours and hands the task back to whoever asked. On an `idea`, an answer that starts with «да», `ok`, `approve` or `+` also approves it. Answers are stored once, however often you run it.

### Rules of hygiene

The limits bind assistants. The human writes what they need.

| Field | Limit |
|---|---|
| Title (`description`) | 80 characters |
| `body` | 800 characters, line breaks allowed |
| Comment (`annotate`) | 500 characters, one comment per event |

Each comment gets an `[author]` prefix. Each task records its `author`, and each change records who made it in `changed_by`.

### Cheat sheet

    squire init
    squire add "Add rubocop to the demos" priority:H version:0.5
    squire 469e1a60 modify "body:Add rubocop, rubocop-rails and rubocop-rspec.
    One follow-up task per class of offence."
    squire 469e1a60 modify state:open assignee:claude
    squire ready
    squire 469e1a60 annotate "Added to all demos; follow-ups 9c1e0f2a, 77ab31d0"
    squire 469e1a60 modify state:fixed
    squire 469e1a60 done
    squire 9c1e0f2a modify depends:469e1a60
    squire state:idea assignee:$USER list
    squire _unique version
    squire 469e1a60 info

Use the UUID prefix in references. taskwarrior renumbers its short numeric IDs as tasks close.

### Assistants

The assistant writes as itself through one line in `.claude/settings.json`:

    { "env": { "SQUIRE_AUTHOR": "claude" } }

Then tell it in `CLAUDE.md` or `AGENTS.md`: use `squire` for tasks, and read `squire --help`.

### Architecture

The nearest `.squire/` directory up from the current one holds a taskwarrior database, one per project. `squire` is a shell script that points taskwarrior at it. The rules are a taskwarrior hook in Python. `squire-tuicr` turns questions into a file and tuicr comments into answers.

Yes, you commit the SQLite file to git with every change. This is a known issue. The way out is known as well: TaskChampion's storage is pluggable, and [DoltLite](https://www.dolthub.com/blog/2026-03-25-doltlite/) is a SQLite with commits and merges. YAGNI (yet).

### Why not

- **taskwarrior alone**: no flow, no author on a comment, no limits. That is what squire adds.
- **[beads](https://github.com/gastownhall/beads)**: `bd init` wrote 19 files into the repository, among them other assistants' configs and five git hooks. It also tells your assistant to stop using its own memory.
- **[Backlog.md](https://github.com/MrLesk/Backlog.md)**: markdown files again. We are escaping from those.
- **[git-bug](https://github.com/git-bug/git-bug)**: open or closed, and nothing in between.
- **GitHub Issues**: needs the network, and the assistant writes with your token, so everyone is you.
- **Jira**: no.

### Install

    brew install task        # taskwarrior 3
    git clone https://github.com/pirj/squire ~/.local/share/squire
    ln -s ~/.local/share/squire/squire ~/.local/bin/squire

Needs `python3`; answering needs `tuicr`. Tests: `test/run.sh`.

## License

squire is released under the [MIT License](https://opensource.org/licenses/MIT).
