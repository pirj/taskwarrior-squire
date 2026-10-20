# Changelog

## [Unreleased]

## [0.10.0] — 2026-10-21

- `squire init` adds a hook that gives every Claude Code session and subagent the installed skill at its start.
- The skill says: ask for a step only the human may do on the task the work belongs to.

## [0.9.0] — 2026-10-21

- The hook refuses a tag that does not start with a letter: taskwarrior reads `+0.6` and `-0.6` as text.

## [0.8.0] — 2026-10-20

- `task mine` shows the tags of each task.

## [0.7.0] — 2026-10-20

- `taskwarrior-squire(7)` lists the command for every move in the flow, the question and the answer included.

## [0.6.0] — 2026-10-20

- An assistant moves a task only along open → doing → fixed → done, and adds a `+bug` only as open. The human moves a task to any state.

## [0.5.0] — 2026-10-19

- `squire init` installs a skill that reads the installed `SKILL.md`, so an upgrade reaches the assistant without another `init`.

## [0.4.0] — 2026-10-19

- `task board`: every live task on one line, with state, assignee, priority, version and ref.

## [0.3.0] — 2026-10-19

- `done` state: `task done` sets it, and `state:done` completes the task. Another state reopens a done or rejected task.

## [0.2.1] — 2026-10-19

- `squire init` prints `TASKRC` and `TASKDATA` for any per-directory env tool; it no longer writes `mise.toml` or `.envrc`.

## [0.2.0] — 2026-10-19

- Renamed to taskwarrior-squire. The `squire` wrapper is gone: set `TASKRC` and `TASKDATA`, then run `task`.
- `task mine` replaces `squire` with no arguments.
- `make install` puts the taskrc, the hook and `taskwarrior-squire(7)` under `PREFIX`.
- An assistant may add a task tagged `+bug` in any state.
- `rejected` state for won't fix, cannot reproduce and the like; `task delete` rejects too.
- `squire init` writes the project's environment and installs the assistant skill.
- The squire taskrc includes `~/.taskrc`, so your own settings apply.
- `brew install pirj/tap/taskwarrior-squire`.

## [0.1.0] — 2026-10-19

- taskwarrior with a project database: the nearest `.squire/` directory.
- A flow in `state` (idea, open, doing, fixed, postponed); only a human moves a task out of `idea`.
- An author on every task, change and comment, from `SQUIRE_AUTHOR`.
- Length limits on titles, bodies and comments, for everyone.
- `squire` with no arguments prints the live tasks assigned to you, the question on top.
- `ref` keeps the id a task had in another tracker.
