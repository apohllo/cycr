$:.unshift "lib"
require 'cycr'

describe Cyc::Parser do
  before(:all) do
    @parser = Cyc::Parser.new
  end

  it "should parse an empty list" do
    @parser.parse('()').should == []
  end

  it "should parse a Cyc term" do
    @parser.parse('#$Dog').should == :Dog
  end

  it "should parse nested lists" do
    @parser.parse('(())').should == [[]]
  end

  it "should raise continuation exception if the message contains continuation" do
    lambda {@parser.parse('(#$Dog ...)')}.should raise_exception(Cyc::ContinueParsing)
  end

  it "should raise parse error if the message is invalid" do
    lambda {@parser.parse('(#$Dog ))')}.should raise_exception(Cyc::ParserError)
  end

  it "should parse an assertion" do
    @parser.parse('#<AS:(#$equals):#$BaseKB>').should == Cyc::Assertion.new([:equals],:BaseKB)
  end

  it "should parse a Cyc symbol" do
    @parser.parse(':BACKWARD').should == Cyc::Symbol.new("BACKWARD")
  end

  it "should parse a variable" do
    @parser.parse('?OBJ').should == Cyc::Variable.new("OBJ")
  end
end
