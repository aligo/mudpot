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

    rule('{')
    rule('}')
    rule('#{')

    rule(:escape => /\\(?:[btnfr\\"]|\\\\)/).as { |s| BACKSLASHED_CHARS[s] }
    rule(:wildcard => /./)

    rule(:inline_mud_start) do |r|
      r['#{', :string].as {|_, mud| mud }
    end

    rule(:inline_mud) do |r|
      r[:inline_mud_start, '}'].as {|mud, _| Parser.new.parse(mud) }
    end

    rule(:string_part) do |r|
      r[:wildcard]
      r[:escape]
    end

    rule(:string) do |r|
      r[:string_part]
      r[:string, :string_part].as     { |a, b| a + b }
    end

    rule(:mixed_string_part) do |r|
      r[:string]
      r[:inline_mud].as do |mud|
        op.string_concat(mud)
      end
    end

    rule(:mixed_string) do |r|
      r[].as                       { '' }
      r[:mixed_string_part]
      r[:mixed_string, :mixed_string_part].as do |a, b|
        if a.is_a?(String) && b.is_a?(String)
          a + b
        elsif a.is_a?(Expression) && a.operator == :string_concat && b.is_a?(Expression) && b.operator == :string_concat
          op.string_concat(*(a.args + b.args))
        elsif a.is_a?(Expression) && a.operator == :string_concat
          op.string_concat(*(a.args + [b]))
        elsif b.is_a?(Expression) && b.operator == :string_concat
          op.string_concat(*([a] + b.args))
        end
      end
    end


    start(:mixed_string)

  end
end