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

  describe '#_get_number_rows!' do
    let(:grid){ ObjectTable::BasicGrid[columns] }

    subject{ grid._get_number_rows! }

    context 'with columns of the same length' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3]} }
      it 'should give unique column lengths' do
        expect(subject).to match_array [3]
      end
    end

    context 'with columns of differing length' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3, 4]} }
      it 'should return the column lengths' do
        expect(subject).to match_array [3, 4]
      end
    end

    context 'with a mix of scalars and columns' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3], col3: 6} }
      it 'should ignore the scalars' do
        expect(subject).to match_array [3]
      end
    end

    context 'with scalars only' do
      let(:columns){ {col1: 1, col2: 2} }
      it 'should be empty' do
        expect(subject).to be_empty
      end
    end

    context 'with ranges' do
      let(:columns){ {col1: 0...3} }
      it 'should convert them to arrays' do
        subject
        expect(grid[:col1]).to eql columns[:col1].to_a
      end

      it 'should use the length of the range' do
        expect(subject).to match_array [3]
      end
    end

    context 'with multi dimensional narrays' do
      context 'with the same last dimension' do
        let(:columns) { {col1: NArray[[1, 1], [2, 2], [3, 3]], col2: [1, 2, 3]} }

        it 'should include the last dimension' do
          expect(subject).to match_array [3]
        end
      end

      context 'with a different last dimension' do
        let(:columns) { {col1: NArray[[1, 2, 3]], col2: [1, 2, 3]} }

        it 'should include the last dimension' do
          expect(subject).to match_array [1, 3]
        end
      end
    end

    context 'with empty narrays' do
      let(:columns) { {col1: [1, 2, 3], col2: NArray[]} }

      it 'should treat them as having zero length' do
        expect(subject).to match_array [3, 0]
      end
    end

  end

  describe '#_ensure_uniform_columns!' do
    let(:grid){ ObjectTable::BasicGrid[columns] }

    subject{ grid._ensure_uniform_columns! }

    context 'with columns of the same length' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3]} }
      it 'should succeed' do
        subject
        expect(grid[:col1]).to eql columns[:col1]
        expect(grid[:col2]).to eql columns[:col2]
      end
    end

    context 'with columns of differing length' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3, 4]} }
      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with a mix of scalars and columns' do
      let(:columns){ {col1: [1, 2, 3], col2: [1, 2, 3], col3: 6} }
      it 'should recycle the scalar into a full column' do
        subject
        expect(grid[:col3]).to eql [6] * 3
      end
    end

    context 'with scalars only' do
      let(:columns){ {col1: 1, col2: 2} }
      it 'should assume there is one column' do
        subject
        expect(grid[:col1]).to eql [columns[:col1]]
        expect(grid[:col2]).to eql [columns[:col2]]
      end
    end

    context 'with ranges' do
      let(:columns){ {col1: 0...3} }
      it 'should succeed' do
        expect{subject}.to_not raise_error
      end
    end

    context 'with multi dimensional narrays' do
      context 'with the correct last dimension' do
        let(:columns) { {col1: NArray[[1, 1], [2, 2], [3, 3]], col2: [1, 2, 3]} }

        it 'should succeed' do
          subject
          expect(grid).to eql columns
        end
      end

      context 'with an incorrect last dimension' do
        let(:columns) { {col1: NArray[[1, 2, 3]], col2: [1, 2, 3]} }

        it 'should succeed' do
          expect{subject}.to raise_error
        end
      end
    end

    context 'with empty narrays' do

      context 'with all other columns empty' do
        let(:columns) { {col1: [], col2: NArray[]} }

        it 'should succeed' do
          expect{subject}.to_not raise_error
        end
      end


      context 'with other non-empty columns' do
        let(:columns) { {col1: [], col2: NArray[], col3: [1, 2, 3]} }

        it 'should fail' do
          expect{subject}.to raise_error
        end
      end
    end

  end

end