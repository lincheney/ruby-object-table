require 'object_table'
require 'object_table/util'

describe ObjectTable::Util do
  let(:nrows) { 100 }
  let(:col1)  { NArray.float(10, nrows).random }
  let(:col2)  { NArray.object(nrows).map!{rand} }
  let(:col3)  { NArray.float(nrows).random }

  let(:table) { ObjectTable.new(col1: col2, col2: col2, col3: col3) }

  describe '.get_rows' do
    subject{ described_class.get_rows(table, [:col1, :col2]) }

    it 'should return an array of rows' do
      table.each_row(:col1, :col2).zip(subject) do |(col1, col2), row|
        expect(row).to eql [col1, col2]
      end
    end
  end

  describe '.group_indices' do
    let(:_key)  { %w{ a a b b a b c a } }
    let(:key)   { NArray.to_na(_key) }

    subject{ described_class.group_indices(key) }

    it 'should return a hash' do
      expect(subject).to be_a Hash
    end

    it 'should have all the keys' do
      expect(subject.keys).to match_array(_key.uniq)
    end

    it 'should group indices by key' do
      subject.each do |k, indices|
        expect(indices).to eq key.eq(k).where.to_a
      end
    end
  end

end