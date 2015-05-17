require 'object_table'
require_relative 'utils'

RSpec.shared_examples 'a join operation' do |all_left, all_right|
  let(:total_groups)  { 50 }
  let(:groups)        { 40 }
  let(:lsize)         { 10 }
  let(:rsize)         { 5 }

  let(:key1)    { (0...total_groups).map{|i| "key1_#{i}"} }
  let(:key2)    { (0...total_groups).map{|i| "key2_#{i}"} * 2 }

  let(:__left__) do
    ObjectTable.new(
      key1:   key1[0, groups] * lsize,
      key2:   key2[0, groups/2] * 2 * lsize,
      lval1:  NArray.object(groups * lsize).map!{rand},
      lval2:  NArray.object(10, groups * lsize).map!{rand},
      )
  end

  let(:__right__) do
    ObjectTable.new(
      key1:   key1[-groups, groups] * rsize,
      key2:   key2[-groups, groups/2] * 2 * rsize,
      rval1:  NArray.object(groups * rsize).map!{rand},
      )
  end

  let(:left)  { make_table(__left__, described_class) }
  let(:right) { make_table(__right__, described_class) }

  let(:common)      { subject.where{lval1.ne(nil).and(rval1.ne(nil))}.clone }
  let(:left_only)   { subject.where{rval1.eq nil}.clone }
  let(:right_only)  { subject.where{lval1.eq nil}.clone }

  let(:lkeys) { ObjectTable::Util.get_rows(left, [:key1, :key2]) }
  let(:rkeys) { ObjectTable::Util.get_rows(right, [:key1, :key2]) }

  let(:expected_left_only) do
    mask = lkeys.map{|k| rkeys.include?(k) ? 0 : 1}
    left.where{NArray.to_na(mask).to_type('byte')}
  end

  let(:expected_right_only) do
    mask = rkeys.map{|k| lkeys.include?(k) ? 0 : 1}
    right.where{NArray.to_na(mask).to_type('byte')}
  end

  it 'shold have all columns' do
    expect(subject.colnames).to eql [:key1, :key2, :lval1, :lval2, :rval1]
  end

  it 'should have the correct keys' do
    join_keys = ObjectTable::Util.get_rows(subject, [:key1, :key2])

    unless all_left
      expect(join_keys & (lkeys - rkeys)).to be_empty
    end

    unless all_right
      expect(join_keys & (rkeys - lkeys)).to be_empty
    end
  end

  it 'should duplicate keys correctly' do
    keys = lkeys & rkeys
    counts = common.group_by(:key1, :key2).apply{ nrows }
    expect(ObjectTable::Util.get_rows(counts, [:key1, :key2])).to match_array(keys)
    expect(counts.v_0.to_a).to eq ([lsize * rsize] * keys.size)
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
        keys = rkeys - lkeys
        expect(right_only.key1.to_a).to eq keys.transpose[0]
        expect(right_only.key2.to_a).to eq keys.transpose[1]
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
        keys = lkeys - rkeys
        expect(left_only.key1.to_a).to eq keys.transpose[0]
        expect(left_only.key2.to_a).to eq keys.transpose[1]
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


RSpec.shared_examples 'a table joiner' do
  context 'inner join' do
    let(:join_type) { 'inner' }
    it_behaves_like 'a join operation', false, false
  end

  context 'left join' do
    let(:join_type) { 'left' }
    it_behaves_like 'a join operation', true, false
  end

  context 'right join' do
    let(:join_type) { 'right' }
    it_behaves_like 'a join operation', false, true
  end

  context 'outer join' do
    let(:join_type) { 'outer' }
    it_behaves_like 'a join operation', true, true
  end
end
