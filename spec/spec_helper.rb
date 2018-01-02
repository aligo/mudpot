require 'mudpot'

module Helper

  OPERATORS = Mudpot::Compiler.load_operators("#{File.dirname(__FILE__)}/operators.yml")

  def op
    Mudpot::Expression.new
  end

  def parse_string(string)
    Mudpot::StringParser.new.parse(string)
  end

  def operators 
    OPERATORS
  end

end

RSpec.configure do |config|
  config.include Helper
end

RSpec::Matchers.define :ast do |expected|
  match do |actual|
    exp = actual.is_a?(Mudpot::Expression) ? actual : Mudpot::Parser.new.parse(actual)
    @r = exp.ast
    @r == expected
  end
  failure_message do |actual|
    "expected that #{actual} would not be #{expected}, got #{@r}"
  end
end

RSpec::Matchers.define :compiled do |expected|
  match do |actual|
    exp = actual.is_a?(Mudpot::Expression) ? actual : Mudpot::Parser.new.parse(actual)
    @r = exp.compile(Helper::OPERATORS)
    @r == expected
  end
  failure_message do |actual|
    "expected that #{actual} would not be #{expected}, got #{@r}"
  end
end