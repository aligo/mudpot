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
    rule('{')
    rule('}')
    rule(':')
    rule('$')
    rule('=')
    rule('|>')

    rule(:nil => 'nil' ).as { nil }
    rule(:do => 'do' )
    rule(:end => 'end' )


    rule(:int => /[0-9]+/).as {|i| Integer(i) }
    rule(:float) do |r|
      r[:int, '.', :int].as {|i, _, f| Float("#{i}.#{f}") }
    end
    rule(:token => /\w+/)
    rule(:single_quoted_string => /'[^']*'/).as {|s| s[1..-2] }

    rule(:list) do |r|
      r['@', '[', ']'].as                   { |_, _, _|             Expression.new.list_list }
      r['@', '[', :lb, :args, :lb, ']'].as  { |_, _, _, args, _, _| Expression.new.list_list(*args) }
      r['@', '[', :args, :lb, ']'].as       { |_, _, args, _, _|    Expression.new.list_list(*args) }
      r['@', '[', :lb, :args, ']'].as       { |_, _, _, args, _|    Expression.new.list_list(*args) }
      r['@', '[', :args, ']'].as            { |_, _, args, _|       Expression.new.list_list(*args) }
    end

    rule(:list_nth) do |r|
      r['[', :expr, ']'].as                        {|_, i, _|                    Expression.new.list_nth  nil, i }
      r['[', :expr, ']', '=', :expr].as            {|_, i, _, _, value|          Expression.new.list_push nil, i, value }
    end

    rule(:hash) do |r|
      r['@', '{', '}'].as                         { |_, _, _|                   Expression.new.hash_table_ht }
      r['@', '{', :lb, :hash_pairs, :lb, '}'].as  { |_, _, _, hash_pair, _, _|  Expression.new.hash_table_ht(*hash_pair.flat_map {|i| i }) }
      r['@', '{', :hash_pairs, :lb, '}'].as       { |_, _, hash_pair, _, _|     Expression.new.hash_table_ht(*hash_pair.flat_map {|i| i }) }
      r['@', '{', :lb, :hash_pairs, '}'].as       { |_, _, hash_pair, _|        Expression.new.hash_table_ht(*hash_pair.flat_map {|i| i }) }
      r['@', '{', :hash_pairs, '}'].as            { |_, _, hash_pair, _|        Expression.new.hash_table_ht(*hash_pair.flat_map {|i| i }) }
    end

    rule(:hash_key) do |r|
      r['{', :expr, '}'].as                        {|_, i, _|                    Expression.new.hash_table_get nil, i }
      r['{', :expr, '}', '=', :expr].as            {|_, i, _, _, value|          Expression.new.hash_table_set nil, i, value }
    end

    rule(:hash_pair) do |r|
      r[:expr, ':', :expr].as { |key, _, value| {key => value} }
    end

    rule(:hash_pairs) do |r|
      r[].as                                  { [] }
      r[:hash_pairs, ',', :lb, :hash_pair].as { |ht, _, _, i| ht.merge(i) }
      r[:hash_pairs, ',', :hash_pair].as      { |ht, _, i|    ht.merge(i) }
      r[:hash_pairs, :lb, :hash_pair].as      { |ht, _, i|    ht.merge(i) }
      r[:hash_pair].as                        { |i| i }
    end

    rule(:pipeline) do |r|
      r['|>', :token].as                  { |_, operator|                 Expression.new.send(operator) }
      r['|>', :token, '(', :args, ')'].as { |_, operator, _, args, _|     Expression.new.send(operator, *([nil] + args)) }
    end

    rule(:args) do |r|
      r[].as                        { [] }
      r[:args, ',', :lb, :expr].as  { |args, _, _, i| args << i }
      r[:args, ',', :expr].as       { |args, _, i|    args << i }
      r[:args, :lb, :expr].as       { |args, _, i|    args << i }
      r[:expr].as                   { |i| [i] }
    end

    rule(:expr) do |r|
      r['$', :int].as               { |_, i|                  Expression.new.scope_arg i }
      r['$', :token].as             { |_, token|              Expression.new.scope_get token }
      r['$', :token, '=', :expr].as { |_, token, _, value|    Expression.new.scope_set token, value }
      r['$', :token, '.', :token, '.', :token].as               { |_, bridge, _, namespace, _, token|  Expression.new.send(:"#{bridge}_scope_#{namespace}_get", token) }
      r['$', :token, '.', :token, '.', :token, '=', :expr].as   { |_, bridge, _, namespace, _, token, _, value|  Expression.new.send(:"#{bridge}_scope_#{namespace}_set", token, value) }
      r[:token, '(', :args, ')'].as { |operator, _, args, _|  Expression.new.send(operator, *args) }
      r[:single_quoted_string]
      r[:nil]
      r[:int]
      r[:float]
      r[:list]
      r[:hash]
      r[:do_exprs]
      r[:expr, :list_nth].as {|expr, list_nth| list_nth.set_arg(0, expr) }
      r[:expr, :hash_key].as {|expr, hash_key| hash_key.set_arg(0, expr) }
      r[:expr, :pipeline].as {|expr, pipeline| pipeline.set_arg(0, expr) }
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