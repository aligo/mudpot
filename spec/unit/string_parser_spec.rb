describe Mudpot::StringParser do

  it 'can parse basic string' do

    expect(parse_string('')).to eq("")
    expect(parse_string('aaa')).to eq("aaa")
    expect(parse_string('a\naa')).to eq("a\naa")

    expect('"string"').to compiled('string')
    expect('"a\naa"').to compiled("a\naa")
    expect('"a\"aa"').to compiled('a"aa')
  end

  it 'can parse inline mud' do
    expect(parse_string('aa#{$ccc}bbb').ast).to eq([:string_concat, 'aa', [:scope_get, 'ccc'], 'bbb'])

    expect('"#{$ccc}"').to ast([:string_concat, [:scope_get, 'ccc']])
    expect('"aa#{$ccc}"').to ast([:string_concat, 'aa', [:scope_get, 'ccc']])
    expect('"aa#{$ccc}bbb"').to ast([:string_concat, 'aa', [:scope_get, 'ccc'], 'bbb'])
    expect('"aa#{($ccc)}bbb"').to ast([:string_concat, 'aa', [:scope_get, 'ccc'], 'bbb'])
    expect('"aa#{($ccc)}#{$ccc}bbb"').to ast([:string_concat, "aa", [:scope_get, "ccc"], [:scope_get, "ccc"], "bbb"])
    expect('"#{$ccc}"').to ast([:string_concat, [:scope_get, 'ccc']])
    expect('"aa#{$ccc}"').to ast([:string_concat, "aa", [:scope_get, "ccc"]])

    # p parse_string('aa#{@{"aa": "ccc"}{"aa"}}bbb').ast
  end

end