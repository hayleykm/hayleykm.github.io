#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "open-uri"
require "rss"
require "time"
require "yaml"

ROOT = File.expand_path("..", __dir__)
CONFIG_PATH = File.join(ROOT, "_config.yml")
PUBLICATIONS_PATH = File.join(ROOT, "_data", "publications.yml")

def load_yaml(path)
  YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: true) || {}
end

def medium_feed_url
  ENV["MEDIUM_FEED_URL"].to_s.strip.then do |value|
    return value unless value.empty?
  end

  config = load_yaml(CONFIG_PATH)
  config.fetch("medium_feed_url", "").to_s.strip
end

def medium_post?(post)
  post.is_a?(Hash) && post["outlet"].to_s == "Medium"
end

def extract_image(item)
  content = if item.respond_to?(:content_encoded)
    item.content_encoded.to_s
  elsif item.respond_to?(:description)
    item.description.to_s
  else
    ""
  end

  content[/<img[^>]+src=["']([^"']+)["']/i, 1].to_s
end

def format_date(value)
  return "" unless value

  Time.parse(value.to_s).strftime("%-d %B %Y")
rescue ArgumentError
  ""
end

def fetch_medium_posts(feed_url)
  rss = URI.open(feed_url, &:read)
  parsed = RSS::Parser.parse(rss, false)

  Array(parsed&.items).map do |item|
    {
      "title" => CGI.unescapeHTML(item.title.to_s.strip),
      "outlet" => "Medium",
      "date" => format_date(item.pubDate || item.dc_date),
      "url" => item.link.to_s.strip,
      "image" => extract_image(item)
    }
  end.reject { |post| post["title"].empty? || post["url"].empty? }
end

feed_url = medium_feed_url
if feed_url.empty?
  warn "Skipping Medium sync: set medium_feed_url in _config.yml or MEDIUM_FEED_URL in the environment."
  exit 0
end

publications = load_yaml(PUBLICATIONS_PATH)
existing_blogs = Array(publications["blogs"])
manual_blogs = existing_blogs.reject { |post| medium_post?(post) }
medium_blogs = fetch_medium_posts(feed_url)

publications["blogs"] = medium_blogs + manual_blogs

File.write(PUBLICATIONS_PATH, YAML.dump(publications, line_width: -1))
puts "Synced #{medium_blogs.size} Medium post(s) into #{PUBLICATIONS_PATH}."
