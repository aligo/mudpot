require 'yaml'
require 'json'

module Mudpot

  module Compiler

    def self.load_operators(path)
      Hash[YAML.load_file(path).map do |key, value|
        [key.downcase.gsub('mud_op_', ''), value]
      end]
    end

    def self.compile(mud, operators)
      Mudpot::Parser.new.parse(mud).compile(operators)
    end

    def self.compile_to_json(mud, operators)
      JSON.generate(self.compile(mud, operators))
    end

  end

end