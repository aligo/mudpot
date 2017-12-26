module Mudpot
  
  class MacroScope
    attr_reader :macros, :shareds

    def initialize(macros = {}, shareds = {})
      @macros   = macros
      @shareds  = shareds
    end

    def clone
      MacroScope.new @macros.clone, @shareds
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
      if symbol == '||='
        macro_init(token, macro, symbol)
      else
        @macros[token] = macro if token && macro
        [self, nil]
      end
    end

    def macro_init(token, macro, symbol = '||=')
      @macros[token] ||= macro if token && macro
      [self, nil]
    end

    def macro_get(token, args = nil)
      if @macros[token]
        if args
          [self.clone.merge_macros!(args), @macros[token]]
        else
          [self, @macros[token]]
        end
      else
        [self, nil]
      end
    end

  end

end