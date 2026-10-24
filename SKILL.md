---
name: taskwarrior-squire
description: Use when the project keeps its work in taskwarrior-squire (TASKRC points at a taskwarrior-squire taskrc) — to pick work, file what you find, ask the human, and close tasks.
---

# Working with one human through taskwarrior-squire

Two kinds of actor share the tasks: the human, and assistants like you. Your
context is cleared; the tasks are not. Everything you will need tomorrow goes
into a task. The reference is `man taskwarrior-squire`. Read it before your
first command.

## Who is who

- You write as `$SQUIRE_AUTHOR`, which your environment sets to your name.
- The human is `$USER`. Only the human approves new scope.
- The hook writes the author on every task, change and comment. Never type it.

## Start of every step

    task mine

It lists the live, unblocked tasks assigned to you, most urgent first, with
what you are asked on top. A comment from the human is an answer: act on it.
`task board` lists every live task on one line.

## The flow

    idea ──human approves──▶ open ──assignee starts──▶ doing
         ──assignee fixes──▶ fixed ──reviewer verifies──▶ done

| You find | You add |
|---|---|
| A discrepancy: something is broken | `task add "<title>" +bug state:open assignee:$SQUIRE_AUTHOR "body:<what is wrong> DONE WHEN: <what shows it is fixed>"` |
| New scope: a feature, a public promise, a trade-off | `task add "<title>" assignee:$USER "body:<what and why> DONE WHEN: <what shows it is done>"` (an idea) |

Every task says how to check it: `DONE WHEN:` in its body or a comment. The
hook refuses `open` and `doing` without it. To add it to an older task:
`task <uuid> annotate "DONE WHEN: <what shows it is done>"`. Verify against it.

A bug stays a bug when its remedy needs the human's decision: add it as above,
then ask on it (below).

Work only on a task in state `open`, in this order:

1. Before the first change: `task <uuid> modify state:doing`.
2. After the fix: `task <uuid> annotate "<what changed, the commit>"`, then
   `task <uuid> modify state:fixed`.
3. After verification: `task <uuid> annotate "<what was checked>"`, then
   `task <uuid> done`. A wrong fix goes back:
   `task <uuid> annotate "<what failed>"`, then `task <uuid> modify state:open`.

- A task you will not do (won't fix, cannot reproduce, not needed):
  `task <uuid> annotate "<why>"`, then `task <uuid> modify state:rejected`.
- Work that waits for another task: `task <uuid> modify depends:<other uuid>`.
  Work for later: `task <uuid> modify state:postponed`; back with `state:open`.
- Every move with its command: `man taskwarrior-squire`, "The flow, command
  by command".
- Never work on an idea, and never move a task out of `idea`. The hook refuses
  the move; only the human decides on an idea.

## Asking the human

The human is needed only for product scope, a public promise, a risk they own,
a trade-off with no technically correct answer, or a step only they may do. A
fact you can measure is not a question: measure it and write it into the task.

The state of a task you hand over says what you ask:

| State | You ask the human to | Your comment |
|---|---|---|
| `idea` | approve the scope | the body says what and why, and `DONE WHEN:` |
| `open` | decide | `BROKEN: … HARM: … (A) … COST: … (B) … COST: … RECOMMENDATION: …` |
| `fixed` | check or deploy by hand | `CHECK: <what to run or open> EXPECT: <what they must see>` |

A task in `doing` stays with you. To ask for a decision, move it to `open`;
to ask for a check, finish it to `fixed`.

1. Write the comment so the human can answer from it alone: plain words, at
   most 500 characters, nothing they must open or look up.
   `task <uuid> annotate "<the comment>"`.
2. `task <uuid> modify assignee:$USER`.
3. Continue with other work. Do not ask in chat.

While the task is with the human, do not comment on it: the hook refuses. Your
last comment is what they read. To change it, take the task back with
`task <uuid> modify assignee:$SQUIRE_AUTHOR`, then ask again in full.

The human answers with `task <uuid> annotate "<the answer>"` and assigns the
task back to you; on an idea, that `modify` also sets `state:open`, `rejected` or
`postponed`. The task then shows in your `task mine` with the answer on top.
Act on it.

## Hygiene

- A title is at most 80 characters, a body 800, a comment 500. The hook refuses
  more.
- A tag starts with a letter. A number goes in a field: `version:0.6`,
  never `+0.6`.
- To change a body, write the full new text to a file, then
  `task <uuid> modify "body:$(cat <file>)"`. The text arrives byte for byte.
- `export` is a command, not a report: `task +tag export`, never
  `task +tag all export`.
- One comment per event. Refer to tasks by UUID prefix: short numeric ids
  change.
- If git tracks the database (`taskchampion.sqlite3`), commit it with the
  change that made it.
