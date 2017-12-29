module Mudpot
  
  class MacroScope
    attr_reader :macros, :shareds

    def initialize(macros = {}, shareds = {})
      @macros   = macros
      @shareds  = shareds
    end

    def clone
      self.class.new @macros.clone, @shareds
    end

    def excluded
      Expression::Excluded.new
    end

    def merge_macros!(macros = {})
      @macros.merge!(macros)
      self
    end

    def [](token)
      @macros[token]
    end

    def []=(token, macro)
      @macros[token] = macro
    end

    def get_shared(key)
      @shareds[key]
    end

    def set_shared(key, value)
      @shareds[key] = value
    end

    def import(file)
      path = File.join(self['_import_base_'], file)
      [self, Compiler.parse_file(path)]
    end

    def macro_set(token, macro, symbol = '=')
      case symbol
      when '||='
        macro_init(token, macro, symbol)
      when '>>', '<<'
        macro_merge(token, macro, symbol)
      else
        @macros[token] = macro if token && macro
        [self, excluded]
      end
    end

    def macro_init(token, macro, symbol = '||=')
      @macros[token] ||= macro if token && macro
      [self, excluded]
    end

    def macro_merge(token, macro, symbol = '>>')
      if token && macro
        if @macros[token] && @macros[token].is_a?(Expression) && macro.is_a?(Expression) && @macros[token].operator == macro.operator
          new_args = symbol == '<<' ?  macro.args + @macros[token].args : @macros[token].args + macro.args
          @macros[token] = Expression.new.send macro.operator, *new_args
        else
          @macros[token] = macro
        end
      end
      [self, excluded]
    end

    def macro_get(token, default = nil, args = {})
      if @macros[token]
        args.merge!({'_macro_name' => token, '_macro_name_prev' => self['_macro_name']}.compact)
        [self.clone.merge_macros!(args), @macros[token]]
      else
        [self, default]
      end
    end


    alias mget macro_get
    alias mset macro_set

  end

end