---
layout: post
title: "Hive: I merged 25,000 lines of code I haven't read"
date: 2026-05-26 12:00:00 +0100
categories: ai engineering
---

Yesterday, I merged 25,000 lines of code. I haven't checked a single one of them. Thanks to [Hive](https://github.com/ivankuznetsov/hive)—my agentic harness that steers SOTA agents like Claude, Codex, and Pi through the "folder as an agent" pipeline—I moved from the rough idea state to the polished PR.

A few weeks ago, I found an article in the Every newsletter (which I highly recommend) from Kieran Klassen, where he described a "folder as an agent" workflow he uses for asynchronous tasks. I knew that big tech companies have asynchronous agentic workflows that run overnight, and I knew that Boris Cherny runs hundreds of agents asynchronously overnight—as he has mentioned in his talks—but all these workflows require additions to publicly available harnesses like Claude Code.

On the other side, most of the features I work on in my projects pass through the same stages every time: brainstorm (optional), plan (mandatory), coding, and a few sets of reviews made by different agents with different skills—compound engineering code review, pr-review-toolkit from Anthropic, and compound engineering code review in Codex. This exhausting set of reviews, together with extensive test coverage and evals where they are needed, allows me to look at the code less and less, and minimizes the biggest bottleneck of my work—testing.

You know this situation where 4–5 sessions of different agents are running on your screen, and you are switching between them, providing your input—it is exhaustive work, especially when the input required from you involves repetitive tasks like: do this review, fix issues, do that review, fix issues, rebase from main, fix conflicts, run tests, etc. Not the kind of creative work we all want to do, right?

So I fired up Claude and started a research folder as an agent approach. What I came to is a state machine where a folder is a current state, and the .md files are the actual tasks that drift from folder to folder as soon as the job changes states. For the past year, I've been a 100% Linux user, and I admire how well native Linux ideas—like "everything is a file"—match modern AI agentic abilities, making them a very good tandem. So my initial set of requirements was simple: a CLI that manages the work, moves tasks between stages, and launches coding agents in headless mode, dumping results into the files.

That's how Hive was born. Many, many iterations later came a daemon that moves tasks between states automatically as soon as the job is done and no user input is required, a TUI—because we all love TUIs, and we want a simple pane where we can interact with an agent—and a lot of work on recovery from incorrect states when something goes wrong, such as Claude credits being exhausted mid-flight, a user authorization prompt being required for a GitHub push, or you closing your laptop in the middle of the agent's work. This was the 20% of the work that took 80% of my time to release Hive (and will take a lot more if some of you start to use it and submit issues and PRs to the [Hive repo](https://github.com/ivankuznetsov/hive)).

I forgot to mention that the 25,000 lines I referenced at the beginning of this article constitute Hive's own codebase; I am "dogfooding" Hive every day, and I believe around 70% of the code was written using Hive itself as an orchestrator.

### So, that's the moment I want to stop talking and show you how Hive works on a sample task, step by step.

First of all, I will show you how to install and init Hive on a new project.

Hive ships as a signed Ruby gem: Homebrew on macOS (Apple Silicon), the AUR on Arch, and a one-line installer on Ubuntu 22.04+ or other glibc Linux (x86_64 / aarch64)—that last one is what the clip shows. You grab `install.sh` from the repo and run it, and it downloads the signed gem, verifies the checksum, and `gem install`s it. (In the clip I'd already downloaded `install.sh`, so you just see me run `./install.sh`.) You only need Ruby 3.4 plus git, an authenticated `gh`, and your agents (`claude`, `codex`); everything lands under `~/.local/share/hive`, so uninstalling is a clean `rm -rf`.

<figure class="demo-video">
  <video muted loop playsinline preload="metadata">
    <source src="/assets/videos/hive/install.mp4" type="video/mp4">
  </video>
  <figcaption>Installing Hive</figcaption>
</figure>

Once it's installed, you run `hive init` inside any project. It asks a handful of setup questions—which agent plans, which one writes the code, how many review rounds, whether to start the daemon—with sensible defaults (Claude for planning, Codex for development), so you can hit enter through most of it. Then it wires everything up: the `.hive-state` folder that holds your tasks, the background daemon that moves them through the pipeline, and a project wiki the agents read from and keep up to date.

<figure class="demo-video">
  <video muted loop playsinline preload="metadata">
    <source src="/assets/videos/hive/init.mp4" type="video/mp4">
  </video>
  <figcaption>Running <code>hive init</code> on a fresh project</figcaption>
</figure>

<aside class="callout">
  <p class="callout-title">In a hurry? Hand this prompt to Claude Code, Codex, or any agent CLI and it'll install Hive for you:</p>
  <div class="callout-code">
    <button type="button" class="copy-btn" data-copy-target="hive-install-prompt">Copy</button>
    <pre><code id="hive-install-prompt">Install the Hive CLI on my machine. Read https://github.com/ivankuznetsov/hive/blob/main/install.md and follow it: detect my OS, pick the right install channel, install the latest stable release, verify `hive --version`, then offer to run `hive init` in my current project.</code></pre>
  </div>
</aside>

Everything starts with an idea. So, I just open the Hive TUI and write an idea here by pressing "n."

<figure class="demo-video">
  <video muted loop playsinline preload="metadata">
    <source src="/assets/videos/hive/new-idea.mp4" type="video/mp4">
  </video>
  <figcaption>Capturing an idea in the TUI</figcaption>
</figure>

Then, the idea will be converted into a new task, and the brainstorming agent will pick it up from here. Brainstorming is the step of the process that requires the most user input, so it will produce documents with questions and wait for your answers. Typically, brainstorming requires two or three rounds of Q&A, which are done 100% inside the document that you edit with your favorite editor (I use vim), which will be opened by just pressing enter on the task that requires user input. After you save the answers, Hive will first check that all answers have been provided (you cannot miss any, sorry), and then the brainstorming agent will pick the file up and either ask new questions or move the task to the planning phase. In 99% of cases, the plan will not require any input from you—it will run the planning agent and plan review, and then will pass the plan to the development agent.

<figure class="demo-video">
  <video muted loop playsinline preload="metadata">
    <source src="/assets/videos/hive/brainstorm.mp4" type="video/mp4">
  </video>
  <figcaption>Answering brainstorm questions in vim</figcaption>
</figure>

The hardest part is what happens after development. First, Hive will open a draft PR; then, it will run review agents, triage their findings, fix them, and run the review again. At the end of this exhaustive process, it will collect artifacts and update the PR with them, moving it from draft status to open.

<figure class="demo-video">
  <video muted loop playsinline preload="metadata">
    <source src="/assets/videos/hive/archive.mp4" type="video/mp4">
  </video>
  <figcaption>Reviewing the collected artifacts and archiving the finished task</figcaption>
</figure>

Then it's your job to merge the PR.

The whole run you just watched is public. The sample project—[`ivankuznetsov/shipped`](https://github.com/ivankuznetsov/shipped), a Telegram bot that posts a daily digest of a repo's merged PRs—started as that one-sentence idea and rode the full pipeline to [PR #1](https://github.com/ivankuznetsov/shipped/pull/1). Browse the repo and the merged PR to see exactly what Hive produced.

## Now it's time to preliminarily address some of the questions you may or may not have.

### Can I select which agents and prompts to use for each stage?

Yes, Hive is highly customizable. Right now, when you run "hive init" in your project directory, it will ask you basic configuration questions based on what I call the "happy path" workflow. For instance, you can select different agents for planning and development—by default, I suggest Claude Code for brainstorming and planning and Codex for development, then run the review with both of them—or use three rounds of review instead of the default two. However, you are free to configure any workflow on top of the state machine—even add new stages like CI (if you want to do it locally) or select different prompts for headless agents (use Superpowers prompts instead of Compound Engineering for planning, for example). Hive is built for you to tinker around.

### What if I want to edit something manually?

Hive has a manual steer option—you can press "s" and Hive will open the worktree in your selected agent for the development stage (Codex by default).

### How do parallel agents avoid interfering with each other?

Each new feature works in its separate worktree and in a separate PR. Parallel work happens with two different agentic harnesses only during the review stage, where Claude and Codex (and Pi, if you wish) write their own findings to separate files and then triage them into the final list of findings to fix. Accidental parallel runs are prevented by locks using .pid files.

### How is the knowledge stored and shared between agents?

I use my own version of Karpathy's LLM wiki approach for managing knowledge. When you init Hive for the project, it automatically creates a wiki. You will have one wiki for the project and one global wiki across all projects. Agents receive info about the wiki during the initialization and update it throughout their work, together with system-scheduled runs that maintain knowledge and ensure its coherence.

### Is that the whole truth, or do you have a secret that makes Hive work for you but not for us?

I very often run Hive via another agent. I drop a few ideas, pass them through a brainstorming session, and ask Codex with the /goal command to monitor them and help if some issue arises along the way, with a goal to get them to the PR. Because hive is cli native you can easily integrate it with your agent from Claude Code to Open Claw and Hermes

### How it's better than OpenClawd or Hermes for end to end work?

Hive works as a state machine orchestrator for specialized coding agents. It's not a do-it-all agent; it's a workflow manager. So, you can give Hive to OpenClawd and they will work perfectly together—OpenClawd will use Hive headless and manage it, and Hive will do what it does best: manage coding agents from idea to PR.

I'm using Hive daily now, but as a single developer who works on it in my spare time, I have limited abilities to test it across different workflows, operating systems, and tasks. I really want your feedback. You can reach me via ivan@ikuznetsov.com or in the Discord group I created especially for Hive.

Happy tinkering.
