$:.unshift "lib"
require 'cycr'

describe Cyc::Assertion do
  before(:all) do
    @client = Cyc::Client.new()
    #@client.debug = true
  end

  after(:all) do
    @client.close
  end

  it "should parse results with assertions" do
    @client.talk("(gather-predicate-extent-index \#$minimizeExtent \#$BaseKB)").should_not == nil
  end

  it "should return assertions as results if present in the result" do
    @client.talk("(gather-predicate-extent-index \#$minimizeExtent \#$BaseKB)").
      first.class.should == Cyc::Assertion
  end

  it "should have microtheory assigned" do
    @client.talk("(gather-predicate-extent-index \#$minimizeExtent \#$BaseKB)").
      first.microtheory.should_not == nil
  end

  it "should have formula assigned" do
    @client.talk("(gather-predicate-extent-index \#$minimizeExtent \#$BaseKB)").
      first.formula.should_not == nil
  end

  it "should return many results" do
    @client.talk("(gather-predicate-extent-index \#$minimizeExtent)").size.should > 100
  end
end
