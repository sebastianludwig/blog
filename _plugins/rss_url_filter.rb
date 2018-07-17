# inspired by https://github.com/eincs/jekyll-rss-absolute-urls
module Jekyll
  module RSSURLFilter
    def relative_urls_to_absolute(input)
      config = @context.registers[:site].config
      site_url = config['url'] + config['baseurl']
      input.gsub('src="/', 'src="' + site_url + '/').gsub('href="/', 'href="' + site_url + '/')
    end
  end
end

Liquid::Template.register_filter(Jekyll::RSSURLFilter)
