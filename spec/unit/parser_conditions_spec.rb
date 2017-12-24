describe Mudpot::Parser do

  it 'can parse condition block' do
    expect("""
      if ($1) {
        $2
      }
    """).to compiled([111, [122, 1], [122, 2]])

    expect("""
      if ($1) {
        $2
      } else {
        $3
      }
    """).to compiled([111, [122, 1], [122, 2], [122, 3]])

    expect("""
      $var = if ($1) {
        $2
      } else {
        $3
      }
    """).to compiled([121, 'var', [111, [122, 1], [122, 2], [122, 3]]])
  end

  it 'can parse condition inline' do
    expect("$var = 1 unless ($2)").to compiled([113, [122, 2], [121, 'var', 1]])
  end

  it 'can parse condition if elsif' do
     expect("""
      if ($1) {
        $2
      } elsif ($3) {
        $4
      } else {
        $5
      }
    """).to compiled([111, [122, 1], [122, 2], [111, [122, 3], [122, 4], [122, 5]]])

     expect("""
      if ($1) {
        $2
      } elsif ($3) {
        $4
      } elsif ($5) {
        $6
      } else {
        $7
      }
    """).to compiled([111, [122, 1], [122, 2], [111, [122, 3], [122, 4], [111, [122, 5], [122, 6], [122, 7]]]])

     expect("""
      if ($1) {
        $2
      } elsif ($3) {
        $4
      } elsif ($5) {
        $6
      } else {
        if (5) {
          $var = 3
        }
      }
    """).to compiled([111, [122, 1], [122, 2], [111, [122, 3], [122, 4], [111, [122, 5], [122, 6], [111, 5, [121, 'var', 3]]]]])
  end

end