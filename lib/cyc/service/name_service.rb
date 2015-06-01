# encoding: utf-8
require 'iconv'

module Cyc
  module Service
    class AmbiguousResult < Exception
      attr_reader :results

      def initialize(results)
        super("Ambiguous prefered label results")
        @results = results
      end
    end

    # Class used to find Cyc terms by their name.
    class NameService
      attr_accessor :cyc

      def initialize(cyc_client=Client.new,term_factory=Term)
        @cyc = cyc_client
        @cyc.connect
        @factory = term_factory
      end

      # Look-up by +name+, i.e. the exact name of the Cyc term.
      def find_by_term_name(name)
        if name =~ /\A\[/
          convert_ruby_term(eval(name))
        else
          term = @cyc.find_constant(transliterate(name))
          if term
            id = @cyc.compact_hl_external_id_string(term)
            @factory.new(term,id)
          end
        end
      end

      # Look-up by ID, i.e. external identifier of the term.
      def find_by_id(id)
        begin
          term = @cyc.find_cycl_object_by_compact_hl_external_id_string(id)
          if term and term!='<The'
            @factory.new(term,id)
          end
        rescue CycError
          nil
        end
      end

      # Approximate find by name - the result is ambiguous, so the result is an
      # array.
      def find_by_name(name)
        result = @cyc.denotation_mapper(transliterate(name))
        if result
          result.select{|label,_,_| label == name }.
            map{|_,_,ruby_term| convert_ruby_term(ruby_term) }
        else
          []
        end
      end

      # Find term by prefered +label+. In rare cases the result is ambiguous - an
      # AmbiguousResult is raised then. You can get the result, by calling 'result' on
      # the returned exception.
      def find_by_label(label)
        result = @cyc.cyc_query( -> { '`(#$prettyString-Canonical ?s ' + transliterate(label).to_cyc + ')' }, :EnglishMt)
        if result
          result.map!{|e| convert_ruby_term(extract_term_name(e.first))}
          if result.size == 1
            result.first
          else
            raise AmbiguousResult.new(result)
          end
        end
      end

      # Returns canonical label for the +term+.
      def canonical_label(term)
        (@cyc.cyc_query(-> { '\'(#$prettyString-Canonical ' + term.to_cyc(true)  + ' ?s)'}, :EnglishMt) || []).
          map{|e| e.first.last }.first
      end

      # Returns all (non-canonical) labels for the +term+.
      def labels(term)
        begin
          (@cyc.cyc_query(-> { '\'(#$prettyString ' + term.to_cyc(true)  + ' ?s)'}, :EnglishMt) || []).
            map{|e| e.first.last }
        rescue CycError
          []
        end
      end

      # Close connection to Cyc server.
      def close
        @cyc.close
      end

      # Convert Ruby term (e.g. :Dog) to cyc term representation.
      def convert_ruby_term(term)
        id = @cyc.compact_hl_external_id_string(term)
        if id
          @factory.new(term,id)
        end
      end

      # Extracts term name from a result that might be either Lisp pair or Lisp
      # list.
      def extract_term_name(expression)
        if expression[1] == "."
          expression[2]
        else
          expression[1..-1]
        end
      end

      private
      # Transliterate non-ascii characters.
      def transliterate(string)
        Iconv.iconv('ascii//translit//ignore', 'utf-8', string).join("")
      end
    end
  end
end
