describe Mudpot::Compiler do

  it 'should can import' do

    source_file = File.join(File.dirname(__FILE__), '../fixtures/test.mud')
    macro_scope = Mudpot::MacroScope.new
    macro_scope['_import_base_'] = File.dirname(source_file)

    expect(JSON.parse(Mudpot::Compiler.compile_to_json(source_file, operators, macro_scope))).to eq([[], [121, "var", "cccc"], 1])
  end


end