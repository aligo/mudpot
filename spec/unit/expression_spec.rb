require 'spec_helper'

describe Mudpot::Expression do

  it 'should can get ast' do
    expect(op.scope_get('a')).to ast([:scope_get, 'a'])
  end

  it 'should can be compiled' do
    expect(op.scope_get('a')).to compiled([120, 'a'])
  end


end