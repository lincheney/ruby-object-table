require 'object_table'

describe ObjectTable do

  describe '#initialize' do
    let(:columns){ {} }
    subject{ ObjectTable.new columns }

    it 'should ensure the columns have the same number of rows' do
      grid = ObjectTable::BasicGrid.new
      allow(ObjectTable::BasicGrid).to receive(:[]).with(columns){ grid }
      expect(grid).to receive(:ensure_uniform_columns!)
      subject
    end

    it 'should convert all columns into ObjectTable::Columns' do
      subject.columns.values.each do |v|
        expect(v).to be_a ObjectTable::Column
      end
    end
  end

  describe '#inspect' do
    subject{ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    it 'should succeed' do
      expect{subject.inspect}.to_not raise_error
    end
  end

  describe 'column methods' do
    let(:columns){ {col1: [1, 2, 3], col2: 5} }
    subject{ ObjectTable.new(columns) }

    it 'should respond to the column names as methods' do
      columns.keys.each do |key|
        expect(subject).to respond_to key
        expect(subject.send(key)).to be subject.columns[key]
      end
    end

    describe '#[]' do
      it 'should allow access to columns through []' do
        columns.keys.each do |key|
          expect(subject[key]).to be subject.columns[key]
        end
      end
    end

    describe '#[]=' do
      let(:value){ [4, 5, 6] }
      subject{ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

      before do
        subject[:col1] = value
      end

      it 'should allow assigning columns' do
        expect(subject.columns[:col1].to_a).to eql value
      end

      it 'should coerce the value to a column' do
        expect(subject.columns[:col1]).to be_a ObjectTable::Column
      end

      context 'with the wrong length' do
        it 'should fail' do
          expect{subject[:col1] = [1, 2]}.to raise_error
        end
      end

      context 'with a scalar' do
        let(:value){ 10 }
        it 'should fill the column with that value' do
          expect(subject.columns[:col1].to_a).to eql ([value] * subject.nrows)
        end
      end

      context 'for a new column' do
        before do
          subject[:col3] = value
        end

        it 'should create a new column' do
          expect(subject.columns).to include :col3
          expect(subject.columns[:col3].to_a).to eql value
        end
      end
    end

  end

  describe '#apply' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    it 'should evaluate in the context of the table' do
      expect(table.apply{ col1 }).to eql table.col1
      expect(table.apply{ col2.sum }).to eql table.col2.sum
    end

    context 'with a block returning a grid' do
      subject{ table.apply{ ObjectTable::BasicGrid[col1: [4, 5, 6]] } }

      it 'should coerce to a table' do
        expect(subject).to be_a ObjectTable
      end
    end

    it 'should have access to a BasicGrid shortcut' do
      result = table.apply{ @R[value: col1 + 5] }
      expect(result).to be_a ObjectTable
      expect(result.value).to eql (table.col1 + 5)
    end
  end

  describe '#where' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 > 1} }

    subject{ table.where &block }

    it 'should return a view' do
      expect(subject).to be_a ObjectTable::View
      expect(subject.instance_eval('@filter')).to eql block
    end
  end

  describe '#group' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 > 1} }

    subject{ table.group &block }

    it 'should return a view' do
      expect(subject).to be_a ObjectTable::Grouped
      expect(subject.instance_eval('@grouper')).to eql block
    end
  end

  describe '#append!' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    subject{ table.append! *others }

    context 'with different columns' do
      let(:others){ [ObjectTable.new(col3: 10)] }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with the same columns' do
      let(:others) do
        [
          ObjectTable.new(col1: 10, col2: 50),
          ObjectTable.new(col2: [10, 30], col1: 15),
          ObjectTable::BasicGrid[col2: [1, 2], col1: [3, 4]],
        ]
      end

      it 'should append the rows to itself' do
        subject
        expect(table.col1.to_a).to eql ([1, 2, 3] + [10] + [15]*2 + [3, 4])
        expect(table.col2.to_a).to eql ([5]*3 + [50] + [10, 30] + [1, 2])
      end
    end
  end

end