module Peka
  module Utils
    def timestamp
      (Time.now.to_f * 1000).to_i
    end

    def timestamped_uri
      uri = URI('http://www.peka.poznan.pl/vm/method.vm')
      uri.tap { |u| u.query = URI.encode_www_form(ts: timestamp) }
    end

    def api_request(api_method, p0)
      uri = timestamped_uri
      req = Net::HTTP::Post.new(
        uri,
        'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'
      )
      # cholera wie, czemu to nie działa :) jakieś jaja z encodowaniem
      # req.set_form_data(method: api_method, p0: p0.to_json)
      # req.body.gsub! '+', '%20'
      req.body = ("method=#{api_method}&p0=#{p0.to_json}")
      Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end
    end

    def parse_response(res)
      JSON.parse(res.body)
    end

    def match_service_from_args(service_preference)
      if ARGV.count == 3 && (ARGV[0].to_i.to_s == ARGV[0] || %w(t n).include?(ARGV[0][0].downcase))
        NextDeparture
      else
        puts 'Składnia: ruby peka.rb LINIA PRZYSTANEK KIERUNEK'
        exit
      end
    end
  end
end
