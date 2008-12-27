module Apohllo
  module Cyc
    class Node
      attr_accessor :parents, :term, :printed, :children, :translations
      @@cyc = Cyc.instance

      def initialize(term, cat, translations=nil)
        @term = term
        @cat = cat
        @translations = translations
        @parents = []
        @children = []
        @printed = false
      end

      def printed?
        @printed
      end

      def lexemes(lang=:en)
        default_str = [@@cyc.symbol_str(term)]
        aux_strs =  @@cyc.symbol_strs(term) || []
        (default_str + aux_strs).uniq.compact.join(", ")
      end
      
      def categories
        Mapping.instance.categories(@cat)
      end

      def kind_of
        @parents.map{|p| p.term}.join(", ")
      end

      def translations(type=nil)
        if type.nil?
          @translations
        else
          unless @translations.nil? || @translations[type].nil?
            @translations[type].map{|t| t[:trans].to_s} 
          else
            []
          end
        end
      end

      def to_s
        @printed = true
        @parents.each{|p| p.to_s unless p.printed?}
        if @translations
          trans_str = '  SELECTED: ' + @translations[:selected].
              map{|e| "#{e[:trans]} (#{e[:qual].join(", ") unless e[:qual].nil?})"}.
              join(", ") + 
              "\n  REJECTED: " + @translations[:rejected].
              map{|e| "#{e[:trans]} (#{e[:qual].join(", ") unless e[:qual].nil?})"}.
              join(", ") + 
              "\n  NOT FOUND: " + @translations[:not_found].
              map{|e| "#{e[:trans]} (#{e[:qual].join(", ") unless e[:qual].nil?})"}.
              join(", ")
        else
          trans_str = ""
        end
        "#{@term} (#{lexemes()}) \n" +
          "  CATEGORY: #{self.categories}\n" +
          "  IS_A_KIND_OF: #{self.kind_of}\n" 
        #  trans_str 
      end

      def ==(other)
        return false unless other.is_a? Node
        self.term == other.term
      end

      def =~(other)
        return false unless other.is_a? Node
        self.categories == other.categories &&
          self.kind_of == other.kind_of 
      end

      def ancestor?(node)
        ancestors = @parents.dup
        while !ancestors.empty?
          ancestor = ancestors.shift
          return true if ancestor == node
          ancestors += ancestor.parents
          ancestors.uniq!
        end
        false
      end
    end # Node
  end
end
