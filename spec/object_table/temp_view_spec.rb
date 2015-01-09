require 'object_table'
require 'object_table/temp_view'

require 'support/object_table_example'
require 'support/view_example'

describe ObjectTable::TempView do
  it_behaves_like 'an object table', ObjectTable::TempView
  it_behaves_like 'a table view', ObjectTable::TempView

  context 'with changes to the parent' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    subject{ ObjectTable::TempView.new(table){ col1 > 2 } }

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

    subject{ ObjectTable::TempView.new(table){ col1 > 2 } }

    it 'should create a view' do
      view = spy('view')
      expect(ObjectTable::View).to receive(:new).with(table, (table.col1 > 2).where){ view }
      subject.apply(&block)
    end

    it 'should call #apply on the view' do
      view = spy('view')
      expect(ObjectTable::View).to receive(:new){ view }
      expect(view).to receive(:apply) do |&b|
        expect(b).to be block
      end

      subject.apply(&block)
    end
  end

  describe '#group' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 + 100} }

    subject{ ObjectTable::TempView.new(table){ col1 > 2 } }

    it 'should create a view' do
      view = spy('view')
      expect(ObjectTable::View).to receive(:new).with(table, (table.col1 > 2).where){ view }
      subject.group(&block)
    end

    it 'should call #group on the view' do
      view = spy('view')
      expect(ObjectTable::View).to receive(:new){ view }
      expect(view).to receive(:group) do |&b|
        expect(b).to be block
      end

      subject.group(&block)
    end
  end

end
