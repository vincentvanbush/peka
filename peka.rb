require 'json'
require 'net/http'
require 'date'

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

from = ARGV[1]
to = ARGV[2]
line = ARGV[0]

if ARGV.count < 3 || ARGV[0].to_i.to_s != ARGV[0]
  puts 'Składnia: ruby peka.rb LINIA PRZYSTANEK KIERUNEK'
  exit
end

# Get stop point by name pattern
res = api_request('getStopPoints', pattern: from)

parsed = parse_response(res)
if parsed['success'].empty?
  puts 'Nie znaleziono grupy przystanków'
  exit
end
exact_match = parsed['success'].find do |m|
  m['name'].downcase == from.downcase
end
stop_name = exact_match ? exact_match['name'] : parsed['success'][0]['name']

# Get bollards by stop point name
res = api_request('getBollardsByStopPoint', name: stop_name)

parsed = parse_response(res)
if parsed['success']['bollards'].nil?
  puts "Nie znaleziono przystanków w grupie '#{stop_name}'"
  exit
end
bollards = parsed['success']['bollards']

bollards.select! do |b|
  b['directions'].any? do |dir|
    dir['lineName'].to_i == line.to_i && dir['direction'].downcase.match(to.downcase)
  end
end
if bollards.empty?
  puts "Nie znaleziono przystanków linii #{line} w kierunku #{to}"
  exit
end

# Get selected line
d = bollards[0]['directions'].find do |dir|
  dir['lineName'].to_i == line.to_i && dir['direction'].downcase.match(to.downcase)
end
dir_name = d['direction']

# puts bollards[0]['bollard']
stop_symbol = bollards[0]['bollard']['tag']
res = api_request('getTimes', symbol: stop_symbol)

parsed = parse_response(res)
# puts parsed['success']['times']
departure = parsed['success']['times'].find { |t| t['line'].to_i == line.to_i && t['direction'].downcase.match(to.downcase) }
if departure.nil?
  puts "Nie znaleziono odjazdów"
  exit
end
puts "#{line} #{stop_name} -> #{dir_name} odjeżdża za #{departure['minutes']} minut"
