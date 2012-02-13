$:.unshift "lib"
require 'cycr'

describe Cyc::Assertion do
  before(:all) do
    @client = Cyc::Client.new()
    #@client.debug = true
    @assertion = @client.talk('(gather-predicate-extent-index #$minimizeExtent #$BaseKB)').
      first
  end

  after(:all) do
    @client.close
  end

  it "should have microtheory assigned" do
    @assertion.microtheory.should_not == nil
  end

  it "should have formula assigned" do
    @assertion.formula.should_not == nil
  end

  it "should allow to check its direction" do
    @client.assertion_direction(@assertion).should_not == nil
  end

  it "should allow to check its truth" do
    @client.assertion_truth(@assertion).should_not == nil
  end

  it "should allow to check its strength" do
    @client.assertion_strength(@assertion).should_not == nil
  end
end
