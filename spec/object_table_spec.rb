require 'object_table'

describe ObjectTable do

  describe '#initialize' do
    let(:columns){ {} }
    subject{ ObjectTable.new columns }

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

    it 'should have a header listing the dimensions' do
      expect(subject.inspect.lines.first).to eql "ObjectTable(#{subject.nrows}, #{subject.ncols})\n"
    end

    it 'should include the column names at the top and bottom' do
      expect(subject.inspect.lines[1].split).to eql subject.colnames.map(&:to_s)
      expect(subject.inspect.lines[-1].split).to eql subject.colnames.map(&:to_s)
    end

    context 'with few rows' do
      subject{ ObjectTable.new(col1: 1..10, col2: 5) }

      it 'should include all the rows' do
        table = subject.inspect.lines[1..-1].join + "\n"
        expect(table).to eql <<EOS
       col1  col2
  0:      1     5
  1:      2     5
  2:      3     5
  3:      4     5
  4:      5     5
  5:      6     5
  6:      7     5
  7:      8     5
  8:      9     5
  9:     10     5
       col1  col2
EOS
      end
    end

    context 'with many rows' do
      subject{ ObjectTable.new(col1: 1..100, col2: 5) }

      it 'should only include the top and bottom 5 rows' do
        table = subject.inspect.lines[1..-1].join + "\n"
        expect(table).to eql <<EOS
        col1  col2
   0:      1     5
   1:      2     5
   2:      3     5
   3:      4     5
   4:      5     5
------------------
  95:     96     5
  96:     97     5
  97:     98     5
  98:     99     5
  99:    100     5
        col1  col2
EOS
      end
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

  describe '#stack!' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    subject{ table.stack! *others }

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

  describe '.stack' do
    let(:data) do
      [
        ObjectTable.new(col1: [1, 2, 3], col2: 5),
        ObjectTable.new(col1: 10, col2: 50),
        ObjectTable.new(col2: [10, 30], col1: 15),
        ObjectTable::BasicGrid[col2: [1, 2], col1: [3, 4]],
      ]
    end

    subject{ ObjectTable.stack *data }

    it 'should join the tables and grids together' do
      expect(subject).to be_a ObjectTable
      expect(subject.col1.to_a).to eql ([1, 2, 3] + [10] + [15]*2 + [3, 4])
      expect(subject.col2.to_a).to eql ([5]*3 + [50] + [10, 30] + [1, 2])
    end
  end

end