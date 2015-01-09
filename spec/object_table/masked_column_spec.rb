require 'object_table/masked_column'

describe ObjectTable::MaskedColumn do

  let(:parent)    { ObjectTable::Column.float(10).random! }
  let(:indices)   { NArray[1, 3, 4, 6] }
  let(:other_indices) { NArray.to_na((0...parent.length).to_a - indices.to_a) }
  let(:masked)    { ObjectTable::MaskedColumn.mask(parent, indices) }

  subject{ masked }

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


  shared_examples '#[]=' do |slice|
    let(:value) { 1000 }
    let!(:original){ parent.clone }
    let(:slice){ slice }

    context "slicing with a #{slice.class}" do

      it "should modify the parent" do
        subject[slice] = value
        expect(parent[indices].to_a).to eql subject.to_a
        expect(parent[other_indices].to_a).to eql original[other_indices].to_a
      end

      context 'without a parent' do
        subject{ ObjectTable::MaskedColumn[1, 2, 3, 4] }

        it 'should still work' do
          expect{subject[slice] = value}.to_not raise_error
        end
      end

    end
  end

  include_examples '#[]=', 0
  include_examples '#[]=', NArray.cast([1, 0, 0, 1], 'byte')
  include_examples '#[]=', 1...4
  include_examples '#[]=', [0, 2]
  include_examples '#[]=', true
  include_examples '#[]=', nil


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
      expect(parent[indices].to_a).to eql subject.to_a
      expect(parent[other_indices].to_a).to eql original[other_indices].to_a
    end

    context 'without a parent' do
      subject{ ObjectTable::MaskedColumn[1, 2, 3, 4] }

      it "#{method} should still work" do
        expect{perform}.to_not raise_error
      end
    end
  end

  include_examples 'destructive methods', 'indgen!'
  include_examples 'destructive methods', 'indgen'
  include_examples 'destructive methods', 'fill!', 100
  include_examples 'destructive methods', 'random!'
  include_examples 'destructive methods', 'mod!', 2
  include_examples 'destructive methods', 'add!', 56
  include_examples 'destructive methods', 'sbt!', 56
  include_examples 'destructive methods', 'mul!', 56
  include_examples 'destructive methods', 'div!', 56
  include_examples 'destructive methods', 'map!' do
    let(:block) { proc{|x| x + 1} }
  end
  include_examples 'destructive methods', 'collect!' do
    let(:block) { proc{|x| x + 1} }
  end

  context 'with complex numbers' do
    let(:parent)    { ObjectTable::Column.complex(10).indgen! }

    include_examples 'destructive methods', 'imag=', 56
    include_examples 'destructive methods', 'conj!'
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
