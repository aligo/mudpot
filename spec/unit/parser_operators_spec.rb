describe Mudpot::Parser do

  it 'can parse boolean operators' do
    expect("!$var").to compiled([190, [120, 'var']])
    expect("!($var)").to compiled([190, [120, 'var']])


    expect("$var1 && $var2").to compiled([191, [120, 'var1'], [120, 'var2']])
    expect("$var1 || $var2").to compiled([192, [120, 'var1'], [120, 'var2']])
  end

end