#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "open-uri"
require "rss"
require "time"
require "uri"
require "yaml"

ROOT = File.expand_path("..", __dir__)
CONFIG_PATH = File.join(ROOT, "_config.yml")
PUBLICATIONS_PATH = File.join(ROOT, "_data", "publications.yml")
BLOG_IMAGE_DIR = File.join(ROOT, "assets", "img", "blogs")

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

def normalize_url(value)
  return "" if value.to_s.strip.empty?

  uri = URI.parse(value.to_s.strip)
  uri.query = nil
  uri.fragment = nil
  uri.to_s
rescue URI::InvalidURIError
  value.to_s.strip
end

def unusable_medium_image?(value)
  value.to_s.include?("medium.com/_/stat")
end

def slugify(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
end

def extract_image(item)
  content = if item.respond_to?(:content_encoded)
    item.content_encoded.to_s
  elsif item.respond_to?(:description)
    item.description.to_s
  else
    ""
  end

  matches = content.scan(/<img[^>]+src=["']([^"']+)["']/i).flatten
  matches.find { |src| !unusable_medium_image?(src) }.to_s
end

def local_blog_tile(title)
  candidate = "#{slugify(title)}-tile.png"
  path = File.join(BLOG_IMAGE_DIR, candidate)
  return "" unless File.exist?(path)

  "/assets/img/blogs/#{candidate}"
end

def preferred_image(new_image, existing_image, title)
  return new_image.to_s if !new_image.to_s.strip.empty? && !unusable_medium_image?(new_image)

  existing = existing_image.to_s
  return existing unless existing.empty? || unusable_medium_image?(existing)

  local_blog_tile(title)
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
existing_medium_blogs = existing_blogs.select { |post| medium_post?(post) }
existing_medium_by_url = existing_medium_blogs.each_with_object({}) do |post, memo|
  memo[normalize_url(post["url"])] = post
end
manual_blogs = existing_blogs.reject { |post| medium_post?(post) }
medium_blogs = fetch_medium_posts(feed_url)

medium_blogs.each do |post|
  existing_post = existing_medium_by_url[normalize_url(post["url"])]
  next unless existing_post

  post["image"] = preferred_image(post["image"], existing_post["image"], post["title"])
end

medium_blogs.each do |post|
  next unless post["image"].to_s.strip.empty? || unusable_medium_image?(post["image"])

  post["image"] = preferred_image(post["image"], "", post["title"])
end

publications["blogs"] = medium_blogs + manual_blogs

File.write(PUBLICATIONS_PATH, YAML.dump(publications, line_width: -1))
puts "Synced #{medium_blogs.size} Medium post(s) into #{PUBLICATIONS_PATH}."
