module Cyc
  class Nart
    attr_accessor :id, :value
    def initialize(id, cyc)  
      @id = id.to_i
      @value = cyc.find_nart_by_id @id
    end

    def to_cyc
      "(find-nart-by-id #{@id})"
    end

    def to_s
      "NART: #{@value.inspect} "
    end
  end
end
