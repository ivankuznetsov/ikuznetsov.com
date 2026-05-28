#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "pathname"
require "set"

ROOT = Pathname.new(__dir__).parent.expand_path
$LOAD_PATH.unshift(ROOT.join("script").to_s)

require "hackernoon/fetcher"
require "hackernoon/converter"
require "hackernoon/post_writer"

options = {
  user: "ivankuznetsov",
  dry_run: false,
  force: false,
  limit: nil,
  seed_urls: [],
  seed_urls_file: nil,
}

OptionParser.new do |opts|
  opts.banner = "Usage: bundle exec ruby script/import_hackernoon.rb [options]"
  opts.on("--user USER", "HackerNoon username (default: ivankuznetsov)") { |v| options[:user] = v }
  opts.on("--dry-run", "Parse and report without writing files") { options[:dry_run] = true }
  opts.on("--force", "Overwrite existing imported posts") { options[:force] = true }
  opts.on("--limit N", Integer, "Only import the first N articles") { |v| options[:limit] = v }
  opts.on("--seed-urls URLS", Array,
          "Comma-separated HackerNoon article URLs to import (merged with the RSS manifest)") do |v|
    options[:seed_urls] = v
  end
  opts.on("--seed-urls-file PATH",
          "Path to a newline-separated file of HackerNoon article URLs to import") do |v|
    options[:seed_urls_file] = v
  end
  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

seed_urls = options[:seed_urls].dup
if options[:seed_urls_file]
  seed_urls.concat(File.readlines(options[:seed_urls_file]).map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") })
end
seed_urls.uniq!

fetcher = HackerNoon::Fetcher.new(user: options[:user])

puts "Fetching manifest for @#{options[:user]}..."
manifest = fetcher.manifest
puts "RSS feed returned #{manifest.size} article#{manifest.size == 1 ? '' : 's'}."

if seed_urls.any?
  known = manifest.map(&:original_url).to_set
  extra = seed_urls.reject { |u| known.include?(u.sub(/\?source=rss\z/, "")) }
  if extra.any?
    puts "Seeding #{extra.size} additional article#{extra.size == 1 ? '' : 's'} from URL list..."
    extra.each do |url|
      manifest << HackerNoon::Article.new(
        title: nil,
        slug: nil,
        original_url: url.sub(/\?source=rss\z/, ""),
        published_at: nil,
        tags: [],
        body_html: nil,
        main_image_url: nil,
        excerpt: nil,
      )
    end
  end
end

manifest = manifest.first(options[:limit]) if options[:limit]
puts "Importing #{manifest.size} article#{manifest.size == 1 ? '' : 's'}."

# Pre-build the cross-post link map: every imported article URL -> its local Jekyll path.
# Slug/date are derived after hydration, so we provisionally use the URL's slug; the converter
# rewrites href matches by URL, so this resolves correctly even before hydration runs.
local_links = manifest.each_with_object({}) do |article, acc|
  slug = article.slug || article.original_url.split("/").last.sub(/\?.*\z/, "")
  acc[article.original_url] = "/posts/#{slug}/"
end

converter = HackerNoon::Converter.new(images_root: ROOT.join("assets/images/posts"), local_links: local_links)
writer = HackerNoon::PostWriter.new(posts_root: ROOT.join("_posts"), force: options[:force])

stats = { written: 0, overwritten: 0, skipped: 0, errors: 0, images: 0 }

manifest.each_with_index do |article, idx|
  puts "\n[#{idx + 1}/#{manifest.size}] #{article.title}"
  puts "  URL:  #{article.original_url}"

  begin
    fetcher.hydrate(article)
  rescue HackerNoon::FetchError => e
    puts "  ! fetch failed: #{e.message}"
    stats[:errors] += 1
    next
  end

  puts "  Date: #{article.published_at.utc.strftime('%Y-%m-%d')}"
  puts "  Tags: #{article.tags.join(', ')}"

  result = converter.convert(article)
  stats[:images] += result.downloaded_images.size
  puts "  Body: #{result.markdown.size} chars, images downloaded: #{result.downloaded_images.size}, broken: #{result.broken_images.size}"
  result.broken_images.each { |u| puts "    broken: #{u}" }

  if options[:dry_run]
    puts "  (dry-run, no file written)"
    next
  end

  outcome = writer.write(article, result.markdown)
  case outcome.status
  when :written     then puts "  → wrote #{outcome.path.relative_path_from(ROOT)}";     stats[:written]     += 1
  when :overwritten then puts "  → overwrote #{outcome.path.relative_path_from(ROOT)}"; stats[:overwritten] += 1
  when :skipped     then puts "  → skipped (#{outcome.reason})";                        stats[:skipped]     += 1
  when :error       then puts "  ! error: #{outcome.reason}";                           stats[:errors]      += 1
  end
end

puts
puts "Summary"
puts "  written:     #{stats[:written]}"
puts "  overwritten: #{stats[:overwritten]}"
puts "  skipped:     #{stats[:skipped]}"
puts "  errors:      #{stats[:errors]}"
puts "  images:      #{stats[:images]}"
exit(stats[:errors].positive? ? 1 : 0)
