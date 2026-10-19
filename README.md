## taskwarrior-squire

Frustrated with a 1.4 MB `TODO.md` whose longest line ran to 66 KB, and failing to resist the urge, built a new tool: `taskwarrior-squire`, a task tracker for one human and the AI assistants who work for them.

It is [taskwarrior](https://taskwarrior.org) carrying a working agreement between you and your assistants, and a hook that enforces it. Every warrior needs a squire.

### What it adds to taskwarrior

- **A flow.** `state` is `idea`, `open`, `doing`, `fixed`, `done`, `postponed` or `rejected`. Only you approve an idea; an assistant files a broken thing with an obvious remedy as a `+bug` and gets on with it.
- **Hand-offs.** `assignee` says who acts next. A question, an approval, a manual test, a push to production: the assistant assigns the task to you and says what it needs. You answer in a comment and assign the task back.
- **`task mine`.** The live, unblocked tasks assigned to you, most urgent first, each with what you are asked on top. For an assistant, it is the work queue.
- **`task board`.** Every live task on one line: UUID, state, assignee, priority, version, ref, title.
- **Authors.** Every task, change and comment records who made it.
- **Hygiene.** A title is at most 80 characters, a body 800, a comment 500, for everyone.
- **A skill** that teaches an assistant all of the above.

Everything else (dependencies, priorities, tags, urgency, search, history, undo) is plain taskwarrior.

### Why

The flow comes from a project where assistants found and fixed about two thousand discrepancies, and asked the human only about the rest. It outgrew the markdown files it started in.

- Priorities survive when the assistant's context is cleared. They live in the database, not in its head.
- The assistant asks a question by assigning the task to you, and keeps working on something else.
- New scope starts only when you approve it. A bug with an obvious remedy goes straight to work.
- No task grows into an essay. Long text is refused at the door.

### Install

    brew install pirj/tap/taskwarrior-squire

Then, in the project:

    squire init

It prints `TASKRC` and `TASKDATA`: set them for the project directory with whatever sets your per-directory environment (mise, direnv, …). For Claude Code it also writes the env into `.claude/settings.json` and, in `.claude/skills/`, a skill that reads the installed one, so upgrades reach the assistant. Your `~/.taskrc` still applies; the squire taskrc includes it. The database, `taskchampion.sqlite3`, appears in the `TASKDATA` directory on first use.

### Flow

```mermaid
stateDiagram-v2
    direction TB
    [*] --> idea: anyone adds new scope,<br/>assigned to you
    [*] --> open: an assistant adds a +bug<br/>(broken, obvious remedy)
    idea --> open: you approve
    idea --> rejected: you reject
    open --> doing: the assignee starts
    doing --> fixed: the assignee fixes
    fixed --> done: a reviewer verifies: task done<br/>(an assistant, or your manual test)
    fixed --> open: a reviewer finds a fault
    open --> postponed: postpone
    postponed --> open: resume
    open --> rejected: won't fix, cannot reproduce,<br/>not needed: task delete
    note left of open
        In any state, a question, an approval
        or a manual test goes to you:
        assignee is you, your comment answers.
        depends: blocks a task until another is done.
    end note
```

Any task can be `postponed` or `rejected`, from any state. `done` and `rejected` close the task; another state opens it again.

The human is `$USER`. An assistant sets `SQUIRE_AUTHOR` to its own name.

### Cheat sheet

You:

    task add "Add rubocop to the demos" state:open priority:H version:0.5 assignee:claude
    task mine
    task 9c1e0f2a annotate "B: only the default cops" && task 9c1e0f2a modify assignee:claude
    task 77ab31d0 modify state:open
    task state:idea board

The assistant:

    task mine
    task board
    task 469e1a60 modify state:doing
    task 469e1a60 annotate "Added to all demos in 3f2a1c9"
    task 469e1a60 modify state:fixed
    task 469e1a60 done
    task 5d0e4b17 annotate "Cannot reproduce on main" && task 5d0e4b17 modify state:rejected
    task 77ab31d0 modify depends:469e1a60
    task 469e1a60 info

Use the UUID prefix in references; taskwarrior renumbers its short numeric IDs. All of it: `man taskwarrior-squire`.

### Assistants

The assistant needs three variables: `TASKRC`, `TASKDATA`, and `SQUIRE_AUTHOR` set to its name (`claude`, `codex`, anything). `squire init` writes them for Claude Code. For another assistant, put them in its environment, and point it at the skill: `$(brew --prefix)/share/taskwarrior-squire/SKILL.md`, or tell it in `AGENTS.md` to read `man taskwarrior-squire`.

### Architecture

The taskrc declares the fields, the hooks directory, and `mine` as an `execute` alias. The rules are one hook in Python. `squire init` only writes the environment; after that, there is no squire binary between you and `task`.

If the database sits in a git-tracked directory, you choose whether to commit it or to ignore it. It is a binary file: git shows no diff for it.

Tests: `make test`.

### Why not

- **taskwarrior alone**: no flow and no limits. A comment has no author, so an assistant that uses your account writes as you.
- **[beads](https://github.com/gastownhall/beads)**: `bd init` wrote 19 files into the repository, among them other assistants' configs and five git hooks. It also tells your assistant to stop using its own memory.
- **[Backlog.md](https://github.com/MrLesk/Backlog.md)**: markdown files again. We are escaping from those.
- **[git-bug](https://github.com/git-bug/git-bug)**: open or closed, and nothing in between.
- **GitHub Issues**: needs the network, and the assistant writes with your token, so everyone is you.
- **Jira**: no.
- **[DoltLite](https://www.dolthub.com/blog/2026-03-25-doltlite/)** as the storage, not yet: it is a SQLite with commits and merges, and TaskChampion's storage is pluggable. Two branches would then merge their tasks.

## License

taskwarrior-squire is released under the [MIT License](https://opensource.org/licenses/MIT).
