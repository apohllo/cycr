$:.unshift "lib"
require 'cycr'

describe Cyc do
  describe "Ruby types conversions" do
    it "should convert proc to literal string" do
      lambda{ "#'null"}.to_cyc.should == "#'null"
    end
  end
end
