# frozen_string_literal: true

describe Nanoc::Int::Context do
  let(:context) do
    Nanoc::Int::Context.new(foo: 'bar', baz: 'quux')
  end

  it 'provides instance variables' do
    expect(eval('@foo', context.get_binding)).to eq('bar')
  end

  it 'provides instance methods' do
    expect(eval('foo', context.get_binding)).to eq('bar')
  end

  it 'supports #include' do
    eval('include Nanoc::Helpers::HTMLEscape', context.get_binding)
    expect(eval('h("<>")', context.get_binding)).to eq('&lt;&gt;')
  end

  it 'has correct examples' do
    expect('Nanoc::Int::Context#initialize')
      .to have_correct_yard_examples
      .in_file('lib/nanoc/base/entities/context.rb')
  end
end
