describe Mudpot::StringParser do

  it 'can parse basic string' do
    expect(parse_string('aaa')).to eq("aaa")
    expect(parse_string('a\naa')).to eq("a\naa")

    expect('"string"').to compiled('string')
    expect('"a\naa"').to compiled("a\naa")
    expect('"a\"aa"').to compiled('a"aa')
  end

end