describe Mudpot::Parser do

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
     expect("""{
        scope_get(1)
        scope_get(2)
      }
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

  it 'can parse comment' do
    expect("""
      #comment1
      $0 #comment2
    """).to ast([:scope_arg, 0])
  end

  it 'can parse lambda' do
    expect("@-> do $3 end").to ast([:lambda_lambda, [:scope_arg, 3]])
    expect("@()-> do $3 end").to ast([:lambda_lambda, [:list_list], [:scope_arg, 3]])
    expect("""
      @-> do
        $0
        $1
      end
    """).to compiled([130, [[122, 0], [122, 1]]])

    expect("""
      @($arg1, $arg2) -> {
        $arg1
        $arg2
      }
    """).to compiled([130, [500, 'arg1', 'arg2'], [[120, 'arg1'], [120, 'arg2']]])

    expect("@-> do $3 end()").to ast([:lambda_apply, [:lambda_lambda, [:scope_arg, 3]]])
    expect("@-> { $3 }(2)").to ast([:lambda_apply, [:lambda_lambda, [:scope_arg, 3]], 2])
    expect("$1(2, 3)").to ast([:lambda_apply, [:scope_arg, 1], 2, 3])
  end

end