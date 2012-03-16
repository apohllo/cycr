require "cyc/exception"

module Cyc #:nodoc:
  module Connection #:nodoc:
    # Author:: Rafal Michalski (mailto:royaltm75@gmail.com)
    # Licence:: MIT/X11 License
    #
    # DataBuffer is chunky text data to server answer assembly class.
    #
    # Usage:
    #
    #   b = DataBuffer.new
    #   b << "200 Some response\n" << "300 Some other" << " response\n" << "additional data\n"
    #   b.next_result
    #   => [200, "Some response"]
    #   b.next_result
    #   => [300, "Some other response\nadditional data"]
    #   b.next_result
    #   => nil
    #   b << "Invalid response\n"
    #   b.next_result("meta data")
    #   Cyc::ProtocolError:
    #     Unexpected data from server: "Invalid response", check the submitted query in detail:
    #       "meta data"
    #
    class DataBuffer
      EOL = "\n"
      RESULT_MATCH = /^(\d\d\d) (.*)$/m

      # Initializes an empty buffer.
      def initialize
        @buffer = ""
      end

      # Appends +data+ to the buffer.
      def <<(data)
        @buffer << data
      end

      # Returns the next complete result stored in the buffer.
      def next_result(org_message=nil)
        res_end = 0
        size = @buffer.length
        while res_end = @buffer.index(EOL, res_end)
          res_end += 1
          if res_end == size || RESULT_MATCH === @buffer[res_end..-1]
            result = @buffer.slice!(0, res_end).chomp EOL
            if RESULT_MATCH === result
              return [$1.to_i, $2]
            else
              raise ProtocolError.new("Unexpected data from server: #{result.inspect}, " +
                "check the submitted query in detail:\n#{org_message.inspect}")
            end
          end
        end
      end

      # String representation of the buffer.
      def to_s
        @buffer
      end

      # Clears the buffer contents.
      def discard!
        @buffer.clear
      end
    end
  end
end
