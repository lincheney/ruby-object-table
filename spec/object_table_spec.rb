require 'object_table'

require 'support/object_table_example'
require 'support/stacker_example'

describe ObjectTable do
  it_behaves_like 'an object table', ObjectTable
  it_behaves_like 'a table stacker'

  describe '#initialize' do
    let(:columns){ {col1: [1, 2, 3], col2: NArray[4, 5, 6], col3: 7..9, col4: 10} }
    subject{ ObjectTable.new columns }

    it 'should convert all columns into NArrays' do
      subject.columns.values.each do |v|
        expect(v).to be_a NArray
      end
    end

    it 'should include all the columns' do
      grid = ObjectTable::BasicGrid[columns]
      grid._ensure_uniform_columns!

      grid.each do |k, v|
        expect(subject[k].to_a).to eql v.to_a
      end
    end

    context 'with multi dimensional columns' do
      let(:columns){ {col1: [1, 2, 3], col2: [[4, 4], [5, 5], [6, 6]]} }

      it 'should convert all columns into NArrays' do
        subject.columns.values.each do |v|
          expect(v).to be_a NArray
        end
      end

      it 'should include all the columns' do
        grid = ObjectTable::BasicGrid[columns]
        grid._ensure_uniform_columns!

        grid.each do |k, v|
          expect(subject[k].to_a).to eql v.to_a
        end
      end

      it 'should preserve the dimensions' do
        expect(subject[:col2].shape).to eql NArray.to_na(columns[:col2]).shape
      end
    end

  end

  describe '#inspect' do
    context 'with an empty table' do
      subject{ ObjectTable.new }
      it 'should say it is empty' do
        text = subject.inspect.split("\n")[1..-1].map(&:rstrip).join("\n")
        expect(text).to eql "(empty table)"
      end
    end

    context 'with table with no rows' do
      subject{ ObjectTable.new(col1: [], col2: []) }
      it 'should give the columns' do
        text = subject.inspect.split("\n")[1..-1].map(&:rstrip).join("\n")
        expect(text).to eql "(empty table with columns: col1, col2)"
      end
    end
  end

  context '#set_column' do
    let(:value){ [4, 5, 6] }
    let(:args) { [] }
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    subject{ table.set_column(column, value, *args) }

    shared_examples 'a column setter' do
      it 'should allow assigning columns' do
        subject
        expect(table.columns[column].to_a).to eql value
      end

      it 'should coerce the value to a narray' do
        subject
        expect(table.columns[column]).to be_a NArray
      end

      context 'with the wrong length' do
        let(:value) { [1, 2] }
        it 'should fail' do
          expect{subject}.to raise_error
        end
      end

      context 'with a scalar' do
        let(:value){ 10 }
        it 'should fill the column with that value' do
          subject
          expect(table.columns[column].to_a).to eql ([value] * table.nrows)
        end
      end

      context 'with a range' do
        let(:value){ 0...3 }
        it 'should assign the range values' do
          subject
          expect(table.columns[column].to_a).to eql value.to_a
        end
      end

      context 'with an empty table' do
        let(:table) { ObjectTable.new }
        let(:value) { 3 }

        context 'adding an empty column' do
          it 'should add the column' do
            subject
            expect(table.columns[column]).to eq NArray[]
          end

          context 'and setting an empty array to the column' do
            it 'should work' do
              subject
              expect{table[column] = []}.to_not raise_error
              expect(table[column]).to be_empty
            end
          end

        end
      end

    end

    context 'for a new column' do
      let(:column) { :col3 }

      it_behaves_like 'a column setter'

      it 'should create a new column' do
        subject
        expect(table.columns).to include column
        expect(table.columns[column].to_a).to eql value
      end

      context 'with a range' do
        let(:value){ 0...3 }
        it 'should assign the range values' do
          subject
          expect(table.columns[column].to_a).to eql value.to_a
        end
      end

      context 'with an NArray' do
        let(:value){ NArray.int(3, 4, table.nrows) }

        it 'should use the narray parameters' do
          subject
          expect(table.columns[column].to_a).to eql value.to_a
        end
      end

      context 'when failed to add column' do
        let(:value) { 'a' }
        let(:args)  { ['int'] }

        it 'should fail' do
          expect{subject}.to raise_error
        end

        it 'should not have that column' do
#           the assignment is going to chuck an error
          subject rescue nil
          expect(table.columns).to_not include column
        end
      end

      context 'with narray args' do
        let(:args) { ['int', 3, 4] }
        let(:value){ NArray.float(3, 4, table.nrows) }

        it 'should create a column with the typecode' do
          subject
          expect(table.columns[column].typecode).to eql NArray.new(*args).typecode
        end

        it 'should create a column with the correct size' do
          subject
          expect(table.columns[column].shape[-1]).to eql table.nrows
          expect(table.columns[column].shape[0...-1]).to eql args[1..-1]
        end
      end

    end

    context 'on an existing column' do
      let(:column) { table.colnames[0] }
      it_behaves_like 'a column setter'

      context 'when failed to set column' do
        let(:value) { 'a' }

        it 'should fail' do
          expect{subject}.to raise_error
        end

        it 'should still have the column' do
#           the assignment is going to chuck an error
          subject rescue nil
          expect(table.columns).to include column
        end

        it 'should make no changes' do
          original = table.clone
          subject rescue nil
#           the assignment is going to chuck an error
          expect(table).to eql original
        end
      end
    end

  end

  describe '#pop_column' do
    let(:table)   { ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:name)    { :col2 }

    subject{ table.pop_column(name) }

    it 'should remove the column' do
      subject
      expect(table.colnames).to_not include name
      expect(table.columns).to_not include name
    end

    it 'should return the column' do
      column = table[name]
      expect(subject).to be column
    end
  end

  describe '#sort_by!' do
    let(:table){ ObjectTable.new(col1: [2, 2, 1, 1], col2: [0, 1, 0, 1], col3: [5, 6, 7, 8]) }
    subject{ table.sort_by!(table.col1, table.col2) }

    it 'should modify the table' do
      expect(subject).to be table
    end

    it 'should sort by the given columns' do
      expect(subject).to eql table.sort_by(table.col1, table.col2)
    end
  end

  describe '#join' do
    let(:groups)  { 100 }
    let(:lsize)   { 10 }
    let(:rsize)   { 5 }

    let(:lgroups) { 80 }
    let(:rgroups) { 80 }

    let(:key1)    { (0...groups).map{|i| "key1_#{i}"} }
    let(:key2)    { (0...groups).map{|i| "key2_#{i}"} }

    let(:lkeys)   { 0...lgroups }
    let(:rkeys)   { (groups-rgroups)..-1 }
    let(:common_keys) { (groups-rgroups)...lgroups }

    let(:left) do
      ObjectTable.new(
        key1:   key1[0...lgroups] * lsize,
        key2:   key2[0...lgroups] * lsize,
        lval1:  NArray.float(lgroups * lsize).random,
        lval2:  NArray.float(10, lgroups * lsize).random,
        )
    end

    let(:right) do
      ObjectTable.new(
        key1:   key1[-rgroups..-1] * rsize,
        key2:   key2[-rgroups..-1] * rsize,
        rval1:  NArray.float(rgroups * rsize).random,
        )
    end

    context 'inner join' do
      subject{ left.join(right, :key1, type: 'inner') }

      it 'shold have all columns' do
        expect(subject.colnames).to eql [:key1, :key2, :lval1, :lval2, :rval1]
      end

      it 'should only have common keys' do
        expect(subject.key1.to_a).to_not include(*key1[0...-rgroups])
        expect(subject.key1.to_a).to_not include(*key1[lgroups...-1])
        expect(subject.key2.to_a).to_not include(*key2[0...-rgroups])
        expect(subject.key2.to_a).to_not include(*key2[lgroups...-1])
      end

      it 'should duplicate keys correctly' do
        counts = subject.group_by(:key1, :key2).apply{ nrows }
        expect(counts.v_0.to_a).to eq ([lsize * rsize] * common_keys.size)
      end

      it 'should cross product the values' do
        subject.group_by(:key1, :key2).each do |grp|
          filter = Proc.new{|t| t.key1.eq(grp.K.key1).and(t.key2.eq(grp.K.key2)) }
          lgroup = left.where(&filter)
          rgroup = right.where(&filter)

          lvalues = lgroup.apply{[lval1.to_a, lval2.to_a]}.transpose
          rvalues = rgroup.apply{[rval1.to_a]}.transpose
          joined_values = grp.apply{[lval1, lval2, rval1]}.map(&:to_a).transpose

          expected = lvalues.product(rvalues).map{|row| row.flatten(1)}
          expect(joined_values).to eq expected
        end
      end
    end

    context 'left join' do
      subject{ left.join(right, key=:key1, type: 'left') }

      let(:result) do
        ObjectTable.new(
          key1:   [ "b",  "b",  "c",  "a",  "a"],
          lvalue: [   1,    3,    4,    0,    2],
          rvalue: [   2,    2,    1,    0,    0],
          )
      end

      it 'should return the joined result' do
        expect(subject).to eql result
      end
    end

    context 'right join' do
      subject{ left.join(right, key=:key1, type: 'right') }

      let(:result) do
        ObjectTable.new(
          key1:   [ "b",  "b",  "c",  "d"],
          lvalue: [   1,    3,    4,    0],
          rvalue: [   2,    2,    1,    0],
          )
      end

      it 'should return the joined result' do
        expect(subject).to eql result
      end
    end

    context 'outer join' do
      subject{ left.join(right, key=:key1, type: 'outer') }

      let(:result) do
        ObjectTable.new(
          key1:   [ "b",  "b",  "c",  "a",  "a",  "d"],
          lvalue: [   1,    3,    4,    0,    2,    0],
          rvalue: [   2,    2,    1,    0,    0,    0],
          )
      end

      it 'should return the joined result' do
        expect(subject).to eql result
      end
    end

  end

end
