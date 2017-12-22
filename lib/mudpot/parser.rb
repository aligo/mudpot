require 'whittle'
require 'mudpot/expression'

module Mudpot
  class Parser < Whittle::Parser

    rule(:wsp => /[ \t]+/).skip!
    rule(:lb => /[\n\r\;]+/)

    rule('(')
    rule(')')
    rule(',')
    rule('"')
    rule('.')
    rule('@')
    rule('[')
    rule(']')

    rule(:nil => 'nil' ).as { nil }
    rule(:do => 'do' )
    rule(:end => 'end' )


    rule(:int => /[0-9]+/).as {|i| Integer(i) }
    rule(:float) do |r|
      r[:int, '.', :int].as {|i, _, f| Float("#{i}.#{f}") }
    end
    rule(:operator => /\w+/)
    rule(:single_quoted_string => /'[^']*'/).as {|s| s[1..-2] }

    rule(:list) do |r|
      r['@', '[', ']'].as { |_, _, _| Expression.new.list_list }
      r['@', '[', :args, ']'].as { |_, _, args, _| Expression.new.list_list(*args) }
    end
    

    rule(:args) do |r|
      r[].as                  { [] }
      r[:args, ',', :expr].as { |args, _, i| args << i }
      r[:expr].as             { |i| [i] }
    end

    rule(:expr) do |r|
      r[:operator, '(', :args, ')'].as { |operator, _, args, _| Expression.new.send(operator, *args) }
      r[:single_quoted_string]
      r[:nil]
      r[:int]
      r[:float]
      r[:list]
      r[:do_exprs]
    end

    rule(:do_exprs) do |r|
      r[:do, :exprs, :end].as { |_, exprs, _| exprs }
    end

    rule(:exprs) do |r|
      r[].as                  { Expression.new }
      r[:exprs, :lb]
      r[:exprs, :lb, :expr].as { |exprs, _, i| exprs + [i] }
      r[:expr].as             { |i| Expression.new[i] }
    end

    start(:exprs)
  end
end