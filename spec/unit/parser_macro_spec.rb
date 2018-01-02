describe Mudpot::Parser do

  it 'can parse set macro one line' do
    expect("""
      macro_set! a = 1
      a!
    """).to ast(1)

    expect("""
      mset! a = 1
      scope_get(a!)
    """).to ast([:scope_get, 1])

    expect("""
      mset! a = scope_get(1)
      a!
    """).to ast([:scope_get, 1])
  end

  it 'can parse def macro' do
    expect("""
      macro_def! a = 1
      macro_set! b = a!
      macro_set! c = b!
      @[a!, b!, c!]
    """).to ast([:list_list, 1, 1, nil])
  end

  it 'can parse set macro block' do
    expect("""
      macro_set! a (str) do
        $a = str!
      end
      a!('hello')
    """).to ast([:scope_set, 'a', 'hello'])

    expect("""
      macro_set! a (str = 'zzz') do
        $a = str!
      end
      a!
      a!('hello')
    """).to ast([[:scope_set, 'a', 'zzz'] ,[:scope_set, 'a', 'hello']])

    expect("""
      macro_set! a (v1 = 1, v2 = 2) do
        @[v1!, v2!]
      end
      a!
      a!(nil, 3)
      a!(3)
    """).to ast([[:list_list, 1, 2], [:list_list, 1, 3], [:list_list, 3, 2]])

    expect("""
      mdef! a (v = 1) do
        v!
      end
      mdef! b (v = 2) do
        a!
        a!(3)
        v!
      end
      a!
      a!(2)
      b!
      b!(a!)
      b!(a!(4))
      b!(a!(b!))
    """).to ast([1, 2, [1, 3, 2], [1, 3, 1], [1, 3, 4], [1, 3, [1, 3, 2]]])
  end

  it 'can extract macro args' do
    expect("""
      mset! a = 1
      mdef! b (value) do
        value!
      end
      b!(a!)
    """).to ast(1)
    expect("""
      mdef! a (value) do
        value!
      end
      mdef! b (value) do
        a!(value!)
      end
      a!(1)
      b!(2)
    """).to ast([1, 2])
  end

  it 'can parse init macro' do 
    expect("""
      macro_set! a (str) do
        mset! str ||= 'hello'
        $a = str!
      end
      a!
      a!('world')
    """).to ast([[:scope_set, 'a', 'hello'], [:scope_set, 'a', 'world']])

    expect("""
      mdef! str = 'hello'
      macro_set! a (str) do
        str!
      end
      macro_set! b (str) do
        mset! str ||= 'the'
        str!
      end
      a!
      b!
      a!('world')
      b!('yes')
    """).to ast(['hello', 'the', 'world', 'yes'])
  end


  it 'can parse merge macro' do
    expect("""
      mset! a = @{'k': 'v'}
      mset! a << @{'k2': 'v2'}
      a!
      mset! b = @{'k': 'v'}
      mset! b >> @{'k2': 'v2'}
      b!
    """).to ast([[:hash_table_ht, 'k', 'v', 'k2', 'v2'], [:hash_table_ht, 'k2', 'v2', 'k', 'v']])

    expect("""
      mset! a = @{'k': 'v1'}
      mset! a << @{'k': 'v2'}
      a!
      mset! b = @{'k': 'v1'}
      mset! b >> @{'k': 'v2'}
      b!
    """).to ast([[:hash_table_ht, 'k', 'v2'], [:hash_table_ht, 'k', 'v1']])

    expect("""
      mdef! a_macro (data) do
        scope_get(data!)
      end
      mdef! b_macro (data) do
        mset! data >> @{}
        a_macro!(data!)
      end
      mdef! c_macro (data) do
        mset! data >> @{'k': 'v'}
        b_macro!(data!)
      end
      mdef! d_macro (data) do
        mset! data << @{'k': 'v2'}
        b_macro!(data!)
      end
      mdef! e_macro (data) do
        mset! data >> @{'k': 'v2'}
        a_macro!(data!)
      end
      a_macro!
      b_macro!
      c_macro!
      d_macro!
      e_macro!(@{'k': 'v'})
    """).to ast([
      [:scope_get],
      [:scope_get, [:hash_table_ht]], 
      [:scope_get, [:hash_table_ht, 'k', 'v']],
      [:scope_get, [:hash_table_ht, 'k', 'v2']],
      [:scope_get, [:hash_table_ht, 'k', 'v']]
    ])
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
    """).to ast(['hello', 'hello', [:list_list, 'hello', nil]])


    expect("""
      mdef! a (input) do
        input!
      end
      mdef! b (input) do
        a!(input!?=@{'k': 'v'})
      end
      mdef! c (input) do
        b!(@{'k2': input!})
      end
      @[
        a!
        b!
        c!('v2')
      ]
    """).to ast([:list_list, nil, [:hash_table_ht, 'k', 'v'], [:hash_table_ht, 'k2', 'v2']])
  end

  it 'can pass hash args' do
    expect("""
      mdef! a (input) do
        input!
      end
      mdef! b (a,b) do
        @[a!,b!]
      end
      a!{input: '1'}
      b!{a: 1, b: 2}
    """).to ast(['1', [:list_list, 1, 2]])
  end

end