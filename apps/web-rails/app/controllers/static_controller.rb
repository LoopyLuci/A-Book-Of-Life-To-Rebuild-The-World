# frozen_string_literal: true

# The files a search engine reads: the robots file and the sitemap.
class StaticController < ApplicationController
  # The robots file.
  def robots
    render plain: <<~TEXT
      User-agent: *
      Allow: /

      Sitemap: #{request.base_url}/sitemap.xml
    TEXT
  end

  # The sitemap of every domain and every entry.
  def sitemap
    body = +%(<?xml version="1.0" encoding="UTF-8"?>\n)
    body << %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n)
    body << url_entry(request.base_url, 1.0)
    corpus.domains.each { |domain| body << url_entry("#{request.base_url}#{domain_path(domain.slug)}", 0.8) }
    corpus.entries.each { |entry| body << url_entry("#{request.base_url}#{entry_path(entry.domain, entry.slug)}", 0.6) }
    body << "</urlset>\n"

    render body: body, content_type: "application/xml"
  end

  private

  def url_entry(location, priority)
    <<~XML
      <url>
        <loc>#{ERB::Util.html_escape(location)}</loc>
        <changefreq>monthly</changefreq>
        <priority>#{priority}</priority>
      </url>
    XML
  end
end
