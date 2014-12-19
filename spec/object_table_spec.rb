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

  describe 'columns' do
    let(:columns){ {a: [1, 2, 3], b: 5} }
    subject{ ObjectTable.new(columns) }

    it 'should respond to the column names as methods' do
      columns.keys.each do |key|
        expect(subject).to respond_to key
        expect(subject.send(key)).to be subject.columns[key]
      end
    end
  end

end