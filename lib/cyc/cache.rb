require 'ref'

module Cyc
  class Cache
    def initialize
      @soft_references = Ref::SoftValueMap.new
      @hard_references = {}
    end

    # Get a value from cache.
    def [](key)
      if @hard_references.has_key?(key)
        @hard_references[key]
      else
        @soft_references[key]
      end
    end

    # Put a value for a given key to the cache.
    def []=(key,value)
      case value
      when TrueClass,FalseClass,NilClass,Fixnum,Symbol
        @soft_references.delete(key)
        @hard_references[key] = value
      else
        @hard_references.delete(key)
        @soft_references[key] = value
      end
    end

    # Clear the cache.
    def clear
      @soft_references.clear
      @hard_references.clear
    end
  end
end
