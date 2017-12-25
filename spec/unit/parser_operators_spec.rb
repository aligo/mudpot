describe Mudpot::Parser do

  it 'can parse boolean operators' do
    expect("!$var").to compiled([190, [120, 'var']])
    expect("!($var)").to compiled([190, [120, 'var']])


    expect("$var1 && $var2").to compiled([191, [120, 'var1'], [120, 'var2']])
    expect("$var1 || $var2").to compiled([192, [120, 'var1'], [120, 'var2']])

    expect("$var1 && $var2 && $var3").to compiled([191, [191, [120, 'var1'], [120, 'var2']], [120, 'var3']])
  end

  it 'can parse arithmetic operators' do
    expect("$var1 + $var2").to compiled([200, [120, 'var1'], [120, 'var2']])
    expect("$var1 - $var2").to compiled([201, [120, 'var1'], [120, 'var2']])
    expect("$var1 * $var2").to compiled([202, [120, 'var1'], [120, 'var2']])
    expect("$var1 / $var2").to compiled([203, [120, 'var1'], [120, 'var2']])
    expect("$var1 % $var2").to compiled([204, [120, 'var1'], [120, 'var2']])

    expect("1 + 2 * 3").to compiled([200, 1, [202, 2, 3]])
    expect("(1 + 2) * 3").to compiled([202, [200, 1, 2], 3])
    expect("1 + 2 + 3").to compiled([200, [200, 1, 2], 3])
  end

end