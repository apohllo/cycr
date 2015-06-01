module Cyc
  class Term
    # Create new Term using Ruby representation of the term (Symbol or
    # Array).
    def initialize(ruby_term,id)
      @ruby_term = ruby_term
      @id = id
    end

    # Return Ruby representation of the term.
    def to_ruby
      @ruby_term
    end

    # Return external ID of the term.
    def id
      @id
    end

    # Return Cyc-protocol compatible representation of the term.
    def to_cyc(raw=false)
      self.to_ruby.to_cyc(raw)
    end

    # Inspect the term.
    def inspect
      "#{@ruby_term}:#{@id}"
    end

    def name
      self.to_ruby.to_s
    end

    def ==(other)
      return false if !(self.class === other)
      @ruby_term == other.to_ruby
    end

    def eql?(other)
      self == other
    end

    def hash
      @ruby_term.hash
    end

    alias to_s inspect
  end
end
