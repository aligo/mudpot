describe Mudpot::Parser do

  it 'can parse literal' do
    expect('1').to compiled(1)
    expect('-1').to compiled(-1)
    expect('0.1').to compiled(0.1)
    expect('-0.1').to compiled(-0.1)
    expect('-99.1').to compiled(-99.1)
    expect("'string'").to compiled('string')
    expect("""
      'str
      ing'
    """).to compiled("str\ning")
  end

  it 'can parse literal list' do
    expect("@['this', 'is', 'list']").to compiled([500, 'this', 'is', 'list'])
    expect("@[]").to compiled([500])
    expect("@[1, nil, 3]").to compiled([500, 1, nil, 3])

    expect("""
      @[
      ]
    """).to compiled([500])

    expect("""
      @[
        1
      ]
    """).to compiled([500, 1])

    expect("""
      @[
        1
        nil
        3
      ]
    """).to compiled([500, 1, nil, 3])

    expect("""
      @[
        1,
        nil
        3
      ]
    """).to compiled([500, 1, nil, 3])

    expect("""
      @[
        1,nil
        3
      ]
      """).to compiled([500, 1, nil, 3])

    expect("""
      @[
        1,nil
        3
      ]
      """).to compiled([500, 1, nil, 3])
  end

  it 'can parse literal hash' do
    expect("@{}").to compiled([600])
    expect("@{'key': 'value'}").to compiled([600, 'key', 'value'])
    expect("@{'key': 'value', 'key2': 'value2'}").to compiled([600, 'key', 'value', 'key2', 'value2'])

    expect("""
      @{
        'key': 'value'
        'key2': 'value2',
        'key3': 'value3'
      }
    """).to compiled([600, 'key', 'value', 'key2', 'value2', 'key3', 'value3'])

    expect("""
      @{
        'key': 'value'
      }
    """).to compiled([600, 'key', 'value'])

    expect("@{'key': 'value', 'key': 'value2'}").to compiled([600, 'key', 'value2'])

    expect("@{'key': 'value', 'key2': @[
      'this', 'is', 'list', @{'and': 'hash'}
    ]}").to compiled([600, 'key', 'value', 'key2', 
      [500, 'this', 'is', 'list',
        [600, 'and', 'hash']
      ]
    ])
  end

  it 'can parse regex' do
    expect("/[^[:space:]]+/").to ast([:regex_regex, '[^[:space:]]+'])
    expect('/[^\/]+/').to ast([:regex_regex, '[^\/]+'])
  end

end