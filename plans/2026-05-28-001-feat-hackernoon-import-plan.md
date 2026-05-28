---
title: "feat: Import HackerNoon articles into ikuznetsov.com"
type: feat
status: active
date: 2026-05-28
---

# feat: Import HackerNoon articles into ikuznetsov.com

## Overview

Import all of Ivan's HackerNoon articles (`https://hackernoon.com/u/ivankuznetsov`) as native Jekyll posts in `_posts/`. Each imported post preserves its original publication date, mirrors embedded images locally, links back to the HackerNoon source as the canonical URL, and shows an "Originally posted on HackerNoon" footer.

The work is a Ruby import script + a small `_layouts/post.html` change. The script is idempotent so future HackerNoon publications can be pulled in by re-running it.

---

## Problem Frame

Articles I publish on HackerNoon currently live only there. I want them mirrored on my own site so they:
- Are discoverable from `ikuznetsov.com/posts/`
- Survive HackerNoon outages, redesigns, or eventual delistings
- Live in the same archive as my native posts (chronologically interleaved)

But I should not steal SEO from HackerNoon (they hosted the originals), and I should make the attribution clear to readers.

---

## Requirements Trace

- R1. Every article from `https://hackernoon.com/u/ivankuznetsov` lands as a file in `_posts/` with filename `YYYY-MM-DD-<slug>.md` using the original publication date.
- R2. Each imported post carries `<link rel="canonical" href="<hackernoon-url>">` in its rendered HTML head.
- R3. Each imported post renders an "Originally posted on HackerNoon" footer linking to the source URL.
- R4. Embedded article images are downloaded to `assets/images/posts/<slug>/` and rewritten to local paths.
- R5. The importer is idempotent: re-running skips posts whose target file already exists.
- R6. Native (non-imported) posts continue to render exactly as today — the layout change is additive only.

---

## Scope Boundaries

- Comments, reactions, and reads counters are not imported.
- HackerNoon-specific embeds (their internal story-embed widgets) render as a plain link to the source — full embed fidelity is out of scope.
- No automated scheduling/cron — the user runs the script manually when they want to pull new articles.
- No bidirectional sync — edits made on ikuznetsov.com do not propagate back to HackerNoon (and vice versa, unless the user re-runs after deleting the local file).
- SEO tooling beyond `<link rel="canonical">` (e.g., sitemap regeneration, structured data) is out of scope; Jekyll plugins handle whatever the site already does.

---

## Context & Research

### Relevant Code and Patterns

- `_posts/` — existing posts establish the front-matter shape: `layout: post`, `title`, `date` (with `+0100` tz), `categories`, optional `redirect_from`. The importer writes the same shape.
- `_layouts/post.html` — minimal post template. This is where the canonical link and the "originally posted" footer hook in. Today it has a `<header>`, `<div class="post-content">`, and a `<nav class="post-navigation">`.
- `_layouts/default.html` — emits `<head>`. The canonical `<link>` will be conditional on `page.canonical_url` so existing posts are unaffected.
- `Gemfile` — pinned Ruby gems. Two new dev-time gems are needed: `nokogiri` (HTML parsing) and `reverse_markdown` (HTML → Markdown).
- `assets/images/` — existing image directory. New subtree `assets/images/posts/<slug>/` for imported article images.

### External References

- HackerNoon RSS feed: `https://hackernoon.com/u/ivankuznetsov/feed` — provides title, link, pubDate, categories, and a truncated summary. Confirmed during planning.
- HackerNoon article pages include a `<script id="__NEXT_DATA__">` block (~60KB) containing structured article content from their Next.js SSR. Confirmed during planning to contain title, datePublished, articleBody, and the post body's HTML. This is the primary content source.
- Article pages also include a `<script type="application/ld+json">` block with schema.org `Article` metadata (datePublished, image, articleSection, headline). Useful as a fallback / cross-check.
- HackerNoon profile page (`/u/<user>`) only shows 5 stories in its initial SSR payload. If the total article count exceeds the RSS feed's 5-item cap, the script must paginate via HackerNoon's GraphQL/Algolia API or the profile's "load more" JSON endpoint. **Today the user has 5 articles total** and both surfaces return the same 5, so this is currently a non-issue — but the script should fail loudly (not silently truncate) if it later discovers articles on the profile page that the RSS feed missed.

---

## Key Technical Decisions

- **Language: Ruby.** Matches the Jekyll stack; no new toolchain required. Script lives in `script/import_hackernoon.rb` (new `script/` directory follows common Ruby repo convention).
- **Data source: RSS feed for the manifest, per-article HTML scrape for the body.** RSS gives reliable title/date/categories/link metadata. RSS content is truncated, so each article's body comes from parsing `__NEXT_DATA__` on its HTML page. JSON-LD is the cross-check for datePublished.
- **HTML → Markdown via `reverse_markdown`.** Battle-tested, handles code blocks, lists, blockquotes. Images and links get post-processing passes (image URL rewriting, embed handling).
- **Canonical URL: HackerNoon.** Per user choice. Implemented as a `canonical_url:` front-matter field on imported posts; `_layouts/default.html` emits `<link rel="canonical">` only when this field is set, leaving native posts unaffected.
- **Image storage: mirrored locally.** Per user choice. Each `<img>` source URL is downloaded once during import to `assets/images/posts/<slug>/<filename-or-hash>.<ext>` and the markdown body rewritten to the local path.
- **Idempotency by target file existence.** The script computes the target path (`_posts/YYYY-MM-DD-<slug>.md`) for each article and skips if the file already exists. A `--force` flag re-imports (useful if HackerNoon updates an article).
- **Attribution: footer only.** Per user choice — rendered by `_layouts/post.html` after `post-content` and before `post-navigation`, conditional on `page.original_url`.
- **Front-matter shape for imported posts:**
  - `layout: post`
  - `title: "..."`
  - `date: YYYY-MM-DD HH:MM:SS +0000` (HackerNoon `pubDate`, kept in UTC for clarity)
  - `categories:` (the RSS `<category>` tags, lowercased, dash-separated)
  - `original_url: https://hackernoon.com/...` (drives the footer)
  - `canonical_url: https://hackernoon.com/...` (drives the canonical `<link>`)
  - `source: hackernoon` (machine-readable marker; useful for future filters)

---

## Open Questions

### Resolved During Planning

- Canonical link target: HackerNoon URL.
- Image handling: mirror locally.
- Callout placement: bottom of post only.
- Repeatability: idempotent script, retained for future re-runs.

### Deferred to Implementation

- Exact CSS for the "Originally posted on HackerNoon" footer — match site palette (`#666` muted text, top border). Will iterate visually after first run.
- Whether to render HackerNoon's article tags as Jekyll `categories` or `tags`. The site currently uses `categories`. Imported posts will follow the same convention unless tag/category semantics diverge meaningfully when rendered — to be decided when looking at real output.
- Code-block language detection — `reverse_markdown` may produce fenced blocks without a language hint. Decide whether to leave them plain or attempt detection from HackerNoon's class hints during a post-conversion pass.

---

## Implementation Units

- [ ] U1. **Add import-time gem dependencies**

**Goal:** Make `nokogiri` and `reverse_markdown` available to the import script without polluting the production Jekyll build.

**Requirements:** R1, R2, R4

**Dependencies:** None

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock` (regenerated by `bundle install`)

**Approach:**
- Add a dedicated `group :import` block in the `Gemfile` so the gems aren't loaded during `jekyll build` or `jekyll serve`.
- Pin to currently stable major versions; let bundler resolve minors.
- The script will require them explicitly.

**Patterns to follow:**
- Existing `Gemfile` structure (`group :jekyll_plugins` block).

**Test scenarios:**
- Happy path: `bundle install` succeeds.
- Happy path: `bundle exec ruby script/import_hackernoon.rb --help` resolves both gems (proves the `:import` group is required correctly).
- Edge case: `bundle exec jekyll build` does not load the import gems (proves the group isolation).

**Verification:**
- `bundle install` exits 0.
- `jekyll build` output is unchanged from baseline (no new warnings about loaded gems).

---

- [ ] U2. **HackerNoon fetcher: manifest + article HTML**

**Goal:** Given a HackerNoon username, return a list of structured article records `{title, slug, original_url, published_at, categories, body_html, image_urls}` ready for downstream conversion.

**Requirements:** R1

**Dependencies:** U1

**Files:**
- Create: `script/import_hackernoon.rb` (main entry point; this unit lands the fetcher module + plumbing)
- Create: `script/hackernoon/fetcher.rb`

**Approach:**
- Parse the RSS feed (`https://hackernoon.com/u/<user>/feed`) for the article manifest: title, link, pubDate, categories.
- For each manifest entry, GET the article URL with a polite user-agent and a small rate limit (e.g., 1 request/second), then extract the article body from `<script id="__NEXT_DATA__">`.
- Cross-check `datePublished` from the JSON-LD `<script type="application/ld+json">` block. If the two dates disagree, prefer JSON-LD's `datePublished` (more precise) but log a warning.
- Also fetch the profile page once to compare total story count against the RSS-derived list. If profile shows more stories than RSS returned, fail loudly with the count delta so the user can decide how to extend pagination — do not silently import a subset.
- Collect all `<img src="...">` URLs from the body for U3 to download.
- Return plain Ruby Structs/Hashes; no I/O side effects (no writing posts, no downloading images) — keeps this unit testable in isolation.

**Patterns to follow:**
- Plain stdlib `Net::HTTP` + `Nokogiri` — no extra HTTP client gem needed.

**Test scenarios:**
- Happy path: feed parser extracts the expected count of items from a saved RSS fixture, with title/link/pubDate/categories populated.
- Happy path: article scraper extracts non-empty `body_html` and `image_urls` from a saved HTML fixture.
- Edge case: feed with zero items returns an empty list, not an error.
- Edge case: article HTML missing `__NEXT_DATA__` returns a clear error naming the URL (not a nil dereference).
- Error path: HTTP 404 / 500 on an article URL aborts that article with a log entry and continues with the rest.
- Integration: profile-page count check fails loudly when story count > RSS count (asserts the safety net is wired, not just present).

**Verification:**
- Running the fetcher against the live feed prints a manifest matching the RSS item count.
- A `--dry-run` flag (added in U6) prints each parsed article's title/date/image-count without writing files.

---

- [ ] U3. **HTML → Markdown converter with local image mirroring**

**Goal:** Convert a HackerNoon article's HTML body to Jekyll-ready Markdown, downloading each embedded image to `assets/images/posts/<slug>/` and rewriting `src` references to the local path.

**Requirements:** R4

**Dependencies:** U2

**Files:**
- Create: `script/hackernoon/converter.rb`

**Approach:**
- Use `reverse_markdown` for the bulk HTML → Markdown conversion.
- Before conversion, walk the parsed body with Nokogiri:
  - For each `<img>`: download the source URL to `assets/images/posts/<slug>/<sha1-prefix>-<basename>.<ext>` (sha prefix dedupes if HackerNoon reuses filenames across articles); rewrite `src` to the repo-root-relative path (`/assets/images/posts/<slug>/...`). Skip downloads when the file already exists (per-image idempotency on top of U4's per-article idempotency).
  - For HackerNoon's internal story-embed widgets (their card-style links to other HackerNoon articles), replace with a plain `<a>` to the linked article — full embed fidelity is out of scope (per Scope Boundaries).
- Post-process Markdown to clean up artifacts: collapse triple-blank-lines, strip empty `<p>` residue.
- Return `{markdown, downloaded_image_paths}`.

**Patterns to follow:**
- Existing image storage convention in `assets/images/`.

**Test scenarios:**
- Happy path: HTML with headings, paragraphs, code blocks, and lists converts to Markdown that round-trips cleanly through Kramdown (Jekyll's renderer).
- Happy path: an `<img>` with a `cdn.hackernoon.com` source gets downloaded once and its `src` rewritten to the local path; second invocation with the same image is a no-op (no second download).
- Edge case: article with zero images converts without creating an empty `assets/images/posts/<slug>/` directory.
- Edge case: image URL returns 404 — the image is logged as broken and the markdown keeps the original remote URL so the post is still readable.
- Error path: network failure mid-download leaves no partial file (download to a temp path, atomic rename on success).
- Integration: code blocks with HackerNoon's syntax-highlight wrappers convert to fenced markdown code blocks without nested HTML residue.

**Verification:**
- Running converter on a fixture HTML produces Markdown that Jekyll renders without warnings or errors.
- Image files appear on disk and resolve to `/assets/images/posts/<slug>/*` in the final post.

---

- [ ] U4. **Post writer: front matter + Markdown + idempotency**

**Goal:** Given a converted article record, write a Jekyll post file to `_posts/YYYY-MM-DD-<slug>.md` with the correct front matter, skipping the write if the target file already exists (unless `--force` is set).

**Requirements:** R1, R2, R3, R5

**Dependencies:** U3

**Files:**
- Create: `script/hackernoon/post_writer.rb`

**Approach:**
- Compute target path from article's `published_at` (date in UTC) and `slug`.
- Skip write when the file exists, unless `--force` was passed. Log every skip and every write.
- Front matter emits exactly the fields listed in Key Technical Decisions: `layout`, `title`, `date`, `categories`, `original_url`, `canonical_url`, `source`.
- `title` is YAML-quoted; embedded double-quotes are escaped.
- `date` is formatted `YYYY-MM-DD HH:MM:SS +0000` to match Jekyll's accepted form.
- Categories from RSS are lowercased and joined with spaces in the front-matter sequence form. The first category becomes the URL category slug (Jekyll convention).
- Run a slug-collision pre-check against existing files in `_posts/`: if any existing file shares the exact target filename, abort with a clear error so the user can decide (rename existing or pass `--force`).

**Patterns to follow:**
- Existing post conventions from `_posts/*.md` (front matter shape).

**Test scenarios:**
- Happy path: writes a new post file when none exists; resulting file has the correct front matter and body.
- Happy path: second invocation with the same article is a no-op (file unchanged on disk; mtime preserved).
- Edge case: `--force` overwrites an existing file.
- Edge case: title containing double quotes is correctly escaped in YAML.
- Error path: filename collides with an existing native post — script aborts with a message naming the file, does not overwrite.

**Verification:**
- `_posts/` after a dry-run-then-real-run contains exactly one new file per HackerNoon article.
- `jekyll build` after the run completes without errors and the new posts appear in the post listing.

---

- [ ] U5. **Layout: render canonical link and "originally posted" footer**

**Goal:** When a post has `canonical_url` and/or `original_url` front matter, render the canonical `<link>` in `<head>` and the attribution footer at the bottom of the article. Native posts (without these fields) render exactly as today.

**Requirements:** R2, R3, R6

**Dependencies:** None (parallel with U1–U4)

**Files:**
- Modify: `_layouts/default.html` (conditional `<link rel="canonical">` in `<head>`)
- Modify: `_layouts/post.html` (footer block after `post-content`, before `post-navigation`)
- Modify: `assets/css/main.css` (small style block for `.original-source`)

**Approach:**
- `default.html`: inside `<head>`, add `{% if page.canonical_url %}<link rel="canonical" href="{{ page.canonical_url }}">{% endif %}`. Defensive: do not emit anything for pages without the field.
- `post.html`: add a new `<aside class="original-source">` between `</div>` (closing `.post-content`) and `<nav class="post-navigation">`, conditional on `page.original_url`. Copy: "Originally posted on [HackerNoon]({{ page.original_url }})". The "HackerNoon" link uses the source URL.
- CSS: muted top border, small text, slight top margin. Match the existing typography scale.

**Patterns to follow:**
- Existing `_layouts/post.html` structure (header / content / nav blocks).
- Existing CSS conventions in `assets/css/main.css` (no inline styles; muted color is `#666`).

**Test scenarios:**
- Test expectation: none — this is template/styling change with no programmatic logic to unit-test. Verification is visual via local Jekyll preview and HTML inspection.

**Verification:**
- Imported post page source contains `<link rel="canonical" href="https://hackernoon.com/...">` in `<head>`.
- Imported post page renders an "Originally posted on HackerNoon" footer linking to the source URL.
- A native (existing) post page contains neither (regression check).

---

- [ ] U6. **CLI plumbing, one-shot run, and verify**

**Goal:** Wire the modules into `script/import_hackernoon.rb` with sane CLI flags (`--user`, `--dry-run`, `--force`, `--limit N`), run it against the live feed, review generated posts, and confirm Jekyll builds cleanly.

**Requirements:** R1, R5

**Dependencies:** U2, U3, U4, U5

**Files:**
- Modify: `script/import_hackernoon.rb` (final wiring + flag parsing + summary output)

**Approach:**
- Parse flags with `OptionParser` (stdlib).
- `--user` defaults to `ivankuznetsov`.
- `--dry-run` prints the per-article plan (target file, image count, total size) without writing anything.
- `--force` overrides idempotency.
- `--limit N` imports only the first N articles for quick smoke tests.
- After the run, print a summary: written, skipped, errored, image MB downloaded.
- Manual review pass on each generated post: scan for malformed code blocks, broken images, formatting glitches. Fix in `converter.rb` if systematic, edit individual files if one-off.
- Run `bundle exec jekyll build` and confirm zero errors and that all new posts appear in `_site/`.

**Test scenarios:**
- Test expectation: none beyond what's covered in U2–U4 — this unit is the integration glue. Manual review is the verification step.

**Verification:**
- All HackerNoon articles present in `_posts/` with valid front matter.
- `bundle exec jekyll build` exits 0 with zero warnings introduced by new posts.
- `bundle exec jekyll serve` renders each imported post; canonical link and footer present; images load locally; existing posts unchanged.

---

## System-Wide Impact

- **Interaction graph:** The layout changes (U5) affect every post page. Mitigated by making both additions strictly conditional on front-matter fields — native posts pass through unchanged.
- **Error propagation:** The import script fails per-article rather than aborting the batch (one bad article shouldn't block the other four). U2 includes the "fail loudly on RSS truncation" safety net to prevent silent partial imports.
- **State lifecycle risks:** Image files in `assets/images/posts/<slug>/` are written before the post file. If the script crashes mid-article, orphan images may remain. Acceptable — re-running the script reuses them via the per-image idempotency check in U3.
- **API surface parity:** No public API changes. The site's RSS feed (if any), sitemap, and Atom feed will include the new posts via Jekyll's normal pipeline.
- **Integration coverage:** The canonical link change is HTML-only — easy to verify by inspecting served output. The image mirroring is the highest-risk piece; verified via the manual review pass in U6.
- **Unchanged invariants:** Native posts, navigation, social links, and homepage projects sections must render byte-for-byte identically to today. The layout change in U5 is the only template touch and is guarded by `{% if page.canonical_url %}` / `{% if page.original_url %}`.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| HackerNoon changes their HTML structure / removes `__NEXT_DATA__` | Parser is isolated in `script/hackernoon/fetcher.rb`; a one-line CSS selector swap is the recovery path. JSON-LD fallback already wired in. |
| Total article count exceeds the 5-item RSS cap (currently no, but could grow) | U2 cross-checks profile page count against RSS count and fails loudly. Adding GraphQL pagination becomes a follow-up task at that point. |
| Image URLs on cdn.hackernoon.com break after import | We mirror locally on import (per user decision) so the local copy survives any upstream change. Broken image at import time logs and keeps the remote URL as a graceful fallback. |
| Markdown conversion artifacts (mangled code blocks, lost formatting) | Manual review pass in U6. Conversion logic is in one file (`converter.rb`) so iterating is cheap. |
| Slug collision with an existing native post | U4 pre-check aborts with a clear message; user renames manually. Five existing posts have unique slugs; live HackerNoon slugs do not currently collide. |
| Canonical link wrong (or missing) hurts SEO | Layout change is guarded by `{% if page.canonical_url %}` and verified in U6 via served HTML inspection. |
| Categories spelling/casing diverges between HackerNoon and existing posts | Lowercased on import. If divergence is undesirable, edit `_posts/*.md` post-hoc; cheap to fix. |

---

## Documentation / Operational Notes

- The script's `--help` output documents the available flags.
- Re-running after new HackerNoon articles publish is a single command. No state file or registry needed — idempotency is filesystem-based.
- A one-paragraph note in `aikuznetsov-com.md` (or a new `script/README.md`) explaining the import flow would help future me, but is not blocking.

---

## Sources & References

- HackerNoon feed: `https://hackernoon.com/u/ivankuznetsov/feed`
- HackerNoon profile: `https://hackernoon.com/u/ivankuznetsov`
- Existing posts: `_posts/`
- Existing layouts: `_layouts/post.html`, `_layouts/default.html`
- Image directory: `assets/images/`
- Gem documentation: `nokogiri`, `reverse_markdown`
