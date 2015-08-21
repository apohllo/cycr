# encoding: utf-8
$:.unshift "lib"
require 'cycr'


describe Cyc::Service::NameService do
  let(:service) { Cyc::Service::NameService.new(@client) }

  before(:all) do
    @client = Cyc::Client.new()
    #@client.debug = true
  end

  after(:all) do
    @client.close
  end

  it "should find term by exact name" do
    service.find_by_term_name("Dog").should_not == nil
  end

  it "should find term by id" do
    term = service.find_by_term_name("Dog")
    service.find_by_id(term.id).should_not == nil
  end

  it "should find concept by name" do
    service.find_by_name("dog").should_not == nil
    service.find_by_name("dog").should_not be_empty
  end

  it "should find concept by label" do
    service.find_by_label("dog").should_not == nil
  end

  it "should convert Ruby term" do
    term = service.convert_ruby_term(:Dog)
    term.name.should == "Dog"
  end

  it "should transliterate non-ascii characters" do
    service.find_by_term_name("Dóg").name.should == "Dog"
  end

  describe "with term" do
    let(:term) { service.find_by_term_name("Dog") }

    it "should return canonical label" do
      service.canonical_label(term).should == "dog"
    end

    it "should return labels" do
      service.labels(term).should include("dogs")
    end
  end
end

