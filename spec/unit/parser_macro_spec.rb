describe Mudpot::Parser do

  it 'can parse one line macro' do
    expect("""
      macro_set! a = 1
      a!
    """).to ast(1)

    expect("""
      macro_set!('a', 1)
      a!
    """).to ast(1)

    expect("""
      macro_set! a = 1
      scope_get(a!)
    """).to ast([:scope_get, 1])

    expect("""
      macro_set! a = scope_get(1)
      a!
    """).to ast([:scope_get, 1])

    expect("""
      macro_set! a = scope_get(b!)
      a!{b: 1}
    """).to ast([:scope_get, 1])

    expect("""
      macro_set! b = 2
      macro_set! a = scope_get(b!)
      a!{b: 1}
      b!
    """).to ast([[:scope_get, 1], 2])

    expect("""
      macro_set! b = 2
      scope_get(c!, 1, b!, c!, 3)
    """).to ast([:scope_get, nil, 1, 2, nil, 3])
  end

  it 'can parse block macro' do
    expect("""
      macro_set! a do
        $a = str!
      end
      a!{str: 'hello'}
    """).to ast([:scope_set, 'a', 'hello'])

    expect("""
      macro_set! if_macro do
        if (check!) {
          true!
        } else {
          false!
        }
      end
      if_macro!{check: 1, true: 2, false: 3}
    """).to ast([:cond_if, 1, 2, 3])

    expect("""
      macro_set! if_macro do
        if (check!) {
          true!
        } else {
          false!
        }
      end
      macro_set! new_if_macro do
        if_macro!{check: 1}
      end
      new_if_macro!{true: 2, false: 3}
    """).to ast([:cond_if, 1, 2, 3])

    expect("""
      macro_set! if_macro do
        if (check!) {
          true!
        } else {
          false!
        }
      end
      if_macro!{
        check: 1
        true: do
          $a = 1
          $b = 2
        end
        false: 3
      }
    """).to ast([:cond_if, 1, [[:scope_set, 'a', 1], [:scope_set, 'b', 2]], 3])
  end

  it 'can parse init macro' do
    expect("""
      macro_set! a do
        macro_init! str = 'hello'
        $a = str!
      end
      a!
      a!{str: 'world'}
    """).to ast([[:scope_set, 'a', 'hello'], [:scope_set, 'a', 'world']])

    expect("""
      macro_set! a do
        macro_set! str ||= 'hello'
        $a = str!
      end
      a!
      a!{str: 'world'}
    """).to ast([[:scope_set, 'a', 'hello'], [:scope_set, 'a', 'world']])

    expect("""
      macro_set! a do
        3
      end
      macro_set! b do
        macro_set! str ||= 'hello'
        $a = str!
      end
      a!
      b!{str: 'world'}
    """).to ast([3, [:scope_set, 'a', 'world']])

    expect("""
      macro_set! a do
        3
      end
      macro_set! b do
        macro_set! str ||= 'hello'
        $a = str!
      end
      macro_set! c do
        1
      end
      a!
      b!{str: 'world'}
      c!
    """).to ast([3, [:scope_set, 'a', 'world'], 1])
  end



  it 'can parse merge macro' do
    expect("""
      macro_set! a_macro do
        scope_get(data!)
      end
      macro_set! b_macro do
        macro_set! data >> @{}
        a_macro!
      end
      macro_set! c_macro do
        macro_set! data >> @{'k': 'v'}
        b_macro!
      end
      macro_set! d_macro do
        macro_set! data << @{'k': 'v2'}
        b_macro!
      end
      a_macro!
      b_macro!
      c_macro!
      d_macro!
    """).to ast([[:scope_get, nil], [:scope_get, [:hash_table_ht]], [:scope_get, [:hash_table_ht, 'k', 'v']], [:scope_get, [:hash_table_ht, 'k', 'v2', 'k', 'v']]])
  end

end