# frozen_string_literal: true

describe Nanoc::Int::PrefixedDataSource, stdio: true do
  let(:klass) do
    Class.new(Nanoc::DataSource) do
      def item_changes
        [
          [:some_type, :item, Nanoc::Identifier.new('/item')],
          [:some_type, :item, Nanoc::Identifier.new('/item_other')],
        ]
      end

      def layout_changes
        [
          [:some_type, :layout, Nanoc::Identifier.new('/layout')],
          [:some_type, :layout, Nanoc::Identifier.new('/layout_other')],
        ]
      end
    end
  end

  let(:original_data_source) do
    klass.new({}, nil, nil, {})
  end

  subject(:data_source) do
    described_class.new(original_data_source, '/itemz', '/layoutz')
  end

  describe '#item_changes' do
    subject { data_source.item_changes }

    it 'yields changes from the original' do
      expected =
        [
          [:some_type, :item, Nanoc::Identifier.new('/itemz/item')],
          [:some_type, :item, Nanoc::Identifier.new('/itemz/item_other')],
        ]

      expect(subject).to eq(expected)
    end
  end

  describe '#layout_changes' do
    subject { data_source.layout_changes }

    it 'yields changes from the original' do
      expected =
        [
          [:some_type, :layout, Nanoc::Identifier.new('/layoutz/layout')],
          [:some_type, :layout, Nanoc::Identifier.new('/layoutz/layout_other')],
        ]

      expect(subject).to eq(expected)
    end
  end
end
