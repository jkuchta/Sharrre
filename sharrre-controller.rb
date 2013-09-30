require 'nokogiri'
require 'curb'

def index
  result = {}
  result[:url] = params[:url]

  url = Rack::Utils.escape(params[:url])
  type = Rack::Utils.escape(params[:type])

  if(URI.parse(result[:url]))
    if(type == 'googlePlus')
      content = parse("https://plusone.google.com/u/0/_/+1/fastbutton?url=#{url}&count=true")

      doc = Nokogiri::HTML(content)
      count = doc.xpath("//div[@id='aggregateCount']").first

      if (count != nil)
        if count.content.include? "M"
          count.content = count.content.gsub!(/M/, "")
          count.content = 1000000 * count.content.to_f
        elsif count.content.include? "k"
          count.content = count.content.gsub!(/k/, "")
          count.content = 1000 * count.content.to_f
        end
        result[:count] = count.content
      end
    elsif(type == 'stumbleupon')
      content = parse("http://www.stumbleupon.com/services/1.01/badge.getinfo?url=#{url}")
      json_content = JSON.parse(content)

      if (json_content["result"]["views"] != nil)
        result[:count] = json_content["result"]["views"]
      end
    elsif(type == 'pinterest')
      content = parse("http://api.pinterest.com/v1/urls/count.json?callback=&url=#{url}")
      json_content = JSON.parse(content.gsub!(/[()]/, ""))
      result[:count] = json_content["count"]
    end
  end

  render :json => result
end

def parse(url)
  c = Curl::Easy.new(url) do |curl|
    curl.headers["User-Agent"] = "Share-ruby"
    curl.follow_location = true
    curl.max_redirects = 3
    curl.encoding = ""
    curl.autoreferer = true
    curl.connect_timeout = 5
    curl.timeout = 10
    curl.ssl_verify_host = 0
    curl.ssl_verify_host = false
  end
  c.perform
  c.body_str
end
