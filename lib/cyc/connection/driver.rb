module Cyc
  # use Cyc::Connection.driver = Cyc::Connection::SomeDriver
  # to set default connection driver
  module Connection
    EOL = "\n"
    class << self
      attr_accessor :driver
    end
  end
end
Cyc::Connection.driver = nil
