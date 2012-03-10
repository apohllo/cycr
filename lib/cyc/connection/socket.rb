require "socket"
require "cyc/connection/driver"
require "cyc/exception"
require "cyc/connection/buffer"
# TCPSocket Cyc::Client driver
# Author:: Rafal Michalski (mailto:royaltm75@gmail.com)
# Licence:: MIT/X11 License
#
# Default driver for Cyc::Client.
#
module Cyc
  module Connection
    class SocketDriver
      def self.type; :socket; end
      def initialize
        @sock = nil
        @buffer = DataBuffer.new
        @meta = nil
      end

      def connected?
        !! @sock
      end

      def connect(host, port, conn_timeout=0.2)
        with_timeout(conn_timeout.to_f) do
          @sock = TCPSocket.new(host, port)
          @sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
        end
      end

      def disconnect
        @sock.close if @sock
      rescue
      ensure
        @sock = nil
        @buffer.discard!
      end

      def timeout=(seconds)
        usecs   = (seconds.to_f * 1_000_000 % 1_000_000).to_i
        seconds = seconds.to_i

        optval = [seconds, usecs].pack("l_2")

        begin
          @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
          @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
        rescue Errno::ENOPROTOOPT
        end
      end

      def write(rawmsg)
        @meta = rawmsg
        @sock.write(rawmsg + EOL)
      end

      def read
        begin
          data = @sock.readpartial(4096)

          raise Errno::ECONNRESET unless data

          @buffer << data
        rescue IOError, EOFError
          raise Errno::ECONNRESET
        end until result = @buffer.next_result(@meta)
        result << @meta
      rescue Errno::ECONNRESET
        disconnect
        raise
      end

    protected

      # borrowed from redis-rb
      begin
        require "system_timer"

        def with_timeout(seconds, &block)
          SystemTimer.timeout_after(seconds, &block)
        end

      rescue LoadError
        if ! defined?(RUBY_ENGINE)
          # MRI 1.8, all other interpreters define RUBY_ENGINE, JRuby and
          # Rubinius should have no issues with timeout.
          warn "WARNING: using the built-in Timeout class which is known to have issues when used for opening connections. Install the SystemTimer gem if you want to make sure the Redis client will not hang."
        end

        require "timeout"

        def with_timeout(seconds, &block)
          Timeout.timeout(seconds, &block)
        end
      end
    end
  end
end

Cyc::Connection.driver = Cyc::Connection::SocketDriver
