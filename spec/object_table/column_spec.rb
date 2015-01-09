require 'object_table/column'

shared_examples 'a column coercer' do |value|
  subject{ ObjectTable::Column.make(value) }

  it "should convert #{value.class} into a column" do
    expect(subject).to be_a ObjectTable::Column
    expect(subject.to_a).to eql value.to_a
  end
end

shared_examples 'a NArray' do |operator, options={}|
  unary = options[:unary]

  let(:x){ ObjectTable::Column.make(0..10) }
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

  describe "#{operator}" do
    it "should give the correct result" do
      expect(subject).to eq expected_result
    end

    it 'should return a column' do
      expect(subject).to be_a ObjectTable::Column
    end
  end
end

shared_examples 'NArray slicing' do |is_column, *args|
  let(:x_na)            { NArray.to_na(x.to_a) }

  %w{ [] slice }.each do |method|
    describe "##{method}" do
      let(:result)          { x.send(method, *args) }
      let(:expected_result) { x_na.send(method, *args) }

      it "should give the correct result" do
        expect(result).to eq expected_result
      end

      if is_column
        it 'should return a column' do
          expect(result).to be_a ObjectTable::Column
        end
      end
    end
  end
end


shared_examples 'a vectorized operator' do |method|
  it "should vectorize :#{method} over the array" do
    expect(subject.send(method).to_a).to eql subject.to_a.map{|x| x.send(method)}
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

    it_behaves_like "a column coercer", NArray[1, 2, 3]
    it_behaves_like "a column coercer", 0...100
    it_behaves_like "a column coercer", [1, 2, 3]

    context 'on something unsupported' do
      let(:value){ Object.new }

      it 'should fail' do
        expect{subject}.to raise_error
      end
    end

  end

  describe '#to_object' do
    let(:column){ ObjectTable::Column[1, 2, 3] }

    it 'should coerce the column into objects' do
      expect(column.typecode).to eql NArray.int(0).typecode
      expect(column.to_object.typecode).to eql NArray.object(0).typecode
      expect(column.to_object).to eq column
    end
  end

  describe '#get_rows' do
    let(:value)   { NArray.float(50, 50, 50, 50).random! }
    let(:column)  { ObjectTable::Column.make(value) }
    let(:index)   { 30 }

    subject{ column.get_rows(index) }

    it 'should retrieve the row from the last dimension' do
      expect(subject).to eql column[nil, nil, nil, index]
    end
  end

  describe '#uniq' do
    subject{ ObjectTable::Column.make([1, 1, 2, 2, 3, 1]) }

    it 'should return a column of unique elements' do
      expect(subject.uniq).to be_a ObjectTable::Column
      expect(subject.uniq.to_a).to eql subject.to_a.uniq
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
    it_behaves_like 'a NArray', 'to_type'

    it_behaves_like 'a NArray', '~', unary: true
    it_behaves_like 'a NArray', '-@', unary: true
    it_behaves_like 'a NArray', 'abs', unary: true
    it_behaves_like 'a NArray', 'not', unary: true

  end

  describe 'slicing' do
    let(:x){ ObjectTable::Column.float(10, 10, 10).random! }

    it_behaves_like 'NArray slicing', false, 0
    it_behaves_like 'NArray slicing', true, nil
    it_behaves_like 'NArray slicing', false, 1, 2, 3
    it_behaves_like 'NArray slicing', true, nil, nil, 5
    it_behaves_like 'NArray slicing', true, nil, 5, 5
    it_behaves_like 'NArray slicing', true, nil, true, false
    it_behaves_like 'NArray slicing', true, [1, 2, 3, 4], nil, nil
    it_behaves_like 'NArray slicing', true, [1, 2, 3, 4], nil, [1, 2]
    it_behaves_like 'NArray slicing', true, 3...6
    it_behaves_like 'NArray slicing', true, nil, nil, 3...6
    it_behaves_like 'NArray slicing', true, 6...3, nil, 3...6
    it_behaves_like 'NArray slicing', true, NArray[1..10] > 5, nil, nil
  end

  describe "#mask" do
    let(:x)     { ObjectTable::Column.float(10, 10, 10).random! }
    let(:mask)  { x < 0.5 }

    let(:expected_result) { NArray.to_na(x.to_a)[mask] }

    subject{ x.mask(mask) }

    it "should give the correct result" do
      expect(subject).to eq expected_result
    end

    it 'should return a column' do
      expect(subject).to be_a ObjectTable::Column
    end
  end

end