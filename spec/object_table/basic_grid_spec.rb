require 'object_table/basic_grid'

describe ObjectTable::BasicGrid do
  describe '.[]' do
    subject{ ObjectTable::BasicGrid[] }

    it 'should ensure the columns have the same number of rows' do
      expect_any_instance_of(ObjectTable::BasicGrid).to receive(:_ensure_uniform_columns!)
      subject
    end
  end

  describe '#_ensure_uniform_columns!' do
    let(:grid){ ObjectTable::BasicGrid[columns] }

    subject{ grid }

    context 'with rows of the same' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3]} }
      it 'should succeed' do
        subject
        expect(grid[:col1]).to eql columns[:col1]
        expect(grid[:col2]).to eql columns[:col2]
      end
    end

    context 'with rows of differing length' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3, 4]} }
      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with a mix of scalars and rows' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3], col3: 6} }
      it 'should recycle the scalar into a full column' do
        subject
        expect(grid[:col3]).to eql [6] * 3
      end
    end

    context 'with scalars only' do
      let(:columns){ {col1: 1, col2: 2} }
      it 'should assume there is one row' do
        subject
        expect(grid[:col1]).to eql [columns[:col1]]
        expect(grid[:col2]).to eql [columns[:col2]]
      end
    end
  end

  describe '#_next_available_key' do
    let(:grid){ ObjectTable::BasicGrid[col1: 1, col2: 2, col5: 5] }

    subject{ grid._next_available_key(prefix) }

    context 'with no matching keys' do
      let(:prefix){ 'prefix' }
      it 'should suffix the key with 0' do
        expect(subject).to eql 'prefix0'
      end
    end

    context 'with matching keys' do
      let(:prefix){ 'col' }
      it 'should suffix the key with the next available number' do
        expect(subject).to eql 'col6'
      end
    end

  end
end