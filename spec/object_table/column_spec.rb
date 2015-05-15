require 'object_table/column'

describe ObjectTable::Column do

  describe '.length_of' do
    it 'should return the length of narrays' do
      expect(described_class.length_of NArray.float(10, 20, 30)).to eql 30
    end

    it 'should return the length of arrays' do
      expect(described_class.length_of [ [0] * 20 ] * 30).to eql 30
    end

    it 'should return the length of empty narrays' do
      expect(described_class.length_of NArray.float(0)).to eql 0
    end

    it 'should return nil on other inputs' do
      expect(described_class.length_of 123456).to be_nil
    end
  end

  describe '.stack' do
    let(:columns) do
      [
        NArray.float(10, 10).random!,
        NArray.float(10, 30).random!,
        NArray.to_na([[100] * 10] * 5),
      ]
    end

    subject{ ObjectTable::Column.stack(*columns) }

    it 'should return a narray in the correct format' do
      expect(subject).to be_a NArray
      expect(subject.typecode).to eql columns[0].typecode
    end

    it 'should return a narray with the correct size' do
      expect(subject.shape[0...-1]).to eql columns[0].shape[0...-1]
      expect(subject.shape[-1]).to eql (10 + 30 + 5)
    end

    it 'should stack the narrays' do
      expect(subject[nil, 0...10]).to eq columns[0]
      expect(subject[nil, 10...40]).to eq columns[1]
      expect(subject[nil, 40...45]).to eq columns[2]
    end

    context 'with no arguments' do
      let(:columns) { [] }

      it 'should return an empty NArray' do
        expect(subject).to eq NArray[]
      end
    end

    context 'with empty narrays' do
      let(:columns) do
        [
          NArray.float(10, 10).random!,
          NArray.float(10, 30).random!,
          NArray[],
          NArray.to_na([[100] * 10] * 5),
        ]
      end

      it 'should skip empty narrays' do
        expect(subject).to eq ObjectTable::Column.stack(columns[0], columns[1], columns[3])
      end
    end

    context 'when arguments all have the same dimensions' do
      let(:columns) do
        [
          NArray.float(10, 20, 30).random!,
          NArray.float(10, 20, 30).random!,
          NArray.float(10, 20, 30).random!,
          NArray.float(10, 20, 30).random!,
        ]
      end

      it 'should stack them' do
        expect(subject[false, 0...30]).to eq columns[0]
        expect(subject[false, 30...60]).to eq columns[1]
        expect(subject[false, 60...90]).to eq columns[2]
        expect(subject[false, 90...120]).to eq columns[3]
      end
    end

  end

end
