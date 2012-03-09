require "cyc/exception"

module Cyc
  module Connection
    class DataBuffer
      EOL = "\n"
      RESULT_MATCH = /^(\d\d\d) (.*)$/m

      def initialize
        @buffer = ""
      end
      
      def <<(data)
        @buffer << data
      end

      def next_result(org_message)
        res_end = 0
        size = @buffer.length
        while res_end = @buffer.index(EOL, res_end)
          res_end+= 1
          if res_end == size || RESULT_MATCH === @buffer[res_end..-1]
            result = @buffer.slice!(0, res_end).chomp EOL
            if RESULT_MATCH === result
              return [$1.to_i, $2]
            else
              raise ProtocolError.new("Unexpected data from server: #{result}, " +
                "check the submitted query in detail:\n#{org_message.inspect}")
            end
          end
        end
      end
      
      def to_s
        @buffer
      end

      def discard!
        @buffer.clear
      end
    end
  end
end
