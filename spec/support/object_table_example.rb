require 'object_table'
require_relative 'utils'

require 'support/joining_example'
require 'support/stacking_example'

RSpec.shared_examples 'an object table' do
  subject{ make_table(table, described_class) }

  describe '#inspect' do
    let(:table){ ObjectTable.new(col1: 1..10, col2: 5) }
    it 'should succeed' do
      expect{subject.inspect}.to_not raise_error
    end

    it 'should have a header listing the dimensions' do
      expect(subject.inspect.lines.to_a.first).to eql "#{subject.class}(#{subject.nrows}, #{subject.ncols})\n"
    end

    it 'should include the column names at the top and bottom' do
      expect(subject.inspect.lines.to_a[1].split).to eql subject.colnames.map(&:to_s)
      expect(subject.inspect.lines.to_a[-1].split).to eql subject.colnames.map(&:to_s)
    end

    context 'with few rows' do
      let(:table){ ObjectTable.new(col1: 1..10, col2: 5) }

      it 'should include all the rows' do
        table = subject.inspect.lines.to_a[1..-1].join + "\n"
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

    context 'with an odd number of rows' do
      let(:table){ ObjectTable.new(col1: 1..5, col2: 5) }

      it 'should include all the rows' do
        table = subject.inspect.lines.to_a[1..-1].join + "\n"
        expect(table).to eql <<EOS
       col1  col2
  0:      1     5
  1:      2     5
  2:      3     5
  3:      4     5
  4:      5     5
       col1  col2
EOS
      end
    end

    context 'with one row' do
      let(:table){ ObjectTable.new(col1: 1, col2: 5) }

      it 'should include all the rows' do
        table = subject.inspect.lines.to_a[1..-1].join + "\n"
        expect(table).to eql <<EOS
       col1  col2
  0:      1     5
       col1  col2
EOS
      end
    end

    context 'with many rows' do
      let(:table){ ObjectTable.new(col1: 1..100, col2: 5) }

      it 'should only include the top and bottom 5 rows' do
        table = subject.inspect.lines.to_a[1..-1].join + "\n"
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

    context 'with matrixy columns' do
      let(:table){ ObjectTable.new(col1: 1..100, col2: NArray.to_na([[1, 2]] * 100) ) }

      it 'should handle the matrixy columns' do
        table = subject.inspect.lines.to_a[1..-1].join + "\n"
        expect(table).to eql <<EOS
        col1      col2
   0:      1  [ 1, 2 ]
   1:      2  [ 1, 2 ]
   2:      3  [ 1, 2 ]
   3:      4  [ 1, 2 ]
   4:      5  [ 1, 2 ]
----------------------
  95:     96  [ 1, 2 ]
  96:     97  [ 1, 2 ]
  97:     98  [ 1, 2 ]
  98:     99  [ 1, 2 ]
  99:    100  [ 1, 2 ]
        col1      col2
EOS
      end

      context 'with long rows in the matrix' do
        let(:table){ ObjectTable.new(col1: 1..100, col2: NArray.to_na([(0...100).to_a] * 100) ) }

        it 'should let NArray truncate them' do
          table = subject.inspect.lines.to_a[1..-1].join + "\n"
        expect(table).to eql <<EOS
        col1                                                                           col2
   0:      1  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
   1:      2  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
   2:      3  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
   3:      4  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
   4:      5  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
-------------------------------------------------------------------------------------------
  95:     96  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
  96:     97  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
  97:     98  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
  98:     99  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
  99:    100  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, ... ]
        col1                                                                           col2
EOS
        end
      end

      context 'with > 3 dimensions in the matrix' do
        let(:table){ ObjectTable.new(col1: 1..100, col2: NArray.int(2, 2, 100).indgen! ) }

        it 'should align the columns' do
          table = subject.inspect.split("\n")[1..-1].map(&:rstrip).join("\n") + "\n"
          expect(table).to eql <<EOS
        col1              col2
   0:      1      [ [ 0, 1 ],
                    [ 2, 3 ] ]
   1:      2      [ [ 4, 5 ],
                    [ 6, 7 ] ]
   2:      3      [ [ 8, 9 ],
                  [ 10, 11 ] ]
   3:      4    [ [ 12, 13 ],
                  [ 14, 15 ] ]
   4:      5    [ [ 16, 17 ],
                  [ 18, 19 ] ]
------------------------------
  95:     96  [ [ 380, 381 ],
                [ 382, 383 ] ]
  96:     97  [ [ 384, 385 ],
                [ 386, 387 ] ]
  97:     98  [ [ 388, 389 ],
                [ 390, 391 ] ]
  98:     99  [ [ 392, 393 ],
                [ 394, 395 ] ]
  99:    100  [ [ 396, 397 ],
                [ 398, 399 ] ]
        col1              col2
EOS
        end
      end

    end

    context 'when raising a no method error' do
      it 'should propagate it as some other exception' do
        expect(subject).to receive(:columns){ raise NoMethodError.new('asd') }
        expect{subject.inspect}.to raise_error do |error|
          expect(error).to_not be_a NoMethodError
          expect(error.message).to eql 'asd'
        end
      end
    end

  end

  describe '#has_column?' do
    let(:table) { ObjectTable.new(col1: [1, 2, 3], col2: [5, 5, 5]) }

    it 'should be true for columns in the table' do
      expect(subject).to have_column :col1
      expect(subject).to have_column :col2
    end

    it 'should be false for columns not in the table' do
      expect(subject).to_not have_column :col3
      expect(subject).to_not have_column 'something else'
    end
  end

  describe '#nrows' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: [5, 5, 5]) }

    it 'should return the number of rows' do
      expect(table.nrows).to eql 3
    end

    context 'on an empty table' do
      let(:table){ ObjectTable.new }

      it 'should return 0' do
        expect(table.nrows).to eql 0
      end
    end

    context 'on a table with empty columns' do
      let(:table){ ObjectTable.new(a: []) }

      it 'should return 0' do
        expect(table.nrows).to eql 0
      end
    end
  end

  describe 'column methods' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: [5, 5, 5]) }

    it 'should respond to the column names as methods' do
      subject.columns.keys.each do |key|
        expect(subject).to respond_to key
        expect(subject.send(key)).to eql subject.columns[key]
      end
    end

    describe '#[]' do
      it 'should allow access to columns through []' do
        subject.columns.keys.each do |key|
          expect(subject[key]).to eql subject.columns[key]
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

    it 'should return the results of the block' do
      expect(subject.apply{ col1 }).to eql subject.col1
    end

    context 'with a block returning a grid' do
      let(:result)  { subject.apply{ ObjectTable::BasicGrid[col1: [4, 5, 6]] } }

      it 'should coerce to a table' do
        expect(result).to be_a ObjectTable
      end
    end

    it 'should have access to a BasicGrid shortcut' do
      result = subject.apply{ @R[value: col1 + 5] }
      expect(result).to be_a ObjectTable
      expect(result.value).to eql (subject.col1 + 5)
    end

    context 'when the block takes an argument' do
      it 'should not evaluate in the context of the table' do
        rspec_context = self

        subject.apply do |tbl|
          receiver = eval('self', binding)
          expect(receiver).to_not be subject
          expect(receiver).to be rspec_context
        end
      end

      it 'should pass the table into the block' do
        subject.apply do |tbl|
          expect(tbl).to eq subject
        end
      end
    end

    context 'when the block takes no arguments' do
      it 'should call the block in the context of the table' do
        _ = self
        subject.apply do
          receiver = eval('self', binding)
          _.expect(receiver).to _.eq _.subject
        end
      end
    end

  end

  describe '#where' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 > 1} }
    let(:filtered){ subject.where &block }

    it 'should return a temp view' do
      expect(filtered).to be_a ObjectTable::View
      expect(filtered.instance_eval('@filter')).to eql block
    end
  end

  describe '#group_by' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 > 1} }
    let(:grouped){ subject.group_by &block }

    it 'should return groups' do
      expect(grouped).to be_a ObjectTable::Grouping
      expect(grouped.instance_eval('@grouper')).to eql block
    end
  end

  describe '#clone' do
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
        expect(clone.columns[k]).to eq v
        expect(clone.columns[k]).to_not be v
      end
    end

    context 'with matrixy columns' do
      let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: NArray.float(10, 3).random!) }

      it 'should be equivalent to the original table' do
        expect(clone).to eql subject
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

  describe '#each_row' do
    let(:col1)  { [1, 2, 3, 4] }
    let(:col2)  { [NArray[1, -1], NArray[2, -2], NArray[3, -3], NArray[4, -4]] }
    let(:col3)  { %w{ a b c d } }

    let(:table) { ObjectTable.new(col1: col1, col2: col2, col3: col3) }

    context 'with a block' do
      it 'should yield successive rows' do
        rows = []
        subject.each_row{|row| rows.push row}
        expect(rows.map(&:col1)).to eq col1
        expect(rows.map(&:col2)).to eq col2
        expect(rows.map(&:col3)).to eq col3
      end
    end

    context 'without a block' do
      it 'should return an enumerator' do
        enum = subject.each_row
        expect(enum).to be_a Enumerator
      end

      it 'should yield successive rows' do
        rows = subject.each_row.to_a
        expect(rows.map(&:col1)).to eq col1
        expect(rows.map(&:col2)).to eq col2
        expect(rows.map(&:col3)).to eq col3
      end
    end

    context 'with specific columns' do
      it 'should yield those columns' do
        rows = subject.each_row(:col1, :col3).to_a.transpose
        expect(rows).to eql [col1, col3]
      end
    end

    context 'with an empty table' do
      let(:table) { ObjectTable.new }
      it 'should do nothing' do
        expect(subject.each_row.to_a).to be_empty
      end
    end

    context 'with a row factory' do
      it 'should use the row factory' do
        tmp_cls = Class.new(Struct)
        subject.each_row(row_factory: tmp_cls) do |row|
          expect(row).to be_a tmp_cls
        end
      end
    end

  end

  describe '#stack' do
    it_behaves_like 'a stacking operation' do
      subject{ grids[0].stack *grids[1..-1] }

      it 'should make a new table' do
        expect(subject).to_not be grids[0]
      end

      it 'should duplicate the contents' do
        grids.each do |chunk|
          expect(subject).to_not be chunk
        end
      end

      context 'with no arguments' do
        let(:table){ ObjectTable.new(col1: 1..100, col2: 5) }
        let(:grids){ [table] }

        it 'should make a copy' do
          expect(subject).to eql table
          expect(subject).to_not be table
        end
      end
    end
  end

  describe '#join' do
    it_behaves_like 'a table joiner' do
      subject{ left.join(right, :key1, :key2, type: join_type) }
    end
  end

end
