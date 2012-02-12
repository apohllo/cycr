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

    # Representation of the symbol with colon as prefix.
    def to_s
      ":#{@name}"
    end

    # Two symbols are equal if they have the same name.
    def ==(other)
      return false if other.class != self.class
      self.name == other.name
    end
  end
end
