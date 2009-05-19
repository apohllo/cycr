require 'net/telnet'

module Cyc
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License
  #
  # This class is the implementation of the Cyc server client. 
  class Client
    # If set to true, all communication with the server is logged
    # to standard output
    attr_accessor :debug
    # Creates new Client. 
    def initialize
      @pid = Process.pid
      @lexer = SExpressionLexer.new 
      @mts_cache = {}
      # read domains mapings
      talk(File.read(File.join(
        File.dirname(__FILE__), 'domains.lisp')))

      # read utility functions
      talk(File.read(File.join(
        File.dirname(__FILE__), 'words_reader.lisp')))

      # wait untill files are processed
      send_message("(define end-of-routines ())")
      while answer = receive_answer do
        break if answer =~ /END-OF-ROUTINES/
      end
    end

    def conn
      #puts "#{@pid} #{Process.pid}"
      if @conn.nil? or @pid != Process.pid
        @pid = Process.pid
        @conn = Net::Telnet.new("Port" => 3601, "Telnetmode" => false,
          "Timeout" => 600)
      end
      @conn 
    end

    protected :conn

    def clear_cache
      @mts_cache = {}
    end

    # Closes connection with the server
    def close
      conn.puts("(api-quit)")
      @conn = nil
    end

    NART_QUERY =<<-END
      (clet ((result ())) 
        (cdolist (el :call) 
          (pif (nart-p el) 
            (cpush (nart-id el) result) 
            (cpush el result))) result)
    END


    # Sends message +msg+ directly to the Cyc server and receives 
    # the answer. 
    def talk(msg, options={})
      #conn.puts(msg.respond_to?(:to_cyc) ? msg.to_cyc : msg)
      msg = NART_QUERY.sub(/:call/,msg) if options[:nart]

      send_message(msg)
      receive_answer(options)
    end

    # Send the raw message.
    def send_message(msg) 
      puts "Send: #{msg}" if @debug
      conn.puts(msg)
    end

    # Receive answer from server.
    def receive_answer(options={})
      answer = conn.waitfor(/\d\d\d/)
      puts "Recv: #{answer}" if @debug
      return answer if answer.nil?
      # XXX ignore some potential asynchronous answers
      answer = answer.split("\n")[-1]
      answer = answer.sub(/(\d\d\d) (.*)/,"\\2")
      if($1.to_i == 200)
        result = parse(answer)
        options[:nart] ? substitute_narts(result) : result
      else
        unless $2.nil?
          puts $2.sub(/^"/,"").sub(/"$/,"")
        else
          puts "unknown error!"
        end
        nil
      end
    end


    def method_missing(name,*args)
      #"_missing_method_#{name}"
      method_name = name.to_s.gsub("_","-")
      def method_name.to_cyc
        self.sub(/-nart$/,"")
      end
      options = {}
      options[:nart] = true if name.to_s =~ /_nart$/
        talk(([method_name] + args).to_cyc,options)
    end

    DENOTATION_QUERY =<<-END
      (clet ((result ())) 
        (cdolist (el (denotation-mapper ":word"))
          (pif (nart-p (cdr el)) 
            (cpush (nart-id (cdr el)) result) 
            (cpush (cdr el) result))) result)
    END

    def denotation_mapper(name)
      talk(DENOTATION_QUERY.sub(/:word/,name),:nart => true)
    end


    # Finds collection with given name. The name has to
    # be the name of the exact name of the constant.
    def find_collection(name)
      term = self.find_constant(name)
      Collection.new(term, self) unless term.nil?
    end

protected
    # Parses message received from server. +Message+ to parse.
    def parse(message)
      @lexer.scan_str(message)
      stack = [[]]
      while !(token = @lexer.next_token).nil?
        case token[0]
        when :open_par
          stack.push []
        when :close_par
          top = stack.pop
          stack[-1].push top
        when :atom
          # FIXME find way to differentiate strings and atoms 
          stack[-1] << token[1]
        when :cyc_symbol
          stack[-1] << token[1][2..-1].to_sym
        when :string
          stack[-1] << token[1]
        end
      end
      stack[0][0]
    rescue 
      puts "Error occured while parsing message:\n#{message}"
      nil
    end

    def substitute_narts(terms)
      unless terms.nil?
        terms.collect{|t| t.is_a?(String) ? Cyc::Nart.new(t,self) : t}
      end
    end

    def relevant_mts(term)
      @mts_cache[term] ||= 
        (mts = self.term_mts(term)
         if mts
           mts.select{|mt| mt.is_a? Symbol}.
             reject{|mt| IRRELEVANT_MTS.include?(mt)} 
         else
           []
         end)
    end
  end
end
