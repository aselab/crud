require 'spec_helper'

describe Crud::ModelMethods do
  class ActiveRecordModel < ActiveRecord::Base
    has_many :items
  end

  class MongoidModel
    include Mongoid::Document
    has_many :items
  end

  class FakeObject
    include Crud::ModelMethods
  end

  subject { FakeObject.new }
  let(:model) {}
  before { allow(subject).to receive(:model).and_return(model) }

  describe "モデル判定" do
    context "ActiveRecord::Base" do
      let(:model) { ActiveRecordModel }

      it "#activerecord? is true" do
        expect(subject.activerecord?).to be true
      end

      it "#mongoid? is false" do
        expect(subject.mongoid?).to be false
      end
    end

    context "Mongoid::Document" do
      let(:model) { MongoidModel }

      it "#activerecord? is false" do
        expect(subject.activerecord?).to be false
      end

      it "#mongoid? is true" do
        expect(subject.mongoid?).to be true
      end
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

  describe "#association_key?" do
    [ActiveRecordModel, MongoidModel].each do |m|
      context m.name do
        let(:model) { m }
        it "関連だったらtrue" do
          expect(subject.association_key?(:items)).to be true
        end
        it "関連でなかったらfalse" do
          expect(subject.association_key?(:zzz)).to be false
        end
      end
    end
  end
end
