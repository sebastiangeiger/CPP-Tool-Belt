require "./parser.rb"
class AToken < Token
  def self.first_line
    /A/
  end
end
class BToken < Token
  def self.first_line
    /B/
  end
end
class CatchAllToken < Token
  def self.first_line
    /.*/
  end
  def self.order
    0
  end
end

describe Parser do
  describe "#find_token(line)" do
    it "returns the applicable token class if there is a match" do
      Parser.stub!(:parse_constructs).and_return([AToken])
      Parser::find_token("ABC").should == AToken
    end
    it "returns the higher order token if both token match" do
      Parser.stub!(:parse_constructs).and_return([AToken,CatchAllToken])
      Parser::find_token("ABC").should == AToken
    end
    it "returns the catchall token if the custom token doesn't match" do
      Parser.stub!(:parse_constructs).and_return([AToken,CatchAllToken])
      Parser::find_token("DEF").should == CatchAllToken
    end
    it "throws an error if no token matched" do
      Parser.stub!(:parse_constructs).and_return([AToken])
      lambda{Parser::find_token("DEF")}.should throw_symbol :no_constructs_found
    end
    it "throws an error if two tokens of the same order matched" do
      Parser.stub!(:parse_constructs).and_return([AToken,BToken])
      lambda{Parser::find_token("ABC")}.should throw_symbol :multiple_constructs_found
    end
  end
end
