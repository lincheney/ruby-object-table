require 'object_table/masked_column'

shared_examples 'a NArray' do |operator, options={}|
  unary = options[:unary]

  let(:indices) { NArray[1, 3, 4, 6] }

  let(:x){ ObjectTable::MaskedColumn.mask(x_na, indices) }
  let(:y){ ObjectTable::MaskedColumn.mask(y_na, indices) }

  let(:x_na){ (NArray.float(10, 20).random * 10).to_i + 1 }
  let(:y_na){ (NArray.float(10, 20).random * 10).to_i + 1 }

  if unary
    subject{ x.send(operator) }
    let(:expected_result){ x_na[false, indices].send(operator) }
  else
    subject{ x.send(operator, y) }
    let(:expected_result){ x_na.send(operator, y_na)[false, indices] }
  end

  describe "#{operator}" do
    it "should give the correct result" do
      expect(subject).to eq expected_result
    end

    context 'with empty indices' do
      let(:indices) { [] }

      it "should give the correct result" do
        expect(subject).to eq expected_result
      end
    end
  end
end

describe ObjectTable::MaskedColumn do

  let(:parent)    { NArray.float(10, 10).random! }
  let(:indices)   { NArray[1, 3, 4, 6] }
  let(:other_indices) { NArray.to_na((0...parent.shape[-1]).to_a - indices.to_a) }
  let(:masked)    { ObjectTable::MaskedColumn.mask(parent, indices) }

  subject{ masked }

  describe '.mask' do
    it 'should mask the parent' do
      expect(subject.to_a).to eql parent[false, indices].to_a
    end

    it 'should set the parent' do
      expect(subject.parent).to eql parent
    end

    it 'should set the indices' do
      expect(subject.indices).to eql indices
    end

    context 'with no indices' do
      let(:indices)   { NArray.int(0) }

      it 'should still work' do
        expect{subject}.to_not raise_error
        expect(subject.rank).to eql 0
      end
    end

    context 'with an empty parent' do
      let(:parent) { NArray.int(0) }
      let(:indices){ NArray.int(0) }

      it 'should still work' do
        expect{subject}.to_not raise_error
        expect(subject.rank).to eql 0
      end
    end
  end


  shared_examples '#[]=' do |slice|
    let(:value)     { 1000 }
    let!(:original) { parent.clone }
    #let(:slice)     { slice }

    context "slicing with a #{slice[-1].class}" do

      it "should modify the parent" do
        subject[*slice] = value
        expect(parent[false, indices].to_a).to eql subject.to_a
        expect(parent[false, other_indices].to_a).to eql original[false, other_indices].to_a
      end

      context 'without a parent' do
        subject{ ObjectTable::MaskedColumn.to_na(parent[false, indices]) }

        it 'should still work' do
          expect{subject[*slice] = value}.to_not raise_error
        end
      end

    end
  end

  context 'with a vector' do
    let(:parent)    { NArray.float(10).random }
    include_examples '#[]=', [0]
    include_examples '#[]=', [NArray.cast([1, 0, 0, 1], 'byte')]
    include_examples '#[]=', [1...4]
    include_examples '#[]=', [[0, 2]]
    include_examples '#[]=', [true]
    include_examples '#[]=', [nil]
  end

  context 'when multi dimensional' do
    let(:parent)  { NArray.float(10, 20).random }
    include_examples '#[]=', [0]
    include_examples '#[]=', [nil]
    include_examples '#[]=', [true]
    include_examples '#[]=', [0, 0]
    include_examples '#[]=', [0, 1...4]
    include_examples '#[]=', [0, [0, 2]]
    include_examples '#[]=', [0, NArray.cast([1, 0, 0, 1], 'byte')]
  end


  shared_examples 'destructive methods' do |method, *args|
    let!(:original) { parent.clone }

    let(:perform) do
      if defined? block
        subject.send(method, *args, &block)
      else
        subject.send(method, *args)
      end
    end

    it "#{method} should affect the parent" do
      perform
      expect(parent[false, indices].to_a).to eql subject.to_a
      expect(parent[false, other_indices].to_a).to eql original[false, other_indices].to_a
    end

    context 'without a parent' do
      subject{ ObjectTable::MaskedColumn.to_na(parent[false, indices]) }

      it "#{method} should still work" do
        expect{perform}.to_not raise_error
      end
    end
  end

  it_behaves_like 'destructive methods', 'indgen!'
  it_behaves_like 'destructive methods', 'indgen'
  it_behaves_like 'destructive methods', 'fill!', 100
  it_behaves_like 'destructive methods', 'random!'
  it_behaves_like 'destructive methods', 'mod!', 2
  it_behaves_like 'destructive methods', 'add!', 56
  it_behaves_like 'destructive methods', 'sbt!', 56
  it_behaves_like 'destructive methods', 'mul!', 56
  it_behaves_like 'destructive methods', 'div!', 56
  it_behaves_like 'destructive methods', 'map!' do
    let(:block) { proc{|x| x + 1} }
  end
  it_behaves_like 'destructive methods', 'collect!' do
    let(:block) { proc{|x| x + 1} }
  end

  context 'with complex numbers' do
    let(:parent)    { NArray.complex(10).indgen! }

    include_examples 'destructive methods', 'imag=', 56
    include_examples 'destructive methods', 'conj!'
  end

  describe '#clone' do
    let(:clone){ subject.clone }

    it 'returns a NArray' do
      expect(clone).to be_an_instance_of NArray
      expect(clone).to_not be_an_instance_of ObjectTable::MaskedColumn
    end

    it 'should clone the data' do
      expect(clone.to_a).to eql subject.to_a
    end

    context 'with an empty mask' do
      let(:indices) { NArray[] }

      it 'should clone the data' do
        expect(clone.to_a).to eql subject.to_a
      end

      context 'with an empty parent' do
        let(:parent) { NArray[] }

        it 'should clone the data' do
          expect(clone.to_a).to eql subject.to_a
        end
      end
    end
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


end
