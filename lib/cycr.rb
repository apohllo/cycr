$:.unshift File.dirname(__FILE__)
Dir.glob(File.join(File.dirname(__FILE__), 'cycr/**.rb')).each { |f| require f }
