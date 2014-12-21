require 'object_table/column'

shared_examples 'a column coercer' do |value|
  subject{ ObjectTable::Column.make(value) }

  it 'should convert it into a column' do
    expect(subject).to be_a ObjectTable::Column
    expect(subject.to_a).to eql value.to_a
  end
end

shared_examples 'a NArray' do |operator, unary: false|
  let(:name){ 'abcd' }
  let(:x){ ObjectTable::Column.make(0..10, name) }
  let(:y){ ObjectTable::Column.make(5..15) }

  let(:x_na){ NArray.to_na((0..10).to_a) }
  let(:y_na){ NArray.to_na((5..15).to_a) }

  if unary
    subject{ x.send(operator) }
    let(:expected_result){ x_na.send(operator) }
  else
    subject{ x.send(operator, y) }
    let(:expected_result){ x_na.send(operator, y_na) }
  end

  it "should give the correct result for :#{operator}" do
    expect(subject.to_a).to eql expected_result.to_a
  end

  it "should set the name of the result of :#{operator}" do
    expect(subject.name).to eql x.name
  end
end

shared_examples 'a vectorized operator' do |method|
  it "should vectorize :#{method} over the array" do
    expect(subject.send(method).to_a).to eql subject.to_a.map{|x| x.send(method)}
  end

  it "should set the name of the result of :#{method}" do
    expect(subject.send(method).name).to eql subject.name
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

  describe 'vectorisation' do
    subject{ ObjectTable::Column.make(Date.today ... (Date.today+100)) }

    it_behaves_like 'a vectorized operator', 'day'
    it_behaves_like 'a vectorized operator', 'month'
    it_behaves_like 'a vectorized operator', 'year'
  end

  describe 'operations' do
    it_behaves_like 'a NArray', '*'
    it_behaves_like 'a NArray', '+'
    it_behaves_like 'a NArray', '/'
    it_behaves_like 'a NArray', '-'
    it_behaves_like 'a NArray', '%'
    it_behaves_like 'a NArray', '**'
    it_behaves_like 'a NArray', '&'
    it_behaves_like 'a NArray', '|'
    it_behaves_like 'a NArray', '^'
    it_behaves_like 'a NArray', 'eq'
    it_behaves_like 'a NArray', 'ne'
    it_behaves_like 'a NArray', 'gt'
    it_behaves_like 'a NArray', '>'
    it_behaves_like 'a NArray', 'ge'
    it_behaves_like 'a NArray', '>='
    it_behaves_like 'a NArray', 'lt'
    it_behaves_like 'a NArray', '<'
    it_behaves_like 'a NArray', 'le'
    it_behaves_like 'a NArray', '<='
    it_behaves_like 'a NArray', 'and'
    it_behaves_like 'a NArray', 'or'
    it_behaves_like 'a NArray', 'xor'

    it_behaves_like 'a NArray', '~', unary: true
    it_behaves_like 'a NArray', '-@', unary: true
    it_behaves_like 'a NArray', 'abs', unary: true
    it_behaves_like 'a NArray', 'not', unary: true
  end

end