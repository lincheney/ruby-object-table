require 'object_table'
require 'object_table/view'

describe ObjectTable::View do

  describe '#columns' do
    let(:table){ ObjectTable.new(a: [1, 2, 3], b: 5) }

    subject{ ObjectTable::View.new(table){ a > 2 } }

    it 'should mask the columns of the parent table' do
      mask = table.a > 2
      table.columns.each do |k, v|
        expect(subject.columns[k]).to eql v[mask]
      end
    end
  end

end
