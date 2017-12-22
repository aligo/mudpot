require 'spec_helper'

describe Mudpot::Parser do

  it 'can parse literal' do
    expect('1').to compiled(1)
    expect('0.1').to compiled(0.1)
    expect("'string'").to compiled('string')
  end

  it 'can parse simple operator invoking' do
    expect('scope_get(1)').to compiled([120, 1])
    expect("scope_get(1, '2', 3.3)").to compiled([120, 1, '2', 3.3])

    expect('scope_get(scope_get(scope_get(3)))').to compiled([120, [120, [120, 3]]])
    expect('scope_get(1, scope_get(2, scope_get(3)))').to compiled([120, 1, [120, 2, [120, 3]]])
  end

  it 'can parse multiple lines' do
    expect("""
      scope_get(2)
      scope_get(1)
    """).to ast([[:scope_get, 2], [:scope_get, 1]])

    expect("""
      scope_get(
        scope_get(2)
        scope_get(3)
      )
      scope_get(1)
    """).to ast([
      [:scope_get, 
        [
          [:scope_get, 2], 
          [:scope_get, 3]
        ]
      ], 
      [:scope_get, 1]
    ])
  end

end