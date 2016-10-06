require 'spec_helper'

describe Crud::ModelReflection do
  subject { Crud::ModelReflection[model] }
  let(:model) {}

  context "ActiveRecord" do
    let(:model) { Ar::Misc }

    its(:activerecord?) { is_expected.to be true }
    its(:mongoid?) { is_expected.to be false }
    it "#association_key?" do
      expect(subject.association_key?(:misc_belongings)).to be true
      expect(subject.association_key?(:zzz)).to be false
    end
  end

  context "Mongoid" do
    let(:model) { Mongo::Misc }

    its(:activerecord?) { is_expected.to be false }
    its(:mongoid?) { is_expected.to be true }
    it "#association_key?" do
      expect(subject.association_key?(:misc_belongings)).to be true
      expect(subject.association_key?(:misc_embeds)).to be false
      expect(subject.association_key?(:zzz)).to be false
    end
  end

  [Ar::Misc, Mongo::Misc].each do |m|
    context m.name do
      let(:model) { m }

      it "#column_metadata" do
        expect(subject.column_metadata(:string)).not_to be nil
        expect(subject.column_metadata(:zzz)).to be nil
      end

      it "#column_type" do
        expect(subject.column_type(:string)).to be :string
        expect(subject.column_type(:date)).to be :date
        expect(subject.column_type(:zzz)).to be nil
      end

      it "#column_key?" do
        expect(subject.column_key?(:string)).to be true
        expect(subject.column_key?(:zzz)).to be false
      end
    end
  end
end
