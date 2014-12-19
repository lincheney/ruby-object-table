require 'object_table'

describe ObjectTable do

  describe '#initialize' do
    let(:columns){ double }
    subject{ ObjectTable.new columns }

    it 'should ensure the columns have the same number of rows' do
      grid = double
      allow(ObjectTable::BasicGrid).to receive(:[]){ grid }
      expect(grid).to receive(:ensure_uniform_columns!)
      subject
    end
  end

  describe '#inspect' do
    subject{ ObjectTable.new(a: [1, 2, 3], b: 5) }
    it 'should succeed' do
      expect{subject.inspect}.to_not raise_error
    end
  end

end