require 'object_table'
require 'object_table/view'

require 'support/object_table_example'

describe ObjectTable::View do
  it_behaves_like 'an object table', ObjectTable::View

  describe '#columns' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    subject{ ObjectTable::View.new(table){ col1 > 2 } }

    it 'should mask the columns of the parent table' do
      mask = table.col1 > 2
      table.columns.each do |k, v|
        expect(subject.columns[k].to_a).to eql v[mask].to_a
      end
    end
  end

  describe '#[]=' do
    let(:table) { ObjectTable.new(col1: [0, 1, 2, 3], col2: 5) }
    let(:view)  { ObjectTable::View.new(table){ col1 > 0 } }

    let(:column){ :col1 }
    let(:value) { [10, 20, 30] }

    subject{ view.columns; view[column] = value; view }

    context 'on an existing column' do
      it 'should assign values to the column' do
        expect(subject.columns[column].to_a).to eql value
      end

      it 'should not modify anything outside the view' do
        subject
        expect(table.columns[column].to_a).to eql [0] + value
      end

    end

    context 'with a scalar' do
      let(:value){ 10 }
      it 'should fill the column with that value' do
        expect(subject.columns[column].to_a).to eql ([value] * subject.nrows)
      end
    end

    context 'with the wrong length' do
      it 'should fail' do
        expect{subject[column] = [1, 2]}.to raise_error
      end
    end

    context 'for a new column' do
      let(:column){ :col3 }

      it 'should create a new column' do
        expect(subject.columns).to include column
        expect(subject.columns[column].to_a).to eql value
      end

      it 'should affect the parent table' do
        subject
        expect(table.columns).to include column
      end

      it 'should fill values outside the view with nil' do
        subject
        expect(table.columns[column].to_a).to eql [nil] + value
      end

      it 'should assign the name of the column' do
        expect(subject[:col3].name).to eql :col3
      end
    end

  end

end
