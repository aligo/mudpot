require 'whittle'
require 'mudpot/expression'

module Mudpot
  class StringParser < Whittle::Parser

    BACKSLASHED_CHARS = {
      "\\b"  => "\b",
      "\\t"  => "\t",
      "\\n"  => "\n",
      "\\f"  => "\f",
      "\\r"  => "\r",
      "\\\"" => "\"",
      "\\\\" => "\\"
    }

    rule(:escape => /\\(?:[btnfr\\"]|\\\\)/).as { |s| BACKSLASHED_CHARS[s] }
    rule(:wildcard => /./)

    rule(:string_part) do |r|
      r[:wildcard]
      r[:escape]
    end

    rule(:string) do |r|
      r[].as                    { '' }
      r[:string_part]
      r[:string, :string_part].as  { |a,b| a + b }
    end

    start(:string)

  end
end