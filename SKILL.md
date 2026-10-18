---
name: taskwarrior-squire
description: Use when the project keeps its work in taskwarrior-squire (TASKRC points at a taskwarrior-squire taskrc) — to pick work, file what you find, ask the human, and close tasks.
---

# Working with one human through taskwarrior-squire

The tasks are the shared memory between you and the human. Your context is
cleared; the tasks are not. Everything you will need tomorrow goes into a task.
The reference is `man taskwarrior-squire`. Read it before your first command.

## Who is who

- You write as `$SQUIRE_AUTHOR`, which your environment sets to your name.
- The human is `$USER`. Only the human approves new scope.
- The hook writes the author on every task, change and comment. Never type it.

## Start of every step

    task mine

It lists the live, unblocked tasks assigned to you, most urgent first, with
what you are asked on top. A comment from the human is an answer: act on it.

## The flow

    idea ──(human approves)──▶ open ──▶ doing ──▶ fixed ──(verified)──▶ done

| You find | You add |
|---|---|
| Something broken with an obvious remedy | `task add "<title>" +bug state:open assignee:$SQUIRE_AUTHOR` |
| New scope: a feature, a public promise, a trade-off | `task add "<title>" assignee:$USER` (an idea) |

- Take a task: `task <uuid> modify state:doing`.
- Finish it: comment what you did and the commit, then `state:fixed`.
- Verify a fixed task before `task <uuid> done`. A wrong fix goes back to
  `state:open` with a comment that says what failed.
- Drop a task: comment why, then `task <uuid> delete`.
- Work that waits for something else: `depends:<uuid>`. Work for later:
  `state:postponed`.
- Never move a task out of `idea`. The hook refuses it.

## Asking the human

The human is needed only for product scope, a public promise, a risk they own,
or a trade-off with no technically correct answer. A fact you can measure is
not a question: measure it and write it into the task.

1. Comment the question, in plain words, at most 500 characters:
   `BROKEN: … HARM: … (A) … COST: … (B) … COST: … RECOMMENDATION: …`
2. `task <uuid> modify assignee:$USER`.
3. Continue with other work. Do not guess the answer. Do not ask in chat.

The same goes for what only the human may do: a push to production, a manual
test, a script your permissions forbid, an approval. Say exactly what to run or
check, and assign the task to them.

The answer comes back as the human's comment, and the task comes back to you.

## Hygiene

- A title is at most 80 characters, a body 800, a comment 500. The hook refuses
  more. The details go in the commit message.
- One comment per event. Refer to tasks by UUID prefix: short numeric ids
  change.
- Commit the database (`taskchampion.sqlite3`) with the change that made it.
