require 'object_table'
require 'object_table/view'

require 'support/object_table_example'
require 'support/view_example'

describe ObjectTable::View do
  it_behaves_like 'an object table'
  it_behaves_like 'a table view'

  describe '#initialize' do
    let(:table) { ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    context 'when the block takes an argument' do

      it 'should not evaluate in the context of the table' do
        rspec_context = self

        view = ObjectTable::View.new(table) do |tbl|
          receiver = eval('self', binding)
          expect(receiver).to_not be table
          expect(receiver).to be rspec_context
        end
        view.columns # call columns to make it call the block
      end

      it 'should pass the table into the block' do
        view = ObjectTable::View.new(table) do |tbl|
          expect(tbl).to be table
        end
        view.columns # call columns to make it call the block
      end
    end

    context 'when the block takes no arguments' do
      it 'should call the block in the context of the table' do
        _ = self
        view = ObjectTable::View.new(table) do
          receiver = eval('self', binding)
          _.expect(receiver).to _.be _.table
        end
        view.columns # call columns to make it call the block
      end
    end

  end

  context 'with changes to the parent' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    subject{ ObjectTable::View.new(table){ col1 > 2 } }

    it 'should mirror changes to the parent' do
      expect(subject).to eql ObjectTable.new(col1: 3, col2: 5)
      table[:col1] = [5, 6, 7]
      expect(subject).to eql ObjectTable.new(col1: [5, 6, 7], col2: 5)
    end
  end

  context 'with nested views' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:view1){ table.where{col1 > 1} }
    let(:view2){ view1.where{col1 < 3} }

    it 'should add columns correctly' do
      view2[:col3] = 5
      expect(view2.col3.to_a).to eql [5]
      expect(view1.col3.to_a).to eql [5, nil]
      expect(table.col3.to_a).to eql [nil, 5, nil]
    end
  end

  describe '#apply' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 + 100} }

    subject{ ObjectTable::View.new(table){ col1 > 2 } }

    it 'should create a view' do
      view = spy('view')
      expect(ObjectTable::StaticView).to receive(:new).with(table, (table.col1 > 2).where){ view }
      subject.apply(&block)
    end

    it 'should call #apply on the view' do
      view = spy('view')
      expect(ObjectTable::StaticView).to receive(:new){ view }
      expect(view).to receive(:apply) do |&b|
        expect(b).to be block
      end

      subject.apply(&block)
    end
  end

  describe '#cache_indices' do
    let(:table) { ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:view)  { ObjectTable::View.new(table){ col1 > 2 } }

    it 'should yield to the block' do
      expect{|b| view.cache_indices(&b)}.to yield_control
    end
  end

  describe '#cache_columns' do
    let(:table) { ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:view)  { ObjectTable::View.new(table){ col1 > 2 } }

    it 'should yield to the block' do
      expect{|b| view.cache_columns(&b)}.to yield_control
    end
  end

end
