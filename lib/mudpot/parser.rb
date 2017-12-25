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
    rule('/')
    rule('do')
    rule('end')
    rule('if')
    rule('unless')
    rule('elsif')
    rule('else')
    rule('<<')
    rule('>>')

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
    rule(:negative_int => /\-[0-9]+/).as { |i| Integer(i) }
    rule(:float) do |r|
      r[:int, '.', :int].as { |i, _, f| Float("#{i}.#{f}") }
      r[:negative_int, '.', :int].as { |i, _, f| Float("-#{i.abs}.#{f}") }
    end
    rule(:token => /\w+/)
    rule(:single_quoted_string => /'[^']*'/m).as { |s| s[1..-2].gsub(/\n\s*/, "\n") }
    rule(:double_quoted_string => /"(?:\\"|[^"])*"/m).as { |s| StringParser.new.parse(s[1..-2]) }

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

    rule(:regex => /\/(?:\\.|[^\/])*\//).as { |s| op.regex_regex s[1..-2] }

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
      r[:negative_int]
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

    rule(:def_macro) do |r|
      r['<<', :token, '=', :expr].as    { |_, token, _, macro|    op.macro_set(token, macro) }
      r['<<', :token, '||=', :expr].as  { |_, token, _, macro|    op.macro_init(token, macro) }
      r['<<', :token, :do_exprs].as     { |_, token, macro|       op.macro_set(token, macro) }
    end

    rule(:get_macro) do |r|
      r['>>', :token, '<<'].as { |_, token, _| op.macro_get(token) }
      r['>>', :token, '(', :get_macro_args, ')', '<<'].as { |_, token, _, args, _ , _| op.macro_get(token, args) }
    end

    rule(:get_macro_arg) do |r|
      r[:token, ':', :expr].as { |key, _, value| {key => value} }
    end

    rule(:get_macro_args) do |r|
      r[].as                                              {             {} }
      r[:get_macro_args, :args_comma].as                  { |ht, _|     ht }
      r[:get_macro_args, :args_comma, :get_macro_arg].as  { |ht, _, i|  ht.merge(i) }
      r[:get_macro_arg].as                                { |i|         i }
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
      r[:exprs, :lb, :exprs_line].as  { |exprs, _, i| exprs + [i] }
      r[:exprs_line]
    end

    start(:exprs)
  end
end