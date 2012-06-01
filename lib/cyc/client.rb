require 'uri'
require 'cyc/connection'
require 'cyc/exception'
require 'cyc/cache'

module Cyc #:nodoc:
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT/X11 License
  #
  # This class is the implementation of a Cyc client.
  #
  # Example:
  #
  #   cyc = Cyc::Client.new
  #   cyc.genls? :Dog, :Animal # checks if Dog generalizes to Animal
  #   #=> true
  #   cyc.genls? :Animal, :Dog # checks if Animal generalizes to Dog
  #   #=> nil
  class Client
    # If set to true, all communication with the server is logged
    # to standard output
    attr_accessor :debug
    #
    # If set to true, results of the queries are cached. This is
    # turned off by default, since there is a functional-languages
    # assumption, that the result for the same query is always the
    # same, but this might not be true in case of Cyc (however
    # highly probable). The cache is used only in the +talk+ call
    # (and calls based on it -- i.e. direct Cyc calls, e.g. cyc.genls :Dog).
    attr_accessor :cache_enabled

    # The +host+ the client connects to.
    attr_reader :host

    # The +port+ the client connects to.
    attr_reader :port

    # The +driver+ the client uses to connect to the server.
    attr_reader :driver

    # +true+ if the client is thread safe.
    attr_reader :thread_safe
    alias_method :thread_safe?, :thread_safe

    # The +connection+ object - direct usage is discouraged.
    # Use connection() call instead.
    attr_accessor :conn
    protected :conn

    # Creates new Client.
    # Usage:
    #   Cyc::Client.new [options = {}]
    #
    # options:
    # - +:host+ = +localhost+   server address
    # - +:port+ = +3601+        server port
    # - +:debug+ = +false+      initial debug flag
    # - +:cache+ = +false+      initial cache enabled flag
    # - +:timeout+ = +0.2+      connection timeout in seconds
    # - +:url+ (String):        +cyc://host:port+ overrides +:host+, +:port+
    # - +:driver+ (Class) = Cyc::Connection::Socket  client connection driver class
    # - +:thread_safe+ = +true+   set to +true+ if you want to share client between
    #   threads
    #
    # Example:
    #   Cyc::Client.new
    #   Cyc::Client.new :host => 'cyc.example', :port => 3661, :debug => true
    #   Cyc::Client.new :debug => true, :url => 'cyc://localhost/3661',
    #     :timeout => 1.5, :driver => Cyc::Connection::SynchronyDriver
    #
    # Thread safe client:
    #   Cyc::Client.new :thread_safe => true
    def initialize(options={})
      @pid = Process.pid
      unless Hash === options
        raise ArgumentError.new("The Client.new(host,port) API is no longer supported.")
      end
      @host = options[:host] || "localhost"
      @port = (options[:port] || 3601).to_i
      if url = options[:url]
        url = URI.parse(url)
        @host = url.host || @host
        @port = url.port || @port
      end
      @timeout = (options[:timeout] || 0.2).to_f
      @driver = options[:driver] || Connection.driver
      @debug = !!options[:debug]
      @cache_enabled = !!options[:cache]
      @cache = Cache.new
      @thread_safe = !!options[:thread_safe]

      if @thread_safe
        self.extend ThreadSafeClientExtension
      else
        @conn = nil
      end
    end

    # Returns +true+ if the client is connected with the server.
    def connected?
      (conn=self.conn) && conn.connected? && @pid == Process.pid || false
    end

    # (Re)connects to the cyc server.
    def reconnect
      # reuse existing connection driver
      # to prevent race condition between fibers
      conn = (self.conn||= @driver.new)
      conn.disconnect if connected?
      @pid = Process.pid
      puts "connecting: #@host:#@port $$#@pid" if @debug
      conn.connect(@host, @port, @timeout)
      self
    end

    # Usually the connection will be established on first use
    # however connect() allows to force early connection:
    #   Cyc::Client.new().connect
    # Usefull in fiber concurrent environment to setup connection early.
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

    # Closes connection with the server.
    def close
      conn.write("(api-quit)") if connected?
    rescue Errno::ECONNRESET
    ensure
      self.conn = nil
    end

    # Sends the +messsage+ to the Cyc server and returns a parsed answer.
    def talk(message, options={})
      if @cache_enabled && @cache[message]
        return @cache[message]
      end
      send_message(message)
      result = receive_answer(options)
      if @cache_enabled
        @cache[message] = result
      end
      result
    end

    # Sends the +message+ to the Cyc server and
    # returns the raw answer (i.e. not parsed).
    def raw_talk(message, options={})
      send_message(message)
      receive_raw_answer(options)
    end

    # Scans the +message+ to find out if the parenthesis are matched.
    # Raises UnbalancedClosingParenthesis exception if there is a not matched closing
    # parenthesis. The message of the exception contains the string with the
    # unmatched parenthesis highlighted.
    # Raises UnbalancedOpeningParenthesis exception if there is a not matched opening
    # parenthesis.
    def check_parenthesis(message)
      count = 0
      message.scan(/[()]/) do |char|
        count += (char == "(" ?  1 : -1)
        if count < 0
          # this *is* thread safe
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
    # receive_answer or receive_raw_answer.
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
        end
        return result
      end
    end

    # Receives raw answer from server. If a block is given
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
    #
    #   cyc = Cyc::Client.new
    #   cyc.genls? :Dog, :Animal
    #
    # He/She returns a parsed answer from the server:
    #   => true
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
    # It is also possible to nest the calls to build more complex calls:
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
  end

  module ThreadSafeClientExtension #:nodoc:
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
