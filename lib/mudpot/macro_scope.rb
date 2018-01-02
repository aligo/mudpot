module Mudpot
  
  class MacroScope

    attr_reader :global, :shareds, :scope

    @@macro_methods = []

    def self.define_macro(*macro_names, &block)
      @@macro_methods += macro_names
      define_method(macro_names[0].to_sym, block)
      macro_names[1..-1].each do |macro_name|
        alias_method macro_name, macro_names[0]
      end
    end

    def initialize(global = {}, shareds = {})
      @global   = global
      @shareds  = shareds
      @scope    = {}
    end

    def push
      self.class.new @global, @shareds
    end

    def excluded
      Expression::Excluded.new
    end

    def call_macro(method, args)
      if @@macro_methods.include?(method.to_sym)
        send method.to_sym, *args
      else
        macro_get method.to_s, args
      end
    end

    define_macro :import do |file|
      path = File.join(_get('_import_base_')[:body], file)
      Compiler.parse_file(path)
    end

    define_macro :macro_get, :mget do |token, args = [], default = nil|
      if macro = _get(token)
        new_scope = self.push
        if macro[:params]
          macro[:params].each.with_index do |param, i|
            value = (args.is_a?(Hash) ? args[param[0]] : args[i])
            value = extract(value) if value.is_a?(Expression)
            value ||= param[1]
            new_scope.macro_set(param[0], value) if value
          end
        end
        ret = new_scope.extract(macro[:body])
        ret
      else
        default
      end
    end

    define_macro :macro_set, :mset do |token, macro, symbol = '=', params = nil, block = nil|
      _set(@scope,  token, macro, symbol, params, block)
    end

    define_macro :macro_def, :mdef do |token, macro, symbol = '=', params = nil, block = nil|
      _set(@global, token, macro, symbol, params, block)
    end

    def set_global(token, value)
      _set(@global, token, value)
    end

    def extract(op)
      if op.is_a?(Expression)
        op = op.clone
        op.args.map.with_index {|a, i| op.set_arg(i, extract(a)) }
        if op.operator == :macro
          op = call_macro op.macro_operator, op.args
        end
      elsif op.is_a?(Array)
        op = op.map{|a| extract(a)}
      end
      op
    end

    private

    def _get(token)
      @scope[token] || @global[token]
    end

    def _set(scope, token, macro, symbol = '=', params = nil, block = nil)
      if params
        params.map! do |param|
          param[1] ? [param[0], extract(param[1])] : param
        end
      end
      macro = extract(macro) unless block
      macro = { body: macro, params: params }.compact
      case symbol
      when '||='
        scope[token] ||= macro
        excluded
      when '>>', '<<'
        if scope_macro = _get(token)
          if scope_macro[:body].is_a?(Expression) && macro[:body].is_a?(Expression) && scope_macro[:body].operator == macro[:body].operator
            new_args = ( symbol == '<<' ) ?  scope_macro[:body].args + macro[:body].args : macro[:body].args + scope_macro[:body].args
            macro[:body] = Expression.new.send scope_macro[:body].operator, *new_args
          end
        end
        scope[token] = macro
        excluded
      else
        scope[token] = macro
        excluded
      end
    end

  end

end