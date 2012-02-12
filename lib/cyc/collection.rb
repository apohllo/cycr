module Cyc
  class Collection
    attr_reader :symbol

    def initialize(symbol, cyc)
      @symbol = symbol
      @cyc = cyc
      @printed = false
    end

    def printed?
      @printed
    end

    def parents
      unless @parents
        parents = @cyc.min_genls(symbol)
        @parents = if parents
          parents.map{|p| Collection.new(p,@cyc)}
        else
          []
        end
      end
      @parents
    end

    def children
      unless @children
        children = @cyc.max_specs(symbol)
        if children
          @children = children.map{|p| Collection.new(p,@cyc)}
        else
          @children = []
        end
      end
      @children
    end

    def comment
      @cyc.comment(@symbol)
    end

    def lexemes()
      default_str = [@cyc.symbol_str(symbol)]
      aux_strs =  @cyc.symbol_strs(symbol) || []
      (default_str + aux_strs).uniq.compact.join(", ")
    end

    def to_s
      @symbol.to_s
    end

    def ==(other)
      return false unless other.is_a? Collection
      self.symbol == other.symbol
    end

    def =~(other)
      return false unless other.is_a? Collection
      self.parents - other.parents == [] &&
        other.parents - self.parents == []
    end

    def ancestor?(node)
      return true if node == :Thing
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
