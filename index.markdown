---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: default
---

<div class="profile">
  <div class="profile-image">
    <img src="/assets/images/profile.jpg" alt="Ivan Kuznetsov">
  </div>
  <div class="profile-info">
    <h1>Ivan Kuznetsov</h1>
    <p>Senior Technical PM working on storage and AI by day, indie hacker shipping Rails + AI side projects by night.</p>
    
    <div class="social-links">
      <a href="http://twitter.com/ikuznetsov_com" target="_blank" title="X">
        <img src="/assets/icons/x.svg" alt="X" class="social-icon">
        <span>X</span>
      </a>
      <a href="https://www.linkedin.com/in/ivankuznetsov/" target="_blank" title="LinkedIn">
        <img src="/assets/icons/linkedin.svg" alt="LinkedIn" class="social-icon">
        <span>LinkedIn</span>
      </a>
    </div>
  </div>
</div>

<section class="projects">
  <h2>My Projects</h2>

  <div class="project">
    <h3>Opensource</h3>
    <div class="current-items">
      <div class="project-item">
        <h4><img src="/assets/icons/star.svg" alt="Featured" class="featured-icon"><a href="https://github.com/ivankuznetsov/hive" target="_blank">Hive</a></h4>
        <p>Multi-agent pipeline that turns a rough idea into a merge-ready pull request. Folder-based stages you can watch, edit, and steer in your editor — compound engineering, made tangible.</p>
      </div>

      <div class="project-item">
        <h4><a href="https://github.com/ivankuznetsov/rails_simple_auth" target="_blank">Rails Simple Auth</a></h4>
        <p>Modern authentication gem for Rails 8+ with email/password auth, magic links, and OAuth.</p>
      </div>
    </div>
  </div>

  <div class="project">
    <h3>Agent Plugins</h3>
    <p>Four plugins I use daily, vendored together as a <a href="https://github.com/ivankuznetsov/agent-plugins" target="_blank">marketplace</a> for Claude Code and Codex.</p>
    <div class="current-items">
      <div class="project-item">
        <h4><a href="https://github.com/ivankuznetsov/llm-wiki" target="_blank">LLM Wiki</a></h4>
        <p>Bootstraps and maintains an LLM-readable project wiki indexed by QMD — your agents' memory across sessions.</p>
      </div>

      <div class="project-item">
        <h4><a href="https://github.com/ivankuznetsov/agent-plugins/tree/main/plugins/screenote" target="_blank">Screenote</a></h4>
        <p>Gives agents eyes. Captures the rendered page, ships it to <a href="https://screenote.ai" target="_blank">Screenote</a> for human annotation, pulls comments back via MCP.</p>
      </div>

      <div class="project-item">
        <h4><a href="https://github.com/ivankuznetsov/claude-seo" target="_blank">Agent SEO</a></h4>
        <p>Long-form SEO pipeline — keyword research, drafting, AI-prose humanizing, fact-checking as a workflow step, and on-site optimization.</p>
      </div>

      <div class="project-item">
        <h4><a href="https://github.com/ivankuznetsov/agent-plugins/tree/main/plugins/agent-writing" target="_blank">Agent Writing</a></h4>
        <p>Three rival voices for prose that matters — a journalist who grounds, a writer who drafts, an editor who cuts. No self-praise loop.</p>
      </div>
    </div>
  </div>

  <div class="project">
    <h3>Products</h3>
    <div class="current-items">
      <div class="project-item">
        <h4><a href="https://todero.app" target="_blank">Todero</a></h4>
        <p>No-nonsense to-do list built for power users. Features keyboard-first navigation and seamless Telegram integration for capturing tasks on the go.</p>
      </div>

      <div class="project-item">
        <h4><a href="https://writero.app" target="_blank">Writero</a></h4>
        <p>Smart writing assistant that helps you craft better content, faster. AI-powered suggestions without the fluff.</p>
      </div>

      <div class="project-item">
        <h4><a href="https://screenote.ai" target="_blank">Screenote</a></h4>
        <p>Visual feedback for AI agents. Agents capture screenshots, humans drop Figma-style comments, and agents read the annotations back via MCP.</p>
      </div>

      <div class="project-item">
        <h4><a href="https://topgreendeals.co.uk" target="_blank">TopGreenDeals.co.uk</a></h4>
        <p>Curated aggregator of green energy solutions for homes and SMBs. Making sustainable choices simple and cost-effective.</p>
      </div>
    </div>
  </div>
</section>

{% include newsletter-signup.html %}

<section>
  <h2>Publications</h2>
  <ul>
    {% for post in site.posts %}
      <li>
        <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
        <div class="post-date">{{ post.date | date: "%B %d, %Y" }}</div>
      </li>
    {% endfor %}
  </ul>
</section>
