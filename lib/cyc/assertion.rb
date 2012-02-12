module Cyc
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT/X11 License
  #
  # This class represent the Cyc assertions.
  class Assertion
    # The logical formula of the assertion.
    attr_reader :formula

    # The microtheory the assertion was asserted in.
    attr_reader :microtheory

    # Initialize the assertion with a +formula+ and a +microtheory+.
    def initialize(formula,microtheory)
      @formula = formula
      @microtheory = microtheory
    end

    # Returns the string representation of the assertion.
    def to_s
      "#{@formula} : #{@microtheory}"
    end

    def ==(other)
      return true if self.object_id == other.object_id
      return false unless other.respond_to?(:formula)
      return false unless other.respond_to?(:microtheory)
      self.formula == other.formula && self.microtheory == other.microtheory
    end
  end
end
