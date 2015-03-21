require 'object_table/column'

describe ObjectTable::Column do

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

  end

end
