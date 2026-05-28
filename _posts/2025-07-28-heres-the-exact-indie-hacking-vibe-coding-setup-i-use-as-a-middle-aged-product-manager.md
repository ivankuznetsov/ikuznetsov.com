---
layout: post
title: Here's The Exact Indie-Hacking Vibe-Coding Setup I Use as a Middle-Aged Product Manager
date: '2025-07-28 19:00:08 +0000'
categories:
- llms
- cursor
- vibe-coding
- product-management
- indie-hackers
- indie-hacking-vibe-coding
- vibe-coding-setup
- hackernoon-top-story
original_url: https://hackernoon.com/heres-the-exact-indie-hacking-vibe-coding-setup-i-use-as-a-middle-aged-product-manager
canonical_url: https://hackernoon.com/heres-the-exact-indie-hacking-vibe-coding-setup-i-use-as-a-middle-aged-product-manager
source: hackernoon
excerpt: 'Middle-aged PM shares his AI-powered vibe-coding setup after restarting dev journey to beat burnout. '
---

I suppose you've seen a lot of memes about product managers making 3000-line pull requests to the senior devs' repository. Now you can meet one of them—that's me, yes.

## A Bit of History

My vibe-coding journey started a year and a half ago. While burned out by immigration hurdles and resettlement, and working my pretty solid job, I was looking to regain that childish joy of building something by myself—not via the hands of others. Being inspired by DHH, I found myself across Rails, and as any junior programmer, I started with a To-Do list app tutorial, which became [Todero.app](https://hackernoon.com/isomorphic-universal-boilerplate-react-redux-server-rendering-tutorial-example-webpack-compenent-6e22106ae285) now.

The biggest change came soon with ChatGPT, which allowed me to spend less time reading docs and more time building the actual app. It was the first time I found it quite easy to beat procrastination when facing something new. Before, I didn't know where to start or what to Google, but since ChatGPT arrived, I just started asking questions on how to do the thing I wanted to do. Answers weren't so good at the time, but while I wrote the question and got some cues from our AI overlord, I usually found the way to build the thing I wanted. Then Sonnet 3.5 was released, and that was when I actually developed most of the app—because that's when I got a pair programmer who was good enough to work with (assuming that I don't think I'm a very good programmer myself).

AI as an ultimate procrastination-beating tool—and I see it like this, not as a universal do-it-all replacement for me. You have an idea, and this is a very brief moment while your inspiration lives. So you have to do it, or the idea dies.

After a year and a half, I found the setup that suits me well. Nothing fancy, but as (not imaginary) people keep asking me about it, I decided to share it with the world.

## Present Times

First of all, I use a very vanilla set of tools. There are two reasons for that:

1. **Simplicity is key to successfully creating maintainable code using AI tools.** That's the main thing I've learned, and that's why many people struggle to use AI. In addition to a lack of engineering knowledge, they use overcomplicated tools they don't understand and rely solely on AI as a source of expertise.
2. **Longer runway.** The hard thing I learned while running a now-bankrupt and closed venture business is that you don't have to move fast—you should have enough runway to validate your ideas. No matter if you vibe-code or not, the more times you can roll the dice, the higher your chance of success. Golden or plastic dice don't matter in the real game. So, being an employed person with a limited amount of money I can spend on my hobby projects, I decided to squeeze as much value out of every dollar spent as I can and ruthlessly optimize my running budget—even if we're talking about $10 vs. $0.

### Infrastructure:

- Hetzner Cloud as a hosting provider ($5 per month instances work perfectly and can be upgraded when you start to grow with a couple of clicks; also, they have an easy-to-setup firewall, so you don't have to learn firewalld or iptables, and very simple backups).
- Netdata for hardware monitoring (they have a homelab plan that covers my needs for $5 per instance, giving you all the insights needed about your server).
- [Rabata.io](http://Rabata.io) for S3 cloud storage. Hetzner S3 has a minimal charge per bucket of $5, and Rabata doesn't—my typical bill now is about $1 per month for S3 cloud storage, which is perfect for hobby projects like mine and I can have as much bucket as I want. I also don't care how much disk space I use, because it literally doesn't matter with this pricing. They also not charging for requests made, as many others do.
- Cloudflare for security and caching CDN (completely free).
- I used Hatchbox.io for deployment ($10 per server) but moved to [Kamal](https://kamal-deploy.org), which is free and more flexible.
- Resend for email sending (just easier to use than Amazon SES).
- Openrouter for LLMs connection.

### As a technical stack, I use:

- Rails 8 with Solid Trifecta for all the code, including chatbots.
- Rails built-in Turbo and Stimulus.js for all my front-end needs.
- Postgres as database.
- Docker (managed by Kamal).

### My main coding tools:

- Ubuntu + [Omakub](https://omamix.org) as OS.
- Alacritty with Zellij as a terminal.
- Cursor as the main IDE.
- Micro (because I'm too soft to learn Vim) as a terminal editor.
- Git + GitHub (obviously) as source control.
- Grok for all outside-of-IDE LLM usage, from research and writing texts to generating images (for example Grok helped me as an editor for this article).

## **The Vibes**

After trying all widely available LLMs I found pretty obvious mix working best for me.

**Opus for backend planning and half of the frontend development.** Opus is expensive to use for all coding needs—my bill for the last month reached $500 mostly because of it before Cursor introduced their new $200 plan, which I recommend to anyone who writes a lot of code. With the same usage as last month, I haven't gone over the tier included in the new $200 plan. I use Opus mostly for planning backend features and writing prompts for Sonnet.

**Sonnet for day to day coding of most of the backend and half of the frontend code.** Opus good at generic designs and writes good texts, so I split the front-end work between Opus and Sonnet based on design and content complexity of the front-end.

[Here is the example](https://gist.github.com/ivankuznetsov/94dfc802d4148e2e33bda58dbf127e85) of my .cursorrules that I use for each conversation.

[Here is the example](https://gist.github.com/ivankuznetsov/cb38116de80c5acb93bc8b6b0f5ccfbe) of my planning prompt variations of which I use when I need Claude Opus to create a set of tasks for Sonnet.

I found that LLMs write good prompts for LLMs, so I don't have any tricked-out specific prompts. When I have to develop something complicated, I ask Opus to generate a prompt and write it down to Markdown files if the feature requires several steps—and I understand that it's better to split it across several chats because of the output quality degradation of LLMs with growing context.

As opposed to the Cursor team's own recommendations, I was unable to find o3 useful for planning. On my tasks and with my usage patterns, I found o3 is mostly useless for me, but many of my friends are happy with it. You can try for yourself to use o3 instead of Opus for prompt writing and feature planning.

## Why Not Claude Code?

I've heard a lot of positives about Claude Code but never tried it myself, because I'll still need an IDE for code editing, and I like Cursor. Paying for both Cursor and Claude Code at $400/month is a bit overkill for me. Also, I like the Cursor team after watching their interview with Lex Fridman (the best AI team interview I've heard among all the ones he made), and I want them to succeed.

## More Generic Advice Nobody Asked For, Based on My Limited Experience

You have to understand the code the LLM generates. So use only programming languages and frameworks you're familiar with. It's tempting to add various fancy tools while the LLM can greatly use them, but then you'll be writing one more Twitter post about vibe-coding not working for you.

Get a good understanding of how your tech stack works, so you can do simple things without LLMs. If you work on a web app, you should be able to create a website and deploy it to a self-hosted web server without any help from the LLM (you can learn it with an LLM, though, and then try to rawdog it by yourself). If you do a mobile app—same approach: you have to be able to create a simple app without help from the LLM to be able to leverage AI for you.

If you know how to do a thing, do it yourself and use the LLM as a pair programmer. If you struggle to start—start with the LLM. As I said before, for me AI is the best procrastination beater: when I don't know where to start, I fire up Cursor Agent to do it for me, and then after a few iterations, I'll understand what and how I want to build.

LLMs try to bring a lot of third-party libraries to your project just because someone on Reddit mentioned them three years ago. Libraries may be outdated and unmaintainable since then, so when it happens, stop the answer generation and ask why we need it and what the more "raw technology X alternative" is. The less code you have, the fewer third-party libraries, the less context LLMs need to process—the more intelligent the answers will be.

## Future

I started my coding journey again after a 10-year absence from development—having been a manager and founder—as a way to overcome my anxiety and become technically proficient again. AI comes in handy to help me get back on track. I plan to code any crazy idea I have in my mind and get as much as possible from this. And the hands-on building experience helps me be a better manager and better understand the technical challenges my team meets. So, no matter if my projects succeed or fail, I do it for the sake of craftsmanship and improving my skills with AI that I can use in my main job and get better. So, I would recommend any manager to start tinkering in their free time—not to become a self-made one-man billion-dollar vibe-coded startup, but as the best way to ride the wave of the AI revolution.

## About the Author

[Ivan Kuznetsov](https://ikuznetsov.com), ex-fullstack dev, ex-fintech executive, failed startup founder, now product manager, vibe-coding and RoR enthusiast.
