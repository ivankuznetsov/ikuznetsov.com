---
layout: post
title: "Building Hive: the Ruby implementation behind \"the folder is the agent\""
date: 2026-06-11 12:00:00 +0100
categories: ai engineering ruby
description: "Kieran Klaassen's folder-as-agent concept came with one sentence of implementation detail. Hive is my machinery for it: a state machine made of folders, markdown markers, and a Ruby daemon that ships PRs unattended."
image:
  path: /assets/images/posts/hive-folder-agent/og.png
  width: 1200
  height: 630
  alt: "A terminal showing ls of nine Hive stage folders and an mv command moving a task from brainstorm to plan."
twitter:
  card: summary_large_image
---

Back in April, ["The Folder Is the Agent"](https://every.to/source-code/the-folder-is-the-agent) by [Kieran Klaassen](https://x.com/kieranklaassen) arrived in the Every newsletter; twelve days later, I landed the [first commit](https://github.com/ivankuznetsov/hive/commit/e49041ba) of Hive — a CLI/TUI tool that turns a rough software idea into a merge-ready pull request by driving coding agents through a folder-based pipeline. By May 20, there was a v0.1.0 release, and the public demo shows the whole Hive loop on a real repo: I seeded [ivankuznetsov/shipped](https://github.com/ivankuznetsov/shipped) with a one-sentence idea, "a Telegram bot that sends a daily digest of what was shipped," and Hive drove it through brainstorm, plan, implementation, and multi-agent review, landing the result as [PR #1](https://github.com/ivankuznetsov/shipped/pull/1).

If you'd rather read code than prose, the repo is [github.com/ivankuznetsov/hive](https://github.com/ivankuznetsov/hive) and the docs are at [hivecli.sh](https://hivecli.sh) — everything below is in there. I introduced Hive itself in [an earlier post]({% post_url 2026-05-26-introducing-hive %}); this one is about the architecture.

<figure class="demo-video">
  <video muted loop playsinline preload="metadata">
    <source src="/assets/videos/hive/ph-loop.mp4" type="video/mp4">
  </video>
  <figcaption>The whole Hive loop in 49 seconds: capture an idea, answer brainstorm questions, hands-off pipeline, archive the shipped task</figcaption>
</figure>

## The concept: a folder is already an agent

An agent needs three things: instructions, capabilities, and memory. A project folder already carries all three — a `CLAUDE.md` telling the model how to work here, skill definitions, and the context that piles up in files as you work. You don't need an advanced RAG database for it: the everything-is-a-file model perfectly suits what modern LLMs and coding agents can do. Point a model at the folder and you have an "agent". That's the entire concept, and Klaassen's formulation of it is worth quoting verbatim:

> "A project folder with a CLAUDE.md/AGENT.md (the file that tells an AI how to work in your project), some skill definitions, and context accumulated through months of compound engineering—that's an agent."

He mentioned that he runs 44 of these folders-as-agents across multiple projects — a source folder, a customer-support folder, a bug-investigation folder, each a persistent specialist. The part his piece doesn't walk through is the machinery that runs them unattended. The entire technical disclosure is one sentence:

> "There's a Ruby daemon that watches a directory for spawn requests...Workers report back by writing files. The daemon checks status every 60 seconds."

Beyond that sentence the piece contains nothing you could build from. I wanted to figure out how the machinery might actually work for me, and I learn best by building — so I pointed my agents at the concept and let them take a few runs at it. Ten days of those tries later, the first draft of Hive was born.

## Everything starts with a loop

The loop I wanted to stop running by hand: Hive started as a research project, and every good research project requires a good problem to solve. When I read Klaassen's piece, I recognized my own workflows in it — the ones I run in a loop, multi-agent code review above all. Reviewing a serious PR with multiple agents meant multiple Claude Code and Codex instances open at a time, with me as the dispatcher between them. I didn't want to sit and orchestrate them manually.

<figure>
  <img src="/assets/images/posts/hive-folder-agent/review-pass.svg" alt="Flow diagram of one Hive review pass: a CI-fix agent, three sequential cross-vendor reviewers (claude and codex), an orange triage step, a fix agent, then either another pass (capped at 2) or a browser test ending in REVIEW_COMPLETE.">
  <figcaption>Current design of the code review stage in Hive</figcaption>
</figure>

## Design decisions

One structural decision diverges from Klaassen's setup, and it's worth being explicit about. His folders are persistent specialists, each accumulating domain context for months. Hive keeps the principle — a folder plus markdown files as the agent's entire observable state — and changes the unit: a Hive folder is a task, and the folder moves. So I built a state machine with folders.

Every task is a directory inside one of nine stage folders:

`1-inbox → 2-brainstorm → 3-plan → 4-execute → 5-open-pr → 6-review → 7-artifacts → 8-finalize → 9-done`

The folder's location is the task state, which makes the pipeline a state machine you and your agents can read with a simple `ls`. Approval is `mv`: moving a task from `2-brainstorm/` to `3-plan/` is the approval gesture, and the daemon monitors the folder and takes it from there. By the time a task reaches review, its folder holds `idea.md`, `brainstorm.md`, `plan.md`, `task.md`, `pr.md`, `worktree.yml`, and a `reviews/` directory with per-reviewer files like `claude-ce-code-review-01.md` and `codex-ce-code-review-01.md`.

So the main architecture principle is:

> Hive needs state that any editor, shell, or git command can inspect. Folder location, markdown files, and git commits keep the queue portable and auditable.

Here is what that looks like in production — the live state directory of the project behind Writero, the writing tool I run Hive against sometimes:

```
writero/.hive-state/                  # worktree of orphan branch hive/state
├── config.yml                        # project pipeline config (+ .lock while the daemon holds it)
├── stages/
│   ├── 1-inbox/
│   ├── 2-brainstorm/
│   ├── 3-plan/
│   ├── 4-execute/
│   │   ├── add-download-icon-on-media-260527-e058/
│   │   └── writero-needs-an-option-to-260601-273b/
│   ├── 5-open-pr/
│   ├── 6-review/
│   ├── 7-artifacts/
│   ├── 8-finalize/
│   └── 9-done/
│       └── we-need-to-support-media-260526-c4c0/
│           ├── idea.md  brainstorm.md  plan.md  pr.md
│           ├── task.md               # ends with:  <!-- COMPLETE -->
│           ├── meta.yml  worktree.yml
│           └── reviews/
├── logs/we-need-to-support-media-260526-c4c0/
└── patrol/                           # findings, patches, reports from unattended scans

writero.worktrees/                    # sibling dir: one feature worktree per task
├── add-download-icon-on-media-260527-e058/
└── we-need-to-support-media-260526-c4c0/
```

A few conventions carry the whole thing. Task names are the idea's first words plus a date and a short hash — `we-need-to-support-media-260526-c4c0` was filed May 26 — so a slug stays unique and readable in `ls` without any registry.

The two tasks sitting in the `4-execute/` folder are real work in flight; the daemon's view of the queue is exactly this listing. Each task gets a matching directory under `logs/` for full agent transcripts and a worktree under `writero.worktrees/` for the implementation itself, so deleting a task is removing a folder in three places. And because `.hive-state/` is a git worktree, every transition is a commit on the `hive/state` branch — the log reads like a flight recorder, with subjects like `hive: 4-execute/add-download-icon-on-media-260527-e058 execute_waiting_dirty_worktree`. Your Claw or Hermes or Claude can read this perfectly and steer Hive even without the TUI (I even published a Hive skill on Clawhub).

Some of my projects run this layout today; [agent-plugins](https://github.com/ivankuznetsov/agent-plugins), `screenote`, [xbookmark](https://github.com/ivankuznetsov/xbookmark), and Hive's own repo carry the same `.hive-state/` next to their checkouts, because Hive builds Hive.

### Where the context accumulates

Changing the unit from specialist folder to task creates a problem Klaassen's design never has: his folders are valuable precisely because of "context accumulated through months of compound engineering," and a task folder archives itself after a few days.

Hive splits the accumulation across three layers. Within a task, context flows forward as files: the brainstorm agent reads `idea.md` and writes `brainstorm.md`, the planner turns that into `plan.md`, reviewers write findings into `reviews/`, finalize distills `summary.md` — each stage leaves a durable result the next stage can trust, instead of a conversation that dies with the session.

Across tasks, the long-term memory is the project's [LLM-wiki]({% post_url 2026-04-21-how-i-built-a-self-maintaining-knowledge-base-for-6-projects-using-claude-code-and-karpathys-llm-wiki %}): Hive ships expecting the llm-wiki and compound-engineering plugins next to the agent CLIs, the installer brings a managed QMD full-text index for it, and the plan stage's default skills — `/plan` for Claude, `/llm-wiki:wiki-plan` for Codex — search that wiki for past patterns, decisions, and pitfalls before designing anything new, so a lesson written down once comes back as context in every later task's planning pass.

And underneath both layers, the `hive/state` branch holds every marker, review, and transition of every task ever run — an archive any future agent can grep. Hive's own repo is the existence proof: the 131-document wiki and 34 ADRs behind it are maintained by the same loop they document.

## Markers: how agents and humans hand off

Inside each stage, handoff happens through HTML comments appended to the bottom of the stage's state file, and the last marker wins: `AGENT_WORKING`, `WAITING`, `COMPLETE`, `ERROR`, `REVIEW_WAITING`, `REVIEW_COMPLETE`, and a few more. An agent finishes its phase by appending a marker; the daemon reads it on the next tick and decides what runs next. Human edits are part of the protocol — answering a `WAITING` question in the markdown and saving the file is a legal state transition, the same way `mv` is. The file is the final source of truth, no database needed.

## One daemon, one dispatcher

The first version had no daemon. The design was manual `mv` — me approving every transition by moving the folder — and it lasted exactly as long as it took my urge to automate to notice I had become the polling loop. The daemon is the same gesture performed on my behalf: it polls the stage folders, dispatches the next stage when a task's markers say it's ready, and waits when they say a human is needed — mid-edit, unanswered brainstorm questions, a PR not yet merged. It adds no approval logic of its own; it delegates to the same marker rules the manual `mv` path uses, so the daemon can never advance a task that a human moving folders couldn't.

One rule keeps the whole thing sane: the daemon is the only process that spawns state-mutating runs. The TUI, the Telegram bot, the unattended patrol — anything that wants work done files a request into the daemon's queue, and the daemon executes it on its tick, a few tasks at a time. One writer means no races over who moves a folder.

The other half of the daemon's job is keeping the state honest while nobody watches. Agents are processes that die mid-run, models hit usage limits, sessions get killed — and each of those leaves a marker that no longer matches reality. So the daemon carries a healer: it notices markers whose agent is gone, clears the ones that are safe to retry, waits out the ones that fix themselves with time — a usage limit clears on its own — and leaves a task red with a note for me only when automation has genuinely run out of moves.

State lives in three trees. The project checkout stays clean. All task state sits in `.hive-state/`, a worktree of an orphan branch named `hive/state` — every marker, every review file, every stage transition gets git history without touching the project's own branches. Implementation work happens in per-task feature worktrees.

## Why Ruby

Hive is written in Ruby, which is an unusual pick for agent infrastructure — the ecosystem default is Python or TypeScript. Two reasons. Ruby is my personal language of choice, and a research project moves fastest in the language you think in. And Ruby is one of the most token-efficient programming languages in common use — low-ceremony code that says more per token. In an AI-first project that gets paid twice: agents write most of the code, so every pass over the codebase costs tokens, and agents read the code back as context on every task. The entire orchestrator — daemon, nine stages, TUI, Telegram bot, patrol — is about 13,000 lines of library code. It also doesn't hurt that the one technical sentence in Klaassen's article starts with "There's a Ruby daemon."

What Ruby actually buys the project is domain fit. Hive's domain is files, processes, and YAML-plus-markdown, and Ruby's standard library treats all three as first-class. This is visible in the gemspec: the orchestration core runs on the standard library alone, and the eight runtime gems are interface and accounting at the edges — the TUI (Ruby ports of bubbletea and lipgloss), Thor for the CLI, the Telegram client, faraday for the voice transcriber, sqlite3 for usage stats. Ah, and the daemon that moves folders, shells out to CLIs, and parses markdown is the job Ruby's scripting heritage was built for.

## Where it stands

Twenty-five days separated the first commit from the first signed release. The recent work is about running unattended: patrol scans repos on its own and fixes bugs by itself, a babysitter watches open PRs and keeps them in a ready-to-merge state, and a Telegram bot surfaces the gates that need a human (like answering a brainstorm question from your bathroom throne).

When I started building in late April, I hadn't found any public implementation of the folder-is-an-agent mechanism to install or read — the article's entire technical disclosure was the sentence quoted above. Kieran has since published a guide to swarm orchestration in Claude Code, built on the TeammateTool primitive rather than folders and a daemon; the folder machinery itself stays unpublished.

Hive is my design of that machinery, made public. Now I'm working on a dockerized Hive version with a web UI and the simplest possible install flow, and I'm also experimenting with different, not-only-software-development workflows that can be done with Hive. Follow me — or better yet, follow the [Hive repo](https://github.com/ivankuznetsov/hive) for updates.
