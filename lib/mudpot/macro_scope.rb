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

    def method_missing(method, *args)
      macro_get method.to_s, args
    end

    def excluded
      Expression::Excluded.new
    end

    def call_macro(method, *args)
      if @@macro_methods.include?(method.to_sym)
        send method.to_sym, *args
      else
        macro_get method.to_s, args
      end
    end

    define_macro :import do |file|
      path = File.join(_get('_import_base_')[:body], file)
      [self, Compiler.parse_file(path)]
    end

    define_macro :macro_get, :mget do |token, args = [], default = nil|
      macro_apply(_get(token), args, default)
    end

    define_macro :macro_set, :mset do |token, macro, symbol = '=', params = nil|
      _set(@scope,  token, macro, symbol, params)
    end

    define_macro :macro_def, :mdef do |token, macro, symbol = '=', params = nil|
      _set(@global, token, macro, symbol, params)
    end

    define_macro :macro_apply, :mapply do |macro, args = [], default = nil|
      if macro
        new_scope = self.push
        if macro[:params]
          macro[:params].each.with_index do |param, i|
            value = (args.is_a?(Hash) ? args[param[0]] : args[i]) || param[1]
            new_scope.macro_set(param[0], _extract(value)) if value
          end
        end
        [new_scope, macro[:body]]
      else
        [self, default]
      end
    end

    def set_global(token, value)
      _set(@global, token, value)
    end

    private

    def _extract(op)
      if op.is_a?(Expression)
        if op.operator == :macro && [:mget, :macro_get].include?(op.args[0].to_sym)
          op = Expression.new.macro :macro_apply, _get(op.args[1]), *op.args[2..-1]
        else
          op.args.map!{|a| _extract(a) }
        end
      end
      op
    end

    def _get(token)
      @scope[token] || @global[token]
    end

    def _set(scope, token, macro, symbol = '=', params = nil)
      macro = { body: macro, params: params }.compact
      case symbol
      when '||='
        scope[token] ||= macro
      when '>>', '<<'
        if scope_macro = _get(token)
          if scope_macro[:body].operator == :macro && scope_macro[:body].args[0] == :macro_apply
            _, scope_macro[:body] = call_macro(*scope_macro[:body].args)
          end
          if scope_macro[:body].is_a?(Expression) && macro[:body].is_a?(Expression) && scope_macro[:body].operator == macro[:body].operator
            new_args = ( symbol == '<<' ) ?  scope_macro[:body].args + macro[:body].args : macro[:body].args + scope_macro[:body].args
            macro[:body] = Expression.new.send scope_macro[:body].operator, *new_args
          end
        end
        scope[token] = macro
        [self, excluded]
      else
        scope[token] = macro
        [self, excluded]
      end
    end

  end

end