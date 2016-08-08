require 'json'
require 'net/http'
require 'date'

require_relative 'lib/peka'
include Peka::Utils
include Peka::Services

sanitize_args

line, from, to = ARGV
service = NextDeparture.new(line, from, to)
if service.perform
  puts "#{service.line} #{service.stop_name} -> #{service.dir_name} odjeżdża za #{service.mins_left} minut"
else
  puts service.err
end
