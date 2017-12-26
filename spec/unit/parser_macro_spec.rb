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
  end

end