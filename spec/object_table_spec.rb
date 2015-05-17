require 'object_table'

require 'support/object_table_example'
require 'support/stacking_example'

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
        key1:   key1[lkeys] * lsize,
        key2:   key2[lkeys] * lsize,
        lval1:  NArray.object(lgroups * lsize).map!{rand},
        lval2:  NArray.object(10, lgroups * lsize).map!{rand},
        )
    end

    let(:right) do
      ObjectTable.new(
        key1:   key1[rkeys] * rsize,
        key2:   key2[rkeys] * rsize,
        rval1:  NArray.object(rgroups * rsize).map!{rand},
        )
    end

    subject           { left.join(right, :key1, :key2, type: join_type) }
    let(:common)      { subject.where{lval1.ne(nil).and(rval1.ne(nil))}.clone }
    let(:left_only)   { subject.where{rval1.eq nil}.clone }
    let(:right_only)  { subject.where{lval1.eq nil}.clone }

    let(:expected_left_only) do
      a = left.apply{[key1.to_a, key2.to_a]}.transpose
      b = [key1[0...-rgroups], key2[0...-rgroups]].transpose
      mask = a.map{|k| b.include?(k) ? 1 : 0}
      left.where{NArray.to_na(mask).to_type('byte')}
    end

    let(:expected_right_only) do
      a = right.apply{[key1.to_a, key2.to_a]}.transpose
      b = [key1[lgroups..-1], key2[lgroups..-1]].transpose
      mask = a.map{|k| b.include?(k) ? 1 : 0}
      right.where{NArray.to_na(mask).to_type('byte')}
    end

    shared_examples 'a table joiner' do |all_left, all_right|
      it 'shold have all columns' do
        expect(subject.colnames).to eql [:key1, :key2, :lval1, :lval2, :rval1]
      end

      it 'should have the correct keys' do
        unless all_left
          expect(subject.key1.to_a).to_not include(*key1[0...-rgroups])
          expect(subject.key2.to_a).to_not include(*key2[0...-rgroups])
        end

        unless all_right
          expect(subject.key1.to_a).to_not include(*key1[lgroups...-1])
          expect(subject.key2.to_a).to_not include(*key2[lgroups...-1])
        end
      end

      it 'should duplicate keys correctly' do
        counts = common.group_by(:key1, :key2).apply{ nrows }
        expect(counts.v_0.to_a).to eq ([lsize * rsize] * common_keys.size)
      end

      it 'should cross product the values' do
        common.group_by(:key1, :key2).each do |grp|
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

      describe 'missing left keys' do
        if all_right
          it 'should have the right keys' do
            counts = right_only.group_by(:key1, :key2).apply{ nrows }
            expect(counts.v_0.to_a).to eq ([rsize] * (groups - lgroups))
          end

          it 'should fill the right values with nil' do
            expect(right_only.lval1.to_a).to eq [nil] * right_only.nrows
            expect(right_only.lval2.to_a).to eq [[nil] * 10] * right_only.nrows
          end

          it 'should keep the right columns' do
            right_only.pop_column(:lval1)
            right_only.pop_column(:lval2)
            expect(right_only).to eq expected_right_only
          end

        else
          it 'should not have any' do
            expect(right_only.nrows).to eq 0
          end
        end
      end

      describe 'with missing right keys' do
        if all_left
          it 'should have the left keys' do
            counts = left_only.group_by(:key1, :key2).apply{ nrows }
            expect(counts.v_0.to_a).to eq ([lsize] * (groups - rgroups))
          end

          it 'should fill the right values with nil' do
            expect(left_only.rval1.to_a).to eq [nil] * left_only.nrows
          end

          it 'should keep the left columns' do
            left_only.pop_column(:rval1)
            expect(left_only).to eq expected_left_only
          end

        else
          it 'should not have any' do
            expect(left_only.nrows).to eq 0
          end
        end
      end

    end

    context 'inner join' do
      let(:join_type) { 'inner' }
      it_behaves_like 'a table joiner', false, false
    end

    context 'left join' do
      let(:join_type) { 'left' }
      it_behaves_like 'a table joiner', true, false
    end

    context 'right join' do
      let(:join_type) { 'right' }
      it_behaves_like 'a table joiner', false, true
    end

    context 'outer join' do
      let(:join_type) { 'outer' }
      it_behaves_like 'a table joiner', true, true
    end

  end

end
