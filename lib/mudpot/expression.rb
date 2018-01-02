require 'mudpot/macro_scope'

module Mudpot
  class Expression
    attr_reader :operator, :macro_operator, :args

    class Excluded; end

    def initialize(operator = nil, macro_operator = nil, args = [])
      @operator = operator
      @macro_operator = macro_operator
      @args = args
    end

    def clone
      self.class.new @operator, @macro_operator, args.clone
    end

    def method_missing(method, *args)
      @operator = method.to_s.downcase.to_sym
      @macro_operator = args.shift if @operator == :macro
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
        ops = macro_scope.call_macro @macro_operator, @args
        ast_with ops, compile, operators, macro_scope
      else
        if compile && @operator
          operator = operators[@operator.to_s]
          raise "Unknown Operator '#{@operator}' " if operator.nil?
        else
          operator = @operator
        end
        optimize([ operator ].compact + @args.map do |arg|
          ast_with(arg, compile, operators, macro_scope)
        end)
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

    def optimize(ret)
      ret = ret.reject {|a| a.is_a?(Excluded) }.map {|a| a == [] ? nil : a }
      if ret.count > 0
        case @operator
        when nil
          ret = ret.compact
          ret = ret.first if ret.count == 1
        when :string_concat
          ret = ret[1..-1].join if ret[1..-1].all?{|a| a.is_a?(String) }
        when :hash_table_ht
          ret = [ret[0]] + Hash[ret[1..-1].each_slice(2).to_a].flat_map{|k,v| [k, v]}
        when :list_list
        else
          ret.pop until ret.last
        end
      end
      ret
    end

    def compile(operators, macro_scope = MacroScope.new)
      ast(true, operators, macro_scope)
    end


  end

end