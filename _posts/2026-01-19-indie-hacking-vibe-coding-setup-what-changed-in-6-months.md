---
layout: post
title: 'Indie Hacking Vibe Coding Setup: What Changed in 6 Months'
date: '2026-01-19 05:24:14 +0000'
categories:
- vibe-coding
- claude-code
- compound-engineering
- ai
- ai-agents
- coding-agents
- product-management
- hackernoon-top-story
original_url: https://hackernoon.com/indie-hacking-vibe-coding-setup-what-changed-in-6-months
canonical_url: https://hackernoon.com/indie-hacking-vibe-coding-setup-what-changed-in-6-months
source: hackernoon
excerpt: It’s far more efficient to run multiple Claude instances simultaneously, spin up git worktrees, and tackle several tasks at once.
---

In my _[previous article](/posts/heres-the-exact-indie-hacking-vibe-coding-setup-i-use-as-a-middle-aged-product-manager/)_, I broke down my vibe-coding workflow. A lot has changed since then, so it’s time to lock in what I’ve learned and share an update for those following along.

It’s only been six months, but it feels like a lifetime. I look back at my own naivety when I talked about Claude Code back then:

> I've heard a lot of positives about Claude Code but never tried it myself, because I'll still need an IDE for code editing, and I like Cursor. Paying for both Cursor and Claude Code at $400/month is a bit overkill for me. Also, I like the Cursor team after watching their interview with Lex Fridman (the best AI team interview I've heard among all the ones he made), and I want them to succeed.

A lot of water has flowed under the bridge since then, and Claude Code is now my primary tool. I use it for the vast majority of my tasks, even those unrelated to programming—like data analysis across various spreadsheet formats or generating logos via the Nano Banana 3 API.

Naturally, the biggest catalyst for this switch was the release of Opus 4.5. As a power user of Sonnet 4, I used to offload a chunk of my tasks to Cursor and various GPT-5 iterations, yet I always walked away with a nagging sense of "unfinished business." The arrival of Sonnet 4.5 already shifted about 95% of my workflow to Claude, but it wasn't quite the "slam dunk" I wanted—mostly due to the latency. Sonnet's reasoning chains were just too long-winded. I spent time experimenting with both Codex and Composer, relegating Sonnet primarily to high-level planning and code reviews. Opus 4.5 finally ended that back-and-forth; it pumps out high-quality code fast enough and actually ends up being more token-efficient than Sonnet. Even with four agents running simultaneously, I haven't managed to hit my weekly limits on the Max plan.

Three other things that have impacted my workflow the most, besides the new Opus, were: the arrival of the _[playwright skill for Claude](https://github.com/lackeyjb/playwright-skill)_, ditching safety constraints, and the _[plugins from Compound Engineering for Claude Code](https://github.com/EveryInc/compound-engineering-plugin)_.

AI testing deserves a deep dive of its own, but we’ve all been there: a dev or an AI agent hands over code that simply doesn’t work. With AI, it’s even funnier—I habitually prompt it to cover everything with unit tests, and the agent usually delivers a suite that passes perfectly, yet I still end up staring at 500 errors during actual testing.

For a long time, writing E2E tests with AI was a massive pain. I’ve never been a huge fan of E2E to begin with, mostly because the maintenance cost tends to grow quadratically as the codebase expands. Everything changed when I realized that with the right setup and new models, testing actually became simple and accessible. Now, that classic manager line—"test it yourself before handing it over to QA"—which usually gets ignored, has become a core part of my Claude.md. I just ask it to write Playwright E2E tests for all the new functionality and verify that we haven't broken anything old by running the test suite after every code edit.

When it comes to safety constraints, I used to think stories about AI agents solving tasks for half an hour without human intervention were total BS. I was constantly hitting permission prompts from Claude, even with most permissions pre-configured and the auto-mode toggled on. Everything changed once I started running Claude Code with the `--dangerously-skip-permissions` flag. That was the moment I finally got that full AGI vibe—the agent just grinds away at a task solo and hands me the finished result.

But neither of these points delivers as much impact on its own as they do when combined with the concept of Compound Engineering. It's a tricky term to translate into Russian, because in a financial context, "compound" usually just becomes "сложный" (complex/compound interest), which doesn't quite capture the structural essence here.

In my workflow, heavily inspired by the Compound Engineering methodology from Every, I build a closed-loop learning cycle: AI agents analyze errors, tests, and successful solutions, then bake that experience directly into the knowledge base (using files like `CLAUDE.md`).

This approach allows me to deliver results that previously required a team of five. My time is distributed accordingly: about 80% of the effort goes into planning, review, and testing, while only 20% is spent on actual coding. The main focus is on research—analyzing the codebase, commit history, and finding the optimal path—to then transform these insights into precise instructions for the agents.

Technically, everything I need is already baked into the Compound Engineering skills for _[Claude Code](https://mixait.ru/claude-code-cli-rukovodstvo/)_ by Every. This toolkit currently features 24 specialized agents, 13 slash commands, and 11 skills supercharged via MCP servers.

The entire workflow follows a strict "plan — delegate — evaluate — codify" loop. I’ve integrated clear checklists for testing and versioning that the agents follow religiously, ensuring a closed-loop learning process where every fix and edge case is automatically documented in the knowledge base.

## Here is how a typical compound engineering workflow looks:

![](/assets/images/posts/indie-hacking-vibe-coding-setup-what-changed-in-6-months/KLbs1aomwbUZiV9XHjj0nS36CTy1-2026-01-19T05_24_09_910Z-vnwsqhozouhfy4u5dajomt5g-af46be49.png)

First, I initiate the **Plan** phase (using the `/workflows:plan` command). This is where I transform high-level ideas into detailed specifications that serve as the blueprint for my AI agents. These plans are stored as Markdown files. For large-scale changes, the plan is broken down into manageable chunks.

A crucial part of this stage is the **Review** (via `/plan_review`), which is incredibly helpful because Claude tends to overengineer during the initial planning phase. If you need more granular detail, you can use the `/deepen_plan` command to flesh out specific sections. If your plan covers multiple features, you can run `/triage` to decide what to build, what to scrap, and what needs more refinement. Effectively, your entire engineering management process shifts into Markdown files with AI agents acting as the engineers

Next, the **Work** phase kicks in (`/workflows:work`): the system picks up the tasks, executing them in parallel using isolated git worktrees. This setup allows for progress tracking without cluttering the main branch or locking files that another agent might be working on simultaneously

Once the code is ready, I trigger the **Review** phase (`/workflows:review`). This is a multi-agent audit where several specialized algorithms hunt for bugs before the merge. Much like the planning stage, the output consists of Markdown files awaiting your `/triage`. Once approved, fixes can be executed in parallel. Just as with the initial plans, a specialized agent builds a dependency tree for these corrections to ensure that overlapping changes don't conflict with one another.

This approach mirrors emerging industry trends where AI-driven code reviews help teams accelerate delivery and minimize human error. For those prioritizing privacy, similar workflows can even be deployed using local LLMs via Ollama to keep the codebase entirely within a secure perimeter. By integrating these agentic capabilities directly into the development lifecycle, the system acts less like a simple assistant and more like a proactive peer programmer.

The home stretch is **Compound** (`/workflows:compound`). In this phase, the system captures the learned experience—whether it’s specific fixes or new patterns—to bake them into the workflow for the future.

Adding this to your Claude Code is simple: first, add the marketplace with `/plugin marketplace add https://github.com/EveryInc/compound-engineering-plugin`, and then install the plugin itself via `/plugin install compound-engineering`.

## So, does it actually work just like that?

My typical workflow looks like this: I start by generating a feature description focused on user experience, layering in critical technical context (if I have a specific architectural vision). My `CLAUDE.md` acts as a "living memory," containing cross-project best practices tailored to my stack: no-build, BEM, vanilla Rails, self-hosting, and so on.

Crucially, every project has a local CI script to run tests and linters. The `CLAUDE.md` explicitly defines what makes a "good" test, how to write them, and mandates a strict "test-fix-commit" loop: manual verification followed by the CI script before any code hits the repo.

"Manual" testing isn't a typo here. Using skills from _[Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin)_ or native browser integration via Chrome plugins, Claude can effectively replicate user flows. If you're building an API-first app, it's even simpler—he can trigger `curl` commands and then wrap those into tests. This manual phase is vital to prevent "test-passing optimization" and hallucinations.

Then I launch Claude using the **--dangerously-skip-permissions** flag and ask it to create a new branch. If I’m juggling multiple features at once, I have it set up a worktree using a compound engineering tool (there’s no specific slash command for it, but if you just tell Claude what to do, it triggers the right workflow). Worktrees are a game-changer for me—they let me comfortably handle several tasks within the same project simultaneously.

Finally, I move on to the actual planning phase: **/plan** and **/plan\_review**, followed by **/triage** if necessary. For the most part, the quality of the final result is determined right here at the planning stage.

Once the plan looks good, I fire off **/workflows:work** and switch to other tasks. Claude works autonomously in the branch and doesn't distract me, thanks to the **--dangerously-skip-permissions** mode.

The longest and most grueling part of the process starts once the coding is actually "done" — review and testing. Before starting the code review, I ask the agent to verify that tests were written (despite strict instructions in `claude.md`, this step often gets ignored — AI is truly becoming human-like), run them using my local CI script (which handles linting and test execution), and ensure all new functionality is covered.

Then the actual review cycle kicks in using `/workflows:review` and `/triage` for any discovered issues. It often takes several iterations; frequently, the initial review reveals that the entire implementation is fundamentally flawed, requiring multiple rounds to reach an acceptable result. Naturally, everything flagged during review and marked for fixing at the triage stage is handled via `/resolve_parallel`.

Beyond local review, two other tricks help keep the code working: a Claude-powered bot review on GitHub and Cursor BugBot. I’m happy to pay for the latter because it works surprisingly well, catching bugs that both manual reviews and tests consistently miss. Both of these are triggered automatically on every commit to the branch. I simply ask Claude to check the PR comments: if there are many, he drafts a plan; if just a few, he fixes them directly without me ever opening GitHub. It’s worth noting that sometimes the GitHub bot finds issues that Claude missed locally.

After all these tweaks, I run a manual test, and if everything looks solid, all that's left is to deploy. If I ran into anything worth remembering for the future, I just fire up `/workflows:compound`.

## Notes and Comments.

The most expensive resource when using AI agents is human attention. The idea that a person must meticulously supervise an agent’s every move is dead. For most projects, the intrinsic value of code is depreciating. You can spin up four instances of Claude simultaneously to explore four different approaches to a single task, then simply pick the winner. You can research things that will never even see the light of day. You can cover edge cases with tests that you’d never bother with in real life. You don’t even have to read all the generated code—provided your project specs allow for it, and you’re building just another SaaS rather than a rocket ship. The only thing truly worth optimizing is the expenditure of your focus.

Ten rounds of code review with agents just to get a decent result? No problem, that's just clicking a button ten times. A hundred tests that need reviewing? Don't sweat it—nobody is ever going to evaluate the quality of those tests, because nobody would have ever written them in the first place, and nobody is ever going to touch them by hand. All that matters is that they verify the functionality.

When agents work autonomously, you end up with a lot of micro-pauses in your workflow. You could fill them by doomscrolling TikTok, but it’s far more efficient to run multiple Claude instances simultaneously, spin up git worktrees, and tackle several tasks at once.

## Are there any legit experts here?

- To dive deeper into the topic, I recommend reading Dan Shipper's article _["Compound Engineering: How Every Codes With Agents"](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents)_ on Every.to. It describes the internal development cycle and explains how this method allows a solo developer to work at the scale of a department. There are installation instructions and examples of agent orchestration.
- Another material — _["The Story Behind Compounding Engineering"](https://github.com/EveryInc/compound-engineering-plugin/blob/main/README.md)_, where the creators share project details, including stories about how AI started fixing code errors in advance.
- You can also read _[Reddit](https://www.reddit.com/r/ClaudeCode/comments/1pnpaa5/as_a_vibe_coder_how_can_i_genuinely_secure_my)_ (r/ClaudeCode), where similar results are noted: many report a 3–5x productivity increase, especially on code review and security tasks.
- There are demo videos on YouTube (e.g., _["Compound Engineering with Claude Code"](https://www.youtube.com/watch?v=ZVvW7PvVnnk)_), showing sessions where one person works at the speed of a team.
- If implementing it yourself, check the README and CLAUDE.md files in the _[repository](https://github.com/EveryInc/compound-engineering-plugin/blob/main/CLAUDE.md)_ on GitHub — they contain checklists.
- The _["Chain of Thought"](https://every.to/chain-of-thought/agent-native-architectures-how-to-build-apps-after-the-end-of-code)_ series explains how to build app architectures in the age of agents.
- _[This plugin makes Claude work for hours without going off the rails.](https://levelup.gitconnected.com/this-plugin-makes-claude-code-work-for-hours-without-going-off-the-rails-f176e474b284)_

## About the Author

_[Ivan Kuznetsov](https://ikuznetsov.com/?ref=hackernoon.com)_, ex-fullstack dev, ex-fintech executive, now technical product manager, vibe-coding and RoR enthusiast.
