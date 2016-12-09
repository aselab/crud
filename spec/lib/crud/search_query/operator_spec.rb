require 'spec_helper'

describe Crud::SearchQuery::Operator do
  let(:default) { Crud::SearchQuery::DefaultOperator }
  let(:equals) { Crud::SearchQuery::EqualsOperator }
  let(:not_equals) { Crud::SearchQuery::NotEqualsOperator }
  let(:contains) { Crud::SearchQuery::ContainsOperator }
  let(:not_contains) { Crud::SearchQuery::NotContainsOperator }
  let(:greater_or_equal) { Crud::SearchQuery::GreaterOrEqualOperator }
  let(:less_or_equal) { Crud::SearchQuery::LessOrEqualOperator }
  let(:between) { Crud::SearchQuery::BetweenOperator }
  let(:any) { Crud::SearchQuery::AnyOperator }
  let(:none) { Crud::SearchQuery::NoneOperator }

  describe ".[]" do
    it "名前で取得できること" do
      expect(Crud::SearchQuery::Operator[:equals]).to eq equals
      expect(Crud::SearchQuery::Operator[:less_or_equal]).to eq less_or_equal
    end

    it "別名で取得できること" do
      expect(Crud::SearchQuery::Operator["="]).to eq equals
      expect(Crud::SearchQuery::Operator["<="]).to eq less_or_equal
    end
  end

  describe ".available_for(type)" do
    subject { Crud::SearchQuery::Operator.available_for(type) }
    let(:type) { self.class.description }
    context :string do
      it { should eq [equals, not_equals, contains, not_contains] }
    end

    context :integer do
      it { should eq [equals, not_equals, greater_or_equal, less_or_equal, between] }
    end
  end

  describe ".args" do
    subject { described_class }
    context Crud::SearchQuery::EqualsOperator do
      its(:args) { should eq 1 }
    end
    context Crud::SearchQuery::ContainsOperator do
      its(:args) { should eq 1 }
    end
    context Crud::SearchQuery::BetweenOperator do
      its(:args) { should eq 2 }
    end
    context Crud::SearchQuery::AnyOperator do
      its(:args) { should eq 0 }
    end
  end

  describe "#apply" do
    subject { operator.new(model, column).apply(*args) }
    let(:model) { described_class }
    let(:args) { [] }

    context "default" do
      let(:operator) { default }
      context "association" do
        let(:column) { :misc_belongings }
        context "search_field定義なし" do
          let(:args) { ["abc"] }
          context Ar::Misc do
            it { should eq %q["ar_misc_belongings"."name" LIKE '%abc%'] }
          end
        end
        context "search_field定義あり" do
          let(:args) { [34] }
          before { expect(Ar::MiscBelonging).to receive(:search_field).and_return("id") }
          context Ar::Misc do
            it { should eq %q["ar_misc_belongings"."id" = 34] }
          end
        end
        context "search_field複数項目指定" do
          let(:args) { ["abc"] }
          before { expect(Ar::MiscBelonging).to receive(:search_field).and_return([:id, :name]) }
          context Ar::Misc do
            it { should eq %q[0 = 1 OR "ar_misc_belongings"."name" LIKE '%abc%'] }
          end
        end
      end
    end

    context "equals" do
      let(:operator) { equals }
      context "string" do
        let(:column) { :string }
        let(:args) { ["abc"] }
        context Ar::Misc do
          it { should eq %q["ar_miscs"."string" = 'abc'] }
        end
        context Mongo::Misc do
          it { should eq(string: 'abc') }
        end
      end
      context "float" do
        let(:column) { :float }
        let(:args) { [3.4] }
        context Ar::Misc do
          it { should eq %q["ar_miscs"."float" = 3.4] }
        end
        context Mongo::Misc do
          it { should eq(float: 3.4) }
        end
      end
      context "enum" do
        let(:column) { :enumerized }
        context "値検索" do
          let(:args) { "C" }
          context Ar::Misc do
            it { should eq %q["ar_miscs"."enumerized" = 'C'] }
          end
          context Mongo::Misc do
            it { should eq(enumerized: 'C') }
          end
        end
        context "ラベル検索" do
          let(:args) { "BLabel" }
          context Ar::Misc do
            it { should eq %q["ar_miscs"."enumerized" = 'B'] }
          end
          context Mongo::Misc do
            it { should eq(enumerized: 'B') }
          end
        end
      end
    end

    context "contains" do
      let(:operator) { contains }
      context "string" do
        let(:column) { :string }
        let(:args) { ["abc"] }
        context Ar::Misc do
          it { should eq %q["ar_miscs"."string" LIKE '%abc%'] }
        end
        context Mongo::Misc do
          it { should eq(string: /abc/) }
        end
      end
    end

    context "between" do
      let(:operator) { between }
      context "integer" do
        let(:column) { :integer }
        context "with valid values" do
          let(:args) { [2, 5] }
          context Ar::Misc do
            it { should eq %q["ar_miscs"."integer" BETWEEN 2 AND 5] }
          end
          context Mongo::Misc do
            it { should eq(integer: 2..5) }
          end
        end
        context "with invalid values" do
          let(:args) { ["aa", "bb"] }
          context Ar::Misc do
            it { should eq "0 = 1" }
          end
          context Mongo::Misc do
            it { should eq(id: 0) }
          end
        end
      end
    end

    context "any" do
      let(:operator) { any }
      context "string" do
        let(:column) { :string }
        context Ar::Misc do
          it { should eq %q["ar_miscs"."string" IS NOT NULL] }
        end
        context Mongo::Misc do
          it { should eq(:string.ne => nil) }
        end
      end
    end
  end
end
