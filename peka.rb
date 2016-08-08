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
  Net::HTTP.post_form(timestamped_uri, method: api_method, p0: p0.to_json)
end

from = ARGV[1] # 'wilsona'
to = ARGV[2] # 'wilczak'
line = ARGV[0] # 14

if ARGV.count < 3 || ARGV[0].to_i.to_s != ARGV[0]
  puts 'Składnia: ruby peka.rb LINIA PRZYSTANEK KIERUNEK'
  exit
end

# Get stop point by name pattern
res = api_request('getStopPoints', pattern: from)

parsed = JSON.parse(res.body)
if parsed['success'].empty?
  puts 'Nie znaleziono grupy przystanków'
  exit
end
stop_name = parsed['success'][0]['name']
puts stop_name
# Get bollards by stop point name
res = api_request('getBollardsByStopPoint', name: stop_name)

parsed = JSON.parse(res.body)
if parsed['success']['bollards'].nil?
  puts "Nie znalziono przystanków w grupie '#{stop_name}'"
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
puts dir_name

# puts bollards[0]['bollard']
stop_symbol = bollards[0]['bollard']['tag']
res = api_request('getTimes', symbol: stop_symbol)

parsed = JSON.parse(res.body)
# puts parsed['success']['times']
departure = parsed['success']['times'].find { |t| t['line'].to_i == line.to_i && t['direction'].downcase.match(to.downcase) }
if departure.nil?
  puts "Nie znaleziono odjazdów"
  exit
end
puts "#{line} #{stop_name} -> #{dir_name} odjeżdża za #{departure['minutes']} minut"