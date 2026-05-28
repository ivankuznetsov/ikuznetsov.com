# feat: Launch aikuznetsov.com - AI Developer Community Site

## Overview

Create aikuznetsov.com, an AI-focused sister site to ikuznetsov.com, targeting Russian-speaking AI developers and practitioners. The site will feature curated articles, newsletter integration, Telegram channel promotion, and a $100 lifetime-access paid community with application-based entry.

## Problem Statement / Motivation

- No dedicated platform for Russian-speaking AI practitioners to share experiences and learn
- Existing ikuznetsov.com focuses on general product/tech content; need specialized AI focus
- Growing community of AI developers needs a quality-filtered space for professional discussions
- Content published across multiple platforms lacks a centralized hub

## Proposed Solution

Build a Jekyll static site (same stack as ikuznetsov.com) with:
1. **Articles Section** - External links + article mirrors with proper SEO handling
2. **Newsletter Integration** - Buttondown-powered AI-focused newsletter
3. **Telegram Promotion** - Cross-promotion with Telegram channel
4. **Paid Community** - $100 lifetime access with application screening

---

## Technical Approach

### Architecture

```
aikuznetsov.com/
├── _config.yml                    # Site configuration
├── _layouts/
│   ├── default.html              # Base layout (from ikuznetsov.com)
│   ├── post.html                 # Blog posts
│   ├── article.html              # Articles (external links + mirrors)
│   └── landing.html              # Community landing page
├── _includes/
│   ├── head.html                 # SEO tags, fonts, CSS
│   ├── footer.html               # Site footer
│   ├── newsletter-signup.html    # Buttondown integration
│   ├── telegram-promo.html       # Telegram channel CTA
│   ├── community-application.html # Formspree application form
│   └── sections/
│       ├── rules.html            # Community rules
│       ├── pricing.html          # $100 pricing display
│       └── faq.html              # FAQ accordion
├── _articles/                    # Original articles collection
├── _external_links/              # Curated external links (no output)
├── _data/
│   ├── sections/
│   │   ├── community_rules.yml   # Rules data
│   │   └── faq.yml               # FAQ data
│   └── navigation.yml            # Site navigation
├── _posts/                       # Blog posts (optional)
├── assets/
│   ├── css/main.css              # Styles (extended from ikuznetsov.com)
│   ├── icons/*.svg               # Social icons
│   └── images/                   # Profile, OG images
├── .github/workflows/
│   └── jekyll.yml                # GitHub Pages deployment
├── index.markdown                # Homepage
├── articles.md                   # Articles listing page
├── community.md                  # Community landing page (Russian)
├── newsletter.md                 # Newsletter archive/signup
├── CNAME                         # aikuznetsov.com
├── Gemfile                       # Ruby dependencies
└── favicon.ico                   # Site favicon
```

### Implementation Phases

#### Phase 1: Foundation - Site Setup

**Tasks:**
- [ ] Create new GitHub repository `aikuznetsov.com`
- [ ] Copy base Jekyll structure from ikuznetsov.com:
  - `_layouts/default.html`
  - `_layouts/post.html`
  - `_includes/head.html`
  - `_includes/footer.html`
  - `assets/css/main.css`
  - `assets/icons/*.svg`
  - `Gemfile`
  - `.github/workflows/jekyll.yml`
  - `.gitignore`
  - `.ruby-version`
- [ ] Update `_config.yml` with aikuznetsov.com settings
- [ ] Create `CNAME` file with `aikuznetsov.com`
- [ ] Configure domain DNS (point to GitHub Pages)
- [ ] Test deployment pipeline

**Files to create/modify:**

```yaml
# _config.yml
title: AI Kuznetsov
email: ai@aikuznetsov.com
description: >-
  Сообщество для тех, кто строит продукты с помощью ИИ
url: "https://aikuznetsov.com"

# Locale settings
locale: ru_RU
lang: ru

# Theme & plugins (same as ikuznetsov.com)
theme: minima
plugins:
  - jekyll-feed
  - jekyll-redirect-from
  - jekyll-seo-tag

permalink: /posts/:title/

# Twitter/SEO
twitter:
  username: ikuznetsov_com
  card: summary_large_image

image: /assets/images/og-image.jpg

# Author
author:
  name: "Ivan Kuznetsov"
  twitter: ikuznetsov_com
  url: "https://aikuznetsov.com"

# Collections
collections:
  articles:
    output: true
    permalink: /articles/:path/
  external_links:
    output: false
    sort_by: date

# Defaults
defaults:
  - scope:
      path: ""
      type: articles
    values:
      layout: article
      lang: ru
      image: /assets/images/og-image.jpg
  - scope:
      path: ""
      type: pages
    values:
      layout: default
      image: /assets/images/og-image.jpg
```

**Success Criteria:**
- Site deploys successfully on GitHub Pages
- Homepage loads at aikuznetsov.com
- All CSS/assets load correctly

---

#### Phase 2: Content Infrastructure - Articles & Newsletter

**Tasks:**
- [ ] Create `_layouts/article.html` for article display
- [ ] Set up `_articles/` collection for original content
- [ ] Set up `_external_links/` collection for curated links
- [ ] Create `articles.md` listing page with mixed content
- [ ] Set up Buttondown newsletter account (aikuznetsov or similar)
- [ ] Create `_includes/newsletter-signup.html` with new Buttondown endpoint
- [ ] Create `newsletter.md` page with signup and archive link
- [ ] Add RSS feed configuration for articles

**Files to create:**

```html
<!-- _layouts/article.html -->
---
layout: default
---
<nav class="back-to-home">
  <a href="/">← aikuznetsov.com</a>
</nav>

<article class="post">
  <header class="post-header">
    <h1 class="post-title">{{ page.title }}</h1>
    <p class="post-meta">
      <time datetime="{{ page.date | date_to_xmlschema }}">
        {{ page.date | date: "%d.%m.%Y" }}
      </time>
      {% if page.external_url %}
        <span class="source">• Источник: <a href="{{ page.external_url }}" target="_blank" rel="noopener">{{ page.source }}</a></span>
      {% endif %}
    </p>
  </header>

  <div class="post-content">
    {{ content }}
  </div>
</article>

{% include newsletter-signup.html %}
```

```yaml
# Example: _articles/2025-01-15-building-ai-agents.md
---
title: "Как строить AI агентов в 2025"
date: 2025-01-15
description: "Практический гайд по созданию автономных AI агентов"
tags: [agents, claude, cursor]
lang: ru
---

Article content here...
```

```yaml
# Example: _external_links/2025-01-10-openai-agents.md
---
title: "OpenAI выпустила Agents SDK"
date: 2025-01-10
external_url: "https://openai.com/blog/agents"
source: "OpenAI Blog"
excerpt: "Новый SDK для создания AI агентов от OpenAI"
tags: [openai, agents, news]
---
```

**Success Criteria:**
- Articles display correctly with proper SEO tags
- External links show source attribution
- Newsletter signup form submits to Buttondown
- RSS feed generates correctly

---

#### Phase 3: Community Page - Russian Landing Page

**Tasks:**
- [ ] Create `_layouts/landing.html` for section-based pages
- [ ] Create `_data/sections/community_rules.yml` with Russian rules
- [ ] Create `_data/sections/faq.yml` with FAQ content
- [ ] Create `_includes/sections/rules.html` template
- [ ] Create `_includes/sections/pricing.html` template
- [ ] Create `_includes/sections/faq.html` template (accordion)
- [ ] Create `community.md` page with full Russian content from aikuznetsov-com.md
- [ ] Add CSS for landing page sections

**Files to create:**

```yaml
# _data/sections/community_rules.yml
title: "Правила игры"
rules:
  - icon: "constructive"
    title: "Конструктивное взаимодействие"
    description: "Приветствуются открытость, профессиональная взаимопомощь и поддержание благоприятной атмосферы"
  - icon: "ethics"
    title: "Этическое поведение"
    description: "Любые формы токсичности, оскорбления и дискриминация недопустимы"
  - icon: "no-politics"
    title: "Информационная гигиена"
    description: "Запрет на обсуждение политических тем"
  - icon: "no-commercial"
    title: "Запрет на коммерцию"
    description: "Несанкционированная реклама и продажа услуг запрещены"
```

```yaml
# _data/sections/faq.yml
title: "Часто задаваемые вопросы"
questions:
  - question: "Как долго рассматривается заявка?"
    answer: "Мы рассматриваем заявки в течение 5 рабочих дней. После одобрения вы получите ссылку на оплату."
  - question: "Какие способы оплаты принимаются?"
    answer: "Оплата производится через Stripe — принимаются Visa, MasterCard и другие карты."
  - question: "Можно ли получить возврат?"
    answer: "Взнос не возвращается. Это минимальный фильтр для формирования качественного сообщества."
  - question: "Что входит в членство?"
    answer: "Доступ в закрытое сообщество, еженедельные модерируемые созвоны, периодические лайв-сессии от экспертов."
  - question: "На какой платформе проходит общение?"
    answer: "Основное общение происходит в закрытой Telegram-группе."
```

```markdown
<!-- community.md -->
---
layout: landing
title: "Сообщество AI разработчиков"
description: "Закрытое сообщество для тех, кто строит продукты с помощью ИИ"
lang: ru
sections:
  - hero
  - about
  - audience
  - included
  - rules
  - pricing
  - faq
  - application
---
```

**Success Criteria:**
- Community page displays all sections from aikuznetsov-com.md
- FAQ accordion works without JavaScript (using `<details>`)
- All Russian text renders correctly
- Proper `og:locale=ru_RU` in meta tags

---

#### Phase 4: Application & Payment Flow

**Tasks:**
- [ ] Create Formspree account and form endpoint
- [ ] Create `_includes/community-application.html` form
- [ ] Create Stripe account and Payment Link ($100)
- [ ] Create `/application-received/` thank you page
- [ ] Set up Google Sheet for application tracking (manual)
- [ ] Create email templates for manual workflow:
  - Application received confirmation
  - Application approved with payment link
  - Application rejected
  - Payment received with access instructions
- [ ] Configure Stripe Payment Link with metadata field for email

**Files to create:**

```html
<!-- _includes/community-application.html -->
<section class="application-section" id="apply">
  <div class="container">
    <h2>Заполнить анкету участника</h2>
    <p>После рассмотрения заявки (обычно 2-5 рабочих дней) вы получите ссылку на оплату.</p>

    <form
      action="https://formspree.io/f/YOUR_FORM_ID"
      method="POST"
      class="application-form"
    >
      <input type="hidden" name="_subject" value="Новая заявка в сообщество">
      <input type="hidden" name="_next" value="https://aikuznetsov.com/application-received/">
      <input type="text" name="_gotcha" style="display:none">

      <div class="form-group">
        <label for="name">Имя и фамилия *</label>
        <input type="text" id="name" name="name" required>
      </div>

      <div class="form-group">
        <label for="email">Email *</label>
        <input type="email" id="email" name="email" required>
      </div>

      <div class="form-group">
        <label for="telegram">Telegram *</label>
        <input type="text" id="telegram" name="telegram" placeholder="@username" required>
      </div>

      <div class="form-group">
        <label for="role">Текущая роль *</label>
        <input type="text" id="role" name="role" placeholder="ML Engineer, Backend Developer, Product Manager..." required>
      </div>

      <div class="form-group">
        <label for="experience">Опыт работы с AI инструментами *</label>
        <select id="experience" name="experience" required>
          <option value="">Выберите...</option>
          <option value="beginner">Начинающий (0-1 год)</option>
          <option value="intermediate">Средний (1-3 года)</option>
          <option value="advanced">Продвинутый (3+ года)</option>
        </select>
      </div>

      <div class="form-group">
        <label for="motivation">Почему хотите присоединиться? *</label>
        <textarea id="motivation" name="motivation" rows="4" required
                  placeholder="Расскажите о вашем интересе к AI и что надеетесь получить от сообщества"></textarea>
      </div>

      <div class="form-group">
        <label for="contribution">Чем можете быть полезны сообществу?</label>
        <textarea id="contribution" name="contribution" rows="3"
                  placeholder="Ваш опыт, экспертиза, идеи контента"></textarea>
      </div>

      <button type="submit" class="submit-btn">Отправить заявку</button>
    </form>
  </div>
</section>
```

```markdown
<!-- application-received.md -->
---
layout: default
title: "Заявка получена"
description: "Ваша заявка на вступление в сообщество получена"
lang: ru
---

<div class="thank-you-page">
  <h1>Спасибо за заявку!</h1>
  <p>Мы получили вашу анкету и рассмотрим её в течение 5 рабочих дней.</p>
  <p>Если ваша заявка будет одобрена, вы получите письмо со ссылкой на оплату ($100).</p>
  <p>Пока ждёте — подписывайтесь на <a href="https://t.me/your_channel">Telegram-канал</a> для бесплатных AI-инсайтов.</p>
  <a href="/" class="back-link">← Вернуться на главную</a>
</div>
```

**Stripe Payment Link Setup:**
1. Create product "AI Community Membership" - $100 one-time
2. Create Payment Link with:
   - Allow customer to adjust quantity: No
   - Collect email: Yes
   - Custom fields: Add "telegram" text field
3. Success URL: `https://aikuznetsov.com/payment-success/`

**Manual Workflow (documented for future automation):**
1. Formspree sends application to your email
2. Add to Google Sheet with columns: Date, Name, Email, Telegram, Role, Experience, Status
3. Review application (criteria: real developer/PM, not spam, genuine motivation)
4. If approved: Send email with Stripe Payment Link
5. If rejected: Send rejection email (optional: with feedback)
6. On payment: Stripe sends confirmation to your email
7. You send Telegram group invite link to paid member

**Success Criteria:**
- Application form submits successfully
- Form data arrives in email/spreadsheet
- Payment link works and processes $100
- Thank you pages display correctly

---

#### Phase 5: Telegram Integration & Homepage

**Tasks:**
- [ ] Create `_includes/telegram-promo.html` component
- [ ] Add Telegram link to footer
- [ ] Create homepage `index.markdown` with:
  - Brief intro about AI focus
  - Latest articles section
  - Newsletter signup
  - Telegram channel CTA
  - Community teaser with link
- [ ] Add CSS for homepage layout
- [ ] Create profile image/avatar for AI site

**Files to create:**

```html
<!-- _includes/telegram-promo.html -->
<section class="telegram-promo">
  <div class="telegram-content">
    <img src="/assets/icons/telegram.svg" alt="Telegram" class="telegram-icon">
    <div>
      <h3>Telegram-канал</h3>
      <p>Ежедневные инсайты об AI инструментах и практиках</p>
    </div>
    <a href="https://t.me/your_channel" target="_blank" class="telegram-btn">
      Подписаться
    </a>
  </div>
</section>
```

```markdown
<!-- index.markdown -->
---
layout: default
title: "AI Kuznetsov"
description: "Инсайты о разработке с AI для русскоязычных специалистов"
lang: ru
---

<div class="profile">
  <div class="profile-image">
    <img src="/assets/images/profile.jpg" alt="Ivan Kuznetsov">
  </div>
  <div class="profile-info">
    <h1>AI Kuznetsov</h1>
    <p>Пространство для тех, кто использует AI в работе — от Cursor и Claude Code до кастомных агентов. Статьи, рассылка и закрытое сообщество.</p>

    <div class="social-links">
      <a href="https://t.me/your_channel" target="_blank" title="Telegram">
        <img src="/assets/icons/telegram.svg" alt="Telegram" class="social-icon">
        <span>Telegram</span>
      </a>
      <a href="http://twitter.com/ikuznetsov_com" target="_blank" title="X">
        <img src="/assets/icons/x.svg" alt="X" class="social-icon">
        <span>X</span>
      </a>
    </div>
  </div>
</div>

<section class="articles-preview">
  <h2>Статьи</h2>
  <ul>
    {% for article in site.articles limit:5 %}
      <li>
        <a href="{{ article.url | relative_url }}">{{ article.title }}</a>
        <div class="post-date">{{ article.date | date: "%d.%m.%Y" }}</div>
      </li>
    {% endfor %}
    {% for link in site.external_links limit:3 %}
      <li class="external">
        <a href="{{ link.external_url }}" target="_blank" rel="noopener">
          {{ link.title }} <span class="external-icon">↗</span>
        </a>
        <div class="post-date">{{ link.date | date: "%d.%m.%Y" }} • {{ link.source }}</div>
      </li>
    {% endfor %}
  </ul>
  <p><a href="/articles/">Все статьи →</a></p>
</section>

{% include newsletter-signup.html %}

{% include telegram-promo.html %}

<section class="community-teaser">
  <h2>Закрытое сообщество</h2>
  <p>Для тех, кто строит продукты с помощью AI. Еженедельные созвоны, лайв-сессии, обмен опытом.</p>
  <a href="/community/" class="cta-btn">Узнать больше →</a>
</section>
```

**Success Criteria:**
- Homepage displays articles and external links
- Telegram CTA is prominent
- Newsletter signup works
- Community teaser links to community page

---

#### Phase 6: Polish & Launch

**Tasks:**
- [ ] Add CSS for all new components (application form, landing sections, telegram promo)
- [ ] Test all forms (newsletter, application)
- [ ] Test Stripe payment flow end-to-end
- [ ] Test mobile responsiveness
- [ ] Add 404 page with Russian text
- [ ] Set up Google Analytics (GA4)
- [ ] Test SEO tags (og:locale, og:image, etc.)
- [ ] Create initial articles (2-3) for launch content
- [ ] Create initial external links (5-10) for content variety
- [ ] Cross-link from ikuznetsov.com (footer mention or article)
- [ ] Announce on Telegram channel

**CSS additions for `assets/css/main.css`:**

```css
/* === APPLICATION FORM === */
.application-section {
  margin: 2.5rem 0;
  padding: 2rem;
  background: #f9f9f9;
  border-radius: 0.625rem;
}

.application-form .form-group {
  margin-bottom: 1.25rem;
}

.application-form label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.application-form input,
.application-form select,
.application-form textarea {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 0.0625rem solid #ddd;
  border-radius: 0.3125rem;
  font-family: Georgia, serif;
  font-size: 1rem;
}

.application-form .submit-btn {
  padding: 0.875rem 2rem;
  background: #333;
  color: #fff;
  border: none;
  border-radius: 0.3125rem;
  font-size: 1rem;
  cursor: pointer;
}

/* === TELEGRAM PROMO === */
.telegram-promo {
  margin: 2.5rem 0;
  padding: 1.5rem;
  background: #f0f4f8;
  border-radius: 0.625rem;
  border-left: 0.25rem solid #0088cc;
}

.telegram-content {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.telegram-icon {
  width: 2.5rem;
  height: 2.5rem;
}

.telegram-btn {
  margin-left: auto;
  padding: 0.625rem 1.25rem;
  background: #0088cc;
  color: #fff;
  border-radius: 0.3125rem;
  text-decoration: none;
}

/* === LANDING SECTIONS === */
.landing-section {
  padding: 3rem 0;
  border-bottom: 0.0625rem solid #eee;
}

.rules-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
  margin-top: 1.5rem;
}

.rule-card {
  padding: 1.25rem;
  background: #fff;
  border-radius: 0.5rem;
  border: 0.0625rem solid #e5e5e5;
}

/* FAQ Accordion */
.faq-item {
  margin-bottom: 0.75rem;
  border: 0.0625rem solid #e5e5e5;
  border-radius: 0.3125rem;
}

.faq-question {
  padding: 1rem;
  cursor: pointer;
  font-weight: bold;
}

.faq-answer {
  padding: 0 1rem 1rem;
}

/* External link indicator */
.external-icon {
  font-size: 0.875rem;
  opacity: 0.7;
}

/* Mobile responsive */
@media (max-width: 48rem) {
  .telegram-content {
    flex-direction: column;
    text-align: center;
  }

  .telegram-btn {
    margin-left: 0;
    margin-top: 1rem;
  }

  .rules-grid {
    grid-template-columns: 1fr;
  }
}
```

**Success Criteria:**
- All pages render correctly on desktop and mobile
- All forms submit successfully
- Payment flow works end-to-end
- Site passes basic SEO audit (meta tags, OG images)
- Google Analytics tracking events fire

---

## Acceptance Criteria

### Functional Requirements
- [ ] Homepage displays with AI-focused branding and content
- [ ] Articles section shows both original articles and curated external links
- [ ] Newsletter signup submits to Buttondown successfully
- [ ] Community page displays all content from aikuznetsov-com.md in Russian
- [ ] Application form submits to Formspree with all required fields
- [ ] Thank you page displays after application submission
- [ ] Stripe Payment Link processes $100 payments
- [ ] Telegram channel links work and open Telegram app/web
- [ ] All social links (X, Telegram) are functional

### Non-Functional Requirements
- [ ] Page load time < 3 seconds
- [ ] Mobile responsive (tested on iPhone, Android)
- [ ] SEO tags render correctly (og:locale=ru_RU, og:image, twitter:card)
- [ ] Favicon displays in browser tabs
- [ ] RSS feed generates valid XML
- [ ] GitHub Actions deployment completes successfully

### Quality Gates
- [ ] Site deploys without build errors
- [ ] All forms tested with real submissions
- [ ] Payment tested with Stripe test mode
- [ ] Content reviewed for typos/broken links
- [ ] Cross-browser tested (Chrome, Safari, Firefox)

---

## Dependencies & Prerequisites

1. **Domain**: aikuznetsov.com registered and DNS configured
2. **Accounts**:
   - GitHub (existing)
   - Buttondown (new newsletter account)
   - Formspree (free tier sufficient)
   - Stripe (existing or new for payment)
   - Google Analytics (GA4 property)
3. **Content**:
   - Profile photo for AI site
   - OG image (1200x630)
   - Initial 2-3 articles for launch
   - Initial 5-10 curated external links
4. **Telegram**: Channel created and populated with initial content

---

## Risk Analysis & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Low application volume | Medium | Medium | Pre-announce on existing channels; start with soft launch |
| Payment flow issues | Low | High | Thorough testing with Stripe test mode; manual fallback |
| Spam applications | Medium | Low | Formspree honeypot; manual review as filter |
| Community platform issues | Low | High | Start with Telegram (proven); have Discord backup plan |
| SEO penalties for mirrored content | Medium | Medium | Use canonical URLs; add unique commentary |
| Manual workflow bottleneck | High | Medium | Document process; consider automation in Phase 2 |

---

## Success Metrics

- **Newsletter**: 100 subscribers in first month
- **Applications**: 20 applications in first month
- **Conversion**: 50% application-to-paid conversion rate
- **Community**: 10 paying members in first month
- **Content**: 10 articles (original + curated) published in first month
- **Telegram**: Cross-promotion increases channel subscribers by 20%

---

## Future Considerations

### Phase 2 (Post-Launch)
- Automate application → approval → payment → access flow with Zapier/Make
- Add member-only content section with password protection
- Implement search functionality
- Add comments to articles (Disqus/Giscus)
- Create bilingual (EN/RU) content strategy

### Phase 3 (Scale)
- Custom authentication for member dashboard
- Payment plans (monthly option alongside lifetime)
- Course/workshop sales integration
- Affiliate/referral program
- Mobile app for community

---

## Documentation Plan

- [ ] README.md with setup instructions
- [ ] WORKFLOW.md documenting application review process
- [ ] Email templates stored in `_docs/emails/`
- [ ] Google Sheet template for application tracking

---

## References & Research

### Internal References
- Existing site structure: `/home/asterio/Dev/ikuznetsov.com/`
- Community content (Russian): `/home/asterio/Dev/ikuznetsov.com/aikuznetsov-com.md`
- Newsletter integration pattern: `/home/asterio/Dev/ikuznetsov.com/_includes/newsletter-signup.html`
- CSS patterns: `/home/asterio/Dev/ikuznetsov.com/assets/css/main.css`
- Deployment workflow: `/home/asterio/Dev/ikuznetsov.com/.github/workflows/jekyll.yml`

### External References
- [Formspree Jekyll Guide](https://formspree.io/guides/jekyll/)
- [Stripe Payment Links](https://stripe.com/docs/payments/payment-links)
- [Buttondown API](https://buttondown.email/api)
- [Jekyll Collections](https://jekyllrb.com/docs/collections/)
- [jekyll-seo-tag Configuration](https://github.com/jekyll/jekyll-seo-tag)
- [GitHub Pages Jekyll Deployment](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll)

---

## Open Questions for Clarification

1. **Community Platform**: Confirm Telegram private group as community platform?
2. **Payment Automation**: Start with manual workflow or invest in Zapier automation upfront?
3. **Language**: Site primarily Russian, or add English articles later?
4. **Branding**: Same profile photo as ikuznetsov.com or new AI-themed image?
5. **Cross-promotion**: Add link to aikuznetsov.com from ikuznetsov.com footer?
