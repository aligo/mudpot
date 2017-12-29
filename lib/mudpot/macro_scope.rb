module Mudpot
  
  class MacroScope
    attr_reader :global, :scope, :parent, :shareds

    def initialize(global = {}, scope = {}, parent = {}, shareds = {})
      @global   = global
      @scope    = scope
      @parent   = parent
      @shareds  = shareds
    end

    def push(new_scope = {})
      self.class.new @global, new_scope, @parent.clone.merge(@scope), @shareds
    end

    def excluded
      Expression::Excluded.new
    end

    def import(file)
      path = File.join(_get('_import_base_'), file)
      [self, Compiler.parse_file(path)]
    end

    def macro_def(token, macro, symbol = '=')
      _set(@global, token, macro, symbol)
    end

    def macro_set(token, macro, symbol = '=')
      _set(@scope, token, macro, symbol)
    end

    def macro_get(token, default = nil, new_scope = {})
      if macro = _get(token)
        new_scope = Hash[new_scope.map do |k, v|
          [k, _extract(v)]
        end]
        [self.push(new_scope), macro]
      else
        [self, default]
      end
    end

    alias mget macro_get
    alias mset macro_set
    alias mdef macro_def

    private

    def _extract(op)
      if op.is_a?(Expression)
        if op.operator == :macro
          _, op = self.send(*op.args)
        end
      end
      op
    end

    def _get(token)
      @scope[token] || @parent[token] || @global[token]
    end

    def _set(scope, token, macro, symbol)
      case symbol
      when '||='
        _init(scope, token, macro, symbol)
      when '>>', '<<'
        _merge(scope, token, macro, symbol)
      else
        scope[token] = macro if token && macro
        [self, excluded]
      end
    end

    def _init(scope, token, macro, symbol)
      scope[token] ||= macro if token && macro
      [self, excluded]
    end

    def _merge(scope, token, macro, symbol = '>>')
      if token && macro
        if scope[token] && scope[token].is_a?(Expression) && macro.is_a?(Expression) && scope[token].operator == macro.operator
          new_args = symbol == '<<' ?  macro.args + scope[token].args : scope[token].args + macro.args
          scope[token] = Expression.new.send macro.operator, *new_args
        else
          scope[token] = macro
        end
      end
      [self, excluded]
    end

  end

end