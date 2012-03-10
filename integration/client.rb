$:.unshift "lib"
require 'cycr'
require 'cyc/connection/synchrony'

shared_examples Cyc::Client do
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

  it "should raise an error for raw talk if Cyc reported error" do
    lambda {@client.raw_talk("(aaa)")}.should raise_error(Cyc::CycError)
  end

  it "should allow to talk to server and return parsed answer" do
    result = @client.talk('(genls #$Dog)')
    result.should_not == nil
    result.should respond_to :size
  end

  it "should not allow to send a message with unbalanced parenthesis" do
    lambda {@client.talk("(")}.should raise_error(Cyc::UnbalancedOpeningParenthesis)
    lambda {@client.talk("())")}.should raise_error(Cyc::UnbalancedClosingParenthesis)
  end

  it "should parse results with assertions" do
    @client.talk('(gather-predicate-extent-index #$minimizeExtent #$BaseKB)').should_not == nil
  end

  it "should return assertions as results if present in the result" do
    @client.talk('(gather-predicate-extent-index #$minimizeExtent #$BaseKB)').
      first.class.should == Cyc::Assertion
  end

  it "should return results with continuation" do
    @client.talk('(gather-predicate-extent-index #$minimizeExtent)').size.should > 100
  end

end

describe Cyc::Client do
  include_examples Cyc::Client
  
  it "should have socket driver" do
    @client.driver.type.should == :socket
  end

  before(:all) do
    Cyc::Connection.driver = Cyc::Connection::SocketDriver
    @client = Cyc::Client.new()
#    @client.debug = true
  end

  after(:each) do
    @client.close
  end

end

describe Cyc::Connection::SynchronyDriver do
  include_examples Cyc::Client

  it "should have synchrony driver" do
    @client.driver.type.should == :synchrony
  end

  around(:each) do |blk|
    EM.synchrony do
      @client = Cyc::Client.new(:driver => Cyc::Connection::SynchronyDriver)
#    @client.debug = true
      blk.call
      @client.close
      EM.stop
    end
  end

end

describe "synchrony fiber concurrency" do
  around(:each) do |blk|
    EM.synchrony do
      @client = EM::Synchrony::ConnectionPool.new(size: 1) do
        Cyc::Client.new(:driver => Cyc::Connection::SynchronyDriver, :debug => false)
      end
      blk.call
      @client.close
      EM.stop
    end
  end

  # this is a little bit loooong test
  # but tests aync nature of Fibers and composite results (subseq x)
  it "should have consistent results running long query in separate fibers" do
    @fiber = Fiber.current
    togo = 0
    size = ('A'..'Z').to_a.each do |char|
      Fiber.new do
        result_size = @client.fi_complete(char).each do |value|
          value.to_s[0].upcase.should == char
        end.length
        result_size.should > 0
        togo+= 1
        EM.next_tick { @fiber.resume }
      end.resume
    end.size
    while togo < size
      @fiber = Fiber.current
      Fiber.yield
    end
  end
end

describe "client thread concurrency" do
  
  before(:all) do
    Cyc::Connection.driver = Cyc::Connection::SocketDriver
    @client = Cyc::Client.new :thread_safe => true
    # @client.debug = true
  end

  it "should have socket driver" do
    @client.driver.type.should == :socket
  end

  it "should have thread_safe? flag set" do
    @client.thread_safe?.should == true
  end

  it "should have consistent results running long query in separate threads" do
    results = {}
    m = Mutex.new
    ('A'..'Z').map do |char|
      Thread.new do
        Thread.pass
        res = @client.fi_complete char
        @client.close
        m.synchronize { results[char] = res }
      end
    end.each {|t| t.join }
    results.each_pair do |char, res|
      res.should_not == nil
      size = res.each do |value|
        value.to_s[0].upcase.should == char
      end.length
      size.should > 0
    end
  end

end

describe "client multiple processes" do
  
  it "should have socket driver" do
    @client.driver.type.should == :socket
  end

  it "should allow multiple processes to use the client" do
    parent_pid = Process.pid
    if fork
      @client.find_constant("Cat").should == :Cat
    else
      @client.find_constant("Dog").should == :Dog
    end
    if Process.pid == parent_pid
      Process.waitall
    end
  end

  before(:all) do
    Cyc::Connection.driver = Cyc::Connection::SocketDriver
    @client = Cyc::Client.new()
#    @client.debug = true
  end

  after(:each) do
    @client.close
  end

end
