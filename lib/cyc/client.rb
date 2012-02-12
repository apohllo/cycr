require 'net/telnet'
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
    attr_reader :host, :port

    # Creates new Client.
    def initialize(host="localhost",port="3601",debug=false)
      @debug = debug
      @host = host
      @port = port
      @pid = Process.pid
      @parser = Parser.new
      @mts_cache = {}
      @builder = Builder.new
    end

    # (Re)connects to the cyc server.
    def reconnect
      @pid = Process.pid
      @conn = Net::Telnet.new("Port" => @port, "Telnetmode" => false,
                              "Timeout" => 600, "Host" => @host)
    end

    # Returns the connection object. Ensures that the pid of current
    # process is the same as the pid, the connection was initialized with.
    #
    # If the block is given, the command is guarded by assertion, that
    # it will be performed, even if the connection was reset.
    def connection
      if @conn.nil? or @pid != Process.pid
        reconnect
      end
      if block_given?
        begin
          yield @conn
        rescue Errno::ECONNRESET
          reconnect
          yield @conn
        end
      else
        @conn
      end
    end

    protected :connection, :reconnect

    # Clears the microtheory cache.
    def clear_cache
      @mts_cache = {}
    end

    # Closes connection with the server
    def close
      connection{|c| c.puts("(api-quit)")}
      @conn = nil
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
      position = 0
      message.scan(/./) do |char|
        position += 1
        next if char !~ /\(|\)/
        count += (char == "(" ?  1 : -1)
        if count < 0
          raise UnbalancedClosingParenthesis.
            new((position > 1 ? message[0..position-2] : "") +
              "<error>)</error>" + message[position..-1])
        end
      end
      raise UnbalancedOpeningParenthesis.new(count) if count > 0
    end

    # Sends a raw message to the Cyc server. The user is
    # responsible for receiving the answer by calling
    # +receive_answer+ or +receive_raw_answer+.
    def send_message(message)
      position = 0
      check_parenthesis(message)
      @last_message = message
      puts "Send: #{message}" if @debug
      connection{|c| c.puts(message)}
    end

    # Receives and parses an answer for a message from the Cyc server.
    def receive_answer(options={})
      receive_raw_answer do |answer|
        begin
          result = @parser.parse(answer,options[:stack])
        rescue ContinueParsing => ex
          result = ex.stack
          current_result = result
          last_message = @last_message
          while current_result.size == 100 do
            send_message("(subseq #{last_message} #{result.size} " +
                         "#{result.size + 100})")
            current_result = receive_answer(options) || []
            result.concat(current_result)
          end
        rescue CycError => ex
          puts ex.to_s
          return nil
        end
        return result
      end
    end

    # Receives raw answer from server. If a +block+ is given
    # the answer is yield to the block, otherwise the answer is returned.
    def receive_raw_answer(options={})
      answer = connection{|c| c.waitfor(/./)}
      puts "Recv: #{answer}" if @debug
      if answer.nil?
        raise CycError.new("Unknwon error occured. " +
          "Check the submitted query in detail:\n" +
          @last_message)
      end
      while not answer =~ /\n/ do
        next_answer = connection{|c| c.waitfor(/./)}
        puts "Recv: #{next_answer}" if @debug
        if answer.nil?
          answer = next_answer
        else
          answer += next_answer
        end
      end
      # XXX ignore some potential asynchronous answers
      # XXX check if everything works ok
      #answer = answer.split("\n")[-1]
      answer = answer.sub(/(\d\d\d) (.*)/,"\\2")
      if($1.to_i == 200)
        if block_given?
          yield answer
        else
          return answer
        end
      else
        unless $2.nil?
          raise CycError.new($2.sub(/^"/,"").sub(/"$/,"") + "\n" + @last_message)
        else
          raise CycError.new("Unknown error! #{answer}")
        end
        nil
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
      @builder.reset
      @builder.send(name,*args,&block)
      talk(@builder.to_cyc)
    end
  end
end
