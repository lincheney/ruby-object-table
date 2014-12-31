require 'object_table'
require 'object_table/grouped'

describe ObjectTable::Grouped do
  let(:table){ ObjectTable.new(col1: [1, 2, 3, 4], col2: [5, 6, 7, 8] ) }
#     group based on parity (even vs odd)
  let(:names){ [:parity] }
  let(:groups){ {[0] => even, [1] => odd} }
  let(:grouped){ ObjectTable::Grouped.new(table, names, groups) }

  let(:even){ (table.col1 % 2).eq(0).where }
  let(:odd) { (table.col1 % 2).eq(1).where }

  describe '._generate_name' do
    let(:prefix){ 'key_' }
    subject{ ObjectTable::Grouped._generate_name(prefix, existing_keys) }

    context 'with no matching keys' do
      let(:existing_keys){ ['a', 'b', 'c'] }
      it 'should suffix the key with 0' do
        expect(subject).to eql "key_0"
      end
    end

    context 'with matching keys' do
      let(:existing_keys){ ['key_1', 'key_67', 'key_8', 'abcd'] }
      it 'should suffix the key with the next available number' do
        expect(subject).to eql "key_68"
      end
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
      expect(subject.sort_by(subject.parity)).to eql ObjectTable.new(parity: [0, 1], v_0: [6, 4])
    end

    describe 'value column auto naming' do
      it 'should auto name the value column' do
        grouped = ObjectTable::Grouped.new(table, names, {[123] => NArray[0, 1, 2, 3]})
        result = grouped.apply{|group| group.col1.sum}
        expect(result.v_0.to_a).to eql [table.col1.sum]
      end

      it 'should auto name the value column' do
        grouped = ObjectTable::Grouped.new(table, [:v_0], {[123] => NArray[0, 1, 2, 3]})
        result = grouped.apply{|group| group.col1.sum}
        expect(result.v_1.to_a).to eql [table.col1.sum]
      end
    end

    context 'with results that are grids' do
      subject{ grouped.apply{|g| @R[sum: g.col1.sum, mean: g.col2.mean]} }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :parity
      end

      it 'should stack the grids' do
        expect(subject.sort_by(subject.parity)).to eql ObjectTable.new(
          parity: [0, 1],
          sum:    [even_group.col1.sum, odd_group.col1.sum],
          mean:   [even_group.col2.mean, odd_group.col2.mean],
        )
      end
    end
  end

end
