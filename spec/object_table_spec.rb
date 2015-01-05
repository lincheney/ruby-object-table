require 'object_table'

require 'support/object_table_example'

describe ObjectTable do
  it_behaves_like 'an object table', ObjectTable

  describe '#initialize' do
    let(:columns){ {} }
    subject{ ObjectTable.new columns }

    it 'should convert all columns into ObjectTable::Columns' do
      subject.columns.values.each do |v|
        expect(v).to be_a ObjectTable::Column
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

    context 'with a range' do
      let(:value){ 0...3 }
      it 'should assign the range values' do
        expect(subject.columns[:col1].to_a).to eql value.to_a
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

      it 'should assign the name of the column' do
        expect(subject[:col3].name).to eql :col3
      end

      context 'with a range' do
        let(:value){ 0...3 }
        it 'should assign the range values' do
          expect(subject.columns[:col3].to_a).to eql value.to_a
        end
      end
    end
  end

  describe '.stack' do
    let(:others) do
      [
        ObjectTable.new(col1: [1, 2, 3], col2: 5),
        ObjectTable.new(col1: 10, col2: 50),
        ObjectTable.new(col2: [10, 30], col1: 15).where{col2.eq 10},
        ObjectTable::BasicGrid[col2: [1, 2], col1: [3, 4]],
      ]
    end

    subject{ ObjectTable.stack *others }

    it 'should join the tables and grids together' do
      expect(subject).to be_a ObjectTable
      expect(subject).to eql ObjectTable.new(
        col1: others.flat_map{|x| x[:col1].to_a},
        col2: others.flat_map{|x| x[:col2].to_a},
        )
    end

    it 'should duplicate the contents' do
      others.each do |chunk|
        expect(subject).to_not be chunk
      end
    end

    context 'with non grids/tables' do
      let(:others){ [ObjectTable.new(col1: 10, col2: 50), 'not a table'] }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with differing column names' do
      let(:others){ [ObjectTable.new(col1: 10, col2: 50), ObjectTable.new(col1: 10, col3: 50)] }

      it 'should fail' do
        expect{subject}.to raise_error
      end
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

end
