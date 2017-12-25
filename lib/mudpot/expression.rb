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

    def ast(compile = false, operators = {}, macros = {})
      if @operator == :macro_set
        macros[@args[0]] = @args[1]
        Excluded.new
      elsif @operator == :macro_init
        macros[@args[0]] ||= @args[1]
        Excluded.new
      elsif @operator == :macro_get
        new_macros = macros.clone
        new_macros.merge!(@args[1]) if @args[1]
        ast_with((macros[@args[0]] || Excluded.new), compile, operators, new_macros)
      else
        if compile && @operator
          operator = operators[@operator.to_s]
          raise "Unknown Operator '#{@operator}' " if operator.nil?
        else
          operator = @operator
        end
        ret = [ operator ].compact + @args.map do |arg|
          ast_with(arg, compile, operators, macros)
        end.reject {|a| a.is_a?(Excluded) } 
        if ret.count == 1 && !@operator
          ret.first
        else
          ret
        end
      end
    end

    def ast_with(arg, compile, operators, macros = {})
      if arg.is_a? Expression
        arg.ast(compile, operators, macros)
      elsif arg.is_a?(Integer) || arg.is_a?(Float) || arg.is_a?(String) || arg.is_a?(Symbol) || arg.is_a?(TrueClass) || arg.is_a?(FalseClass)
        arg
      end
    end

    def compile(operators)
      ast(true, operators, {})
    end


  end

end