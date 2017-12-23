require 'whittle'
require 'mudpot/expression'

module Mudpot
  class Parser < Whittle::Parser

    def self.op
      Expression.new
    end

    rule(:wsp => /[ \t]+/).skip!
    rule(:comment => /#.*$/).skip!
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
    rule('||')
    rule('|>')
    rule('->')
    rule('do')
    rule('end')

    rule(:nil => 'nil' ).as { nil }
    rule(:do) do |r|
      r['do']
      r['{']
    end
    rule(:end) do |r|
      r['end']
      r['}']
    end


    rule(:int => /[0-9]+/).as { |i| Integer(i) }
    rule(:float) do |r|
      r[:int, '.', :int].as { |i, _, f| Float("#{i}.#{f}") }
    end
    rule(:token => /\w+/)
    rule(:single_quoted_string => /'[^']*'/).as { |s| s[1..-2] }

    rule(:list) do |r|
      r['@', '[', ']'].as                   { |_, _, _|             op.list_list }
      r['@', '[', :args, ']'].as            { |_, _, args, _|       op.list_list(*args) }
    end

    rule(:list_nth) do |r|
      r['[', :expr, ']'].as                        { |_, i, _|                    op.list_nth  nil, i }
      r['[', :expr, ']', '=', :expr].as            { |_, i, _, _, value|          op.list_push nil, i, value }
    end

    rule(:hash) do |r|
      r['@', '{', '}'].as                         { |_, _, _|                   op.hash_table_ht }
      r['@', '{', :hash_pairs, '}'].as            { |_, _, hash_pair, _|        op.hash_table_ht(*hash_pair.flat_map { |i| i }) }
    end

    rule(:hash_key) do |r|
      r['{', :expr, '}'].as                        { |_, i, _|                    op.hash_table_get nil, i }
      r['{', :expr, '}', '=', :expr].as            { |_, i, _, _, value|          op.hash_table_set nil, i, value }
    end

    rule(:hash_pair) do |r|
      r[:expr, ':', :expr].as { |key, _, value| {key => value} }
    end

    rule(:hash_pairs) do |r|
      r[].as                                      {             {} }
      r[:hash_pairs, :args_comma].as              { |ht, _|     ht }
      r[:hash_pairs, :args_comma, :hash_pair].as  { |ht, _, i|  ht.merge(i) }
      r[:hash_pair].as                            { |i|         i }
    end

    rule(:lambda) do |r|
      r['->', :do_exprs].as                               { |_, exprs|                     op.lambda_lambda(exprs)}
      r['(', :params, ')', '->', :do, :exprs, :end].as    { |_, params, _, _, _, exprs, _| op.lambda_lambda( op.list_list(*params), exprs)}
    end

    rule(:pipeline) do |r|
      r['|>', :token].as                  { |_, operator|                 op.send(operator) }
      r['|>', :token, '(', :args, ')'].as { |_, operator, _, args, _|     op.send(operator, *([nil] + args)) }
    end

    rule(:params) do |r|
      r[].as                        { [] }
      r[:params, ',', '$', :token].as    { |params, _, _, i|  params << i }
      r['$', :token].as                  { |_, i|             [i] }
    end

    rule(:args) do |r|
      r[].as                          {                 [] }
      r[:args, :args_comma].as        { |args|          args }
      r[:args, :args_comma, :expr].as { |args, _, i|    args << i }
      r[:expr].as                     { |i|             [i] }
    end

    rule(:args_comma) do |r|
      r[',']
      r[:lb]
      r[',', :lb]
    end

    rule(:scope_expr) do |r|
      r['$', :int].as               { |_, i|                  op.scope_arg i }
      r['$', :token].as             { |_, token|              op.scope_get token }
      r['$', :token, '=', :expr].as { |_, token, _, value|    op.scope_set token, value }
      r['$', :token, '||', '=', :expr].as { |_, token, _, _, value|    op.cond_if(op.is_nil(op.scope_get(token)), op.scope_set(token, value)) }
      r['$', :token, '.', :token, '.', :token].as                   { |_, bridge, _, namespace, _, token|               op.send(:"#{bridge}_scope_#{namespace}_get", token) }
      r['$', :token, '.', :token, '.', :token, '=', :expr].as       { |_, bridge, _, namespace, _, token, _, value|     op.send(:"#{bridge}_scope_#{namespace}_set", token, value) }
      r['$', :token, '.', :token, '.', :token, '||', '=', :expr].as { |_, bridge, _, namespace, _, token, _, _, value|  op.send(:"#{bridge}_scope_#{namespace}_init", token, value) }
    end

    rule(:literal_expr) do |r|
      r[:single_quoted_string]
      r[:nil]
      r[:int]
      r[:float]
      r[:list]
      r[:hash]
      r[:lambda]
    end

    rule(:lambda_apply) do |r|
      r[:expr, '(', :args, ')'].as  { |lambda, _, args, _|    op.lambda_apply(*([lambda] + args)) }
    end

    rule(:expr) do |r|
      r[:scope_expr]
      r[:token, '(', :args, ')'].as { |operator, _, args, _|  op.send(operator, *args) }
      r[:literal_expr]
      r[:do_exprs]
      r[:lambda_apply]
      r[:expr, :list_nth].as { |expr, list_nth| list_nth.set_arg(0, expr) }
      r[:expr, :hash_key].as { |expr, hash_key| hash_key.set_arg(0, expr) }
      r[:expr, :pipeline].as { |expr, pipeline| pipeline.set_arg(0, expr) }
    end

    rule(:do_exprs) do |r|
      r[:do, :exprs, :end].as { |_, exprs, _| exprs }
    end

    rule(:exprs) do |r|
      r[].as                  { op }
      r[:exprs, :lb]
      r[:exprs, :lb, :expr].as { |exprs, _, i| exprs + [i] }
      r[:expr].as             { |i| op[i] }
    end

    start(:exprs)
  end
end