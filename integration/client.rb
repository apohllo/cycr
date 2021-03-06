$:.unshift "lib"
require 'cycr'
require 'cyc/connection/synchrony' if defined? Fiber

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

  it "should allow to use cached results" do
    @client.cache_enabled = true
    start_time = Time.now
    @client.specs(:Animal).size.should > 100
    end_time = Time.now
    duration1 = end_time - start_time
    start_time = Time.now
    100.times{ @client.specs(:Animal).size.should > 100}
    end_time = Time.now
    duration2 = end_time - start_time
    duration2.should < duration1
    @client.cache_enabled = false
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

if defined? Cyc::Connection::SynchronyDriver
  describe Cyc::Connection::SynchronyDriver do
    include_examples Cyc::Client

    it "should have synchrony driver" do
      @client.driver.type.should == :synchrony
    end

    around(:each) do |test_case|
      EM.synchrony do
        @client = Cyc::Client.new(:driver => Cyc::Connection::SynchronyDriver)
  #    @client.debug = true
        test_case.call
        @client.close
        EM.stop
      end
    end

  end

  describe "synchrony fiber concurrency" do
    around(:each) do |test_case|
      EM.synchrony do
        @client = EM::Synchrony::ConnectionPool.new(size: 1) do
          Cyc::Client.new(:driver => Cyc::Connection::SynchronyDriver, :debug => false)
        end
        test_case.call
        @client.close
        EM.stop
      end
    end

    # this is a little bit loooong test
    # but tests aync nature of Fibers and composite results (subseq x)
    it "should have consistent results running long query in separate fibers" do
      @fiber = Fiber.current
      done = 0
      size = ('A'..'C').to_a.each do |char|
        Fiber.new do
          result_size = @client.fi_complete(char).each do |value|
            value.to_s[0].upcase.should == char
          end.length
          result_size.should > 0
          done += 1
          EM.next_tick { @fiber.resume }
        end.resume
      end.size
      while done < size
        @fiber = Fiber.current
        Fiber.yield
      end
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
    mutex = Mutex.new
    ('A'..'C').map do |char|
      Thread.new do
        Thread.pass
        result = @client.fi_complete char
        @client.close
        mutex.synchronize { results[char] = result }
      end
    end.each {|t| t.join }
    results.each_pair do |char, result|
      result.should_not == nil
      size = result.each do |value|
        value.to_s[0].upcase.should == char
      end.length
      size.should > 0
    end
  end

end

describe "client multiple processes" do

  before(:all) do
    Cyc::Connection.driver = Cyc::Connection::SocketDriver
    @client = Cyc::Client.new()
#    @client.debug = true
  end

  after(:each) do
    @client.close
  end

  it "should have socket driver" do
    @client.driver.type.should == :socket
  end

  it "should allow multiple processes to use the client" do
    fork { @client.find_constant("Cat").should == :Cat }
    fork { @client.find_constant("Dog").should == :Dog }
    @client.find_constant("Animal").should == :Animal
    Process.waitall
  end

end
