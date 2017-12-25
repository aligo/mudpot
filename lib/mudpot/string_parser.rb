require 'whittle'
require 'mudpot/expression'

module Mudpot
  class StringParser < Whittle::Parser

    def self.op
      Expression.new
    end

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
    rule(:inline_mud => /#\{.+\}/).as { |s| s[2..-2] }

    rule(:string_part) do |r|
      r[:wildcard]
      r[:escape]
    end

    rule(:string) do |r|
      r[].as                    { '' }
      r[:string_part]
      r[:string, :string_part].as  { |a,b| a + b }
      r[:string, :inline_mud, :string].as { |a, mud, b| op.string_concat(a, Parser.new.parse(mud), b) }
    end

    start(:string)

  end
end