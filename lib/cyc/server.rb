# Cyc server client

module Apohllo
  module Cyc
    class CycNart
      attr_accessor :id, :value
      def initialize(id)  
        @id = id.to_i
        @value = Cyc.instance.find_nart_by_id @id
      end

      def to_cyc
        "(find-nart-by-id #{@id})"
      end

      def to_s
        "NART: #{@value.inspect} "
      end
    end


    class Cyc
      include Singleton

      def initialize
        @conn = Net::Telnet.new("Port" => 3601, "Telnetmode" => false,
                   "Timeout" => 600)
        @lexer = SExpressionLexer.new 
        @mts_cache = {}
      end

      def clear_cache
        @mts_cache = {}
      end


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

      NART_QUERY =<<-END
      (clet ((result ())) 
        (cdolist (el :call) 
          (pif (nart-p el) 
            (cpush (nart-id el) result) 
            (cpush el result))) result)
      END


      def talk(msg, options={})
        #@conn.puts(msg.respond_to?(:to_cyc) ? msg.to_cyc : msg)
        msg = NART_QUERY.sub(/:call/,msg) if options[:nart]

        @conn.puts(msg)
        answer = @conn.waitfor(/\d\d\d/)
        answer = answer.sub(/(\d\d\d) (.*)\n/,"\\2")
        if($1.to_i == 200)
          result = parse answer
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

      def substitute_narts(terms)
        unless terms.nil?
          terms.collect{|t| t.is_a?(String) ? CycNart.new(t) : t}
        end
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

      # read some useful functions
      Cyc.instance.talk(File.read(File.join(
        File.dirname(__FILE__), '..','..', 'export', 'words_reader.lisp')))

      # read domains mapings
      Cyc.instance.talk(File.read(File.join(
        File.dirname(__FILE__), '..', '..', 'export', 'domains.lisp')))
    end
  end
end

