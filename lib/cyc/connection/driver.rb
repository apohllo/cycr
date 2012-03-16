module Cyc #:nodoc:
  # Use Cyc::Connection.driver = Cyc::Connection::SomeDriver
  # to set default connection driver.
  module Connection
    EOL = "\n"
    class << self
      # The driver used to connect to the Cyc server.
      attr_accessor :driver
    end
  end
end
Cyc::Connection.driver = nil
