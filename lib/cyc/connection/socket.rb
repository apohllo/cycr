require "socket"
require "cyc/connection/driver"
require "cyc/exception"
require "cyc/connection/buffer"

module Cyc #:nodoc:
  module Connection #:nodoc:
    # TCPSocket Cyc::Client driver
    # Author:: Rafal Michalski (mailto:royaltm75@gmail.com)
    # Licence:: MIT/X11 License
    #
    # Default driver for Cyc::Client.
    #
    class SocketDriver
      # The type of the driver, i.e. +:socket+.
      def self.type; :socket; end

      # Initialize a new driver.
      def initialize
        @sock = nil
        @buffer = DataBuffer.new
        @last_message = nil
      end

      # Returns true if the driver is connected to the server.
      def connected?
        !! @sock
      end

      # Connects to the server on +host+ and +port+ with given
      # connection +timeout+.
      def connect(host, port, timeout=0.2)
        with_timeout(timeout.to_f) do
          @sock = TCPSocket.new(host, port)
          @sock.sync = true
          @sock.binmode
          #@sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
        end
      end

      # Disconnects the driver from the server.
      def disconnect
        @sock.close if @sock
      rescue
        # This should go to log #2.
      ensure
        @sock = nil
        @buffer.discard!
      end

      # Send a message to the server.
      def write(rawmsg)
        @last_message = rawmsg
        @sock.write(rawmsg + EOL)
        # ensure that the connection is still with a server
        # and wait for an answer at the same time
        if @sock.eof?
          disconnect
          raise Errno::ECONNRESET
        end
      end

      # Read next message from the server.
      def read
        begin
          @buffer << @sock.readpartial(4096)
        end until result = @buffer.next_result(@last_message)
        result << @last_message
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
