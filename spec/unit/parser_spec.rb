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
  end

  it 'can parse literal hash' do
    expect("@{}").to compiled([600])
    expect("@{'key': 'value'}").to compiled([600, 'key', 'value'])
    expect("@{'key': 'value', 'key2': 'value2'}").to compiled([600, 'key', 'value', 'key2', 'value2'])
    expect("@{'key': 'value', 'key': 'value2'}").to compiled([600, 'key', 'value2'])
  end

  it 'can parse simple operator invoking' do
    expect('scope_get(1)').to compiled([120, 1])
    expect("scope_get(1, '2', 3.3)").to compiled([120, 1, '2', 3.3])
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

end