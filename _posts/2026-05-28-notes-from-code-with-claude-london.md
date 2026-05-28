---
layout: post
title: "Notes from the margins of Code with Claude London"
date: 2026-05-28 12:00:00 +0100
categories: ai engineering
---

"Hands up — who shipped a PR from Claude this past week without reading the diff?" The question came from the stage, flat, no setup. Most of the room raised their hands. The way you'd raise your hand if someone asked who uses git.

I wasn't on the floor for the first day. Anthropic announced the second day three days before the conference started, once it became clear that demand was running way past capacity, and that's the ticket I got.

For anyone who'd rather watch than read, the [YouTube playlist is here](https://www.youtube.com/watch?v=K4-flzsPraE&list=PLmWCw1CzcFilPJdvw6scjHjbBripZWFps). The talks I missed I caught later on video — two parallel stages mean you can't be in three places at once.

<figure>
  <img src="/assets/images/code-with-claude/venue.jpg" alt="The Code w/ Claude London venue exterior, with branding and registration tents along the boardwalk.">
  <figcaption>Code w/ Claude London — the venue on the morning of day two.</figcaption>
</figure>

Day two: six hundred and change people, two main stages, a workshop track in the rooms next door. I came to a conference about engineering around AI, so the *subject* was no surprise — I've spent the last year working on exactly this. The surprise was somewhere else. The stuff I'd been piecing together from threads, notes, and my own experiments turned out to already be consensus in a room of six hundred people. Nobody needs convincing about where the future is. We're already there.

## The argument is over

Nobody is debating coding with AI versus not. Nobody is asking how best to use AI to write code. Nobody is showing slides titled "10 tips for prompting Claude." That question is settled. AI writes code. New normal.

Every talk I saw and every conversation I had in the hallway was about engineering around agents. How do you get an agent to solve a task on its own? How do you get it to solve it *well*? How does it learn from its mistakes? How do you hand it the right context? How do you give it memory? How do you teach it what "good design" and "bad test" actually mean? How do you organize a team of six people and three hundred agents so the whole thing functions?

Judging by the talks, the strongest engineers at serious companies are not working on the product. They're working on the infrastructure around the agents. That's where the work pays off right now.

<figure>
  <img src="/assets/images/code-with-claude/laptop.jpg" alt="A laptop in the audience with a terminal multiplexer running an agentic workflow during a talk.">
  <figcaption>The view from the audience — most of us were running agents while watching the talks about running agents.</figcaption>
</figure>

How Anthropic itself runs its AI-first engineering teams:

- Code is the source of truth. Anything that can be codified should be. Prototypes instead of documents. Design is code, not a mock.
- Anything Claude can do, Claude should do.
- Flat teams. The manager is part of the team and writes code (with Claude, naturally). Everyone starts as an IC, and polycules form around the products.
- Async agent work to take pressure off engineer attention: keeping PRs current, triaging user feedback.

## Memory and context

The second thread, running through half the day-one talks, is agent memory. Self-learning. Context accumulation. Agents that get better at their job over time.

Anthropic shipped updated memory for their cloud agents during the conference. It reminds me of [the LLM-wiki implementation](https://github.com/ivankuznetsov/llm-wiki) I built for my own work.

What I find interesting here: Andrej Karpathy, in one X post last fall, planted the concept — memory is markdown files, plus headless agents that keep them current on their own — and shipped the prompt as a Gist. From that one statement grew what hundreds of different people are now doing, and what Anthropic is now baking into a product. I keep being surprised at how a simple, non-mathematical, non-"academic" idea can set a whole direction. Not embeddings, not vector databases — markdown files in a folder and an agent that re-reads them in its sleep. The Karpathy prompt itself is poetry; go read it.

The other use of memory is avoiding repeated mistakes — Warp's talk about their agent that replies to tweets. I'm sitting in the audience and gradually realizing there's nothing in the architecture I couldn't build over a weekend. No managed platform, no special infrastructure. A headless agent in cron. One agent spins in a loop and spawns the others. A folder of skills — each skill knows how to reply to a particular kind of tweet.

The logic is just as plain. The agent first decides whether a given tweet needs a reply at all — about half don't. For the ones that do, it drafts a reply and drops it into Slack. A human either approves it (the reply goes out) or writes back in the thread saying what's wrong. The agent reads the feedback and rewrites. Sometimes several rounds.

Here's the part that matters. When the Slack thread closes, the agent looks at the whole exchange and decides whether there's something generally applicable in it. If the situation looks reproducible, the agent edits its own skill, adds the lesson as a rule, and opens a PR.

## How do you give an agent taste?

Models, left to themselves, produce the industry average. This is true for everything — interface design, the agent's judgment of its own work, all of it. But we want output that isn't average.

Average isn't a property of the model. It's a property of the prompt and the workflow. The strongest talk I saw on this was the one on building eval-as-taste, using a slide-generating agent as the worked example, with practical code for a simple evaluator that scores the agent's output. An eval is a higher-order test for non-deterministic output. You can't compare the result to a reference byte-for-byte, but you can score it on a set of criteria. The eval also doubles as the agent's goal: "don't merge a PR that worsens this eval. Change the code so this eval improves." You hand the agent the eval as a function to optimize. An agent has no taste of its own. You give it taste through an evaluator.

The other talk that stuck with me was about writing quality prose with Claude — text that gets past the neuroslop ceiling. The recording isn't up yet, but here are the two ideas I took away:

First — *persona instead of rules.* If you have a long document that says "don't use em-dashes, don't write throat-clearing intros, avoid the word 'leverage'" — throw it out. Replace it with one line: "you are Hemingway." Or: "you are a finicky New Yorker editor." A persona is compression. One word holds thousands of rules you'd otherwise try to write down by hand and still forget half of. The model already knows how Hemingway writes. Give it something to grab onto.

Second — *agents as rivals.* A single agent drifts toward sycophancy. Whatever you write, it'll say "great question" and agree. Useless for quality. You need tension. You need agents to argue with each other asynchronously and leave each other comments. Programmer and code reviewer is the canonical adversarial pair. Writer and editor is another.

The writer is allowed to defend their text, their style, their decisions. The editor exists not to agree but to argue. The editor's job is to ship a good text, not to make the writer feel good. Two people fighting write better than one trying to make everyone happy.

I tried to apply the findings from that talk in [a still-rough skill](https://github.com/ivankuznetsov/agent-plugins/tree/main/plugins/agent-writing) that shows the concept in action. It's the plugin that produced this very post — writer and editor as rivals, a journalist persona doing the research first.

## Is prompting dead?

No, it just moved. It's no longer about prompts for one-off tasks; it's about prompts for agentic workflows. Modern agents have gotten good at clarifying the user's one-off prompt, so the perfect prompt stops mattering as much when all you want is to fix a bug in your best b2b SaaS. On top of that, planning skills have proliferated, from the built-ins to Superpowers and Compound Engineering. But once you're talking about agents that run on their own, even small ones — writer and editor above — changes in the prompt move the result enormously.

For long multi-step workflows the prompt doesn't just improve the result; it can save tokens. There are already two published talks worth reading on this: the prompting playbook, and "Tool, skill, or subagent? Decomposing an agent that outgrew a prompt." The first is the basics; the second is for people building agent workflows. I won't recap them.

The most vivid example of prompt-versus-workflow for me was the Minecraft contest — teams were given a repo with an agent and access to a Minecraft server, where the agent controlled a character. The task: collect the most ore using the fewest tokens in a limited time. A long agentic workflow with tool calls, and in a 3D environment on top of that. I got the default result from 7 up to 9. Some people got to 20 — I didn't see their prompts, so I can't tell you how they did it.

## Engineering in the AI era

The most professionally interesting topic for me, second only to bots playing Minecraft, was managing AI-first teams and building AI-first engineering workflows. Some of these ideas I'd arrived at on my own, from articles and intuition, but I wanted to hear from people doing this at scale.

Two good case studies: Base44 and Spotify.

**Base44** is a startup building a vibe-coding tool in the Replit vein. Wix acquired them, and over a few months they went from "one guy is the CTO, the CEO, and the founder, all at once" to a team of eighty. The talk goes through the scaling problems they hit at each stage and how they solved them. How do you onboard new hires onto a project that changes faster than anyone can write documentation?

They wrote two prompts. First: *"look at the project, the commit history, the reviews — carefully — and tell me what the people working on this codebase actually care about."* Second: *"draw a mermaid diagram of how the part of the project I'll be touching works."* That's the entire onboarding. A new hire walked in and three days later shipped a WhatsApp integration into the Base44 app. They applied the same trick to code review — a reviewer skill that scores code with the eyes of the CTO, which got the co-founder off the critical path. The Base44 commit-mining prompt is more interesting than the one I used in [my own writeup on code review with Claude](https://github.com/ivankuznetsov/agent-plugins). *"Look for the things people who worked on this codebase cared deeply about."* That's poetry.

Product management was replaced by an A/B test setup that a custom AI rig handles itself — plans the experiment, kicks it off in PostHog, surfaces status in a custom dashboard.

Next bottleneck: QA. They took the existing pieces of test infrastructure (how to create a user in the database, how to verify an event landed in Mixpanel) and packaged them as skills, so the agent doesn't have to re-derive the same scaffolding every time. They built a CLI for test setup, deliberately ergonomic for Claude. And on top of all of it, a meta-skill: how to do QA for Base44, given a CLI and a library of skills.

One line I wrote down separately: "things determined by taste need to be pulled out of the history and turned into skills." Taste isn't an epiphany. Taste is an extractable artifact. If there's a person on your team who intuitively knows what a feature should look like, find where they showed it — in a review, in a commit, in a thread — pull the signal out, package it as a skill. From there the agent works to *your* taste, not to the industry average.

**Spotify** — same idea at a different scale.

- 4,500 production deploys per day.
- 73% of PRs go through an agent.
- AI-assisted PR volume up 76% year-over-year (the whole funnel — both PRs the agent writes end to end and PRs where it nudges a human).
- Production codebase growing 7× faster than engineering headcount.
- 2.5 million PRs are automated maintenance — dependency bumps, package versions, all the scaffolding.

That last number is pre-AI. Spotify was already living in a world where the boring processes were codified and run by robots. Instead of a meeting about migrating service X from contract v2 to v3, they have a service that performs the migration.

The "big release" model does not survive in the AI era. Not because it's bad, but because it doesn't pair with how agents work. An agent is more effective the more independently it can verify its own result. Tests, canary, metrics, prod observability, evals, the ability to roll back — that's the macro-layer. A two-week release with a manual regression suite suffocates the agent. The agent itself becomes the bottleneck.

## Boris, a calculator, and seven likes

I'd never seen Boris Cherny in person before — only through Claude Code materials. He told his own story from the stage.

He has no CS background. He started programming to get better grades in school math by writing a program for the calculator. Never studied classical algorithms theory. He joined Anthropic and landed on a team building Anthropic's own code editor. At the time — hold on for this — Anthropic's biggest token customer was Cursor, at 95% of all consumption. So Anthropic was paying for its models to power somebody else's product, and wanted its own.

The project moved slowly. To be clear: slowly *by Anthropic standards* means three months on a code editor before the project nearly got killed.

Boris took a different route: a CLI instead of an editor, solo instead of a team, a side project instead of a roadmap item. Two weeks. Shipped.

The first release got seven likes. That's Claude Code — the product millions of people now use, generating billions in revenue.

PMF arrived later, when Opus 4 came out — the first model that could run long and autonomously, producing code you didn't have to babysit.

On stage he was relaxed about all of it. It worked because he tried.

## Regular people, doing the work

The speakers I got to talk to came into AI from ordinary engineering, not from an ML PhD. They started playing with AI — out of curiosity, out of work, out of boredom — and didn't stop. They got into research because they were interested, not because they'd picked the academic track ten years ago.

AI has sharply lowered the floor on applied research. Used to be that doing anything meaningful in models and agents required reading mathematical papers, knowing what attention is, telling LSTM from GRU and so on. Now — most of the applied knowledge can be unblocked by Claude or Codex.

I look at how memory is built at Anthropic and I recognize a paper I read myself three months ago. I recognize in their solution the same solution I arrived at. Theirs is deeper, better integrated — but there's no inhuman math in there. There are just people doing their job.

Most of working with agents is working with markdown files, text, and JSON. This isn't fine-tuning and it isn't deep ML engineering. It's engineering, but from a different side — the side of interacting with the model, not training it. Dario Amodei, who founded Anthropic, came into ML from biology — a neuroscience background, not CS. Amanda Askell, a philosopher by training, defines a lot of Claude's "character" in the system prompts and is the most influential woman philosopher in history, if not the most influential philosopher full stop.

Not gods firing pots.

## What about the catering?

<figure>
  <img src="/assets/images/code-with-claude/author.jpg" alt="The author standing in front of a large Code w/ Claude wall at the venue.">
  <figcaption>The Code w/ Claude wall, for the obligatory conference photo.</figcaption>
</figure>

Anthropic ran the conference clean. Six hundred people, two stages, plus the parallel workshop track — and not a single queue anywhere, enough seats for everyone, enough outlets for everyone, the internet worked. Avocado toast and specialty coffee for breakfast, flatbread with lamb and rosé for dinner. I don't know where they found these event organizers, but it's top tier — in twenty years of attending tech industry events for a mass audience, I haven't seen anything better organized.

## The hands in the room

Back to the hands.

They go down as quietly as they went up. Nobody looks sideways at the person next to them. The speaker nods and moves to the next slide. Nobody thinks anything notable happened. It's just the work everyone has been doing for the last year.
