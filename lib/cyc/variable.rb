module Cyc
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT/X11 License
  #
  # This class represent the Cyc variable.
  class Variable
    # The name of the variable.
    attr_reader :name

    # Initialize the variable with its +name+.
    def initialize(name)
      @name = name
    end

    # Representation of the variable with question mark as prefix.
    def to_s
      "?#{@name}"
    end

    # Two variables are equal if they have the same name.
    def ==(other)
      return false if other.class != self.class
      self.name == other.name
    end
  end
end
