require 'object_table'

describe ObjectTable do

  describe '#initialize' do
    let(:columns){ {} }
    subject{ ObjectTable.new columns }

    it 'should ensure the columns have the same number of rows' do
      grid = ObjectTable::BasicGrid.new
      allow(ObjectTable::BasicGrid).to receive(:[]).with(columns){ grid }
      expect(grid).to receive(:ensure_uniform_columns!)
      subject
    end

    it 'should convert all columns into ObjectTable::Columns' do
      subject.columns.values.each do |v|
        expect(v).to be_a ObjectTable::Column
      end
    end
  end

  describe '#inspect' do
    subject{ ObjectTable.new(a: [1, 2, 3], b: 5) }
    it 'should succeed' do
      expect{subject.inspect}.to_not raise_error
    end
  end

end