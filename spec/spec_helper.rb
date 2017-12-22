require 'mudpot'

module Helper

  OPERATORS = Mudpot::Compiler.load_operators("#{File.dirname(__FILE__)}/operators.yml")

  def op
    Mudpot::Expression.new
  end

end

RSpec.configure do |config|
  config.include Helper
end

RSpec::Matchers.define :ast do |expected|
  match do |actual|
    exp = actual.is_a?(Mudpot::Expression) ? actual : Mudpot::Parser.new.parse(actual)
    exp.ast == expected
  end
  failure_message do |actual|
    "expected that #{actual} would not be #{expected}"
  end
end

RSpec::Matchers.define :compiled do |expected|
  match do |actual|
    exp = actual.is_a?(Mudpot::Expression) ? actual : Mudpot::Parser.new.parse(actual)
    exp.compile(Helper::OPERATORS) == expected
  end
  failure_message do |actual|
    "expected that #{actual} would not be #{expected}"
  end
end