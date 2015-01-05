require 'object_table/masked_column'

describe ObjectTable::MaskedColumn do

  let(:name)      { 'abcdef' }
  let(:parent)    { ObjectTable::Column.make([0, 1, 2, Complex(2, 3), *(4...10)], name) }
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

    it 'should have the same name as its parent' do
      expect(subject.name).to eql parent.name
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


  shared_examples 'a parent modifier' do |method, *args, block: nil|
    let!(:original) { parent.clone }
    it "should affect the parent table on #{method}" do
      if block
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
  it_behaves_like 'a parent modifier', 'map!', block: proc{|x| x + 1}
  it_behaves_like 'a parent modifier', 'collect!', block: proc{|x| x + 1}
  it_behaves_like 'a parent modifier', 'imag=', 56
  it_behaves_like 'a parent modifier', 'add!', 56
  it_behaves_like 'a parent modifier', 'sbt!', 56
  it_behaves_like 'a parent modifier', 'mul!', 56
  it_behaves_like 'a parent modifier', 'div!', 56

  %w{ xor or and <= >= le ge < > gt lt % ** ne eq & | ^ to_type }.each do |op|
    context "when performing #{op}" do
      let(:parent)    { ObjectTable::Column.make([0, 1, 2, 3, *(4...10)], name) }

      it 'should return a ObjectTable::Column' do
        expect(subject.send(op, subject)).to be_a ObjectTable::Column
      end
    end
  end

  %w{ not abs -@ ~ }.each do |op|
    context "when performing #{op}" do
      let(:parent)    { ObjectTable::Column.make([0, 1, 2, 3, *(4...10)], name) }

      it 'should return a ObjectTable::Column' do
        expect(subject.send(op)).to be_a ObjectTable::Column
      end
    end
  end

  context 'with real values' do
    let(:parent)    { ObjectTable::Column.make(0...10, name) }
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
      expect(clone.name).to eql subject.name
    end
  end

end
