require 'spec_helper'

describe Crud::ModelReflection do
  subject { reflection }
  let(:model) {}
  let(:reflection) { Crud::ModelReflection[model] }

  context "ActiveRecord" do
    let(:model) { Ar::Misc }

    its(:activerecord?) { is_expected.to be true }
    its(:mongoid?) { is_expected.to be false }

    it "#association_key?" do
      expect(subject.association_key?(:misc_belongings)).to be true
      expect(subject.association_key?(:zzz)).to be false
    end

    describe "#sanitize_sql" do
      subject { reflection.sanitize_sql(condition) }

      context "Array condition" do
        let(:condition) { ["string = ? AND integer = ?", "abc", 3] }
        it { is_expected.to eq "string = 'abc' AND integer = 3" }
      end

      context "Hash condition" do
        let(:condition) { {string: "abc", integer: 3} }
        it { is_expected.to eq %q["ar_miscs"."string" = 'abc' AND "ar_miscs"."integer" = 3] }
      end

      context "arel condition" do
        let(:condition) { model.arel_table[:string].eq("abc") }
        it { is_expected.to eq %q["ar_miscs"."string" = 'abc'] }
      end

      context "string condition" do
        let(:condition) { "string = 'abc'" }
        it { is_expected.to eq condition }
      end
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
        expect(subject.column_metadata(:string)).to eq(name: :string, type: :string)
        expect(subject.column_metadata(:enumerized)).to eq(name: :enumerized, type: :enum)
        expect(subject.column_metadata(:zzz)).to be nil
        expect(subject.column_metadata(:misc_belongings)).to eq(name: :misc_belongings, type: :association)
      end

      it "#column_type" do
        expect(subject.column_type(:string)).to be :string
        expect(subject.column_type(:date)).to be :date
        expect(subject.column_type(:enumerized)).to be :enum
        expect(subject.column_type(:zzz)).to be nil
        expect(subject.column_type(:misc_belongings)).to be :association
      end

      it "#column_key?" do
        expect(subject.column_key?(:string)).to be true
        expect(subject.column_key?(:zzz)).to be false
      end

      it "#enum_values_for" do
        expect(subject.enum_values_for(:enumerized)).not_to be nil
        expect(subject.enum_values_for(:string)).to be nil
      end
    end
  end
end
