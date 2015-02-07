require 'object_table'
require 'object_table/grouped'

describe ObjectTable::Grouped do
  let(:table){ ObjectTable.new(col1: [1, 2, 3, 4], col2: [5, 6, 7, 8] ) }
#     group based on parity (even vs odd)
  let(:grouped){ ObjectTable::Grouped.new(table){ {parity: col1 % 2} } }

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

  describe '#initialize' do

    context 'when the block takes an argument' do
      it 'should not evaluate in the context of the table' do
        rspec_context = self

        grouped = ObjectTable::Grouped.new(table) do |tbl|
          receiver = eval('self', binding)
          expect(receiver).to_not be table
          expect(receiver).to be rspec_context
          {}
        end
        grouped._groups # call _groups to make it call the block
      end

      it 'should pass the table into the block' do
        grouped = ObjectTable::Grouped.new(table) do |tbl|
          expect(tbl).to be table
          {}
        end
        grouped._groups # call _groups to make it call the block
      end
    end

    context 'when the block takes no arguments' do
      it 'should call the block in the context of the table' do
        _ = self
        grouped = ObjectTable::Grouped.new(table) do
          receiver = eval('self', binding)
          _.expect(receiver).to _.be _.table
          {}
        end
        grouped._groups # call _groups to make it call the block
      end
    end

  end

  context 'with changes to the parent' do
    subject{ grouped }

    it 'should mirror changes to the parent' do
      expect(subject._groups[1]).to eql ({[0] => [1, 3], [1] => [0, 2]})
      table[:col1] = [2, 3, 4, 5]
      expect(subject._groups[1]).to eql ({[0] => [0, 2], [1] => [1, 3]})
    end
  end

  describe '#_groups' do
    subject{ grouped._groups }

    it 'should return the names' do
      expect(subject[0]).to eql [:parity]
    end

    it 'should return the group key => row mapping' do
      groups = subject[1]
      expect(groups[[0]]).to eql even.to_a
      expect(groups[[1]]).to eql odd.to_a
    end

    context 'when grouping by columns' do
      let(:table){ ObjectTable.new(key1: [0]*4 + [1]*4, key2: [0, 0, 1, 1]*2, data: 1..8 ) }
      let(:grouped){ ObjectTable::Grouped.new(table, :key1, :key2) }

      it 'should use the columns as group names' do
        expect(subject[0]).to eql [:key1, :key2]
      end

      it 'should use the columns as groups' do
        groups = subject[1]
        expect(groups[[0, 0]]).to eql (table.key1.eq(0) & table.key2.eq(0)).where.to_a
        expect(groups[[0, 1]]).to eql (table.key1.eq(0) & table.key2.eq(1)).where.to_a
        expect(groups[[1, 0]]).to eql (table.key1.eq(1) & table.key2.eq(0)).where.to_a
        expect(groups[[1, 1]]).to eql (table.key1.eq(1) & table.key2.eq(1)).where.to_a
      end
    end
  end

  describe '#each' do
    let(:even_group){ table.where{ (col1 % 2).eq(0) } }
    let(:odd_group) { table.where{ (col1 % 2).eq(1) } }

    context 'when the block takes an argument' do
      it 'should not evaluate in the context of the group' do
        rspec_context = self

        grouped.each do |group|
          receiver = eval('self', binding)
          expect(receiver).to_not be_a ObjectTable::Group
          expect(receiver).to be rspec_context
        end
      end
    end

    context 'when the block takes no arguments' do
      it 'should call the block in the context of the group' do
        _ = self
        grouped.each do
          receiver = eval('self', binding)
          _.expect(receiver).to _.be_a ObjectTable::Group
        end
      end
    end

    it 'should yield the groups' do
      groups = [even_group, odd_group]
      grouped.each do |group|
        expect(groups).to include group
        groups -= [group]
      end
    end

    it 'should give access to the keys' do
      keys = []
      grouped.each do
        keys << @K
      end

      expect(keys).to match_array [{parity: 0}, {parity: 1}]
    end

    it 'should give access to the correct key' do
      keys = []
      correct_keys = []
      grouped.each do
        keys << [@K[:parity]]
        correct_keys << (self.col1 % 2).uniq.to_a
      end

      expect(keys).to match_array(correct_keys)
    end

    context 'with no block' do
      it 'should return an enumerator' do
        expect(grouped.each).to be_a Enumerator
      end

      it 'should enumerate the groups' do
        groups = [even_group, odd_group]
        grouped.each.each do |group|
          expect(groups).to include group
          groups -= [group]
        end
      end

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
        grouped = ObjectTable::Grouped.new(table){{parity: 1}}
        result = grouped.apply{|group| group.col1.sum}
        expect(result).to have_column :v_0
        expect(result.v_0.to_a).to eql [table.col1.sum]
      end

      it 'should auto name the value column' do
        grouped = ObjectTable::Grouped.new(table){{v_0: 1}}
        result = grouped.apply{|group| group.col1.sum}
        expect(result).to have_column :v_1
        expect(result.v_1.to_a).to eql [table.col1.sum]
      end
    end

    context 'with results that are grids' do
      subject{ grouped.apply{ @R[sum: col1.sum, mean: col2.mean] } }

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

    context 'when the block takes an argument' do
      it 'should not evaluate in the context of the group' do
        rspec_context = self

        grouped.apply do |group|
          receiver = eval('self', binding)
          expect(receiver).to_not be_a ObjectTable::Group
          expect(receiver).to be rspec_context
          nil
        end
      end
    end

    context 'when the block takes no arguments' do
      it 'should call the block in the context of the group' do
        _ = self
        grouped.apply do
          receiver = eval('self', binding)
          _.expect(receiver).to _.be_a ObjectTable::Group
          nil
        end
      end
    end
  end

end
