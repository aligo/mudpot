require 'yaml'
require 'json'

module Mudpot

  module Compiler

    def self.load_operators(path)
      Hash[YAML.load_file(path).map do |key, value|
        [key.downcase.gsub('mud_op_', ''), value]
      end]
    end

    def self.parse_file(path)
      Mudpot::Parser.new.parse File.open(path).read
    end

    def self.compile(path, operators, macro_scope = MacroScope.new)
      mud = parse_file path
      mud.compile(operators, macro_scope)
    end

    def self.compile_to_json(path, operators, macro_scope = MacroScope.new)
      JSON.generate(self.compile(path, operators, macro_scope))
    end

  end

end