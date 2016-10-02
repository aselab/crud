require 'spec_helper'

describe Crud::ModelReflection do
  subject { Crud::ModelReflection[model] }
  let(:model) {}

  context "ActiveRecord" do
    let(:model) { User }

    its(:activerecord?) { is_expected.to be true }
    its(:mongoid?) { is_expected.to be false }
    it "#association_key?" do
      expect(subject.association_key?(:company)).to be true
      expect(subject.association_key?(:zzz)).to be false
    end
  end

  context "Mongoid" do
    let(:model) { MongoUser }

    its(:activerecord?) { is_expected.to be false }
    its(:mongoid?) { is_expected.to be true }
    it "#association_key?" do
      expect(subject.association_key?(:mongo_group)).to be true
      expect(subject.association_key?(:zzz)).to be false
    end
  end

  [User, MongoUser].each do |m|
    context m.name do
      let(:model) { m }

      it "#column_metadata" do
        expect(subject.column_metadata(:name)).not_to be nil
        expect(subject.column_metadata(:zzz)).to be nil
      end

      it "#column_type" do
        expect(subject.column_type(:name)).to be :string
        expect(subject.column_type(:birth_date)).to be :date
        expect(subject.column_type(:zzz)).to be nil
      end

      it "#column_key?" do
        expect(subject.column_key?(:name)).to be true
        expect(subject.column_key?(:zzz)).to be false
      end
    end
  end
end
