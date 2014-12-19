require 'object_table'
require 'object_table/grouped'

describe ObjectTable::Grouped do
  let(:table){ ObjectTable.new(col1: [1, 2, 3, 4], col2: [5, 6, 7, 8] ) }
#     group based on parity (even vs odd)
  let(:grouped){ ObjectTable::Grouped.new(table){ col1 % 2 } }

  let(:even){ (table.col1 % 2).eq(0).where }
  let(:odd) { (table.col1 % 2).eq(1).where }

  describe '#groups' do
    subject{ grouped.groups }

    it 'should return a group key => row mapping' do
      expect(subject[0]).to eql even.to_a
      expect(subject[1]).to eql odd.to_a
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

end
