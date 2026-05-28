# frozen_string_literal: true

require "fileutils"
require "pathname"
require "yaml"

module HackerNoon
  class PostWriter
    Outcome = Struct.new(:status, :path, :reason, keyword_init: true)

    def initialize(posts_root:, force: false, logger: $stdout)
      @posts_root = Pathname.new(posts_root)
      @force = force
      @logger = logger
    end

    def write(article, markdown)
      target = target_path(article)

      if target.exist? && !@force
        return Outcome.new(status: :skipped, path: target, reason: "already exists")
      end

      collision = filename_collision(target, article)
      return Outcome.new(status: :error, path: target, reason: collision) if collision

      FileUtils.mkdir_p(target.dirname)
      File.write(target, render(article, markdown))
      Outcome.new(status: (@force ? :overwritten : :written), path: target, reason: nil)
    end

    private

    def target_path(article)
      date = article.published_at.utc.strftime("%Y-%m-%d")
      @posts_root.join("#{date}-#{article.slug}.md")
    end

    def filename_collision(target, article)
      return nil unless target.exist?
      return nil if @force

      existing = File.read(target)
      return "already imported (matched front-matter source: hackernoon)" if existing.include?("source: hackernoon")

      "filename #{target.basename} collides with a non-imported post; rename it or pass --force"
    end

    def render(article, markdown)
      front_matter = {
        "layout" => "post",
        "title" => article.title.to_s,
        "date" => article.published_at.utc.strftime("%Y-%m-%d %H:%M:%S +0000"),
        "categories" => article.tags.to_a.map(&:to_s).map(&:downcase),
        "original_url" => article.original_url,
        "canonical_url" => article.original_url,
        "source" => "hackernoon",
      }
      front_matter["excerpt"] = article.excerpt.to_s if article.excerpt && !article.excerpt.empty?

      yaml = YAML.dump(front_matter, line_width: -1).sub(/\A---\n/, "")
      "---\n#{yaml}---\n\n#{markdown.strip}\n"
    end
  end
end
