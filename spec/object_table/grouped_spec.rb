require 'object_table'
require 'object_table/grouped'

describe ObjectTable::Grouped do
  let(:table){ ObjectTable.new(col1: [1, 2, 3, 4], col2: [5, 6, 7, 8] ) }
#     group based on parity (even vs odd)
  let(:grouped){ ObjectTable::Grouped.new(table){ {parity: col1 % 2} } }

  let(:even){ (table.col1 % 2).eq(0).where }
  let(:odd) { (table.col1 % 2).eq(1).where }

  describe '#groups' do
    subject{ grouped.groups }

    it 'should return a group key => row mapping' do
      expect(subject[[0]]).to eql even.to_a
      expect(subject[[1]]).to eql odd.to_a
    end
  end

  describe '#each' do
    let(:even_group){ table.where{ (col1 % 2).eq(0) } }
    let(:odd_group) { table.where{ (col1 % 2).eq(1) } }

    it 'should yield the groups' do
      groups = []
      grouped.each do |group|
        groups << group
      end

      expect(groups).to match_array [even_group, odd_group]
    end
  end

  describe '#apply' do
    let(:even_group){ table.where{ (col1 % 2).eq(0) } }
    let(:odd_group) { table.where{ (col1 % 2).eq(1) } }

    subject{ grouped.apply{|group| group.col1.sum} }

    it 'should return a table with the group keys' do
      expect(subject).to be_a ObjectTable
      expect(subject.colnames).to include :parity
    end

    it 'should concatenate the results of the block' do
      expect(subject.where{parity.eq 0}.value.to_a).to eql [even_group.col1.sum]
      expect(subject.where{parity.eq 1}.value.to_a).to eql [odd_group.col1.sum]
    end

    context 'with results that are grids' do
      subject{ grouped.apply{|g| @R[sum: g.col1.sum, mean: g.col2.mean]} }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :parity
      end

      it 'should stack the grids' do
        expect(subject.where{parity.eq 0}.sum.to_a).to eql [even_group.col1.sum]
        expect(subject.where{parity.eq 0}.mean.to_a).to eql [even_group.col2.mean]
        expect(subject.where{parity.eq 1}.sum.to_a).to eql [odd_group.col1.sum]
        expect(subject.where{parity.eq 1}.mean.to_a).to eql [odd_group.col2.mean]
      end
    end
  end

end
