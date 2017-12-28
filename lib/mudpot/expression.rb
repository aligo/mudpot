require 'mudpot/macro_scope'

module Mudpot
  class Expression
    attr_reader :operator, :args

    class Excluded; end

    def initialize
      @operator = nil
      @args = []
    end

    def method_missing(method, *args)
      @operator = method.to_s.downcase.to_sym
      @args = args
      self
    end

    def is_nil(arg)
      Expression.new.compare_eq_to(Expression.new.cond_if, arg)
    end

    def [](*args)
      @args += args
      self
    end

    def +(args)
      @args += args
      self
    end

    def set_arg(i, v)
      @args[i] = v
      self
    end

    def ast(compile = false, operators = {}, macro_scope = MacroScope.new)
      if @operator == :macro
        macro_scope, ops = macro_scope.send(*@args)
        unless ops.nil? || ops.is_a?(Excluded)
          ast_with(ops, compile, operators, macro_scope)
        else
          ops
        end
      else
        if compile && @operator
          operator = operators[@operator.to_s]
          raise "Unknown Operator '#{@operator}' " if operator.nil?
        else
          operator = @operator
        end
        ret = [ operator ].compact + @args.map do |arg|
          ast_with(arg, compile, operators, macro_scope)
        end.reject {|a| a.is_a?(Excluded) }
        if ret.count == 1 && !@operator
          ret.first
        else
          ret
        end
      end
    end

    def ast_with(arg, compile, operators, macro_scope = MacroScope.new)
      if ( arg.is_a? Expression ) && ( arg.operator.nil? ) && ( arg.args.count == 1 )
        arg = arg.args[0] 
      end
      if arg.is_a? Expression
        arg.ast(compile, operators, macro_scope)
      elsif arg.is_a?(Integer) || arg.is_a?(Float) || arg.is_a?(String) || arg.is_a?(Symbol) || arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
        arg
      end
    end

    def compile(operators, macro_scope = MacroScope.new)
      ast(true, operators, macro_scope)
    end


  end

end