require 'json'
require 'net/http'
require 'date'

require_relative 'lib/peka'
include Peka::Utils
include Peka::Services

service_preference = [NextDeparture] # moar plz
service_class = match_service_from_args(service_preference)

# line, from, to = ARGV
service = service_class.new(*ARGV)
if service.perform
  puts service.to_s
else
  puts service.err
end
