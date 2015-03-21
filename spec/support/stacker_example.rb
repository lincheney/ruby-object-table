require 'object_table'

RSpec.shared_examples 'a table stacker' do

  let(:grids) do
    [
      ObjectTable.new(col1: [1, 2, 3], col2: 5),
      ObjectTable.new(col1: 10, col2: 50),
      ObjectTable.new(col2: [10, 30], col1: 15).where{col2.eq 10},
      ObjectTable::BasicGrid[col2: [1, 2], col1: 3..4],
    ]
  end

  let(:segment)     { NArray.float(10, 10, 10).indgen }

  let!(:grids_copy) { grids.map(&:clone) }

  shared_examples 'a stacking operation' do

    it 'should join the tables and grids together' do
      expect(subject).to be_a described_class
      expect(subject).to eql described_class.new(
        col1: grids_copy.flat_map{|x| x[:col1].to_a},
        col2: grids_copy.flat_map{|x| x[:col2].to_a},
        )
    end

    context 'with non grids/tables' do
      let(:grids){ [ObjectTable.new(col1: 10, col2: 50), 'not a table'] }

      it 'should fail' do
        expect{subject}.to raise_error
      end

      context 'with only a non-grid/table' do
        let(:grids)  { ['not a table'] }

        it 'should fail' do
          expect{subject}.to raise_error
        end
      end
    end

    context 'with extra column names' do
      let(:grids){ [ObjectTable.new(col1: 10, col2: 50), ObjectTable.new(col1: 10, col2: 30, col3: 50)] }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with missing column names' do
      let(:grids){ [ObjectTable.new(col1: 10, col2: 50), ObjectTable.new(col1: 10)] }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with empty tables' do
      let(:grids) { [ ObjectTable.new(col1: [1, 2, 3], col2: 5), ObjectTable.new ] }

      it 'should ignore empty tables' do
        expect(subject).to eql grids[0]
      end

      context 'with only empty tables' do
        let(:grids) { [ObjectTable.new] * 3 }

        it 'should return an empty table' do
          expect(subject).to eql described_class.new
        end
      end
    end

    context 'with tables with empty rows' do
      let(:grids) { [ ObjectTable.new(col1: [1, 2, 3], col2: 5), ObjectTable.new(col1: [], col2: []) ] }

      it 'should ignore empty tables' do
        expect(subject).to eql grids_copy[0]
      end
    end

    context 'with empty grids' do
      let(:grids) { [ ObjectTable.new(col1: [1, 2, 3], col2: 5), ObjectTable::BasicGrid.new ] }

      it 'should ignore empty grids' do
        expect(subject).to eql grids_copy[0]
      end
    end

    context 'with only narray segments' do
      let(:grids) { [ObjectTable.new(col1: segment)] * 3  }

      it 'should work' do
        expect(subject.col1).to eql NArray.to_na(segment.to_a * 3)
      end
    end

    context 'with a mixture of segment types' do
      let(:grids) { [ObjectTable.new(col1: segment)] * 2 + [ObjectTable::BasicGrid[col1: segment.to_a]] * 3 }

      it 'should work' do
        expect(subject.col1).to eql NArray.to_na(segment.to_a * 5)
      end
    end

  end


  describe '.stack' do
    subject{ described_class.stack *grids }

    it_behaves_like 'a stacking operation'

    it 'should duplicate the contents' do
      grids.each do |chunk|
        expect(subject).to_not be chunk
      end
    end

    context 'with no arguments' do
      let(:grids){ [] }

      it 'should return an empty table' do
        expect(subject).to eql described_class.new
      end
    end

    context 'with only empty grids' do
      let(:grids) { [ObjectTable::BasicGrid.new] * 3 }

      it 'should return an empty table' do
        expect(subject).to eql described_class.new
      end
    end

    context 'with only array segments' do
      let(:grids) { [ObjectTable::BasicGrid[col1: segment.to_a]] * 3  }

      it 'should work' do
        expect(subject.col1).to eql NArray.to_na(segment.to_a * 3)
      end
    end
  end


  describe '#stack!' do
    subject{ grids[0].stack! *grids[1..-1] }
    it_behaves_like 'a stacking operation'

    it 'should modify the table' do
      expect(subject).to be grids[0]
    end
  end


end