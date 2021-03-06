require 'whittle'
require 'mudpot/expression'
require 'mudpot/string_parser'

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
    rule('==')
    rule('>')
    rule('<')
    rule('||=')
    rule('?=')
    rule('!')
    rule('?')
    rule('||') % :left ^ 3
    rule('&&') % :left ^ 3
    rule('+') % :left ^ 1
    rule('-') % :left ^ 1
    rule('*') % :left ^ 2
    rule('/') % :left ^ 2
    rule('%') % :left ^ 2
    rule('|>')
    rule('->')
    rule('>>')
    rule('<<')
    rule('/')
    rule('do')
    rule('end')
    rule('if')
    rule('unless')
    rule('elsif')
    rule('else')

    rule(:nil => 'nil' ).as { nil }
    rule(:do) do |r|
      r['do']
      r['{']
    end
    rule(:end) do |r|
      r['end']
      r['}']
    end

    rule(:_negative_int => /\-[0-9]+/)
    rule(:_int => /[0-9]+/)

    rule(:int) do |r|
      r[:_int].as { |i| Integer(i) }
      r[:_negative_int].as { |i| Integer(i) }
    end
    rule(:float) do |r|
      r[:_int, '.', :_int].as { |i, _, f| Float("#{i}.#{f}") }
      r[:_negative_int, '.', :_int].as { |i, _, f| Float("-#{i.to_i.abs}.#{f}") }
    end
    rule(:macro_token => /\w+!/)
    rule(:token => /\w+/)
    rule(:single_quoted_string => /'[^']*'/m).as { |s| s[1..-2].gsub(/\n\s*/, "\n") }
    rule(:double_quoted_string => /"(?:\\"|[^"])*"/m).as { |s| StringParser.new.parse(s[1..-2]) }

    rule(:list) do |r|
      r['@', '[', ']'].as                   { |_, _, _|             op.list_list }
      r['@', '[', :args, ']'].as            { |_, _, args, _|       op.list_list(*args) }
    end

    rule(:list_nth) do |r|
      r['[', :expr, ']'].as                        { |_, i, _|                    op.list_nth  nil, i }
      r['[', ']', '=', :expr].as                   { |_, _, _, value|             op.list_push nil, value }
      r['[', :expr, ']', '=', :expr].as            { |_, i, _, _, value|          op.list_replace nil, value, i }
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

    rule(:regex => /\/(?:\\.|[^\/\n\r])*\//).as { |s| op.regex_regex s[1..-2] }

    rule(:lambda) do |r|
      r['@', '->', :do_exprs].as                               { |_, _, exprs|                     op.lambda_lambda(exprs)}
      r['@', '(', :params, ')', '->', :do, :exprs, :end].as    { |_, _, params, _, _, _, exprs, _| op.lambda_lambda( op.list_list(*params), exprs)}
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
      r['$', :int].as                 { |_, i|                  op.scope_arg i }
      r['$', :token].as               { |_, token|              op.scope_get token }
      r['$', :token, '=', :expr].as   { |_, token, _, value|    op.scope_set token, value }
      r['$', :token, '||=', :expr].as { |_, token, _, value|  op.cond_if(op.is_nil(op.scope_get(token)), op.scope_set(token, value)) }
      r['$', :token, '.', :token, '.', :token].as                   { |_, bridge, _, namespace, _, token|               op.send(:"#{bridge}_scope_#{namespace}_get", token) }
      r['$', :token, '.', :token, '.', :token, '=', :expr].as       { |_, bridge, _, namespace, _, token, _, value|     op.send(:"#{bridge}_scope_#{namespace}_set", token, value) }
      r['$', :token, '.', :token, '.', :token, '||=', :expr].as     { |_, bridge, _, namespace, _, token, _, value|     op.send(:"#{bridge}_scope_#{namespace}_init", token, value) }
    end

    rule(:literal_expr) do |r|
      r[:single_quoted_string]
      r[:double_quoted_string]
      r[:nil]
      r[:int]
      r[:float]
      r[:list]
      r[:hash]
      r[:regex]
      r[:lambda]
    end

    rule(:lambda_apply) do |r|
      r[:expr, '(', :args, ')'].as  { |lambda, _, args, _|    op.lambda_apply(*([lambda] + args)) }
    end

    rule(:cond_keyworld) do |r|
      r['if']
      r['unless']
    end

    rule(:cond_start) do |r|
      r[:cond_keyworld, '(', :expr, ')'].as { |cond, _, expr, _| op.send(:"cond_#{cond}", expr) }
    end

    rule(:cond_expr) do |r|
      r[:cond_start, :do_exprs].as { |cond_expr, exprs| cond_expr.set_arg(1, exprs) }
      r[:cond_start, :do_exprs, :cond_expr_else].as { |cond_expr, exprs1, exprs2| cond_expr.set_arg(1, exprs1).set_arg(2, exprs2) }
    end

    rule(:cond_expr_else) do |r|
      r['else', :do_exprs].as                                       { |_, exprs| exprs }
      r['elsif', '(', :expr, ')', :do_exprs].as                     { |_, _, cond, _, exprs|            op.cond_if(cond, exprs) }
      r['elsif', '(', :expr, ')', :do_exprs, :cond_expr_else].as    { |_, _, cond, _, exprs1, exprs2|   op.cond_if(cond, exprs1, exprs2) }
    end

    rule(:inline_cond_expr) do |r|
      r[:expr, :cond_start].as { |expr, cond_expr| cond_expr.set_arg(1, expr) }
    end

    rule(:operator_expr) do |r|
      r['(', :expr, ')'].as             { |_, expr, _| op[expr] }
      r['!', :expr].as                  { |_, expr| op.boolean_not(expr) }
      r[:expr, '&&', :expr].as          { |expr1, _, expr2| op.boolean_and(expr1, expr2) }
      r[:expr, '||', :expr].as          { |expr1, _, expr2| op.boolean_or(expr1, expr2) }

      r[:expr, '+', :expr].as              { |expr1, _, expr2| op.arithmetic_adding(expr1, expr2) }
      r[:expr, '-', :expr].as              { |expr1, _, expr2| op.arithmetic_subtracting(expr1, expr2) }
      r[:expr, '*', :expr].as              { |expr1, _, expr2| op.arithmetic_multiplying(expr1, expr2) }
      r[:expr, '/', :expr].as              { |expr1, _, expr2| op.arithmetic_dividing(expr1, expr2) }
      r[:expr, '%', :expr].as              { |expr1, _, expr2| op.arithmetic_remainder(expr1, expr2) }

      r[:expr, '==', :expr].as             { |expr1, _, expr2|    op.compare_eq_to(expr1, expr2) }
      r[:expr, '<', '>', :expr].as         { |expr1, _, _, expr2| op.compare_not_eq_to(expr1, expr2) }
      r[:expr, '!', '=', :expr].as         { |expr1, _, _, expr2| op.compare_not_eq_to(expr1, expr2) }
      r[:expr, '>', :expr].as              { |expr1, _, expr2|    op.compare_gt(expr1, expr2) }
      r[:expr, '>', '=', :expr].as         { |expr1, _, _, expr2| op.compare_gt_or_eq(expr1, expr2) }
      r[:expr, '<', :expr].as              { |expr1, _, expr2|    op.compare_lt(expr1, expr2) }
      r[:expr, '<', '=', :expr].as         { |expr1, _, _, expr2| op.compare_lt_or_eq(expr1, expr2) }

      r[:expr, '?', :expr, ':', :expr].as  { |cond, _, expr1, _, expr2| op.cond_if(cond, expr1, expr2) }
    end

    rule(:macro_symbol) do |r|
      r['=']
      r['||=']
      r['>>']
      r['<<']
    end

    rule(:def_macro) do |r|
      r[:macro_token, :token, :macro_symbol, :expr].as                { |macro_token, token, symbol, macro|         op.macro(macro_token[0..-2], token, macro, symbol) }
      r[:macro_token, :token, :do_exprs].as                           { |macro_token, token, macro|                 op.macro(macro_token[0..-2], token, macro, '=', nil, true) }
      r[:macro_token, :token, '(', :macro_params, ')', :do_exprs].as  { |macro_token, token, _, params, _, macro|   op.macro(macro_token[0..-2], token, macro, '=', params, true) }
    end

    rule(:get_macro) do |r|
      r[:macro_token, '(', :macro_args, ')'].as       { |macro_token, _, args, _| op.macro(macro_token[0..-2], *args) }
      r[:macro_token, '{', :macro_hash_args, '}'].as  { |macro_token, _, args, _| op.macro(:macro_get, macro_token[0..-2], args) }
      r[:macro_token].as                              { |macro_token|             op.macro(:macro_get, macro_token[0..-2]) }
      r[:macro_token, '?=', :expr].as                 { |macro_token, _, default| op.macro(:macro_get, macro_token[0..-2], [], default) }
    end

    rule(:macro_hash_arg) do |r|
      r[:token, ':', :expr].as { |key, _, value| {key => value} }
    end

    rule(:macro_hash_args) do |r|
      r[].as                                                {             {} }
      r[:macro_hash_args, :args_comma].as                   { |ht, _|     ht }
      r[:macro_hash_args, :args_comma, :macro_hash_arg].as  { |ht, _, i|  ht.merge(i) }
      r[:macro_hash_arg].as                                 { |i|         i }
    end

    rule(:macro_args) do |r|
      r[].as                                          {             [] }
      r[:macro_args, :args_comma].as                  { |a, _|      a }
      r[:macro_args, :args_comma, :expr].as           { |a, _, i|   a + [i] }
      r[:expr].as                                     { |i|         [i] }
    end

    rule(:macro_param) do |r|
      r[:token].as                                        { |param|               [param] }
      r[:token, '=', :expr].as                            { |param, _, default|      [param, default] }
    end

    rule(:macro_params) do |r|
      r[].as                                              {             [] }
      r[:macro_params, :args_comma].as                    { |a, _|      a }
      r[:macro_params, :args_comma, :macro_param].as      { |a, _, i|   a + [i] }
      r[:macro_param].as                                  { |i|         [i] }
    end

    rule(:expr) do |r|
      r[:operator_expr]
      r[:scope_expr]
      r[:token, '(', :args, ')'].as { |operator, _, args, _|  op.send(operator, *args) }
      r[:literal_expr]
      r[:do_exprs]
      r[:lambda_apply]
      r[:cond_expr]
      r[:get_macro]
      r[:expr, :list_nth].as { |expr, list_nth| list_nth.set_arg(0, expr) }
      r[:expr, :hash_key].as { |expr, hash_key| hash_key.set_arg(0, expr) }
      r[:expr, :pipeline].as { |expr, pipeline| pipeline.set_arg(0, expr) }
    end

    rule(:do_exprs) do |r|
      r[:do, :exprs, :end].as { |_, exprs, _| exprs }
    end

    rule(:exprs_line) do |r|
      r[:expr].as               { |i| op[i] }
      r[:inline_cond_expr]
      r[:def_macro]
    end

    rule(:exprs) do |r|
      r[].as                    { op }
      r[:exprs, :lb]
      r[:exprs, :lb, :exprs_line].as  do |exprs, _, i| 
        exprs = op[exprs] unless exprs.operator.nil?
        exprs + [i]
      end
      r[:exprs_line]
    end

    start(:exprs)
  end
end