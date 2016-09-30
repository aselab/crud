require 'spec_helper'

describe Crud::ModelReflection do
  subject { Crud::ModelReflection.new(model) }
  let(:model) {}

  describe "モデル判定" do
    context "ActiveRecord::Base" do
      let(:model) { User }

      its(:activerecord?) { is_expected.to be true }
      its(:mongoid?) { is_expected.to be false }
    end

    context "Mongoid::Document" do
      let(:model) { MongoUser }

      its(:activerecord?) { is_expected.to be false }
      its(:mongoid?) { is_expected.to be true }
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
