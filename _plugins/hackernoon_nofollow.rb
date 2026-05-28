# frozen_string_literal: true

# Adds rel="nofollow noopener" to every <a> pointing at hackernoon.com.
# Runs on rendered HTML of posts, pages, and documents so it covers both
# imported article bodies and template-emitted links (e.g. the
# "Originally posted on HackerNoon" footer).

module HackernoonNofollow
  ANCHOR_PATTERN = %r{<a\b([^>]*?)\bhref\s*=\s*(['"])(https?://(?:[a-zA-Z0-9-]+\.)?hackernoon\.com[^'"]*)\2([^>]*)>}i

  module_function

  def apply(html)
    return html unless html.is_a?(String) && html.include?("hackernoon.com")

    html.gsub(ANCHOR_PATTERN) do
      pre_href = Regexp.last_match(1).to_s
      quote = Regexp.last_match(2)
      href = Regexp.last_match(3)
      post_href = Regexp.last_match(4).to_s
      attrs = "#{pre_href} href=#{quote}#{href}#{quote}#{post_href}"

      rel_match = attrs.match(/\brel\s*=\s*(['"])([^'"]*)\1/i)
      if rel_match
        tokens = rel_match[2].split(/\s+/)
        tokens << "nofollow"   unless tokens.include?("nofollow")
        tokens << "noopener"   unless tokens.include?("noopener")
        new_rel = "rel=#{rel_match[1]}#{tokens.join(' ')}#{rel_match[1]}"
        attrs = attrs.sub(rel_match[0], new_rel)
      else
        attrs = "#{attrs.rstrip} rel=\"nofollow noopener\""
      end

      "<a#{attrs.start_with?(' ') ? '' : ' '}#{attrs}>"
    end
  end
end

Jekyll::Hooks.register %i[posts pages documents], :post_render do |item|
  item.output = HackernoonNofollow.apply(item.output) if item.output
end
