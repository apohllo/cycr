require 'uri'
require 'cyc/connection'
require 'cyc/exception'

module Cyc
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT/X11 License
  #
  # This class is the implementation of the Cyc server client.
  class Client
    # If set to true, all communication with the server is logged
    # to standard output
    attr_accessor :debug
    attr_reader :host, :port, :driver, :thread_safe
    alias_method :thread_safe?, :thread_safe

    # Creates new Client.
    # Usage:
    #   Cyc::Client.new
    #   Cyc::Client.new 'cyc.example', 3661, true
    #   Cyc::Client.new :debug => true, :url => 'cyc://localhost/3661',
    #     :conn_timeout => 0.1, :driver => Cyc::Connection::SynchronyDriver
    #
    # Thread safe client:
    #   Cyc::Client.new :thread_safe => true
    def initialize(host="localhost", port=3601, options=false)
      @pid = Process.pid
      @conn_timeout = 0.2
      @driver = Connection.driver
      if Hash === host
        options, host = host, nil
      elsif Hash === port
        options, port = port, nil
      end
      if Hash === options
        if url = options[:url]
          url = URI.parse(url)
          host = url.host || host
          port = url.port || port
        end
        @conn_timeout = options[:conn_timeout].to_f if options.key? :conn_timeout
        @driver = options[:driver] if options.key? :driver
        @debug = !!options[:debug]
        @thread_safe = !!options[:thread_safe]
      else
        @debug = !!options
        @thread_safe = false
      end
      @host = host || "localhost"
      @port = (port || 3601).to_i

      if @thread_safe
        self.extend ThreadSafeClientExtension
      else
        @conn = nil
      end
    end

    def connected?
      (conn=self.conn) && conn.connected? && @pid == Process.pid
    end

    # (Re)connects to the cyc server.
    def reconnect
      self.conn.disconnect if connected?
      @pid = Process.pid
      conn = @driver.new
      puts "connecting: #@host:#@port $$#@pid" if @debug
      conn.connect(@host, @port, @conn_timeout)
      # instance variable should be initialized only
      # after successfull connection attempt
      self.conn = conn
      self
    end

    # Usually the connection will be established on first use
    # however connect() allows to force early connection:
    #   Cyc::Client.new().connect
    # Usefull in fiber concurrent environment to setup connection early.
    # Should not be called twice
    # (however no big harm is done except for garbage collection)
    alias_method :connect, :reconnect
    # Returns the connection object. Ensures that the pid of current
    # process is the same as the pid, the connection was initialized with.
    #
    # If the block is given, the command is guarded by assertion, that
    # it will be performed, even if the connection was reset.
    def connection
      reconnect unless connected?
      if block_given?
        begin
          yield conn
        rescue Errno::ECONNRESET
          reconnect
          yield conn
        end
      else
        conn
      end
    end

    protected :connection, :reconnect

    # Closes connection with the server
    def close
      connection{|c| c.write("(api-quit)")}
      self.conn = nil
    end

    # Sends message +msg+ to the Cyc server and returns a parsed answer.
    def talk(msg, options={})
      send_message(msg)
      receive_answer(options)
    end

    # Sends message +msg+ to the Cyc server and
    # returns the raw answer (i.e. not parsed).
    def raw_talk(msg, options={})
      send_message(msg)
      receive_raw_answer(options)
    end

    # Scans the :message: to find out if the parenthesis are matched.
    # Raises UnbalancedClosingParenthesis exception if there is not matched closing
    # parenthesis. The message of the exception contains the string with the
    # unmatched parenthesis highlighted.
    # Raises UnbalancedOpeningParenthesis exception if there is not matched opening
    # parenthesis.
    def check_parenthesis(message)
      count = 0
      message.scan(/[()]/) do |char|
        count += (char == "(" ?  1 : -1)
        if count < 0
          position = $~.offset(0)[0]
          raise UnbalancedClosingParenthesis.
            new((position > 1 ? message[0...position] : "") +
              "<error>)</error>" + message[position+1..-1])
        end
      end
      raise UnbalancedOpeningParenthesis.new(count) if count > 0
    end

    # Sends a raw message to the Cyc server. The user is
    # responsible for receiving the answer by calling
    # +receive_answer+ or +receive_raw_answer+.
    def send_message(message)
      check_parenthesis(message)
      puts "Send: #{message}" if @debug
      connection{|c| c.write(message)}
    end

    # Receives and parses an answer for a message from the Cyc server.
    def receive_answer(options={})
      receive_raw_answer do |answer, last_message|
        begin
          result = Parser.new.parse answer, options[:stack]
        rescue ContinueParsing => ex
          current_result = result = ex.stack
          while current_result.size == 100 do
            send_message("(subseq #{last_message} #{result.size} " +
                         "#{result.size + 100})")
            current_result = receive_answer(options) || []
            result.concat(current_result)
          end
        # rescue CycError => ex
        # is this really necessary?
        # shouldn't this be rescued in upper scope instead?
          # puts ex.to_s
          # return nil
        end
        return result
      end
    end

    # Receives raw answer from server. If a +block+ is given
    # the answer is yield to the block, otherwise the answer is returned.
    def receive_raw_answer(options={})
      status, answer, last_message = connection{|c| c.read}
      puts "Recv: #{last_message} -> #{status} #{answer}" if @debug
      if status == 200
        if block_given?
          yield answer, last_message
        else
          return answer
        end
      else
        raise CycError.new(answer.sub(/^"/,"").sub(/"$/,"") + "\n" + last_message)
      end
    end

    # This hook allows for direct call on the Client class, that
    # are translated into corresponding calls for Cyc server.
    #
    # E.g. if users initializes the client and calls some Ruby method
    #   cyc = Cyc::Client.new
    #   cyc.genls? :Dog, :Animal
    #
    # He/She returns a parsed answer from the server:
    #   => "T"
    #
    # Since dashes are not allowed in Ruby method names they are replaced
    # with underscores:
    #
    #   cyc.min_genls :Dog
    #
    # is translated into:
    #
    #   (min-genls #$Dog)
    #
    # As you see the Ruby symbols are translated into Cyc terms (not Cyc symbols!).
    #
    # It is also possible to nest the calls to build more complex functions:
    #
    #   cyc.with_any_mt do |cyc|
    #     cyc.min_genls :Dog
    #   end
    #
    # is translated into:
    #
    #   (with-any-mt (min-genls #$Dog))
    #
    def method_missing(name,*args,&block)
      builder = Builder.new
      builder.send(name,*args,&block)
      talk(builder.to_cyc)
    end
    protected
    attr_accessor :conn
  end

  module ThreadSafeClientExtension
    THR_VAR_TEMLPATE='_cyc_client_$%s_%s'

    def self.extend_object(obj)
      obj.instance_variable_set "@thrconn", (THR_VAR_TEMLPATE%[obj.object_id, 'conn']).intern
      super
    end

    protected
    def conn; Thread.current[@thrconn]; end
    def conn=(conn); Thread.current[@thrconn] = conn; end
  end
end
