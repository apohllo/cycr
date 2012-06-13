require 'thread'
require 'ref'

module Cyc
  class Cache
    def initialize
      @soft_references = Ref::SoftValueMap.new
      @hard_references = {}
      @in_progress = {}
      @lock = Mutex.new
    end

    # Get cached value of a key or generate new one using given block
    def cached_value(key)
      monitor = value = nil
      @lock.synchronize do
        if @hard_references.has_key?(key)
          return @hard_references[key]
        elsif (value = @soft_references[key])
          return value
        elsif (monitor = @in_progress[key])
          monitor.wait(@lock)
          return self[key]
        end
        @in_progress[key] = monitor = ConditionVariable.new
      end
      value = yield
      @lock.synchronize do
        self[key] = value
        @in_progress.delete key
        monitor.broadcast
      end
      value
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
      when TrueClass,FalseClass,NilClass,Fixnum,::Symbol
        @soft_references.delete(key)
        @hard_references[key] = value
      else
        @hard_references.delete(key)
        @soft_references[key] = value
      end
    end

    # Clear the cache.
    def clear
      @lock.synchronize do
        @soft_references.clear
        @hard_references.clear
      end
    end
  end
end
