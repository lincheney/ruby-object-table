require 'object_table'
require_relative 'utils'

RSpec.shared_examples 'a table joiner' do |cls|
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

    let(:__left__) do
      ObjectTable.new(
        key1:   key1[lkeys] * lsize,
        key2:   key2[lkeys] * lsize,
        lval1:  NArray.object(lgroups * lsize).map!{rand},
        lval2:  NArray.object(10, lgroups * lsize).map!{rand},
        )
    end

    let(:__right__) do
      ObjectTable.new(
        key1:   key1[rkeys] * rsize,
        key2:   key2[rkeys] * rsize,
        rval1:  NArray.object(rgroups * rsize).map!{rand},
        )
    end

    let(:left)  { make_table(__left__, cls) }
    let(:right) { make_table(__right__, cls) }

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

    shared_examples 'a join' do |all_left, all_right|
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
      it_behaves_like 'a join', false, false
    end

    context 'left join' do
      let(:join_type) { 'left' }
      it_behaves_like 'a join', true, false
    end

    context 'right join' do
      let(:join_type) { 'right' }
      it_behaves_like 'a join', false, true
    end

    context 'outer join' do
      let(:join_type) { 'outer' }
      it_behaves_like 'a join', true, true
    end

  end
end
