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

    def macro_set(token, macro)
      @macros[token] = macro if token && macro
      [self, nil]
    end

    def macro_init(token, macro)
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