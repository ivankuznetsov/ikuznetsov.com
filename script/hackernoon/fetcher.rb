# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "time"
require "nokogiri"

module HackerNoon
  Article = Struct.new(
    :title, :slug, :original_url, :published_at, :tags, :body_html, :main_image_url, :excerpt,
    keyword_init: true,
  )

  RSS_URL_TEMPLATE = "https://hackernoon.com/u/%<user>s/feed"
  PROFILE_URL_TEMPLATE = "https://hackernoon.com/u/%<user>s"
  USER_AGENT = "ikuznetsov.com-hackernoon-import/1.0 (+https://ikuznetsov.com)"
  REQUEST_DELAY = 1.0

  class FetchError < StandardError; end

  class Fetcher
    def initialize(user:, logger: $stdout)
      @user = user
      @logger = logger
      @last_request_at = nil
    end

    # Returns an array of Article structs with title/slug/original_url/published_at/tags filled in
    # from the RSS feed. body_html and main_image_url remain nil — populate via #hydrate(article).
    def manifest
      xml = http_get(format(RSS_URL_TEMPLATE, user: @user))
      doc = Nokogiri::XML(xml)
      doc.remove_namespaces!
      doc.xpath("//item").map { |item| article_from_rss_item(item) }
    end

    # Cross-check: count stories shown on the profile page. Used by the safety net
    # in #manifest_with_safety_net to detect when the RSS feed truncated.
    def profile_story_count
      html = http_get(format(PROFILE_URL_TEMPLATE, user: @user))
      data = extract_next_data(html)
      stories = data.dig("props", "pageProps", "data", "profileStories")
      stories.is_a?(Array) ? stories.size : 0
    rescue FetchError, JSON::ParserError
      0
    end

    def manifest_with_safety_net
      items = manifest
      profile_count = profile_story_count
      if profile_count > items.size
        raise FetchError,
              "RSS feed returned #{items.size} articles but profile page shows #{profile_count}. " \
                "Pagination support is not implemented; extend script/hackernoon/fetcher.rb before running."
      end
      items
    end

    # Populate body_html, main_image_url, and authoritative published_at by scraping the article page.
    def hydrate(article)
      html = http_get(article.original_url)
      data = extract_next_data(html)
      payload = data.dig("props", "pageProps", "data") or
        raise FetchError, "No article payload found at #{article.original_url}"

      body_html = payload["parsed"]
      raise FetchError, "No parsed body for #{article.original_url}" if body_html.nil? || body_html.empty?

      published_at = parse_published_at(payload, article.published_at)

      article.body_html = body_html
      article.main_image_url = payload["mainImage"]
      article.excerpt = payload["excerpt"]
      article.published_at = published_at if published_at
      article.tags = (payload["tags"] || article.tags).to_a.map(&:to_s)
      article
    end

    private

    def article_from_rss_item(item)
      link = text(item, "link")
      Article.new(
        title: text(item, "title"),
        slug: slug_from_url(link),
        original_url: link.sub(/\?source=rss\z/, ""),
        published_at: Time.parse(text(item, "pubDate")),
        tags: item.xpath("category").map(&:text),
        body_html: nil,
        main_image_url: nil,
        excerpt: nil,
      )
    end

    def slug_from_url(url)
      uri = URI.parse(url)
      uri.path.split("/").reject(&:empty?).last
    end

    def text(node, name)
      el = node.at_xpath(name)
      el ? el.text.strip : ""
    end

    def extract_next_data(html)
      doc = Nokogiri::HTML(html)
      node = doc.at_css('script#__NEXT_DATA__')
      raise FetchError, "No __NEXT_DATA__ block in HTML" if node.nil?
      JSON.parse(node.content)
    end

    def parse_published_at(payload, fallback)
      ts = payload["publishedAt"]
      return Time.at(ts.to_f).utc if ts.is_a?(Numeric) || (ts.is_a?(String) && ts.match?(/\A\d+(\.\d+)?\z/))

      date = payload["datePublished"]
      return Time.parse("#{date} 00:00:00 UTC") if date.is_a?(String) && date.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      fallback
    end

    def http_get(url)
      throttle!
      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = USER_AGENT
      req["Accept"] = "*/*"

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess
        res.body
      when Net::HTTPRedirection
        http_get(res["location"])
      else
        raise FetchError, "HTTP #{res.code} for #{url}"
      end
    end

    def throttle!
      return if @last_request_at.nil?

      elapsed = Time.now - @last_request_at
      sleep(REQUEST_DELAY - elapsed) if elapsed < REQUEST_DELAY
    ensure
      @last_request_at = Time.now
    end
  end
end
