require 'object_table'

RSpec.shared_examples 'a table view' do |cls|
  before do
    @cls = cls
  end

  def _make_relevant_view(table, block)
    if @cls == ObjectTable::View
      @cls.new(table, &block)

    elsif @cls == ObjectTable::StaticView
      indices = table.apply(&block).where
      @cls.new(table, indices)

    else
      nil
    end
  end

  subject{ _make_relevant_view(table, block) }

  describe '#columns' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 > 2} }

    it 'should mask the columns of the parent table' do
      mask = table.col1 > 2
      table.columns.each do |k, v|
        expect(subject.columns[k].to_a).to eql v[mask].to_a
      end
    end

    it 'should make masked columns' do
      subject.columns.each do |k, v|
        expect(v).to be_a ObjectTable::MaskedColumn
      end
    end

    context 'with a matrixy narray in a column' do
      let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: NArray[[1,2,3], [4, 5, 6], [7, 8, 9]] ) }

      it 'should mask the matrixy narray too' do
        indices = (table.col1 > 2).where
        expect(subject.columns[:col2]).to eq table.col2[nil, indices]
      end

    end
  end


  describe '#set_column' do
    let(:table) { ObjectTable.new(col1: [0, 1, 2, 3], col2: 5) }
    let(:block) { Proc.new{col1 > 0} }
    let(:view)  { _make_relevant_view(table, block) }

    let(:column){ :col1 }
    let(:value) { [10, 20, 30] }

    let(:args)  { [] }

    subject{ view.set_column(column, value, *args) }

    context 'on an existing column' do
      it 'should assign values to the column' do
        subject
        expect(view.columns[column].to_a).to eql value
      end

      it 'should not modify anything outside the view' do
        subject
        expect(table.columns[column].to_a).to eql [0] + value
      end

    end

    context 'with a scalar' do
      let(:value){ 10 }
      it 'should fill the column with that value' do
        subject
        expect(view.columns[column].to_a).to eql ([value] * view.nrows)
      end
    end

    context 'with the wrong length' do
      let(:value) { [1, 2] }
      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'for a new column' do
      let(:column){ :col3 }

      it 'should create a new column' do
        subject
        expect(view.columns).to include column
        expect(view.columns[column].to_a).to eql value
      end

      it 'should affect the parent table' do
        subject
        expect(table.columns).to include column
      end

      it 'should fill values outside the view with a default' do
        subject
        default = NArray.new(table.columns[column].typecode, 1)[0]
        expect(table.columns[column].to_a).to eql [default] + value
      end

      context 'with an NArray' do
        let(:value){ NArray.float(3, 4, view.nrows).random! }

        it 'should use the narray parameters' do
          subject
          expect(view.columns[column].to_a).to eql value.to_a
        end
      end

      context 'when failed to add column' do
        let(:value){ NArray[1, 2, 3] }

        it 'should not have that column' do
          expect(view).to receive(:add_column).with(column, value.typecode) do
            table.columns[column] = ObjectTable::Column.make([0] * 10)
            view.columns[column] = ObjectTable::Column.make([0] * 10)
          end

#           the assignment is going to chuck an error
          subject rescue nil
          expect(view.columns).to_not include column
          expect(table.columns).to_not include column
        end
      end
    end

    context 'with an empty view' do
      let(:block) { Proc.new{col1 < 0} }

      context 'adding an empty column' do
        let(:value) { [] }
        it 'should add the column' do
          subject
          expect(view.columns[column].to_a).to eq value
        end
      end
    end

  end

  describe '#pop_column' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 > 2} }
    let(:view) { _make_relevant_view(table, block) }
    let(:name) { :col2 }

    subject{ view.pop_column(name) }

    it 'should remove the column' do
      subject
      expect(view.colnames).to_not include name
      expect(view.columns).to_not include name
    end

    it 'should remove the column from the parent too' do
      subject
      expect(table.colnames).to_not include name
      expect(table.columns).to_not include name
    end
  end

  describe '#inspect' do
    context 'with an empty table' do
      let(:table){ ObjectTable.new }
      let(:block){ Proc.new{nil} }

      subject{ table.where{ nil } }

      it 'should say it is empty' do
        text = subject.inspect.split("\n")[1..-1].map(&:rstrip).join("\n")
        expect(text).to eql "(empty table)"
      end
    end

    context 'with table with no rows' do
      subject{ ObjectTable.new(col1: [], col2: []) }
      let(:block){ Proc.new{nil} }

      it 'should give the columns' do
        text = subject.inspect.split("\n")[1..-1].map(&:rstrip).join("\n")
        expect(text).to eql "(empty table with columns: col1, col2)"
      end
    end
  end

  describe '#clone' do
    let(:table) { ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block) { Proc.new{col1 > 2} }
    let(:clone) { subject.clone }

    it 'should no longer have masked columns' do
      clone.columns.each do |k, v|
        expect(v).to be_a NArray
        expect(v).to_not be_a ObjectTable::MaskedColumn
      end
    end
  end

end
