require 'object_table/basic_grid'

describe ObjectTable::BasicGrid do
#   describe '.[]' do
#     subject{ ObjectTable::BasicGrid[] }
#
#     it 'should ensure the columns have the same number of rows' do
#       expect_any_instance_of(ObjectTable::BasicGrid).to receive(:_ensure_uniform_columns!)
#       subject
#     end
#   end

  describe '#_ensure_uniform_columns!' do
    let(:grid){ ObjectTable::BasicGrid[columns] }

    subject{ grid._ensure_uniform_columns! }

    context 'with rows of the same length' do
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

    context 'with ranges' do
      let(:columns){ {col1: 0...3} }
      it 'should succeed' do
        subject
        expect(grid[:col1]).to eql columns[:col1]
      end
    end
  end

end