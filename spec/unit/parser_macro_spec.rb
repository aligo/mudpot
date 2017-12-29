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
      macro_def! if_macro do
        if (check!) {
          true!
        } else {
          false!
        }
      end
      macro_def! new_if_macro do
        if_macro!{check: 1, true: true!, false: false!}
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
        mset! str ||= 'hello'
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
      mdef! a_macro do
        scope_get(data!)
      end
      mdef! b_macro do
        mset! data >> @{}
        a_macro!{data: data!}
      end
      mdef! c_macro do
        mset! data >> @{'k': 'v'}
        b_macro!{data: data!}
      end
      mdef! d_macro do
        mset! data << @{'k': 'v2'}
        b_macro!{data: data!}
      end
      mdef! e_macro do
        mset! data << @{'k': 'v2'}
        c_macro!{data: data!}
      end
      a_macro!
      b_macro!
      c_macro!
      d_macro!
      e_macro!
    """).to ast([
      [:scope_get, nil],
      [:scope_get, [:hash_table_ht]], 
      [:scope_get, [:hash_table_ht, 'k', 'v']],
      [:scope_get, [:hash_table_ht, 'k', 'v2']],
      [:scope_get, [:hash_table_ht, 'k', 'v']]
    ])
  end

  it 'can parse alias mget mset' do
    expect("""
      mset! a = 'ccc'
      a!
      mget!(a)
    """).to ast(['ccc', 'ccc'])
  end

  it 'can parse alias mget with default' do
    expect("""
      mset! c = 'ccc'
      a!?='ccc'
      b!?='ccc'
      c!?='bbb'
    """).to ast(['ccc', 'ccc', 'ccc'])
  end

  it 'can handle macro scope' do
    expect("""
      mdef! a = 'hello'
      mset! b = 'hello'
      a!
      b!
      mset! c = a!
      mset! d = b!
      @[c!, d!]
    """).to ast(['hello', 'hello', [:list_list, 'hello', 'hello']])

    expect("""
      mdef! a = str!
      mdef! b = a!
      mdef! c = a!{str: str!}
      mdef! d do
        mset! str = 'hello'
        a!
      end
      mdef! e do
        mset! str = 'hello'
        a!{str: str!}
      end
      @[
        a!{str: 'hello'}
        b!{str: 'hello'}
        c!{str: 'hello'}
        d!
        e!
      ]
    """).to ast([:list_list, 'hello', 'hello', 'hello', 'hello', 'hello'])

    expect("""
      mdef! a do
        input!
      end
      mdef! b do
        a!{input: input!?=@{'k': 'v'}}
      end
      mdef! c do
        b!{input: @{'k2': value!}}
      end
      @[
        a!
        b!
        c!{value: 'v2'}
      ]
    """).to ast([:list_list, nil, [:hash_table_ht, 'k', 'v'], [:hash_table_ht, 'k2', 'v2']])
  end

  it 'can get _macro_name and _macro_name_prev' do
    expect("""
      mdef! a = _macro_name!
      mdef! b = _macro_name_prev!
      mdef! c = b!
      mdef! d do
        a!
        b!
        c!
      end
      @[
        _macro_name!
        _macro_name_prev!
        a!
        b!
        c!
        d!
      ]
    """).to ast([:list_list, nil, nil, 'a', nil, 'c', ['a', 'd', 'c']])
  end

end