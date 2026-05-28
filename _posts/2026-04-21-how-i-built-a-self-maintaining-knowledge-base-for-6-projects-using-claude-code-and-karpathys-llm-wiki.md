---
layout: post
title: How I Built a Self-Maintaining Knowledge Base for 6 Projects Using Claude Code & Karpathy's LLM Wiki
date: '2026-04-21 04:55:14 +0000'
categories:
- claude
- claude-code-plan-mode
- claude-code
- llms
- llm-workflows
- persistent-ai-memory
- ai-coding-assistant
- karpathy-wiki-concept
original_url: https://hackernoon.com/how-i-built-a-self-maintaining-knowledge-base-for-6-projects-using-claude-code-and-karpathys-llm-wiki
canonical_url: https://hackernoon.com/how-i-built-a-self-maintaining-knowledge-base-for-6-projects-using-claude-code-and-karpathys-llm-wiki
source: hackernoon
excerpt: 'A practical guide to creating persistent memory for your AI programming assistant that remains intact across sessions using A. Karpathy''s LLM-Wiki pattern '
---

In April 2026, Andrej Karpathy introduced a deceptively simple concept: instead of relying on RAG or endless context windows, you should let an LLM maintain a structured Markdown wiki as a long-term knowledge base. You simply provide the raw data, and the model compiles, organizes, and updates the wiki on its own. You do not need to handle manual editing—the model takes care of the entire record-keeping process.

I adapted this template for my daily workflow, which spans six projects, with Claude Code serving as my primary programming tool.

Here is what I ended up with, what worked, what didn't, and the exact prompts to replicate this experience.

> **Update (May 2026).** Everything below — the bootstrap prompts, the wiki-researcher skill, the `/plan` command, the QMD wiring — is now packaged as the **[LLM Wiki](https://github.com/ivankuznetsov/agent-plugins/tree/main/plugins/llm-wiki) plugin** for Claude Code and Codex. You don't need to copy any gists. Install once:
>
> ```text
> /plugin marketplace add ivankuznetsov/agent-plugins
> /plugin install llm-wiki@aikuznetsov-marketplace
> ```
>
> Then in any project:
>
> - `/llm-wiki:bootstrap` — runs the full five-phase bootstrap described below
> - `/llm-wiki:research` — searches project + master wikis before planning
> - `/llm-wiki:wiki-plan` — wiki-aware planning, hands off to Compound Engineering when present
> - `/llm-wiki:status` — checks for plugin updates
>
> The rest of this article explains the *why* and the *how* the plugin automates. If you just want it working, the install above is all you need.

* * *

## The Problem

Every Claude Code session starts with a blank slate. Yes, the CLAUDE.md file helps. Yes, the model can read your codebase. But there is a gap between "can read the code" and "understands the project."

I had to explain the same things over and over again:

- "The data enrichment pipeline operates in 4 stages..."
- "We chose this gem instead of that one because..."
- "Do not touch this migration, and here is why..."

Multiply this by 6 projects, and you are headed for death by a thousand requests for context clarification.

## The Solution: A Self-Updating Knowledge Base

Fortunately, we are lucky to live at the same time as Andrej Karpathy, [who generously shares his knowledge](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and discoveries. I have already written about Autoresearch, and now I want to talk about the LLM-wiki, a concept he published in the public domain that is easy to replicate in any language and for any tech stack in the LLM era. To the original idea, I added [QMD](https://github.com/tobi/qmd) by Tobi Lütke, CEO of Shopify, as a tool for quick semantic search across text files, and built the entire system around Claude Code, integrating it into the Compound Engineering workflow along the way.

The system consists of four levels:

1. **Project-specific wikis** — a `wiki/` folder in each project repository, maintained using Claude Code
2. **Auto-update hooks** — post-commit hooks that trigger wiki updates whenever code changes are made
3. **QMD search** — semantic search across the wiki, allowing Claude to quickly locate relevant pages
4. **Master wiki** — a centralized knowledge base for all projects, used to document shared patterns

The core idea of Karpathy's approach is that knowledge is compiled as it arrives, rather than at the moment of a query. Unlike RAG, where searching through "raw" data fragments occurs with every question, a wiki pre-structures and links information into finished pages. The challenge of maintaining relevance, which typically ruins human-written wikis, is precisely the task that language models excel at.

## Required Tools

You will need the Claude Code CLI with an active subscription. You will also need Tobi Lütke's QMD tool for semantic search—it runs entirely locally and does not require any API calls. Obsidian is not a mandatory component, but it is excellent for conveniently viewing the knowledge base as a human.

## Knowledge base structure

The wiki folder is located in the root directory of the project. It contains:

1. an index page that serves as a catalog for all materials;
2. a changelog to record all wiki operations;
3. a knowledge gaps page for tracking unresolved issues;
4. the knowledge base pages themselves, organized by domain — models, controllers, services, architectural decisions, established conventions, and libraries used.

Also located in the project root is the `raw/notes/` directory, which is intended for manually adding files such as articles you want to include in the knowledge base, project documentation, or meeting notes. The LLM reads data from `raw/`, but only writes to `wiki/`.

Do not forget to add the QMD search index (the `.qmd/` directory) to `.gitignore`, as it is a generated file.

## Bootstrapping: Core Prompts

You can skip this part and jump straight to the ready-made bootstrapping prompt I provided at the end of the article, but if you want to understand everything in more detail, I recommend reading this section.

Bootstrapping is not about "documenting everything." It is about extracting the 20% of the structure that yields 80% of the useful context. I have divided this process into 5 stages, each aimed at a specific part of the codebase.

### Phase 1: Data Model (The Most Critical Step)

This prompt allowed for the generation of the most useful wiki pages:

```
Read the db/schema.rb file and all files in the app/models/ directory.
Execute git log --all --oneline -- db/migrate/ to retrieve the migration history.

Generate wiki/data-model.md with an overview of entities and relationships,
a list of all tables, key associations, and a Mermaid ER diagram.
Create a wiki/models/ directory and generate one page for each model,
describing its columns with data types, associations, validations, scopes, and important callbacks.
Generate wiki/schema-evolution.md describing key schema changes and the reasons behind them,
based on the migration history.

Use [[backlinks]] between related models. Add YAML frontmatter to each page:
title, type, source file path, date, and tags.
```

Template metadata is crucial. Without it, Claude creates pages with inconsistent formatting. I include this template directly in the prompt:

```
Page metadata template: title, type (model/controller/service/architecture/decision),
source file path, creation date, update date, tags array, and confidence level (high/medium/low).
Start each page with a one-sentence summary (TLDR) after the metadata.
```

A medium-sized project with 21 models generates about 25 pages in a single pass within 10 minutes.

### Phase 2: Routes and Controllers

```
Read config/routes.rb and all files in app/controllers/, including subdirectories.

Create wiki/routes.md covering route groups, namespaces, resource mappings,
and authentication requirements for each namespace.
Generate wiki/controllers/ with a separate page for each key controller—skip trivial CRUD controllers.
Document actions, before_actions, permitted params, and service delegations.
Group by namespace if the application includes admin, api, or portal.

Use [[backlinks]] for cross-referencing with model pages.
```

The instruction to "skip trivial CRUD controllers" is essential. Without it, Claude creates empty pages for every controller, including those that contain nothing more than standard resource actions and lack any notable logic.

### Phase 3: Architecture and Patterns

This stage involves reading not only the code itself but also the intentions behind it:

```
Analyze the contents of the app/services/, app/jobs/, and config/initializers/ directories,
along with the Gemfile.
Execute the following git commands:
git log --all --oneline --grep="refactor|redesign|migrate|breaking|architecture",
git log --all --format="%s%n%b" --merges --since="1 year ago", and
git log --all --since="6 months ago" --shortstat --pretty=format:"%h %s".

Create a wiki/architecture.md file outlining the high-level application structure and component interaction principles.
Establish a wiki/services/ directory containing a dedicated page for each service domain.
Generate a wiki/gems.md file listing key libraries and the rationale behind their selection.
Prepare a wiki/decisions.md file documenting architectural decisions based on git history
using a lightweight ADR format (Title, Context, Decision, Status).

Create a wiki/active-areas.md file providing an overview of current tasks based on recent git activity.
```

These three git log commands were carefully selected. The first finds commits reflecting architectural changes. The second captures summaries of merges and pull requests, which often contain the most valuable context. The third demonstrates patterns of recent activity.

### Phase 4: Gap Analysis

```
Read through all the wiki pages created so far.
Additionally, examine the database schema and routes for comparison.

Generate a wiki/gaps.md file listing all elements from the schema or routes that lack
corresponding wiki pages, any discovered but undocumented patterns, and questions you would like
answered regarding this codebase. Update wiki/index.md by adding a complete, categorized
catalog of all pages. Add an entry about initiating the process to wiki/log.md.
```

The gap analysis stage proved surprisingly useful. For one of the projects, it revealed 9 mailer classes, 20 Rake tasks, and 16 Stimulus controllers that lacked any documentation. It also raised 7 open questions, such as: "What is the full path of the pipeline from detection to enrichment and verification?" These gaps are being filled organically during subsequent sessions.

### Phase 5: Plans, Tasks, and Documentation (Required)

I initially skipped the `plans/` and `todos/` directories. This was a mistake. These files contain the exact information about the reasoning behind decisions that makes a wiki-based knowledge base truly valuable: current initiatives, known technical debt, deferred decisions, and priorities.

```
Read all files located in the plans/, todos/, and (if present) docs/ directories.
Generate a wiki/plans-and-initiatives.md file that summarizes all active plans,
grouped by status and priority. Create a wiki/technical-debt.md file by extracting all
technical debt items and deferred tasks, grouped by priority. Develop a wiki/roadmap.md file
that synthesizes the overall vision for the project's development. Update wiki/active-areas.md
by adding cross-references to plans and tasks to ensure the information remains current.
```

While working on 6 projects, I managed to process 519 files and generate content that has become one of the most valuable sections of the knowledge base. In one of the projects, 151 task files were organized into a clear technical debt register with defined priorities.

### Parallel processing

Real time-saver: the Claude Code sub-agent system allows you to launch the preparation process for multiple projects at once. I instructed Claude Code to set up 4 projects simultaneously; it created separate agents, each reading its own project's codebase and writing wiki pages in parallel. Four projects in 25 minutes instead of 100.

The prompt is simple: specify which projects Claude needs to run and ask it to execute them simultaneously. Claude Code manages concurrency using its Agent tool.

## Key System Component

This is the most critical component of the entire system. Add the following line to your CLAUDE.md file:

```
Always check wiki/ before answering questions about this project's architecture, patterns, or decisions.
```

Without this line, Claude Code will not proactively consult the wiki, limiting itself to reading only the code. With it, Claude reads `wiki/index.md` at the beginning of each relevant request, locates the necessary pages, and bases its answers on pre-collected knowledge instead of analyzing the codebase from scratch every time.

The rest of the wiki section in the CLAUDE.md file contains supplementary information: a description of the wiki structure, instructions for saving acquired knowledge to wiki pages at the end of a session, a request protocol for searching the knowledge base, and a reminder to document information gaps in the wiki/gaps.md file. However, it is this bolded line that serves as the trigger. Everything else follows from it.

### Verification of functionality

After configuring the CLAUDE.md file, start a new Claude Code session and ask a question about the architecture. Claude should consult wiki/index.md, locate the relevant pages, read them, and provide an informed response with links to specific sections of the wiki. If the model simply reads the code without referencing the wiki, it means the instructions in CLAUDE.md are not strict enough.

## Automating Knowledge Base Updates

### SessionStart Hook

Claude Code is equipped with a hook system that executes shell commands whenever specific lifecycle events occur. I configured the SessionStart hook, which triggers at the beginning of each session and after every /clear command: it outputs the first 60 lines of the wiki/index.md file and the last 15 lines of wiki/log.md into the Claude context. This ensures that Claude is aware of the wiki's content and recent changes even before you have a chance to ask a question.

This hook is placed in the `.claude/settings.json` file at the root of your project. If this file already exists and contains permissions or plugin settings, add the hooks key to it without overwriting the existing content.

### Post-commit git hook

When you commit changes to schemas, models, routes, or the Gemfile, the wiki updates automatically. The post-commit Git hook tracks modified files and triggers Claude Code in the background without user intervention, executing the appropriate target request.

### Key Design Decisions

**Everything runs in the background.**

The hook uses `nohup` and `&`, so it never blocks your workflow. Wiki updates appear unobtrusively when you run the next `git status` command.

**Budget constraints per call.**

Claude in headless mode supports the `--max-budget-usd` flag. Updating changes in the model typically costs between $0.05 and $0.15. I set a limit of $0.50 to ensure that an uncontrolled update does not lead to an API budget overrun.

**Tool restrictions.**

The `--allowedTools` flag restricts Claude's capabilities by permitting only file read and write operations, while blocking network calls. This ensures that automated executions remain predictable.

The `-p` (print) flag runs Claude Code in non-interactive mode: the program executes the request and terminates immediately.

The `--bare` flag is essential for automated runs; it skips hooks, plugins, and MCP servers, making execution faster and more predictable.

## Semantic search with QMD

[QMD by Tobi Lütke](https://github.com/tobi/qmd) combines full-text search based on the BM25 algorithm, vector embeddings, and optional LLM-powered reranking. It operates entirely locally, meaning no API calls are made and no data leaves your computer. Once you index your wiki as a "collection," QMD offers three search modes: keyword-based (the fastest), semantic (which understands context), and hybrid with reranking (providing the highest quality results).

Key integration: QMD is equipped with a Claude Code plugin that registers an MCP server. Once installed, Claude Code gains the ability to directly access information in your wiki via MCP tools during any session—without the need for manual command-line entry. Install it through the Claude Code plugin marketplace. This is precisely what turns a wiki into a truly "live" tool: Claude does not just read pages upon your request; it is capable of autonomously performing searches across all indexed collections during its reasoning process.

The CLAUDE.md prompt protocol references these MCP tools, allowing Claude to automatically engage them whenever project context is required. Ripgrep serves as a fallback for keyword-based searches should QMD be unavailable.

For 6 projects containing 192 wiki pages, QMD indexed 388 chunks distributed across 7 collections.

Honestly, for wiki projects with fewer than 100 pages, ripgrep is perfectly sufficient. QMD's semantic search shines when you don't know the exact terms: a query like "how does the data pipeline work" finds pages about "searching → enriching → validating" that a standard keyword search would have missed. But with the MCP plugin, using QMD becomes completely natural—Claude invokes it automatically, even if you haven't explicitly asked for it.

## Knowledge sharing between projects

The main knowledge base is located in `~/wikis/master/`, which is the only directory kept separate as it consolidates multiple repositories. It stores templates found in two or more projects, common coding standards, a matrix of gem file usage for all projects, lessons learned and identified challenges, a technical debt tracker for recurring issues, and brief summaries for each of the projects.

### Initial synchronization

I launched Claude Code within the master wiki directory, granted it access to all six project wikis via the `--add-dir` flag (which allows reading and writing data outside the current working directory), and provided the following instruction:

```
Read the wiki/index.md and key pages—architecture.md, gems.md, and decisions.md—for each project
listed in CLAUDE.md. Create project-summaries, with one page per project.
Generate patterns.md by identifying patterns used in two or more projects.
Create gems-overview.md with an overview of gem usage across all projects.
Prepare conventions.md with explicit coding standards.
Create learnings.md describing pitfalls and lessons learned. Update the index and the changelog.
```

### Automated Knowledge Base Synchronization

For each project, a post-commit hook is configured to create a flag file whenever the wiki content is modified. A task scheduler checks for these flags every two hours and, upon detection, automatically runs Claude Code in the background to synchronize the updated projects with the main knowledge base. An additional monthly task performs a full synchronization of all projects, regardless of whether any flags are present.

After each post-commit hook executes, a marker file named after the project is created in the ~/wikis/.sync-needed/ directory. This allows the main wiki synchronization task to determine exactly which projects have been updated.

## Regular Maintenance

Three scheduled tasks ensure the smooth operation of the system. I use custom systemd timers on Arch Linux for this purpose, but cron would work just as well on other systems.

**The weekly knowledge base audit** covers all projects by running Claude in the background with a request to identify orphaned pages, logical inconsistencies with the current codebase, outdated information, and broken links. The system updates the gaps.md file and performs a re-indexing of the QMD. The budget is limited to $0.50 per project.

**The two-hour master synchronization checks** projects marked with the corresponding flags and performs their synchronization. If no flags are present, the task does not run, which helps save resources when there are no changes.

**A full monthly synchronization** forces a consolidation of all projects into the main wiki, regardless of any flags. This update helps identify any changes that may have been missed during incremental synchronization.

## Operation Log: Auditing Your Wiki

Every wiki operation—initialization, ingestion, querying, or verification—is recorded in `wiki/log.md` with a timestamp. Each entry documents the action performed, the pages created or updated, any identified gaps, and the trigger that initiated the process.

This serves two purposes. First, it ensures Claude understands that information is already present in the wiki, preventing it from duplicating existing pages. Second, it provides you with a clear history of how your knowledge base has evolved. By using grep on the log, you can easily track when a specific topic was last updated or identify the exact moment a gap in the documentation was first discovered.

## Closing the loop: wiki-based planning

To make this useful day-to-day, the plugin ships two commands that close the loop between the wiki and how you plan work.

`/llm-wiki:research` runs before any other research. It uses QMD's MCP tools to search both the project wiki and the master wiki, ranks results, and synthesizes a "Past Knowledge" section: prior decisions, applicable patterns, known bugs, reusable components, and gaps the current work could fill.

`/llm-wiki:wiki-plan` wraps that around your planning workflow. It triggers the research step first, then hands off to Compound Engineering's planner if you have it installed, or writes a standalone plan outline otherwise. The retrieved wiki context becomes the grounding for whatever planning system you use.

Prerequisites: the QMD plugin for Claude Code (provides the MCP search tools). The LLM Wiki plugin installs QMD as a dependency, so this is automatic.

### Integration with Compound Engineering

If you are using the Compound Engineering plugin, the `/plan` command automatically triggers `/workflows:plan` in CE. The process is as follows:

1. You enter `/plan add user notifications`
2. The wiki researcher performs a search across both the project wiki and the main wiki via the QMD MCP
3. The "Past Knowledge" section is synthesized
4. The CE planning workflow is launched with the wiki context — its three research agents (repo-research-analyst, best-practices-researcher, framework-docs-researcher) can now rely on the data retrieved from the wiki
5. The final plan incorporates both the knowledge from the wiki and the results of fresh research into the codebase

If you are not using Compound Engineering, the `/plan` command will still work: it performs a wiki search, and you can then route the result wherever you see fit.

### Integration with other planning agents

This skill is compatible with any planning workflow. The key is the use of MCP tools from QMD (which adhere to the standard MCP protocol), so any agent capable of calling MCP tools can utilize it. If you have your own planning agent or are using a different plugin, simply configure your agent to call the wiki-researcher skill before the research phase.

The output of this skill is structured as follows: "Past Knowledge," with subsections for relevant pages, patterns, solutions, common pitfalls, and reusable components. Any planning agent can utilize this format.

### Practical application

When I run `/plan` for a new feature, the wiki-base researcher prepares a context that looks like this:

```
Previous Knowledge

Relevant wiki pages: wiki/decisions.md contains information on choosing magic link authentication over
passwords (ADR-009). wiki/controllers/auth-controllers.md describes three already implemented
authentication systems. Templates from Master wiki patterns.md show that magic link is
used in 4 out of 6 projects.

Applicable patterns: use signed_id with specified purpose and expiration, similar
to the Company and CompanySubmission models.

Known issues: learnings.md contains a warning about email normalization for rate limiting.
Callback URLs for OAuth require explicit protection against open redirects.

Reusable components: AuthenticationMailer already exists. The signed_id pattern is well-established.
```

Rather than designing authentication from scratch, the plan relies on existing solutions and helps avoid known pitfalls. This is where the cumulative effect of the knowledge base becomes apparent: each completed session makes every subsequent plan even better.

## Operating Costs

The cost of using the API is minimal. By default, your subscription quota is utilized, but even when paying for Anthropic credits, the initial setup costs approximately $0.50–$1.00 per project. Updating the wiki after a commit costs $0.05–$0.15 per iteration. Weekly linting costs $0.30–$0.50 per project, and a full synchronization costs $0.50–$1.00. As a result, the total monthly expenses for six actively developing projects range from $10 to $20.

The `--max-budget-usd` flag serves as your safety net during every automated call. If something goes wrong, the process will stop once the limit is reached instead of uncontrollably consuming funds.

## Get it running

The [LLM Wiki plugin](https://github.com/ivankuznetsov/agent-plugins/tree/main/plugins/llm-wiki) bundles everything described above. Install it once, then point it at a project:

```text
/plugin marketplace add ivankuznetsov/agent-plugins
/plugin install llm-wiki@aikuznetsov-marketplace

# Then, inside any project:
/llm-wiki:bootstrap
```

That single command runs all five bootstrap phases, sets up the SessionStart and post-commit hooks, installs QMD, and indexes your wiki as a searchable collection. From then on, `/llm-wiki:research` and `/llm-wiki:wiki-plan` are available in any Claude Code or Codex session, and the wiki stays up to date as you commit.

* * *

##
