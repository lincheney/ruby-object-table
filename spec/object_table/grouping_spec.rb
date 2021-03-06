require 'object_table'
require 'object_table/grouping'

describe ObjectTable::Grouping do
  let(:col1)  { ((1..100).to_a + (-100..-1).to_a).shuffle }
  let(:col2)  { NArray.float(10, 200).random }

  let(:table){ ObjectTable.new(col1: col1, col2: col2 ) }
  let(:grouped){ described_class.new(table){ {pos: col1 > 0} } }

  let(:positive)  { (table.col1 > 0).where }
  let(:negative)  { (table.col1 < 0).where }

  let(:pos_group) { table.where{|t| positive} }
  let(:neg_group) { table.where{|t| negative} }

  describe '.generate_name' do
    let(:prefix){ 'key_' }
    subject{ described_class.generate_name(prefix, existing_keys) }

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

        grouped = described_class.new(table) do |tbl|
          receiver = eval('self', binding)
          expect(receiver).to_not be table
          expect(receiver).to be rspec_context
          {}
        end
        grouped._keys # call _keys to make it call the block
      end

      it 'should pass the table into the block' do
        grouped = described_class.new(table) do |tbl|
          expect(tbl).to be table
          {}
        end
        grouped._keys # call _keys to make it call the block
      end
    end

    context 'when the block takes no arguments' do
      it 'should call the block in the context of the table' do
        _ = self
        grouped = described_class.new(table) do
          receiver = eval('self', binding)
          _.expect(receiver).to _.be _.table
          {}
        end
        grouped._keys # call _keys to make it call the block
      end
    end

  end

  context 'with changes to the parent' do
    subject{ grouped }

    it 'should mirror changes to the parent' do
      expect(subject._keys).to eq (table.col1 > 0).to_a.zip
      table[:col1] = NArray.int(200).fill(2)
      table[:col1][0] = -100
      expect(subject._keys).to eql ([0] + [1] * 199).zip
    end
  end

  describe '#_keys' do
    let(:grouped){ described_class.new(table){ {key1: col1 > 0, key2: col2 > 0.5} } }

    it 'should return the keys' do
      keys = grouped._keys.transpose
      expect(keys).to eql [(table.col1 > 0).to_a, (table.col2 > 0.5).to_a]
    end

    it 'should set the names' do
      grouped._keys
      expect(grouped.instance_variable_get('@names')).to eql [:key1, :key2]
    end

    context 'when grouping by columns' do
      let(:table){ ObjectTable.new(key1: [0]*4 + [1]*4, key2: [0, 0, 1, 1]*2, data: 1..8 ) }
      let(:grouped){ described_class.new(table, :key1, :key2) }

      it 'should use the columns as keys' do
        keys = grouped._keys.transpose
        expect(keys).to eql [table.key1.to_a, table.key2.to_a]
      end

      it 'should set the names' do
        grouped._keys
        expect(grouped.instance_variable_get('@names')).to eql [:key1, :key2]
      end
    end
  end

  describe '#each' do

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
      groups = [pos_group, neg_group]
      grouped.each do |group|
        expect(groups).to include group
        groups -= [group]
      end
    end

    it 'should give access to the keys' do
      keys = []
      grouped.each{ keys << Hash[@K.each_pair.to_a] }
      expect(keys).to match_array [{pos: 0}, {pos: 1}]
    end

    it 'should give access to the correct key' do
      keys = []
      correct_keys = []
      grouped.each do
        keys << [@K.pos]
        correct_keys << (col1 > 0).to_a.uniq
      end

      expect(keys).to match_array(correct_keys)
    end

    context 'with no block' do
      it 'should return an enumerator' do
        expect(grouped.each).to be_a Enumerator
      end

      it 'should enumerate the groups' do
        groups = [pos_group, neg_group]
        grouped.each.each do |group|
          expect(groups).to include group
          groups -= [group]
        end
      end

    end
  end

  describe '#apply' do
    subject{ grouped.apply{|group| group.col2.sum} }

    it 'should return a table with the group keys' do
      expect(subject).to be_a ObjectTable
      expect(subject.colnames).to include :pos
    end

    it 'should concatenate the results of the block' do
      value = [neg_group.col2.sum, pos_group.col2.sum]
      expect(subject.sort_by(subject.pos)).to eql ObjectTable.new(pos: [0, 1], v_0: value)
    end

    describe 'value column auto naming' do
      it 'should auto name the value column' do
        grouped = described_class.new(table){{parity: 1}}
        result = grouped.apply{|group| group.col1.sum}
        expect(result).to have_column :v_0
        expect(result.v_0.to_a).to eql [table.col1.sum]
      end

      it 'should auto name the value column' do
        grouped = described_class.new(table){{v_0: 1}}
        result = grouped.apply{|group| group.col1.sum}
        expect(result).to have_column :v_1
        expect(result.v_1.to_a).to eql [table.col1.sum]
      end
    end

    context 'with results that are grids' do
      subject{ grouped.apply{ @R[sum: col1.sum, mean: col2.mean] } }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :pos
      end

      it 'should stack the grids' do
        expect(subject.sort_by(subject.pos)).to eql ObjectTable.new(
          pos:    [0, 1],
          sum:    [neg_group.col1.sum, pos_group.col1.sum],
          mean:   [neg_group.col2.mean, pos_group.col2.mean],
        )
      end
    end

    context 'with results that are tables' do
      subject{ grouped.apply{ ObjectTable.new(sum: col1.sum, mean: col2.mean) } }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :pos
      end

      it 'should stack the grids' do
        expect(subject.sort_by(subject.pos)).to eql ObjectTable.new(
          pos:    [0, 1],
          sum:    [neg_group.col1.sum, pos_group.col1.sum],
          mean:   [neg_group.col2.mean, pos_group.col2.mean],
        )
      end
    end

    context 'with results that are arrays' do
      subject{ grouped.apply{ [col1[0], col1[-1]] } }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :pos
      end

      it 'should stack the grids' do
        expect(subject.where{pos.eq 0}.v_0).to eq neg_group.col1[[0, -1]]
        expect(subject.where{pos.eq 1}.v_0).to eq pos_group.col1[[0, -1]]
      end
    end

    context 'with results that are narrays' do
      subject{ grouped.apply{ col2 < 0.5 } }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :pos
      end

      it 'should stack the grids' do
        expect(subject.where{pos.eq 0}.v_0).to eq (neg_group.col2 < 0.5)
        expect(subject.where{pos.eq 1}.v_0).to eq (pos_group.col2 < 0.5)
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

    context 'with a matrix key' do
      let(:ngroups) { 10 }
      let(:table) do
        ObjectTable.new(
          key1: 10.times.map{[rand, 'abc']} * ngroups,
          key2: 10.times.map{[rand, 'def', 'ghi']} * ngroups,
          value: (ngroups*10).times.map{rand},
        )
      end

      let(:grouped) { described_class.new(table, :key1, :key2) }
      subject{ grouped.apply{|group| group.value.sum} }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :key1
        expect(subject.colnames).to include :key2
      end

      it 'should preserve the dimensions of the keys' do
        expect(subject.key1.shape[0...-1]).to eql table.key1.shape[0...-1]
        expect(subject.key2.shape[0...-1]).to eql table.key2.shape[0...-1]
      end

      context 'with vector values' do
        subject{ grouped.apply{|group| group.value[0...10]} }

        it 'should work' do
          expect{subject}.to_not raise_error
        end
      end
    end

    context 'on an empty table' do
      let(:table) { ObjectTable.new(col1: [], col2: []) }

      it 'should return a table with no rows and only key columns' do
        expect(subject.nrows).to eql 0
        expect(subject.columns.keys).to eql [:pos]
      end
    end

  end


  describe '#reduce' do
    let(:col2)  { (NArray.float(10, 200).random * 100).to_i }
    subject{ grouped.reduce{|row| row.R[:col2] += row.col2.sum } }

    it 'should return a table with the group keys' do
      expect(subject).to be_a ObjectTable
      expect(subject.colnames).to include :pos
    end

    it 'should concatenate the results of the block' do
      value = [neg_group.col2.sum, pos_group.col2.sum]
      expect(subject.sort_by(subject.pos)).to eql ObjectTable.new(pos: [0, 1], col2: value)
    end

    context 'with results that are narrays' do
      subject{ grouped.reduce{|row| row.R[:col2] += row.col2 } }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :pos
      end

      it 'should stack the grids' do
        expect(subject.where{pos.eq 0}.col2).to eq neg_group.col2.sum(1).reshape(10, 1)
        expect(subject.where{pos.eq 1}.col2).to eq pos_group.col2.sum(1).reshape(10, 1)
      end
    end

    context 'with results that are arrays' do
      subject{ grouped.reduce(col2: []){ @R[:col2] += col2.to_a } }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :pos
      end

      it 'should stack the grids' do
        expect(subject.where{pos.eq 0}.col2).to eq neg_group.col2.reshape(1000, 1)
        expect(subject.where{pos.eq 1}.col2).to eq pos_group.col2.reshape(1000, 1)
      end
    end

    context 'when the block takes an argument' do
      it 'should not evaluate in the context of the group' do
        rspec_context = self

        grouped.reduce do |group|
          receiver = eval('self', binding)
          expect(receiver).to_not be_a described_class
          expect(receiver).to be rspec_context
          nil
        end
      end
    end

    context 'when the block takes no arguments' do
      it 'should call the block in the context of the row' do
        _ = self
        grouped.reduce do
          receiver = eval('self', binding)
          _.expect(receiver).to _.be_a Struct
          nil
        end
      end
    end

    describe 'defaults' do
      it 'should default to 0' do
        grouped.reduce do |row|
          expect(row.R[:key]).to eql 0
          break
        end
      end

      it 'should enforce defaults' do
        grouped.reduce(key: 1) do |row|
          expect(row.R[:key]).to eql 1
          break
        end
      end

      it 'should fail if defaults are badly specified' do
        expect{ grouped.reduce(123){} }.to raise_error
      end
    end

    context 'with a matrix key' do
      let(:group_count) { 10 }
      let(:group_size)  { 15 }

      let(:table) do
        ObjectTable.new(
          key1: group_count.times.map{[rand, 'abc']} * group_size,
          key2: group_count.times.map{[rand, 'def', 'ghi']} * group_size,
          value: (group_size * group_count).times.map{rand},
        )
      end

      let(:grouped) { described_class.new(table, :key1, :key2) }
      subject{ grouped.reduce{@R[:value] += value} }

      it 'should return a table with the group keys' do
        expect(subject).to be_a ObjectTable
        expect(subject.colnames).to include :key1
        expect(subject.colnames).to include :key2
      end

      it 'should preserve the dimensions of the keys' do
        expect(subject.key1.shape[0...-1]).to eql table.key1.shape[0...-1]
        expect(subject.key2.shape[0...-1]).to eql table.key2.shape[0...-1]
      end

      context 'with vector values' do
        subject{ grouped.reduce(value: []){ @R[:value] += [value] } }

        it 'should work' do
          expect{subject}.to_not raise_error
          expect(subject.nrows).to eql group_count
          expect(subject.value.shape).to eq [group_size, group_count]
        end
      end
    end

    context 'on an empty table' do
      let(:table) { ObjectTable.new(col1: [], col2: []) }

      it 'should return a table with no rows and only key columns' do
        expect(subject.nrows).to eql 0
        expect(subject.columns.keys).to eql [:pos]
      end
    end

  end


end
