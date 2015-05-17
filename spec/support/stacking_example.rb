require 'object_table'
require_relative 'utils'

RSpec.shared_examples 'a stacking operation' do

  let(:grids) do
    [
      ObjectTable.new(col1: [1, 2, 3], col2: 5),
      ObjectTable.new(col1: 10, col2: 50),
      ObjectTable.new(col2: [10, 30], col1: 15).where{col2.eq 10},
      ObjectTable::BasicGrid[col2: [1, 2], col1: 3..4],
    ]
  end

  before do
    grids[0] = make_table(grids[0], described_class) unless grids.empty?
  end

  let(:segment)     { NArray.float(10, 10, 10).indgen }

  let!(:grids_copy) { grids.map(&:clone) }

  it 'should stack the tables and grids together' do
    expect(subject).to be_a grids[0].__table_cls__
    expect(subject).to eql grids[0].__table_cls__.new(
      col1: grids_copy.flat_map{|x| x[:col1].to_a},
      col2: grids_copy.flat_map{|x| x[:col2].to_a},
      )
  end

  context 'with non grids/tables' do
    let(:grids){ [ObjectTable.new(col1: 10, col2: 50), 'not a table'] }

    it 'should fail' do
      expect{subject}.to raise_error
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
        expect(subject).to eql grids[0].__table_cls__.new
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

  context 'with only array segments' do
    let(:grids) { [ObjectTable.new(col1: segment.to_a)] * 3  }

    it 'should work' do
      expect(subject.col1).to eql NArray.to_na(segment.to_a * 3)
    end
  end

end
