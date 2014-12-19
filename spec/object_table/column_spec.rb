require 'object_table/column'

describe ObjectTable::Column do

  describe '.make' do
    subject{ ObjectTable::Column.make(value) }

    context 'on a Column' do
      let(:value){ ObjectTable::Column[1, 2, 3] }

      it 'should return the same column' do
        expect(subject).to be value
      end
    end

    context 'on a NArray' do
      let(:value){ NArray[1, 2, 3] }

      it 'should convert it into a column' do
        expect(subject).to be_a ObjectTable::Column
      end
    end

    context 'on a Array' do
      let(:value){ [1, 2, 3] }

      it 'should convert it into a column' do
        expect(subject).to be_a ObjectTable::Column
      end
    end

    context 'on something unsupported' do
      let(:value){ Object.new }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

    context 'with a name' do
      let(:name){ 'abcd' }
      subject{ ObjectTable::Column.make([1, 2, 3], name) }

      it 'should set the name' do
        expect(subject.name).to eql name
      end
    end
  end

end