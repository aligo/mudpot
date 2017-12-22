require 'whittle'
require 'mudpot/expression'

module Mudpot
  class Parser < Whittle::Parser

    rule(:wsp => /[ ]+/).skip!
    rule('(')
    rule(')')
    rule(',')
    rule('"')
    rule('.')
    rule("\n")
    rule(:int => /[0-9]+/).as {|i| Integer(i) }
    rule(:float) do |r|
      r[:int, '.', :int].as {|i, _, f| Float("#{i}.#{f}") }
    end
    rule(:operator => /\w+/)
    rule(:single_quoted_string => /'[^']*'/).as {|s| s[1..-2] }

    rule(:args) do |r|
      # r[].as                  { [] }
      r[:args, ',', :exprs].as { |args, _, i| args << i }
      r[:exprs].as             { |i| [i] }
    end

    rule(:exprs) do |r|
      r[].as                  { Expression.new }
      r[:exprs, "\n"]
      r[:exprs, "\n", :expr].as { |exprs, _, i| exprs + [i] }
      r[:expr].as             { |i| Expression.new[i] }
    end

    rule(:expr) do |r|
      r[:operator, '(', :args, ')'].as { |operator, _, args, _| Expression.new.send(operator, *args) }
      r[:single_quoted_string]
      r[:int]
      r[:float]
    end

    start(:exprs)
  end
end