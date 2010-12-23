$:.unshift "lib"
require 'cycr'

describe Cyc::Client do
  before(:each) do  
    @client = Cyc::Client.new()
#    @client.debug = true
  end

  after(:each) do 
    @client.close
  end

  it "should allow to talk to the server" do 
    @client.talk("(constant-count)").should_not == nil
  end

  it "should allow to talk to server by calling non-existent methods" do 
    @client.constant_count.should_not == nil
  end

  it "should allow multiple processes to use the client" do 
    parent_pid = Process.pid
    if fork
      @client.find_constant("Cat")
    else
      @client.find_constant("Dog")
    end
    if Process.pid == parent_pid
      Process.waitall
    end
  end
end
