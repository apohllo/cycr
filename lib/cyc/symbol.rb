module Cyc
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT/X11 License
  #
  # This class represent the Cyc symbol.
  class Symbol
    # The name of the symbol.
    attr_reader :name

    # Initialize the symbol with its +name+.
    def initialize(name)
      @name = name
    end

    # String representation of the symbol.
    def to_s
      self.to_cyc
    end

    # Representation of the symbol understandable by Cyc.
    def to_cyc(raw=false)
      ":#{@name}"
    end

    # Two symbols are equal if they have the same name.
    def ==(other)
      return false if other.class != self.class
      self.name == other.name
    end
  end
end
