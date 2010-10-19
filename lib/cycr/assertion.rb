module Cyc
  class Assertion
    attr_reader :formula, :microtheory

    def initialize(formula,microtheory)
      @formula = formula
      @microtheory = microtheory
    end

    def to_s
      "#{@formula} : #{@microtheory}"
    end
  end
end
