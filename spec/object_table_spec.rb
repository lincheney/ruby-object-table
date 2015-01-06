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

  context '#set_column' do
    let(:value){ [4, 5, 6] }
    let(:args) { [] }
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }

    let(:column) { table.colnames[0] }

    subject{ table.set_column(column, value, *args) }

    it 'should allow assigning columns' do
      subject
      expect(table.columns[column].to_a).to eql value
    end

    it 'should coerce the value to a column' do
      subject
      expect(table.columns[column]).to be_a ObjectTable::Column
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

    context 'for a new column' do
      let(:column) { :col3 }

      it 'should create a new column' do
        subject
        expect(table.columns).to include column
        expect(table.columns[column].to_a).to eql value
      end

      it 'should assign the name of the column' do
        subject
        expect(table[column].name).to eql column
      end

      context 'with a range' do
        let(:value){ 0...3 }
        it 'should assign the range values' do
          subject
          expect(table.columns[column].to_a).to eql value.to_a
        end
      end

      it 'should create an object column by default' do
        subject
        expect(table.columns[column].typecode).to eql NArray.object(0).typecode
      end
    end

    context 'with narray args' do
      let(:args) { ['int', 3, 4] }
      let(:value){ NArray.float(table.nrows, 3, 4) }

      context 'for a new column' do
        let(:column) { :col3 }

        it 'should create a column with the typecode' do
          subject
          expect(table.columns[column].typecode).to eql NArray.new(*args).typecode
        end

        it 'should create a column with the correct size' do
          subject
          expect(table.columns[column].shape[0]).to eql table.nrows
          expect(table.columns[column].shape[1..-1]).to eql args[1..-1]
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
