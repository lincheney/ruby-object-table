require 'object_table'

RSpec.shared_examples 'an object table' do |cls|
  before do
    @cls = cls
  end

  def _make_relevant_table(table)
    if @cls == ObjectTable
      table

    elsif @cls == ObjectTable::View
      table.stack! ObjectTable::BasicGrid[table.columns.map{|k, v| [k, v.max]}]
      column = table.colnames.first
      table[column][-1] += 1
      table.where{table[column] < table[column][-1]}

    else
      nil
    end
  end

  subject{ _make_relevant_table(table) }

  describe '#inspect' do
    let(:table){ ObjectTable.new(col1: 1..10, col2: 5) }
    it 'should succeed' do
      expect{subject.inspect}.to_not raise_error
    end

    it 'should have a header listing the dimensions' do
      expect(subject.inspect.lines.first).to eql "#{subject.class}(#{subject.nrows}, #{subject.ncols})\n"
    end

    it 'should include the column names at the top and bottom' do
      expect(subject.inspect.lines[1].split).to eql subject.colnames.map(&:to_s)
      expect(subject.inspect.lines[-1].split).to eql subject.colnames.map(&:to_s)
    end

    context 'with few rows' do
      let(:table){ ObjectTable.new(col1: 1..10, col2: 5) }

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
      let(:table){ ObjectTable.new(col1: 1..100, col2: 5) }

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
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: [5, 5, 5]) }

    it 'should respond to the column names as methods' do
      subject.columns.keys.each do |key|
        expect(subject).to respond_to key
        expect(subject.send(key)).to be subject.columns[key]
      end
    end

    describe '#[]' do
      it 'should allow access to columns through []' do
        subject.columns.keys.each do |key|
          expect(subject[key]).to be subject.columns[key]
        end
      end
    end
  end

  describe '==' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: [5, 5, 5]) }

    it 'should fail for non-tables' do
      expect(subject == 'not a table').to be_falsey
    end

    context 'against a ObjectTable' do
      context 'with different contents' do
        let(:other){ ObjectTable.new(col1: [1, 2, 3], col2: 10000) }

        it 'should fail' do
          expect(subject == other).to be_falsey
        end
      end

      context 'with the same contents' do
        let(:other){ ObjectTable.new(col1: [1, 2, 3], col2: [5, 5, 5]) }

        it 'should succeed' do
          expect(subject == other).to be_truthy
        end
      end
    end

    context 'against a ObjectTable::View' do
      let(:view_parent){ ObjectTable.new(col2: [5, 5, 5, 1000], col1: [1, 2, 3, 4]) }

      context 'with different contents' do
        let(:other){ view_parent.where{ col1 > 1} }

        it 'should fail' do
          expect(subject == other).to be_falsey
        end
      end

      context 'with the same contents' do
        let(:other){ view_parent.where{ col1 < 4} }

        it 'should succeed' do
          expect(subject == other).to be_truthy
        end
      end
    end

  end

  describe '#apply' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    it 'should evaluate in the context of the table' do
      expect(subject.apply{ col1 }).to eql subject.col1
      expect(subject.apply{ col2.sum }).to eql subject.col2.sum
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
    let(:filtered){ subject.where &block }

    it 'should return a view' do
      expect(filtered).to be_a ObjectTable::View
      expect(filtered.instance_eval('@filter')).to eql block
    end
  end

  describe '#group' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 > 1} }
    let(:grouped){ subject.group &block }

    it 'should return groups' do
      expect(grouped).to be_a ObjectTable::Grouped
      expect(grouped.instance_eval('@grouper')).to eql block
    end
  end

  describe '.clone' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:clone){ subject.clone }

    it 'should return a new table' do
      expect(clone).to be_a ObjectTable
      expect(clone).to_not be subject
    end

    it 'should be equivalent to the original table' do
      expect(clone).to eql subject
    end

    it 'should have cloned columns' do
      subject.columns.each do |k, v|
        expect(clone.columns[k]).to eql v
        expect(clone.columns[k]).to_not be v
      end
    end
  end

  describe '#sort_by' do
    let(:table){ ObjectTable.new(col1: [2, 2, 1, 1], col2: [0, 1, 0, 1], col3: [5, 6, 7, 8]) }
    let(:sorted){ subject.sort_by(subject.col1, subject.col2) }

    it 'should return a new table' do
      expect(sorted).to be_a ObjectTable
      expect(sorted).to_not be subject
    end

    it 'should sort by the given columns' do
      expect(sorted).to eql ObjectTable.new(
        col1: [1, 1, 2, 2],
        col2: [0, 1, 0, 1],
        col3: [7, 8, 5, 6],
      )
    end
  end

end