---
layout: post
title: "I cloned my team's code reviewers from their PR history — and the eval that proved me wrong twice"
date: 2026-06-06 12:00:00 +0100
categories: ai engineering
description: "I tried to clone my team's best code reviewers as AI personas. A cheap, cheat-proof, per-comment eval reversed my two strongest design intuitions — and pointed at the one lever that actually matters."
image:
  path: /assets/images/posts/code-reviewer-eval/og.png
  width: 1200
  height: 630
  alt: "Recall through the autoresearch loop, rising from 6.9% to 43.7%."
twitter:
  card: summary_large_image
---

You're staring at a pull request that rewrites half the codebase. The lead engineer who'd normally catch the subtle stuff is on vacation, and now you have to review it as if you were her. Or your team adopted AI so well that the number of PRs grew 2× over three months, and the two top reviewers who held the codebase's integrity are drowning. Or you just closed a Series A and have to double the engineering team without dropping code quality, fast.

The solution looks obvious: your team has already written thousands of reviews. They're sitting in GitHub as dead weight — *"pull this into `validateUser()`"*, *"we already have a helper for dates, third time someone's reinvented it"* — small decisions that took years to learn. The senior engineer's note about why this API can't take `null`? Buried in PR #847 from eight months ago. Why not use that history to build a reviewer that reviews like your real reviewers?

So I built one. This is the story of the tool — and, more importantly, of the **eval** that kept catching me when I was confidently wrong about how to build it. Twice.

I'm skipping the code this time — it's all in the [public repo](https://github.com/ivankuznetsov/agent-plugins), and you can skip the article entirely and install [the plugin](https://github.com/ivankuznetsov/agent-plugins/tree/main/plugins/agent-reviewer) for Claude Code / Codex, which builds a reviewer out of your own repository. For Claude Code:

```
/plugin marketplace add ivankuznetsov/agent-plugins
/plugin install agent-reviewer
/reviewer:extract   # extract the reviewers from the current repo
```

And for Codex (there it runs as a skill, with no slash commands — after installing, you just ask for "Agent Reviewer"):

```
codex plugin marketplace add ivankuznetsov/agent-plugins
# then in Codex: /plugins → select aikuznetsov-marketplace → install agent-reviewer

# launch it — just ask, naming "Agent Reviewer":
use Agent Reviewer to find the prominent reviewers in this repo

# extract a persona for a specific reviewer:
use Agent Reviewer to extract a persona for our top reviewer from their PR history

# review your current changes with the panel:
use Agent Reviewer to review my current changes with the team's reviewer panel

# set the repo scope the reviewer is built from:
use Agent Reviewer to extract personas — ORG=acme REPOS="api worker gateway"
```

But if you're here for the read, what follows is how I built it, the methodology for cloning a reviewer, and — above all — building the eval that scores these virtual reviewers, plus how to build evals at all and use them to drive a [Karpathy-style autoresearch](https://vc.ru/ai/2798012-autoresearch-ii-dlya-optimizatsii-protsessov-vo-sne) loop.

## v1: turn the comments into rules

The first version was the obvious one. Collect every review comment a person ever left, with the diff it sat on and the PR's intent. Ask a model to find the recurring patterns. Mine produced about 45 patterns across nine categories — naming, consistency, simplification, error handling, tests, and so on. Then turn each pattern into a rule with five parts: a name, a one-line rule, the *why*, a good-vs-bad example from the real codebase, and a real quote that motivated it. Wrap the whole catalog in a short voice block — collaborative, explains the reasoning, shows the fix, references existing code, ruthlessly simplifies — and you have a reviewer agent.

It worked. It also looked like a glorified linter config. So for v2 I "fixed" it.

## v2: capture the person, not a rule list

The insight that felt right: a rule list is a frequency table of vocabulary. It tells you the reviewer says "rename this" a lot; it can't tell you they only care about names on the public API, or that they'll forgive almost anything except a silently swallowed error. The signal worth cloning is the *judgment*, not the keywords. So v2 extracted a **persona** — a first-person portrait of how someone thinks: what they care about ranked by how often they raise it, what they let slide, what they explicitly *don't* flag, how they sound, the order they scan a diff in. "Capture the person, not the rules." Keep it concrete and tight.

The nudge came from London. At [Code with Claude](/posts/notes-from-code-with-claude-london/) I kept hearing the same refrain from people building agent systems — capture the *person*, not a list of rules; a checklist is the thing you've already outgrown. It landed hard, and v2 was me acting on it: stop writing rules, extract the human. That instinct turned out to be half-right and expensive in a way I didn't see coming — but that's the rest of this piece.

It read beautifully, it was obviously the better design, and I believed that completely.

## How do I know it actually works?

The hard part isn't building the reviewer. It's knowing whether it reviews like the person, or just reviews. So before building v2 and optimizing anything, I built [an eval](https://github.com/ivankuznetsov/agent-reviewer-eval) — and the eval is the part of this whole article I'd most urge you to steal, so here it is concretely enough to rebuild:

1. **Hold out real PRs the reviewer commented on.** For each of their real inline comments, capture the exact diff hunk that comment sat on. That hunk, stripped of the comment, is one test case; the comment is the ground truth. Anchoring to the per-comment hunk means you're testing against the precise code they reacted to, not a later revision.
2. **Show the clone the code only, blind.** No comment bodies, no PR number, no repo, no author — nothing it could use to look the answer up. Put the ground-truth comments in a separate file the reviewing process never opens, and run that process with no network, so "don't peek" is enforced, not requested. (This matters because you'll want to run the eval with different models, where good behaviour isn't guaranteed.)
3. **Score recall with an independent, strict judge.** A separate model compares the clone's comment to the real one and counts a match only when it's *the same concern on the same code*. Right line, wrong concern is a miss. When in doubt, miss.
4. **Add clean hunks so precision counts too.** Mix in hunks from the same PRs that the reviewer saw and chose *not* to comment on. A flag on those is a false positive. Without this, a reviewer that comments on everything scores a perfect recall and is useless.

A caveat I'll repeat because it governs everything below: the numbers in this piece are **directional, not big-lab benchmark-grade**. Most are a single reviewer over a handful of runs, and run-to-run noise is several points. The *benchmark* — the data and the harness — is public and reproducible; the specific deltas are signal, not gospel. I'll flag where the noise is wide enough to matter.

> I'm making this disclaimer because I'm token-poor. If you're a Big Lab with a lot of tokens, I'd happily take some as a donation in exchange for publishing a proper, scientific-grade code-reviewer eval.

The harness ships with the real review histories of four well-known, opinionated open-source reviewers — DHH and Rafael França on Rails, José Valim on Elixir, Tim Hockin on Kubernetes. Six PRs per reviewer, **24 PRs** and **188 ground-truth comments** in all (yes, it's small — see the disclaimer above), each with its own blind hunk and the real comment to score against, so you can [reproduce all of it](https://github.com/ivankuznetsov/agent-reviewer-eval) without a private repo, or point it at your own repo and build a private eval like I did, alongside the public one. The comments are lopsided — more than half (110 of 188) are Hockin's Kubernetes reviews — so I break every result out per reviewer rather than quoting one blended "public" number.

<figure class="data-table">
  <table>
    <thead>
      <tr><th>Reviewer</th><th>Repo / language</th><th class="num">PRs</th><th class="num">Hunks</th><th class="num">Comments</th></tr>
    </thead>
    <tbody>
      <tr><td>DHH</td><td>Rails</td><td class="num">6</td><td class="num">35</td><td class="num">35</td></tr>
      <tr><td>Rafael França</td><td>Rails</td><td class="num">6</td><td class="num">20</td><td class="num">20</td></tr>
      <tr><td>José Valim</td><td>Elixir</td><td class="num">6</td><td class="num">23</td><td class="num">23</td></tr>
      <tr><td>Tim Hockin</td><td>Kubernetes</td><td class="num">6</td><td class="num">110</td><td class="num">110</td></tr>
      <tr class="total"><td>Total</td><td>—</td><td class="num">24</td><td class="num">188</td><td class="num">188</td></tr>
    </tbody>
  </table>
  <figcaption>What's in the public benchmark: 6 PRs for each of the four reviewers — 24 PRs and 188 ground-truth comments in all. One diff hunk per comment, so recall is scored against exactly these 188.</figcaption>
</figure>

## The benchmark was wrong before it was right

Worth saying plainly: that tidy four-step recipe above is where the eval *ended up*, not where it started. The benchmark was wrong several times first, and each wrong version taught the fix for the next — the eval is software, and it earned trust the same way the reviewer did, by being wrong in measurable ways until it wasn't.

The first version scored a blind review of the PR's *final, squashed* diff against the reviewer's comments. But his comments were left across a dozen force-pushes, on code the final diff had already rewritten or deleted — so a large share of the ground truth was unmatchable by construction. Recall looked dismal for a reason that had nothing to do with the reviewer.

So I tried reviewing the PR *at the revision he commented on*. That fixed the first problem and introduced its mirror image: his comments span ten revisions, so any single snapshot holds only a slice of the code he reacted to, and recall swung on which revision I happened to freeze. The version that finally held is the per-comment one above — each comment carries its own diff hunk, the exact code under his cursor when he wrote it, so every comment is in scope by construction with no revision luck. That turned a meaningless number into a stable ~18%, and for the first time the misses were *real* (genuinely hard to catch) rather than artifacts of the harness.

Two more turns got it to where it is now. Handing the reviewer the whole PR as context instead of the lone hunk lifted ~18% to ~29% — the cross-file "reuse the helper" class became visible. And I made it cheat-proof: the early versions trusted the reviewing model not to fetch the comments it technically could; I replaced trust with enforcement — the reviewer runs with no network and a filesystem view containing only the code, the ground truth in a file it cannot reach, the whole run failing closed if isolation can't be guaranteed.

One last property is what makes every comparison later in this piece mean anything: the harness is **model-agnostic**. Underneath, it's two swappable commands — one that reviews a hunk, one that judges whether a produced comment matches a real one — so the same benchmark runs against Claude, against GPT, against whatever you point it at, by changing an environment variable. The reviewer and the judge are never the same model, so nothing grades its own homework. That decoupling is what let me ask questions the single-model version couldn't — *does the verbose catalog matter more on a weaker reviewing model?* (it does) — and it's why "cheat-proof" had to be structural rather than a polite instruction: once the reviewing command can be a non-Claude binary, the only thing standing between the eval and a contaminated result is the sandbox.

If you build one of these yourself, the wrong versions will teach you more than the right one. The part that transfers — true of almost any eval, not just a reviewer:

- **Anchor ground truth to the unit you judge.** Score against the exact hunk the human reacted to, not the final squashed PR — most of my early "misses" were the harness comparing a review against code that no longer existed.
- **A broken eval is an *unstable* number, not a low one.** The metric was worthless until the misses stopped being harness artifacts and became genuinely hard catches. Stability, not magnitude, is the signal that an eval is ready to optimize against — chase a number that jumps on re-runs and you'll tune to noise.
- **Build the precision control before you trust recall.** Mix in clean cases the reviewer saw and chose to skip, or "comment on everything" scores a perfect grade and you happily ship a spammer.
- **Decouple the reviewer from the judge, and prevent cheating.** Different models (nothing grades its own homework); no network; the answer key on a path the reviewed process cannot reach; the whole run failing closed if isolation can't be proven. "Please don't peek" is worth exactly nothing the instant you swap in a model you don't control.
- **Treat the eval as software that earns trust by being measurably wrong.** It went through more versions than the reviewer did, and each wrong one named the next fix. Ship the eval's own bugs and you'll optimize confidently in the wrong direction — which is worse than not optimizing at all.

## Optimizing with the eval in the loop (autoresearch)

With a number to move, I ran a metric-driven loop — generate a change, measure it, keep what helps, revert what doesn't; Karpathy's autoresearch pointed the search at prompts.

In practice I didn't run the loop by hand — I pointed the **`ce-optimize`** skill from compound-engineering at the eval (that's Karpathy's autoresearch, generalized to prompt edits). You hand it a spec — what to maximize (recall), what measures it (the command that runs the eval — it *is* the metric), what's allowed to change (the reviewer and extractor prompts), and what's untouchable (the harness and the ground truth) — and the skill perturbs the prompt, runs the eval on each try, keeps what raised recall, reverts the rest, and commits every step with its delta:

```yaml
# kick off the autoresearch loop — one command with a spec:
#   /ce-optimize specs/reviewer-recall.yaml
#
# the spec (specs/reviewer-recall.yaml):
name: reviewer-recall
metric:
  primary: { name: recall, type: hard, direction: maximize, target: 0.60 }
  degenerate_gates:          # so recall can't be gamed
    - substantive >= 95      #   the judge still credits ~all ground-truth comments
    - clean_rate  <= 0.90    #   the reviewer neither goes silent nor flags everything
measurement:
  command: "python3 eval-opt/measure.py"            # ← running the eval IS the metric
  env: { REVIEW_MODEL: sonnet, JUDGE_MODEL: opus }  # reviewer and judge are different models
scope:
  mutable:   [agents/persona-reviewer.md, agents/reviewer-profiler.md]  # only the prompt moves
  immutable: [eval-opt/, percomment/, data/]        # harness and ground truth never change
stopping: { max_iterations: 8, plateau_iterations: 3 }
# then the skill loops on its own: mutate prompt → measure.py → recall up? commit with the delta : revert
```

The loop itself was deliberately mechanical, and that was the point. Each idea became one experiment: write the change, run the held-out eval, record the delta, commit it with the number in the message — keep it only if recall moved, revert it the moment it didn't, and never trust the reasoning that motivated it over the measurement that judged it. Across a few dozen experiments the commit log *became* the research record — `+ don't-default-to-clean → 10.7`, `+ per-hunk depth → 22.9`, `author-mode filter → no gain, reverted`. Nothing shipped on plausibility; the eval was the only gatekeeper. That discipline is exactly what let the negative results pile up honestly instead of getting argued away by whoever was most attached to the idea — which, on a solo project, is always you. Three things came out of that loop that reading the prompt alone would never have told me:

- **The biggest lever wasn't the prompt — it was the repository.** Telling the reviewer "don't default to clean" helped a little; a stronger model helped a little; reviewing each hunk with depth helped more. But letting the reviewer *grep the actual codebase* — find the helper that already exists, the sibling test, the convention — helped most, because so much of a senior reviewer's value is *"reuse the thing we already have,"* which is invisible in an isolated diff.
- **Scope beats model strength.** On Tim Hockin's Kubernetes reviews, switching to maximum-reasoning mode barely moved the needle; giving the reviewer the repo did. These are small absolute numbers — on the order of a dozen matched comments out of a hundred, where a few swing the percentage — so I won't pretend it "broke a ceiling." But the direction was consistent: recall is bounded by what the reviewer can *see*, not how hard it thinks.
- **The negative results were the valuable ones.** Pushing recall toward 60% turned out to be possible only by making the reviewer comment on nearly every hunk — high recall, collapsed precision, not a faithful clone. And three plausible "improve the extractor" ideas I was sure would help — separating a maintainer's own-PR replies from their gating comments, teaching it restraint, tagging which concerns need the repo — every one *failed* on the held-out eval. The recurring reason: adding structure to the extraction prompt squeezes out the concrete, quoted specificity that drives recall. The eval stopped me from shipping all three.

<figure class="chart">
  <img src="/assets/images/posts/code-reviewer-eval/evolution.svg" alt="Bar chart: recall climbs from 6.9% at baseline through diff-only tweaks to 29.1%, then 35.9% with repository access and 43.7% with a grounded persona.">
  <figcaption>Recall through the autoresearch loop (private Go reviewer). On the diff alone each lever adds a little: 6.9 → 29.1 (the two-pass union is already in here). Repository access takes it to ~36, and the last step — not an extra pass but a better-extracted, grounded persona at the same recipe — lands it at 43.7%, which is what I ship.</figcaption>
</figure>

## The reckoning: I had v1 and v2 backwards

Eventually I ran the comparison I should have run first: build v1 faithfully — the voice-plus-concrete-pattern catalog — and put it head to head against the v2 persona, same benchmark, same judge.

v1 won. On DHH, the concrete catalog reproduced his real comments at **55%** against the persona's **41%**, with *higher* precision too — it wasn't winning by spraying. The catalog led the persona on every reviewer at the weaker (Sonnet) tier — Rafael 61 vs 53, José 67 vs 36, Hockin 26 vs 18 — though the margins swing several points run-to-run on twenty-odd graded comments. The compressed persona I was proud of was the *worse* artifact.

<figure class="chart">
  <img src="/assets/images/posts/code-reviewer-eval/matrix.svg" alt="Grouped bars: v1 catalog beats v2 persona on every reviewer at the Sonnet tier — DHH 55 vs 41, Rafael 61 vs 53, José 67 vs 36, Hockin 26 vs 18.">
  <figcaption>v1 catalog vs v2 persona — diff-only recall on the weak model (Sonnet). The catalog leads on every reviewer; the persona only catches up where the model already knows them (the stronger-model view is the next chart).</figcaption>
</figure>

<figure class="chart">
  <img src="/assets/images/posts/code-reviewer-eval/control.svg" alt="Four small bars around 9–12% for the private Go reviewer on diff-only, with no Opus surge.">
  <figcaption>Private Go reviewer — diff-only (the control). ~10% with the repo stripped away, and no Opus surge: the signal the famous reviewers show is absent here.</figcaption>
</figure>

One qualification the eval insists on, and it's about the reviewing model: a stronger model narrows the catalog's lead — but by how much depends entirely on the reviewer. On DHH the persona actually pulls *ahead* on Opus (40 vs 42); on José the catalog's 31-point Sonnet lead shrinks to 13; on Rafael and Hockin it barely moves. The verbose catalog matters most when the model is weakest — and it matters least exactly where the model already knows the reviewer. Which is the thread worth pulling on.

<figure class="chart">
  <img src="/assets/images/posts/code-reviewer-eval/gap.svg" alt="Diverging bars: the Sonnet→Opus gap closes most for José (+18) and DHH (+16), stays flat for Hockin, and slightly widens for Rafael and the private reviewer (−3).">
  <figcaption>How much the stronger model closes the catalog-vs-persona gap. Blue = the gap closed (DHH and José — the reviewers the model already knows); grey = it held or widened (Rafael, Hockin) or showed nothing (the private control).</figcaption>
</figure>

And here's the thread I'd actually stake the piece on: those public numbers are inflated by something that has nothing to do with my extractor — **the model already knows these people.** Strip every reviewer to content only and the famous ones reproduce at 40–68% while the private engineer lands at ~10%, a five-to-sixfold gap on the identical harness. DHH's, Rafael's and José's code and reviews are all over any frontier model's training data; your senior backend dev is in no training set. The gap closing exactly where the model knows the reviewer (DHH first, then José) says the same thing from another angle: a thin persona doesn't so much *transfer* the reviewer's judgment as *activate* a version of them the weights already hold — and on someone the model has never seen, there's nothing to activate. Which is why the private reviewer, out of distribution, is the control I trust to predict your team — and once it can read the repo, catalog and persona finish in a dead heat (Opus 30.8 vs 29.5), so the v1-vs-v2 fight mostly washes out anyway. What ports to your repo isn't the persona magic; it's the extracted history plus scope — a ~30%-recall reviewer, which is one worth running.

The lesson, the same one the failed extractor experiments were circling: **concreteness drives recall; compression costs it.** "Capture the person, keep it short" optimized for how the artifact reads, not for how well it reproduces the reviewer.

But here's the objection that law deserves, and it's the most interesting open question in the work: recall is measured against PRs the reviewer *already commented on*. A catalog that enumerates every past pattern may simply be overfitting to seen code — strong on the distribution it was mined from, and no better than the persona, maybe worse, on genuinely novel changes. My eval measures fidelity-to-history, not generalization-to-new-code; the honest version of the law is **concreteness drives recall on the distribution you mined.** Whether it survives off-distribution is the experiment I haven't run yet. I'm stating the law and its limit together, because the whole point of this piece is what happens when you don't.

So I changed the extractor: enumerate *every* grounded pattern, each with its real example and quote; trim only ungrounded prose, never the patterns. On DHH that moved the persona from 41% to 49% — an eight-point bump, which is barely outside the noise I warned you about, so I don't lean on the number itself. I lean on the shape: it moved in the direction the catalog had already mapped, by doing the one thing the catalog did and the persona didn't.

## What if you combine the two approaches?

One more dead end deserves its own autopsy, because it was the obvious move and I was certain of it: the hybrid. **v3** took v2's persona — the voice, the lenience, the "what I'd never flag" — and bolted v1's concrete pattern catalog underneath it. Surely the calibration *plus* the examples beats either alone. It didn't. On the Ruby reviewer it landed *between* the two parents; on the Go systems reviewer it collapsed to 3% — worse than either, against the catalog's 11%. The cause is the same one that killed the three extractor "improvements" the autoresearch loop rejected: the persona prose competes with the catalog for the model's attention, and the concrete, quoted patterns — the part that actually drives recall — get diluted by the surrounding narration. More structure, more words, more "best of both" produced a *worse* reviewer. The thing that worked was the opposite move: strip to the grounded patterns and their quotes, and cut everything that isn't one.

A fair objection: isn't what I ended up shipping — a grounded persona full of concrete patterns and quotes — the very hybrid that just failed? No, and the difference is the whole point. v3 took an *already-compressed* persona (abstract prose) and **bolted a separate rule catalog underneath it** — two layers, where the abstract prose competed with the concrete patterns for the model's attention and blurred them. The shipped skill is a persona built *entirely* out of grounded patterns: every item is a quote plus an example, with no spare prose. Not "persona plus rules," but "a persona that is nothing but rules, spoken in the reviewer's voice." The numbers point the same way: v3 was the worst artifact of all (3% on Go, weak model), and the grounded persona I ship is the best (17.5% diff-only on the strong model).

## How it stacks up against the alternatives

Why clone a person at all when there are excellent general-purpose review skills? To answer that I put the extracted clone on the **private** eval against two popular ones — `pr-review-toolkit` and `ce-code-review` (neither ships a persona reviewer for Go, unlike Rails or TypeScript, so the comparison is fair).

Diff-only, the clone catches **17.5%** to the toolkit's **7.7%** and ce-code-review's **3.9%**; with the full recipe (repository + per-hunk depth + two passes unioned) it's **44%** against **34%** and **31%**. And one caveat that matters: the "full recipe" isn't a benchmark-only setting — `/reviewer:review` now runs two passes and unions them by default (with a confidence gate to hold precision), so 44% is what the tool actually delivers, not a number on paper.

<figure class="chart">
  <img src="/assets/images/posts/code-reviewer-eval/crosstool.svg" alt="Grouped bars: diff-only vs full recipe — our clone 17.5→44, pr-review-toolkit 7.7→34, ce-code-review 3.9→31.">
  <figcaption>Diff-only starves every tool; the full recipe lifts all three. The clone keeps a steady margin once scope is equalized.</figcaption>
</figure>

The more interesting question was how the clone does *alongside* these skills, not against them — the plugin integrates with compound-engineering, so I benchmarked a combined review: the repo-history clone running inside the ce panel. They catch different things, so the union beats either alone — clone **44%**, dry ce **31%**, combined **52%** (+8 over the clone, +21 over ce). Take their machinery, keep your specificity: the clone emits the same structured finding format `ce-code-review` uses, drops into its panel beside the generic reviewers, and runs standalone when that plugin isn't installed. (I also borrowed its one genuinely free idea — a per-finding confidence gate that cut false positives on the eval with no loss of recall, where a blanket "be cautious" just made the reviewer timid.)

<figure class="chart">
  <img src="/assets/images/posts/code-reviewer-eval/combined.svg" alt="Three ascending bars: ce-code-review 31, our clone 44, the two combined 52.">
  <figcaption>Combined review on the private Go reviewer (full recipe): the clone running inside the Compound Engineering panel, versus each alone. They catch different things, so the union beats either — +8 over the clone, +21 over dry ce.</figcaption>
</figure>

## What actually compounds

The reviewer is useful, but the thing worth taking from this isn't the reviewer — it's the eval. I shipped on a strong intuition (persona beats rules) and was wrong; I had a second (a hybrid beats both) and was wrong again. Both times the only reason I found out was a cheap, cheat-proof, per-comment eval with an honest judge and a precision control — it reversed my central design decision, killed three improvements I was sure of, and pointed at the real lever, repository access. And I'm not done being fooled: the biggest claim here — concreteness beats compression — I've only shown on code the reviewers already commented on; whether it holds on novel changes I don't know yet. The eval is how I'll find out. That's the real product — not a reviewer you finish and trust, but an eval you keep, because you'll keep being wrong and it's the only thing that tells you when.

A few takeaways:

- A persona in the prompt works — but only if you hand it the persona as *grounded* examples (quotes + real good/bad code), not abstract prose.
- For famous people the persona works even without that, because the model's training data is already saturated with their work — you're activating weights it already holds, not transferring judgment.
- Before you build any agent system — even one as simple as a Claude Code / Codex skill — build the eval first, so you can actually judge the result instead of trusting your intuition.
- Cloning your own reviewer from your repo's history is worth it when you have strong reviewers who left enough examples and you want to scale their judgment with AI — and scope (the repository) matters more than the prompt.

The [plugin](https://github.com/ivankuznetsov/agent-plugins) and the [public benchmark and harness](https://github.com/ivankuznetsov/agent-reviewer-eval) are open. Reproduce the numbers against these reviewers, or point it at your own team — and since they're directional, go argue with them.
