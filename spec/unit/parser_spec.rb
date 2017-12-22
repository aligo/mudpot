require 'spec_helper'

describe Mudpot::Parser do

  it 'can parse literal' do
    expect('1').to compiled(1)
    expect('0.1').to compiled(0.1)
    expect("'string'").to compiled('string')
  end

  it 'can parse literal list' do
    expect("@['this', 'is', 'list']").to compiled([500, 'this', 'is', 'list'])
    expect("@[]").to compiled([500])
    expect("@[1, nil, 3]").to compiled([500, 1, nil, 3])

    expect("@[
      1
      nil
      3
    ]").to compiled([500, 1, nil, 3])

    expect("@[
      1,
      nil
      3
    ]").to compiled([500, 1, nil, 3])
  end

  it 'can parse list nth' do
    expect("@['this', 'is', 'list'][1]").to compiled([502, [500, 'this', 'is', 'list'], 1])
    expect("$a[1]").to compiled([502, [120, 'a'], 1])
    expect("$a[$2]").to compiled([502, [120, 'a'], [122, 2]])
    expect("$a[1][3]").to compiled([502, [502, [120, 'a'], 1], 3])

    expect("@['this', 'is', 'list'][1] = $3").to compiled([505, [500, 'this', 'is', 'list'], 1, [122, 3]])
    expect("$a[1] = $3").to compiled([505, [120, 'a'], 1, [122, 3]])
  end

  it 'can parse literal hash' do
    expect("@{}").to compiled([600])
    expect("@{'key': 'value'}").to compiled([600, 'key', 'value'])
    expect("@{'key': 'value', 'key2': 'value2'}").to compiled([600, 'key', 'value', 'key2', 'value2'])

    expect("@{
      'key': 'value'
      'key2': 'value2',
      'key3': 'value3'
    }").to compiled([600, 'key', 'value', 'key2', 'value2', 'key3', 'value3'])

    expect("@{'key': 'value', 'key': 'value2'}").to compiled([600, 'key', 'value2'])

    expect("@{'key': 'value', 'key2': @[
      'this', 'is', 'list', @{'and': 'hash'}
    ]}").to compiled([600, 'key', 'value', 'key2', 
      [500, 'this', 'is', 'list',
        [600, 'and', 'hash']
      ]
    ])
  end

  it 'can parse hash key' do
    expect("@{'key': 'value'}{'key'}").to compiled([602, [600, 'key', 'value'], 'key'])
    expect("$a{'xxx'}").to compiled([602, [120, 'a'], 'xxx'])
    expect("$a{$2}").to compiled([602, [120, 'a'], [122, 2]])

    expect("@{'key': 'value'}{'key'} = $3").to compiled([603, [600, 'key', 'value'], 'key', [122, 3]])
    expect("$a{1} = $3").to compiled([603, [120, 'a'], 1, [122, 3]])
  end

  it 'can parse simple operator invoking' do
    expect('do1()').to ast([:do1])
    expect('nil1()').to ast([:nil1])
    expect('scope_get()').to compiled([120])
    expect('scope_get(1)').to compiled([120, 1])
    expect("scope_get(1, '2', 3.3)").to compiled([120, 1, '2', 3.3])
    expect("
      scope_get(1, 
        '2'
        3.3)
    ").to compiled([120, 1, '2', 3.3])
    expect("scope_get(1, nil, 3.3, nil, 'nil')").to compiled([120, 1, nil, 3.3, nil, 'nil'])

    expect('scope_get(scope_get(scope_get(3)))').to compiled([120, [120, [120, 3]]])
    expect('scope_get(1, scope_get(2, scope_get(3)))').to compiled([120, 1, [120, 2, [120, 3]]])
  end

  it 'can parse multiple lines' do
    expect("""
      scope_get(2)
      scope_get(1)
    """).to ast([[:scope_get, 2], [:scope_get, 1]])

    expect("""
      scope_get(2)


      scope_get(1)
    """).to ast([[:scope_get, 2], [:scope_get, 1]])
  end

  it 'can parse do...end exprs' do
     expect("""do scope_get(1) end""").to ast([:scope_get, 1])
     expect("""do scope_get(1); scope_get(2) end""").to ast([[:scope_get, 1],[:scope_get, 2]])
     expect("""do
        scope_get(1)
        scope_get(2)
      end
    """).to ast([[:scope_get, 1],[:scope_get, 2]])
     expect("""do
        scope_get(1)
        scope_get(do
          scope_get(2)
          scope_get(3)
        end)
      end
    """).to ast([[:scope_get, 1],[:scope_get, [[:scope_get, 2],[:scope_get, 3]]]])
  end

  it 'can parse scope getter/setter' do
     expect("$0").to ast([:scope_arg, 0])
     expect("$1").to ast([:scope_arg, 1])

     expect("$var").to ast([:scope_get, 'var'])
     expect("$var = scope_get(2)").to ast([:scope_set, 'var', [:scope_get, 2]])

     expect("$cloud.page.var").to ast([:cloud_scope_page_get, 'var'])
     expect("$cloud.page.var = scope_get(2)").to ast([:cloud_scope_page_set, 'var', [:scope_get, 2]])
  end

  it 'can parse pipeline' do
    expect("$var |> list_nth |> list_nth").to ast([:list_nth, [:list_nth, [:scope_get, 'var']]])
    expect("$var |> list_nth(1) |> list_nth(2)").to ast([:list_nth, [:list_nth, [:scope_get, 'var'], 1], 2])
    expect("$var |> list_nth(1, 2) |> list_nth(3, 4)").to ast([:list_nth, [:list_nth, [:scope_get, 'var'], 1, 2], 3, 4])
  end

  it 'can parse comment' do
    expect("""
      #comment1
      $0 #comment2
    """).to ast([:scope_arg, 0])
  end

  it 'can parse lambda' do
    expect("-> do $3 end").to ast([:lambda_lambda, [:scope_arg, 3]])
    expect("""
      -> do
        $0
        $1
      end
    """).to compiled([130, [[122, 0], [122, 1]]])

    expect("""
      ($arg1, $arg2) -> do
        $arg1
        $arg2
      end
    """).to compiled([130, [500, 'arg1', 'arg2'], [[120, 'arg1'], [120, 'arg2']]])
  end

end