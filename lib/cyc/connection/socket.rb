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
          @sock.sync = true
          @sock.binmode
          #@sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
        end
      end

      def disconnect
        @sock.close if @sock
      rescue
      ensure
        @sock = nil
        @buffer.discard!
      end

      def write(rawmsg)
        @meta = rawmsg
        @sock.write(rawmsg + EOL)
        # ensure that the connection is still with a server
        # and wait for an answer at the same time
        if @sock.eof?
          disconnect
          raise Errno::ECONNRESET
        end
      end

      def read
        begin
          @buffer << @sock.readpartial(4096)
        end until result = @buffer.next_result(@meta)
        result << @meta
      rescue IOError, EOFError, Errno::ECONNRESET
        disconnect
        raise Errno::ECONNRESET
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
