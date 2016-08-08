module Peka
  module Services
    class NextDeparture
      attr_reader :line, :stop_name, :dir_name, :mins_left, :departure, :err

      def initialize(line, from, to)
        @line, @from, @to = line, from, to
      end

      def perform
        find_stop
        find_matching_bollards
        find_departure
      rescue StandardError => e
        @err = e.to_s
        nil
      end

      private

      def find_stop
        # Get stop point by name pattern
        res = api_request('getStopPoints', pattern: @from)

        parsed = parse_response(res)
        if parsed['success'].empty?
          fail 'Nie znaleziono grupy przystanków'
        end
        exact_match = parsed['success'].find do |m|
          m['name'].downcase == @from.downcase
        end
        @stop_name = exact_match ? exact_match['name'] : parsed['success'][0]['name']
      end

      def find_matching_bollards
        # Get bollards by stop point name
        res = api_request('getBollardsByStopPoint', name: @stop_name)

        parsed = parse_response(res)
        if parsed['success']['bollards'].nil?
          fail "Nie znaleziono przystanków w grupie '#{stop_name}'"
        end
        @bollards = parsed['success']['bollards']

        @bollards.select! do |b|
          b['directions'].any? do |dir|
            dir['lineName'].to_i == @line.to_i && dir['direction'].downcase.match(@to.downcase)
          end
        end
        if @bollards.empty?
          fail "Nie znaleziono przystanków linii #{@line} z #{stop_name} w kierunku #{@to}"
        end
      end

      def find_departure
        # Get selected line
        d = @bollards[0]['directions'].find do |dir|
          dir['lineName'].to_i == @line.to_i && dir['direction'].downcase.match(@to.downcase)
        end
        @dir_name = d['direction']

        @stop_symbol = @bollards[0]['bollard']['tag']
        res = api_request('getTimes', symbol: @stop_symbol)

        parsed = parse_response(res)
        departure = parsed['success']['times'].find { |t| t['line'].to_s.downcase == @line.to_s.downcase && t['direction'].downcase.match(@to.downcase) }
        if departure.nil?
          fail "Nie znaleziono odjazdów"
        end
        @mins_left = departure['minutes']
        @departure = departure
      end
    end
  end
end
