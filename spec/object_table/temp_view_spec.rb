require 'object_table'
require 'object_table/temp_view'

require 'support/object_table_example'

describe ObjectTable::TempView do
  it_behaves_like 'an object table', ObjectTable::TempView

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

  describe '#columns' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    subject{ ObjectTable::TempView.new(table){ col1 > 2 } }

    it 'should mask the columns of the parent table' do
      mask = table.col1 > 2
      table.columns.each do |k, v|
        expect(subject.columns[k].to_a).to eql v[mask].to_a
      end
    end
  end

  describe '#set_column' do
    let(:table) { ObjectTable.new(col1: [0, 1, 2, 3], col2: 5) }
    let(:view)  { ObjectTable::TempView.new(table){ col1 > 0 } }

    let(:column){ :col2 }
    let(:value) { [10, 20, 30] }
    let(:args)  { [] }

    subject{ view.set_column(column, value, *args) }

    context 'on an existing column' do
      it 'should assign values to the column' do
        subject
        expect(view.columns[column].to_a).to eql value
      end

      it 'should not modify anything outside the view' do
        subject
        expect(table.columns[column].to_a).to eql [5] + value
      end

    end

    context 'with a scalar' do
      let(:value){ 10 }
      it 'should fill the column with that value' do
        subject
        expect(view.columns[column].to_a).to eql ([value] * view.nrows)
      end
    end

    context 'with a range' do
      let(:value){ 0...3 }
      it 'should assign the range values' do
        subject
        expect(view.columns[column].to_a).to eql value.to_a
      end
    end

    context 'with the wrong length' do
      let(:value) { [1, 2] }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'for a new column' do
      let(:column){ :col3 }

      it 'should create a new column' do
        subject
        expect(view.columns).to include column
        expect(view.columns[column].to_a).to eql value
      end

      it 'should affect the parent table' do
        subject
        expect(table.columns).to include column
      end

      it 'should fill values outside the view with a default value' do
        subject
        default = NArray.new(table.columns[column].typecode, 1)[0]
        expect(table.columns[column].to_a).to eql [default] + value
      end

      context 'with an NArray' do
        let(:value){ NArray.int(3, 4, view.nrows).random! }

        it 'should use the narray parameters' do
          subject
          expect(view.columns[column].to_a).to eql value.to_a
        end
      end

       context 'when failed to add column' do
        let(:value){ NArray[1, 2, 3] }

        it 'should not have that column' do
          expect(view).to receive(:add_column).with(column, value.typecode) do
            view.columns[column] = ObjectTable::Column.make([0] * 10)
            table.columns[column] = ObjectTable::Column.make([0] * 10)
          end

#           the assignment is going to chuck an error
          subject rescue nil
          expect(view.columns).to_not include column
          expect(table.columns).to_not include column
        end
      end

    end

    context 'with an empty view' do
      let(:view)  { ObjectTable::TempView.new(table){col1 < 0} }

      context 'adding an empty column' do
        let(:value) { [] }
        it 'should add the column' do
          subject
          expect(view.columns[column].to_a).to eq value
        end
      end
    end

  end

  describe '#pop_column' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    let(:view) { ObjectTable::TempView.new(table){ col1 > 2 } }
    let(:name)    { :col2 }

    subject{ view.pop_column(name) }

    it 'should remove the column' do
      subject
      expect(view.colnames).to_not include name
      expect(view.columns).to_not include name
    end

    it 'should remove the column from the parent too' do
      subject
      expect(table.colnames).to_not include name
      expect(table.columns).to_not include name
    end
  end

end
