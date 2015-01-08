require 'object_table'
require 'object_table/view'

require 'support/object_table_example'

describe ObjectTable::View do
  it_behaves_like 'an object table', ObjectTable::View

  describe '#columns' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    subject{ ObjectTable::View.new(table, (table.col1 > 2).where) }

    it 'should mask the columns of the parent table' do
      mask = table.col1 > 2
      table.columns.each do |k, v|
        expect(subject.columns[k].to_a).to eql v[mask].to_a
      end
    end

    it 'should make masked columns' do
      subject.columns.each do |k, v|
        expect(v).to be_a ObjectTable::MaskedColumn
      end
    end

    context 'with a matrix in a column' do
      let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    end
  end

  describe '#set_column' do
    let(:table) { ObjectTable.new(col1: [0, 1, 2, 3], col2: 5) }
    let(:view)  { ObjectTable::View.new(table, (table.col1 > 0).where) }

    let(:column){ :col1 }
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
        expect(table.columns[column].to_a).to eql [0] + value
      end

    end

    context 'with a scalar' do
      let(:value){ 10 }
      it 'should fill the column with that value' do
        subject
        expect(view.columns[column].to_a).to eql ([value] * view.nrows)
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

      it 'should fill values outside the view with a default' do
        subject
        default = NArray.new(table.columns[column].typecode, 1)[0]
        expect(table.columns[column].to_a).to eql [default] + value
      end

      it 'should assign the name of the column' do
        subject
        expect(view[:col3].name).to eql :col3
      end

      context 'with an NArray' do
        let(:value){ NArray.int(3, 4, view.nrows).random! }

        it 'should use the narray parameters' do
          subject
          expect(view.columns[column].to_a).to eql value.to_a
        end
      end
    end

  end

end
