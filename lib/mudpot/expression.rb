module Mudpot
  class Expression

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

    def lambda(*args)
      @args = args
      @operator = @operators['lambda_lambda']
      self
    end

    def ast(compile = false, operators = {})
      if compile && @operator
        operator = operators[@operator.to_s]
        raise "Unknown Operator '#{@operator}' " if operator.nil?
      else
        operator = @operator
      end
      ret = [ operator ].compact + @args.map do |arg|
        ast_with(arg, compile, operators)
      end
      if ret.count == 1 && !@operator
        ret.first
      else
        ret
      end
    end

    def ast_with(arg, compile, operators)
      if arg.is_a? Expression
        arg.ast(compile, operators)
      elsif arg.is_a?(Integer) || arg.is_a?(Float) || arg.is_a?(String) || arg.is_a?(Symbol) || arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
        arg
      end
    end

    def compile(operators)
      ast(true, operators)
    end


  end

end