module Cyc
  class Nart
    attr_accessor :id, :value
    def initialize(id, cyc)  
      @id = id.to_i
      @value = cyc.find_nart_by_id @id
    end

    def to_cyc(quote=false)
      "(find-nart-by-id #{@id})"
    end

    def to_s
      "NART[#{@id}]: #{@value.inspect} "
    end

    def self.find_by_name(name,cyc)
      self.new(name.match(/^NART\[([^\]]+)\]/)[1],cyc)
    end
  end
end
