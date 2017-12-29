describe Mudpot::Expression do

  it 'should can get ast' do
    expect(op.scope_get('a')).to ast([:scope_get, 'a'])
  end

  it 'should can be compiled' do
    expect(op.scope_get('a')).to compiled([120, 'a'])
  end

  it 'should can be optimize' do
    expect(op[]).to compiled([])
    expect(op.string_concat('aa', 'bb')).to compiled('aabb')
    expect(op.hash_table_ht('aa', 'bb', 'aa', 'cc')).to compiled([600, 'aa', 'cc'])
    expect(op.hash_table_ht('aa', 'bb', 'aa', 'cc', op.scope_get('a'), 'bb', op.scope_get('a'), 'cc')).to compiled([600, 'aa', 'cc', [120, 'a'], 'cc'])
    expect(op.hash_table_ht(op.scope_get('a'), 'bb', op.scope_get('a'), 'cc', op.scope_get('b'), 'cc')).to compiled([600, [120, 'a'], 'cc', [120, 'b'], 'cc'])
  end

end