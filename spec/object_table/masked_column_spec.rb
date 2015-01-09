require 'object_table/masked_column'

describe ObjectTable::MaskedColumn do

  let(:parent)    { ObjectTable::Column.make([0, 1, 2, Complex(2, 3), *(4...10)]) }
  let(:indices)   { NArray[1, 3, 4, 6] }
  let(:other_indices) { NArray.to_na((0...parent.length).to_a - indices.to_a) }

  subject{ ObjectTable::MaskedColumn.mask(parent, indices) }

  describe '.mask' do
    it 'should mask the parent' do
      expect(subject.to_a).to eql parent[indices].to_a
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


  shared_examples 'a parent slice modifier' do |slice|
    let(:value) { 1000 }
    let!(:original){ parent.clone }
    let(:slice){ slice }

    it "should modify the parent with a #{slice.class} slice" do
      subject[slice] = value
      expect(parent[indices].to_a).to eql subject.to_a
      expect(parent[other_indices].to_a).to eql original[other_indices].to_a
    end
  end

  it_behaves_like 'a parent slice modifier', 0
  it_behaves_like 'a parent slice modifier', NArray.cast([1, 0, 0, 1], 'byte')
  it_behaves_like 'a parent slice modifier', 1...4
  it_behaves_like 'a parent slice modifier', [0, 2]
  it_behaves_like 'a parent slice modifier', true
  it_behaves_like 'a parent slice modifier', nil


  shared_examples 'a parent modifier' do |method, *args|
    let!(:original) { parent.clone }
    it "should affect the parent table on #{method}" do
      if defined? block
        subject.send(method, *args, &block)
      else
        subject.send(method, *args)
      end

      expect(parent[indices].to_a).to eql subject.to_a
      expect(parent[other_indices].to_a).to eql original[other_indices].to_a
    end
  end

  it_behaves_like 'a parent modifier', 'indgen!'
  it_behaves_like 'a parent modifier', 'indgen'
  it_behaves_like 'a parent modifier', 'fill!', 100
  it_behaves_like 'a parent modifier', 'random!'
  it_behaves_like 'a parent modifier', 'conj!'
  it_behaves_like 'a parent modifier', 'map!' do
    let(:block) { proc{|x| x + 1} }
  end
  it_behaves_like 'a parent modifier', 'collect!' do
    let(:block) { proc{|x| x + 1} }
  end
  it_behaves_like 'a parent modifier', 'imag=', 56
  it_behaves_like 'a parent modifier', 'add!', 56
  it_behaves_like 'a parent modifier', 'sbt!', 56
  it_behaves_like 'a parent modifier', 'mul!', 56
  it_behaves_like 'a parent modifier', 'div!', 56

  %w{ * + / - xor or and <= >= le ge < > gt lt % ** ne eq & | ^ to_type }.each do |op|
    context "when performing '#{op}'" do
      let(:parent)    { ObjectTable::Column.make([0, 1, 2, 3, *(4...10)]) }

      it 'should return a ObjectTable::Column' do
        expect(subject.send(op, subject)).to be_a ObjectTable::Column
      end

      it 'should not be a masked' do
        expect(subject.send(op, subject)).to_not be_a ObjectTable::MaskedColumn
      end
    end
  end

  %w{ not abs -@ ~ floor ceil round to_f to_i to_object }.each do |op|
    describe "##{op}" do
      let(:parent)    { ObjectTable::Column.make([0, 1, 2, 3, *(4...10)]) }

      it 'should return a ObjectTable::Column' do
        expect(subject.send(op)).to be_a ObjectTable::Column
      end

      it 'should not be a masked' do
        expect(subject.send(op)).to_not be_a ObjectTable::MaskedColumn
      end
    end
  end

  describe '#collect' do
    let(:parent)    { ObjectTable::Column.make([0, 1, 2, 3, *(4...10)]) }
    let(:block)     { Proc.new{|i| i * 5} }

    it 'should return a ObjectTable::Column' do
      expect(subject.collect &block).to be_a ObjectTable::Column
    end

    it 'should not be a masked' do
      expect(subject.collect &block).to_not be_a ObjectTable::MaskedColumn
    end
  end

  context 'with real values' do
    let(:parent)    { ObjectTable::Column.make(0...10) }
    it_behaves_like 'a parent modifier', 'mod!', 2
  end

  describe '#clone' do
    let(:clone){ subject.clone }

    it 'returns a Column' do
      expect(clone).to be_an_instance_of ObjectTable::Column
      expect(clone).to_not be_an_instance_of ObjectTable::MaskedColumn
    end

    it 'should clone the data' do
      expect(clone.to_a).to eql subject.to_a
    end
  end

end
