module Peka
  module Services
    class StopListForLine
      attr_accessor :line, :err

      def initialize(line)
        @line = line
      end

      def perform
        res = api_request('getBollardsByLine', name: @line.upcase)
        parsed = parse_response(res)
        if parsed['success'] && parsed['success'].key?('directions')
          @result = parsed['success']['directions']
        else
          @err = "Nie znaleziono linii #{@line}"
          nil
        end
      end

      def to_s
        dirs = @result.map do |line_direction|
          {
            direction: line_direction['direction']['direction'],
            stops: line_direction['bollards'].map { |b| b['name'] }
          }
        end
        dirs.map { |d| "[#{d[:direction]}] #{d[:stops].join(' -- ')}" }.join("\n\n")
      end
    end
  end
end
