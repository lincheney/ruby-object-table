require 'object_table'
require 'object_table/view'

describe ObjectTable::View do

  describe '#columns' do
    let(:table){ ObjectTable.new(a: [1, 2, 3], b: 5) }

    subject{ ObjectTable::View.new(table){ a > 2 } }

    it 'should mask the columns of the parent table' do
      mask = table.a > 2
      table.columns.each do |k, v|
        expect(subject.columns[k]).to eql v[mask]
      end
    end
  end

  describe '#[]=' do
    let(:table) {  ObjectTable.new(a: [1, 2, 3], b: 5) }
    let(:view)  { ObjectTable::View.new(table){ a > 1 } }

    let(:column){ :a }
    let(:value) { 1 }

    subject{ view[column] = value; view }

    context 'on an existing column' do
      it 'should assign values to the column' do
        expect(subject.columns[column].to_a).to eql [value] * subject.nrows
      end

      it 'should not modify anything outside the view' do
        subject
        expect(table.columns[column].to_a).to eql [1, value, value]
      end
    end

  end

end
