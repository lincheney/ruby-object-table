require 'object_table'

RSpec.shared_examples 'a table view' do

  def _make_relevant_view(table, block, cls)
    if cls == ObjectTable::View
      cls.new(table, &block)

    elsif cls == ObjectTable::StaticView
      indices = table.apply(&block).where
      cls.new(table, indices)

    else
      raise "Could not make a a #{cls.inspect} view"
    end
  end

  subject{ _make_relevant_view(table, block, described_class) }

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
    let(:view)  { _make_relevant_view(table, block, described_class) }

    let(:value) { [10, 20, 30] }
    let(:args)  { [] }

    subject{ view.set_column(column, value, *args) }

    shared_examples 'a column setter' do
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

      context 'with an empty view' do
        let(:block) { Proc.new{col1 < -1000} }
        let(:value) { 3 }

        context 'adding an empty column' do
          it 'should add the column' do
            subject
            expect(view.columns[column]).to eq NArray[]
            expect(table).to have_column column
          end

          context 'and setting an empty array to the column' do
            it 'should work' do
              subject
              expect{view[column] = []}.to_not raise_error
              expect(view[column]).to be_empty
              expect(table).to have_column column
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
        let(:value) { 'a' }
        let(:args)  { ['int'] }

        it 'should fail' do
          expect{subject}.to raise_error
        end

        it 'should not have that column' do
#           the assignment is going to chuck an error
          subject rescue nil
          expect(view.columns).to_not include column
          expect(table.columns).to_not include column
        end
      end
    end

    context 'on an existing column' do
      let(:column) { table.colnames[0] }
      it_behaves_like 'a column setter'

      it 'should assign values to the column' do
        subject
        expect(view.columns[column].to_a).to eql value
      end

      it 'should not modify anything outside the view' do
        subject
        expect(table.columns[column].to_a).to eql [0] + value
      end

      context 'when failed to set column' do
        let(:value) { 'a' }

        it 'should fail' do
          expect{subject}.to raise_error
        end

        it 'should still have the column' do
#           the assignment is going to chuck an error
          subject rescue nil
          expect(view.columns).to include column
          expect(table.columns).to include column
        end

        it 'should make no changes' do
          original = table.clone
#           the assignment is going to chuck an error
          subject rescue nil
          expect(view).to eql table.where(&block)
          expect(table).to eql original
        end
      end
    end

  end

  describe '#pop_column' do
    let(:table){ ObjectTable.new(col1: [1, 2, 3], col2: 5) }
    let(:block){ Proc.new{col1 > 2} }
    let(:view) { _make_relevant_view(table, block, described_class) }
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

    context 'with an empty view' do
      let(:block) { Proc.new{col1 > col1.max} }

      it 'should clone the view' do
        expect(clone).to eql subject
        clone.columns.each do |k, v|
          expect(v).to be_a NArray
          expect(v).to_not be_a ObjectTable::MaskedColumn
        end
      end

      context 'with an empty parent' do
        let(:table) { ObjectTable.new(col1: [], col2: []) }

        it 'should clone the view' do
          expect(clone).to eql subject
          clone.columns.each do |k, v|
            expect(v).to be_a NArray
            expect(v).to_not be_a ObjectTable::MaskedColumn
          end
        end
      end
    end

  end

end
