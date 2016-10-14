require 'spec_helper'

describe Crud::SearchQuery do
  let(:query) { Crud::SearchQuery.new(scope, columns, extension) }
  let(:model) { described_class }
  let(:scope) { model.all }
  let(:columns) { [] }
  let(:extension) { double("extension") }

  describe ".tokenize" do
    subject { Crud::SearchQuery.tokenize(keyword) }
    let(:keyword) { self.class.description }

    context "nil" do
      let(:keyword) { nil }
      it { should eq [] }
    end

    context "空文字" do
      let(:keyword) { "" }
      it { should eq [] }
    end

    context "キーワード1" do
      it { should eq ["キーワード1"] }
    end

    context "キーワード1 キーワード2　 キーワード3" do
      it { should eq ["キーワード1", "キーワード2", "キーワード3"] }
    end

    context 'abc "スペース含む キーワード" def' do
      it { should eq ["abc", "スペース含む キーワード", "def"] }
    end

    context 'key"word "pre' do
      it { should eq ['key"word', '"pre'] }
    end
  end

  describe "#include_associations" do
    subject { query.scope }
    context Ar::Misc do
      let(:columns) { [:string, :integer, :misc_belongings] }

      its(:includes_values) { should eq [:misc_belongings] }
      its(:references_values) { should eq ["misc_belongings"] }
    end
    context Mongo::Misc do
      let(:columns) { [:string, :integer, :misc_belongings, :misc_embeds] }

      it "includes references only" do
        expect(scope).to receive(:includes).with([:misc_belongings])
        subject
      end
    end
  end

  describe "#where_clause" do
    subject { query.where_clause(model, column, operator, *values) }
    context "operator: nil" do
      let(:operator) {}
      context "column: string" do
        let(:column) { :string }
        let(:values) { ["abc"] }

        context "search_by_stringメソッド定義あり" do
          before { expect(extension).to receive(:search_by_string).with("abc").and_return(string: "foo") }
          context Ar::Misc do
            it { should eq %q["ar_miscs"."string" = 'foo'] }
          end
          context Mongo::Misc do
            it { should eq(string: 'foo') }
          end
        end

        context "advanced_search_by_stringメソッド定義あり" do
          before { expect(extension).to receive(:advanced_search_by_string).with("contains", "abc").and_return(string: "foo") }
          context Ar::Misc do
            it { should eq %q["ar_miscs"."string" = 'foo'] }
          end
          context Mongo::Misc do
            it { should eq(string: 'foo') }
          end
        end

        context "searchメソッド定義なし" do
          context Ar::Misc do
            it { should eq %q["ar_miscs"."string" LIKE '%abc%'] }
          end
          context Mongo::Misc do
            it { should eq(string: /abc/) }
          end
        end
      end

      context "column: integer" do
        let(:column) { :integer }
        let(:values) { [345] }

        context "search_by_integerメソッド定義あり" do
          before { expect(extension).to receive(:search_by_integer).with(345).and_return(result) }
          context Ar::Misc do
            let(:result) { model.arel_table[:integer].eq(111) }
            it { should eq %q["ar_miscs"."integer" = 111] }
          end
          context Mongo::Misc do
            let(:result) { {integer: 111} }
            it { should eq(integer: 111) }
          end
        end

        context "searchメソッド定義なし" do
          context Ar::Misc do
            it { should eq %q["ar_miscs"."integer" = 345] }
          end
          context Mongo::Misc do
            it { should eq(integer: 345) }
          end
        end
      end
    end

    context "operator: not exists" do
      let(:operator) { "not_exists" }
      let(:column) { :string }
      let(:values) { ["abc"] }
      context Ar::Misc do
        it { should eq "0 = 1" }
      end
      context Mongo::Misc do
        it { should eq(id: 0) }
      end
    end

    context "operator: between" do
      let(:operator) { "<>" }
      context "column: date" do
        let(:column) { :date }
        let(:values) { ["2016-01-23", "2016-03-21"] }

        context "advanced_search_by_dateメソッド定義あり" do
          before { expect(extension).to receive(:advanced_search_by_date).with("between", *values).and_return(date: nil) }
          context Ar::Misc do
            it { should eq %q["ar_miscs"."date" IS NULL] }
          end
          context Mongo::Misc do
            it { should eq(date: nil) }
          end
        end

        context "searchメソッド定義なし" do
          context Ar::Misc do
            it { should eq %q["ar_miscs"."date" BETWEEN '2016-01-23' AND '2016-03-21'] }
          end
          context Mongo::Misc do
            it { should eq(date: '2016-01-23'..'2016-03-21') }
          end
        end
      end
    end
  end

  describe "#order_clause" do
    subject { query.order_clause(column, order) }
    context "association" do
      let(:model) { Ar::Misc }
      let(:column) { :misc_belongings }
      let(:order) { :asc }

      context "association_class#sort_field 定義なし" do
        it { should eq "ar_misc_belongings.name asc" }
      end
      context "association_class#sort_field 定義あり" do
        before { expect(Ar::MiscBelonging).to receive(:sort_field).and_return(:id) }
        let(:order) { :desc }
        it { should eq "ar_misc_belongings.id desc" }
      end
    end

    context "column: string" do
      let(:column) { :string }
      let(:order) { :desc }

      context "sort_by_stringメソッド定義あり" do
        before { expect(extension).to receive(:sort_by_string).with(order).and_return(integer: :asc) }
        [Ar::Misc, Mongo::Misc].each do |m|
          context m do
            it { should eq(integer: :asc) }
          end
        end
      end
      context "sortメソッド定義なし" do
        context Ar::Misc do
          it { should eq "ar_miscs.string desc" }
        end
        context Mongo::Misc do
          it { should eq(string: :desc) }
        end
      end
    end
  end

  context "with items" do
    let(:columns) { [:string, :integer] }
    let(:factory) { model == Ar::Misc ? :ar_misc : :mongo_misc }
    let!(:item1) { create(factory, string: "item1", integer: 22) }
    let!(:item2) { create(factory, string: "item2", integer: 11) }
    let!(:item3) { create(factory, string: "foo", integer: 1) }

    describe "#keyword_search" do
      subject { query.keyword_search(keyword) }
      
      context "keyword: nil" do
        let(:keyword) { nil }
        [Ar::Misc, Mongo::Misc].each do |m|
          context m do
            it { should eq m.all }
          end
        end
      end

      context "keyword: item" do
        let(:keyword) { "item" }
        [Ar::Misc, Mongo::Misc].each do |m|
          context m do
            it { should eq [item1, item2] }
          end
        end
      end

      context "keyword: 1" do
        let(:keyword) { "1" }
        [Ar::Misc, Mongo::Misc].each do |m|
          context m do
            it { should eq [item1, item3] }
          end
        end
      end
    end

    describe "#advanced_search" do
      subject { query.advanced_search(values, operators) }
      
      context "operator指定なし: equals" do
        let(:operators) { nil }
        let(:values) { {string: "item2", integer: 11} }
        [Ar::Misc, Mongo::Misc].each do |m|
          context m do
            it { should eq [item2] }
          end
        end
      end

      context "contains and between" do
        let(:operators) { {string: "contains", integer: "between"} }
        let(:values) { {string: "item", integer: [20, 30]} }
        [Ar::Misc, Mongo::Misc].each do |m|
          context m do
            it { should eq [item1] }
          end
        end
      end
    end

    describe "#sort" do
      subject { query.sort(column, order) }
      context "string" do
        let(:column) { :string }
        context "asc" do
          let(:order) { :asc }
          [Ar::Misc, Mongo::Misc].each do |m|
            context m do
              it { should eq [item3, item1, item2] }
            end
          end
        end
        context "desc" do
          let(:order) { :desc }
          [Ar::Misc, Mongo::Misc].each do |m|
            context m do
              it { should eq [item2, item1, item3] }
            end
          end
        end
      end
      context "integer" do
        let(:column) { :integer }
        context "asc" do
          let(:order) { :asc }
          [Ar::Misc, Mongo::Misc].each do |m|
            context m do
              it { should eq [item3, item2, item1] }
            end
          end
        end
        context "desc" do
          let(:order) { :desc }
          [Ar::Misc, Mongo::Misc].each do |m|
            context m do
              it { should eq [item1, item2, item3] }
            end
          end
        end
      end
    end
  end
end
