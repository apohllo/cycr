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

  it "should allow to talk to server by calling SubL methods which are not defined in the client" do
    @client.constant_count.should_not == nil
  end

  it "should allow to talk to server and return raw answer" do
    result = @client.raw_talk("(constant-count)")
    result.should_not == nil
    result.should be_a_kind_of String
  end

  it "should allow to talk to server and return parsed answer" do
    result = @client.talk("(genls \#\$Dog)")
    result.should_not == nil
    result.should respond_to :size
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
