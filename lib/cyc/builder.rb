module Cyc
  # This class is used to capture calls to the Cyc client, to allow
  # nested calls, like
  #
  # cyc.with_any_mt do |cyc|
  #   cyc.comment :Collection
  # end
  class Builder
    def initialize
      reset
    end

    def reset
      @query = ""
    end

    def to_cyc
      @query
    end

    def method_missing(name,*args,&block)
      @query << "(" << name.to_s.gsub("_","-") << " "
      @query << (args||[]).map{|a| a.to_cyc}.join(" ")
      if block
        block.call(self)
      end
      @query << ")"
    end
  end
end
