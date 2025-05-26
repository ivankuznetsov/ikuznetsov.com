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
    <p>Former technical leader, senior PM, fintech executive and multiple failed startups founder; now: psychology enthusiast, product management consultant, and Ruby on Rails amateur tinkering with AI.</p>
    
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
  
  <div class="project-grid-current-past">
    <div class="project">
      <h3>Past</h3>
      
      <div class="project-item">
        <h4><a href="http://innersense.app" target="_blank">InnerSense</a></h4>
        <p>Science-backed psychotherapy practices in your pocket. A mobile app that brought mental wellness tools to thousands of users. (Post-mortem)</p>
      </div>
    </div>
    
    <div class="project">
      <h3>Current</h3>
      
      <div class="project-item">
        <h4><a href="https://todero.app" target="_blank">Todero</a></h4>
        <p>No-nonsense to-do list built for power users. Features keyboard-first navigation and seamless Telegram integration for capturing tasks on the go.</p>
      </div>
    </div>
  </div>
  
  <div class="project-grid-upcoming">
    <div class="project">
      <h3>Upcoming</h3>
      
      <div class="upcoming-items">
        <div class="project-item">
          <h4>Writero</h4>
          <p>Smart writing assistant that helps you craft better content, faster. AI-powered suggestions without the fluff.</p>
        </div>
        
        <div class="project-item">
          <h4>Calendero</h4>
          <p>Intelligent calendar scheduling through a Telegram bot. Schedule meetings and manage your time without leaving your messenger.</p>
        </div>
        
        <div class="project-item">
          <h4><a href="https://topgreendeals.co.uk" target="_blank">Top Green Deals</a></h4>
          <p>Curated aggregator of green energy solutions for homes and SMBs. Making sustainable choices simple and cost-effective.</p>
        </div>
      </div>
    </div>
  </div>
</section>

<section>
  <h2>Recent publications</h2>
  <ul>
    {% for post in site.posts limit:5 %}
      <li>
        <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
        <span class="post-date">{{ post.date | date: "%B %d, %Y" }}</span>
      </li>
    {% endfor %}
  </ul>
  <!-- <p><a href="/posts/">View all →</a></p> -->
</section>
