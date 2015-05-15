require 'object_table'

#
# spec: kind of proof of concept on how to extend a table
#   and any children views, groups etc.
#
# the idea is that we can make a mixin and make it available
#   to the table and also whenever we filter (#where), group (#group)
#   or #clone
#
describe 'Subclassing ObjectTable and friends' do

  class MyTable < ObjectTable
    module Mixin
      def a_plus_b
        a + b
      end
    end

    include Mixin

    class StaticView < StaticView; include Mixin; end
    class View < View; include Mixin; end
    class Group < Group; include Mixin; end
  end

  let(:table){ MyTable.new(a: 0...100, b: 100.times.map{rand}) }

  subject{ table }

  it 'should have the mixin method available' do
    expect(subject.a_plus_b).to eq (subject.a + subject.b)
  end

  describe '#clone' do
    it 'should be an instance of the table subclass' do
      expect(table.clone).to be_a MyTable
    end
  end

  describe '#apply' do
    context 'with a block returning a grid' do
      subject{ table.apply{ ObjectTable::BasicGrid[col1: [4, 5, 6]] } }

      it 'should coerce to the table subclass' do
        expect(subject).to be_a MyTable
      end
    end
  end

  describe '#where' do
    subject{ table.where{a > 50} }

    it 'should create view extending the mixin' do
      expect(subject).to be_a ObjectTable::View
      expect(subject).to be_a MyTable::Mixin
    end

    it 'should have the mixin method available' do
      expect(subject.a_plus_b).to eq (subject.a + subject.b)
    end

    describe '#clone' do
      it 'should be an instance of the subclass' do
        expect(subject.clone).to be_a MyTable
      end
    end

    describe '#apply' do
      subject{ table.where{a > 50}.apply{self} }

      it 'should create static view extending the mixin' do
        expect(subject).to be_a ObjectTable::StaticView
        expect(subject).to be_a MyTable::Mixin
      end

      describe '#clone' do
        it 'should be an instance of the table subclass' do
          expect(subject.clone).to be_a MyTable
        end
      end

    end
  end

  describe '#group_by' do
    subject{ table.group_by{{gt_50: a > 50}} }

    describe '#each' do
      let(:groups) do
        _groups = []
        subject.each{ _groups << self }
        _groups
      end

      it 'should give groups extending the Mixin' do
        groups.each do |g|
          expect(g).to be_a ObjectTable::Group
          expect(g).to be_a MyTable::Mixin
        end
      end

      it 'should have the mixin method available to the groups' do
        groups.each do |g|
          expect(g.a_plus_b).to eql (g.a + g.b)
        end
      end

      describe '#clone' do
        it 'should be an instance of the table subclass' do
          groups.each do |g|
            expect(g.clone).to be_a MyTable
          end
        end
      end
    end

    describe '#apply' do
      let(:groups) do
        _groups = []
        subject.apply{ _groups << self; nil }
        _groups
      end

      it 'should give groups extending the mixin' do
        groups.each do |g|
          expect(g).to be_a ObjectTable::Group
          expect(g).to be_a MyTable::Mixin
        end
      end

      it 'should have the mixin method available to the groups' do
        groups.each do |g|
          expect(g.a_plus_b).to eql (g.a + g.b)
        end
      end

      it 'should aggregate into a subclassed table' do
        expect(subject.apply{nil}).to be_a MyTable
      end

      describe '#clone' do
        it 'should be an instance of the table subclass' do
          groups.each do |g|
            expect(g.clone).to be_a MyTable
          end
        end
      end

    end

    describe '#reduce' do
      it 'should aggregate into a subclassed table' do
        expect(subject.reduce{}).to be_a MyTable
      end
    end

  end

  describe '#sort_by' do
    let(:sorted){ table.sort_by(table.b) }

    it 'should return an instance of the table subclass' do
      expect(sorted).to be_a MyTable
    end
  end

end