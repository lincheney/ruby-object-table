require 'object_table'

RSpec.shared_examples 'a table stacker' do

  describe '.stack' do
    let(:others) do
      [
        ObjectTable.new(col1: [1, 2, 3], col2: 5),
        ObjectTable.new(col1: 10, col2: 50),
        ObjectTable.new(col2: [10, 30], col1: 15).where{col2.eq 10},
        ObjectTable::BasicGrid[col2: [1, 2], col1: 3..4],
      ]
    end

    subject{ described_class.stack *others }

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

      context 'with only a non-grid/table' do
        let(:others)  { ['not a table'] }

        it 'should fail' do
          expect{subject}.to raise_error
        end
      end
    end

    context 'with extra column names' do
      let(:others){ [ObjectTable.new(col1: 10, col2: 50), ObjectTable.new(col1: 10, col2: 30, col3: 50)] }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with missing column names' do
      let(:others){ [ObjectTable.new(col1: 10, col2: 50), ObjectTable.new(col1: 10)] }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with empty tables' do
      let(:others) { [ ObjectTable.new(col1: [1, 2, 3], col2: 5), ObjectTable.new ] }

      it 'should ignore empty tables' do
        expect(subject).to eql others[0]
      end
    end

    context 'with tables with empty rows' do
      let(:others) { [ ObjectTable.new(col1: [1, 2, 3], col2: 5), ObjectTable.new(col1: [], col2: []) ] }

      it 'should ignore empty tables' do
        expect(subject).to eql others[0]
      end
    end

    context 'with empty grids' do
      let(:others) { [ ObjectTable.new(col1: [1, 2, 3], col2: 5), ObjectTable::BasicGrid.new ] }

      it 'should ignore empty grids' do
        expect(subject).to eql others[0]
      end
    end

  end

end