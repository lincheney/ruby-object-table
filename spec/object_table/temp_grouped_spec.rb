require 'object_table'
require 'object_table/temp_grouped'

describe ObjectTable::TempGrouped do
  let(:table){ ObjectTable.new(col1: [1, 2, 3, 4], col2: [5, 6, 7, 8] ) }
#     group based on parity (even vs odd)
  let(:grouped){ ObjectTable::TempGrouped.new(table){ {parity: col1 % 2} } }

  let(:even){ (table.col1 % 2).eq(0).where }
  let(:odd) { (table.col1 % 2).eq(1).where }

  context 'with changes to the parent' do
    subject{ grouped }

    it 'should mirror changes to the parent' do
      expect(subject._groups[1]).to eql ({[0] => NArray[1, 3], [1] => NArray[0, 2]})
      table[:col1] = [2, 3, 4, 5]
      expect(subject._groups[1]).to eql ({[0] => NArray[0, 2], [1] => NArray[1, 3]})
    end
  end

  describe '#_groups' do
    subject{ grouped._groups }

    it 'should return the names' do
      expect(subject[0]).to eql [:parity]
    end

    it 'should return the group key => row mapping' do
      groups = subject[1]
      expect(groups[[0]]).to eql even
      expect(groups[[1]]).to eql odd
    end

    context 'when grouping by columns' do
      let(:table){ ObjectTable.new(key1: [0]*4 + [1]*4, key2: [0, 0, 1, 1]*2, data: 1..8 ) }
      let(:grouped){ ObjectTable::TempGrouped.new(table, table.key1, table.key2) }

      it 'should use the columns as group names' do
        expect(subject[0]).to eql [:key1, :key2]
      end

      it 'should use the columns as groups' do
        groups = subject[1]
        expect(groups[[0, 0]]).to eql (table.key1.eq(0) & table.key2.eq(0)).where
        expect(groups[[0, 1]]).to eql (table.key1.eq(0) & table.key2.eq(1)).where
        expect(groups[[1, 0]]).to eql (table.key1.eq(1) & table.key2.eq(0)).where
        expect(groups[[1, 1]]).to eql (table.key1.eq(1) & table.key2.eq(1)).where
      end
    end
  end

  describe '#each' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 + 100} }

    let(:names){ subject._groups[0] }
    let(:groups){ subject._groups[1] }

    subject{ ObjectTable::TempGrouped.new(table){ {parity: col1 % 2} } }

    it 'should create a group' do
      group = spy('group')
      expect(ObjectTable::Grouped).to receive(:new).with(table, names, groups){ group }
      subject.each(&block)
    end

    it 'should call #each on the view' do
      group = spy('group')
      expect(ObjectTable::Grouped).to receive(:new){ group }
      expect(group).to receive(:each) do |&b|
        expect(b).to be block
      end

      subject.each(&block)
    end
  end

  describe '#apply' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 + 100} }

    let(:names){ subject._groups[0] }
    let(:groups){ subject._groups[1] }

    subject{ ObjectTable::TempGrouped.new(table){ {parity: col1 % 2} } }

    it 'should create a group' do
      group = spy('group')
      expect(ObjectTable::Grouped).to receive(:new).with(table, names, groups){ group }
      subject.apply(&block)
    end

    it 'should call #apply on the view' do
      group = spy('group')
      expect(ObjectTable::Grouped).to receive(:new){ group }
      expect(group).to receive(:apply) do |&b|
        expect(b).to be block
      end

      subject.apply(&block)
    end
  end

end
