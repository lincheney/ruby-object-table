require 'object_table/basic_grid'

describe ObjectTable::BasicGrid do
  describe '#ensure_uniform_columns' do
    let(:grid){ ObjectTable::BasicGrid[columns] }
    subject   { grid.ensure_uniform_columns }

    context 'with rows of the same' do
      let(:columns){ {a: [1, 2, 3], b: [1, 2, 3]} }
      it 'should succeed' do
        subject
        expect(grid[:a]).to eql columns[:a]
        expect(grid[:b]).to eql columns[:b]
      end
    end

    context 'with rows of differing length' do
      let(:columns){ {a: [1, 2, 3], b: [1, 2, 3, 4]} }
      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with a mix of scalars and rows' do
      let(:columns){ {a: [1, 2, 3], b: [1, 2, 3], c: 6} }
      it 'should recycle the scalar into a full column' do
        subject
        expect(grid[:c]).to eql [6] * 3
      end
    end

    context 'with scalars only' do
      let(:columns){ {a: 1, b: 2} }
      it 'should assume there is one row' do
        subject
        expect(grid[:a]).to eql [columns[:a]]
        expect(grid[:b]).to eql [columns[:b]]
      end
    end
  end
end