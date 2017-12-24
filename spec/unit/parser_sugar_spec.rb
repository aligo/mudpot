describe Mudpot::Parser do

  it 'can parse list nth' do
    expect("@['this', 'is', 'list'][1]").to compiled([502, [500, 'this', 'is', 'list'], 1])
    expect("$a[1]").to compiled([502, [120, 'a'], 1])
    expect("$a[$2]").to compiled([502, [120, 'a'], [122, 2]])
    expect("$a[1][3]").to compiled([502, [502, [120, 'a'], 1], 3])

    expect("@['this', 'is', 'list'][1] = $3").to compiled([505, [500, 'this', 'is', 'list'], 1, [122, 3]])
    expect("$a[1] = $3").to compiled([505, [120, 'a'], 1, [122, 3]])
  end

  it 'can parse hash key' do
    expect("@{'key': 'value'}{'key'}").to compiled([602, [600, 'key', 'value'], 'key'])
    expect("$a{'xxx'}").to compiled([602, [120, 'a'], 'xxx'])
    expect("$a{$2}").to compiled([602, [120, 'a'], [122, 2]])

    expect("@{'key': 'value'}{'key'} = $3").to compiled([603, [600, 'key', 'value'], 'key', [122, 3]])
    expect("$a{1} = $3").to compiled([603, [120, 'a'], 1, [122, 3]])
  end

  it 'can parse scope getter/setter' do
     expect("$0").to ast([:scope_arg, 0])
     expect("$1").to ast([:scope_arg, 1])

     expect("$var").to ast([:scope_get, 'var'])
     expect("$var = scope_get(2)").to ast([:scope_set, 'var', [:scope_get, 2]])
     expect("$var ||= scope_get(2)").to ast([:cond_if, [:compare_eq_to, [:cond_if], [:scope_get, 'var']], [:scope_set, 'var', [:scope_get, 2]]])
     expect("$var ||= scope_get(2)").to compiled([111, [290, [111], [120, 'var']], [121, 'var', [120, 2]]])

     expect("$cloud.page.var").to ast([:cloud_scope_page_get, 'var'])
     expect("$cloud.page.var = scope_get(2)").to ast([:cloud_scope_page_set, 'var', [:scope_get, 2]])
     expect("$cloud.page.var ||= scope_get(2)").to ast([:cloud_scope_page_init, 'var', [:scope_get, 2]])
  end

  it 'can parse pipeline' do
    expect("$var |> list_nth |> list_nth").to ast([:list_nth, [:list_nth, [:scope_get, 'var']]])
    expect("$var |> list_nth(1) |> list_nth(2)").to ast([:list_nth, [:list_nth, [:scope_get, 'var'], 1], 2])
    expect("$var |> list_nth(1, 2) |> list_nth(3, 4)").to ast([:list_nth, [:list_nth, [:scope_get, 'var'], 1, 2], 3, 4])
  end

end