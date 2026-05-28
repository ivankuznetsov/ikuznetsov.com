# frozen_string_literal: true

require "digest"
require "fileutils"
require "net/http"
require "nokogiri"
require "pathname"
require "reverse_markdown"
require "uri"

module HackerNoon
  class Converter
    Result = Struct.new(:markdown, :downloaded_images, :broken_images, keyword_init: true)

    USER_AGENT = "ikuznetsov.com-hackernoon-import/1.0 (+https://ikuznetsov.com)"

    # @param local_links [Hash{String => String}] maps a HackerNoon article URL to its local path,
    #   e.g. "https://hackernoon.com/foo" -> "/posts/foo/". Used to rewrite cross-post links so
    #   imported articles point at each other on ikuznetsov.com instead of bouncing readers back
    #   to HackerNoon.
    def initialize(images_root:, local_links: {}, logger: $stdout)
      @images_root = Pathname.new(images_root)
      @local_links = local_links
      @logger = logger
    end

    def convert(article)
      doc = Nokogiri::HTML.fragment(article.body_html)
      downloaded = []
      broken = []
      rewritten_links = 0

      doc.css("underline").each { |n| n.name = "em" }

      doc.css("img").each do |img|
        src = img["src"]
        next if src.nil? || src.empty?

        local_path = mirror_image(src, article.slug)
        if local_path
          downloaded << local_path
          img["src"] = local_path.to_s
        else
          broken << src
        end
      end

      doc.css('a[href*="hackernoon.com/embed/"]').each do |a|
        replacement = Nokogiri::XML::Text.new("[#{a.text.empty? ? a['href'] : a.text}](#{a['href']})", doc)
        a.replace(replacement)
      end

      doc.css("a[href]").each do |a|
        local = local_path_for(a["href"])
        next unless local

        a["href"] = local
        rewritten_links += 1
      end

      # reverse_markdown mangles non-trivial tables (blank lines inside cells break GFM table
      # parsing). Substitute each <table> with a placeholder and re-inject the original HTML
      # after Markdown conversion -- kramdown renders raw HTML blocks unchanged.
      table_placeholders = {}
      doc.css("table").each_with_index do |table, idx|
        placeholder = "<!--HN_TABLE_#{idx}-->"
        table_placeholders[placeholder] = table.to_html(save_with: Nokogiri::XML::Node::SaveOptions::AS_HTML)
        table.replace(Nokogiri::XML::Text.new(placeholder, doc))
      end

      markdown = ReverseMarkdown.convert(
        doc.to_html,
        unknown_tags: :bypass,
        github_flavored: true,
        tag_border: "",
      )

      markdown = tidy(markdown)
      table_placeholders.each { |placeholder, html| markdown.sub!(placeholder, "\n\n#{html}\n\n") }
      markdown.gsub!(/\n{3,}/, "\n\n")

      Result.new(
        markdown: markdown.strip + "\n",
        downloaded_images: downloaded,
        broken_images: broken,
      ).tap { @logger.puts "  cross-post links rewritten: #{rewritten_links}" if rewritten_links.positive? }
    end

    private

    def local_path_for(href)
      return nil if href.nil? || href.empty?

      normalized = href.sub(/\?source=rss\z/, "").sub(/#.*\z/, "")
      @local_links[normalized]
    end

    def mirror_image(src, slug)
      uri = URI.parse(src)
      return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      ext = File.extname(uri.path.to_s)
      ext = ".png" if ext.nil? || ext.empty? || ext.length > 5
      basename = File.basename(uri.path, ext)
      digest = Digest::SHA1.hexdigest(src)[0, 8]
      filename = [basename.gsub(/[^a-zA-Z0-9_-]/, "_"), digest].reject(&:empty?).join("-") + ext

      dest_dir = @images_root.join(slug)
      dest_path = dest_dir.join(filename)
      relative = "/" + Pathname.new("assets/images/posts/#{slug}/#{filename}").to_s

      if dest_path.exist?
        return relative
      end

      bytes = http_get(src)
      return nil if bytes.nil?

      FileUtils.mkdir_p(dest_dir)
      tmp_path = dest_path.sub_ext(dest_path.extname + ".part")
      File.binwrite(tmp_path, bytes)
      FileUtils.mv(tmp_path, dest_path)
      relative
    rescue StandardError => e
      @logger.puts "  ! image download failed for #{src}: #{e.message}"
      nil
    end

    def http_get(url, redirects_remaining = 5)
      raise "too many redirects" if redirects_remaining < 0

      uri = URI.parse(url)
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = USER_AGENT

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess then res.body
      when Net::HTTPRedirection then http_get(res["location"], redirects_remaining - 1)
      else
        @logger.puts "  ! HTTP #{res.code} for #{url}"
        nil
      end
    end

    def tidy(markdown)
      out = markdown.dup
      out.gsub!(" ", " ")
      out.gsub!("&nbsp;", " ")
      out.gsub!(/[ \t]+$/m, "")
      out.gsub!(/\n{3,}/, "\n\n")
      out.strip + "\n"
    end
  end
end
