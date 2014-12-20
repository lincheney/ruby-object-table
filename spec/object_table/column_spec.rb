require 'object_table/column'

shared_examples 'a column coercer' do |value|
  subject{ ObjectTable::Column.make(value) }

  it 'should convert it into a column' do
    expect(subject).to be_a ObjectTable::Column
    expect(subject.to_a).to eql value.to_a
  end
end

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
      it_behaves_like "a column coercer", NArray[1, 2, 3]
    end

    context 'on a Range' do
      it_behaves_like "a column coercer", 0...100
    end

    context 'on an Array' do
      it_behaves_like "a column coercer", [1, 2, 3]
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