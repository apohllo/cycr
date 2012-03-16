require "em-synchrony"
require "cyc/connection/driver"
require "cyc/exception"
require "cyc/connection/buffer"
module Cyc #:nodoc:
  module Connection #:nodoc:
    class ConnectionClient < EventMachine::Connection
      include EventMachine::Deferrable

      def post_init
        @req = []
        @connected = false
        @buffer = DataBuffer.new
      end

      def connection_completed
        @connected = true
        succeed
      end

      def connected?
        @connected
      end

      def receive_data(data)
        @buffer << data

        begin
          while (result = @buffer.next_result(@req.first))
            unless @req.empty?
              msg, req = @req.shift(2)
              req.succeed(result << msg)
            end
          end
        rescue RuntimeError => err
          @req.each_slice(2) {|_, r| r.fail [:error, err]}
          @req.clear
          close_connection
        end
      end

      def read
        EventMachine::Synchrony.sync @req.last unless @req.empty?
      end

      def send(data)
        @req << data << EventMachine::DefaultDeferrable.new
        callback { send_data data + EOL }
        @req.last
      end

      def unbind
        @connected = false
        @buffer.discard!
        unless @req.empty?
          @req.each_slice(2) {|_, r| r.fail [:error, Errno::ECONNRESET]}
          @req.clear
        end
        fail
      end
    end

    # EM-Synchrony Cyc::Client driver
    # Author:: Rafal Michalski (mailto:royaltm75@gmail.com)
    # Licence:: MIT/X11 License
    #
    # Requires: igrigorik/em-synchrony
    #
    # To use this driver simply require this file
    # e.g. require 'cyc/connection/synchrony' beside 'cycr'
    #
    # if required before 'cycr' then the SocketDriver will not be loaded
    #   (however you can still load it by hand: require 'cyc/connection/socket'
    #    but be carefull though it will override default Cyc::Connection.driver)
    #
    # if required after 'cycr' then the SocketDriver will be preserved but
    #   the default driver will be set to SynchronyDriver
    #
    # Async fiber example:
    #
    # require 'cyc/connection/synchrony'
    # require 'cycr'
    # EM.synchrony do
    #   cyc = EM::Synchrony::ConnectionPool.new(size: 5) do
    #     Cyc::Client.new :url => 'cyc://localhost:3601', :debug => true
    #   end
    #   puts cyc.driver, cyc.driver.type.inspect
    #   Fiber.new do
    #     puts "Ani", cyc.fi_complete("Ani").inspect
    #   end.resume
    #   puts "Mi", cyc.talk('(fi-complete "Mi")').inspect
    #   EM.stop
    # end
    #
    # `Mi` will arrive before `Ani`
    #
    # Warning: always use EM::Synchrony::ConnectionPool to handle Fiber
    #          concurrency race conditions.
    class SynchronyDriver
      # The type of the driver, i.e. +:synchrony+.
      def self.type; :synchrony; end

      # Initialize a new driver.
      def initialize
        @connection = nil
      end

      # Returns true if the driver is connected to the server.
      def connected?
        @connection && @connection.connected?
      end

      # Connects to the server on +host+ and +port+ with given
      # connection time-out.
      def connect(host, port, timeout)
        conn = EventMachine.connect(host, port, ConnectionClient) do |c|
          c.pending_connect_timeout = [Float(timeout), 0.1].max
        end

        setup_connect_callbacks(conn, Fiber.current)
      end

      # Disconnects the driver from the server.
      def disconnect
        @connection.close_connection
        @connection = nil
      end

      # Send a message to the server.
      def write(rawmsg)
        @connection.send(rawmsg)
      end

      # Read next message from the server.
      def read
        status, answer, msg = @connection.read
        if status == :error
          raise answer
        else
          return [status, answer, msg]
        end
      end

    private

      def setup_connect_callbacks(conn, f)
        conn.callback do
          @connection = conn
          f.resume conn
        end

        conn.errback do
          @connection = conn
          f.resume :refused
        end

        r = Fiber.yield
        raise Errno::ECONNREFUSED if r == :refused
        r
      end
    end
  end
end

Cyc::Connection.driver = Cyc::Connection::SynchronyDriver
