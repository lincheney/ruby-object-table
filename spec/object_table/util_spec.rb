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
end