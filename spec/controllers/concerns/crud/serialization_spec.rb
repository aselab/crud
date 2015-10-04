require 'spec_helper'

describe Crud::Serialization do
  module Mongo
    class Category
      include Mongoid::Document
      embeds_one :item, class_name: "Mongo::Item"
      embeds_many :items, class_name: "Mongo::Item"
      field :name, type: String
      validates :name, presence: true
    end

    class Item
      include Mongoid::Document
      field :name, type: String
      validates :name, presence: true
    end
  end

  class FakeObject
    include Crud::Serialization
  end

  let(:controller) { FakeObject.new }

  describe "#json_errors_options" do
    subject { controller.json_errors_options(category) }
    let(:category) { Mongo::Category.new(item: item, items: items) }
    let(:item) { Mongo::Item.new }
    let(:items) { [Mongo::Item.new(name: "item1"), Mongo::Item.new] }
    before { category.valid? }
                                         
    it "status should be :unprocessable_entity" do
      expect(subject[:status]).to be :unprocessable_entity
    end

    context "json" do
      let(:json) { subject[:json] }
      it("name") { expect(json[:name]).not_to be nil }
      it("item") { expect(json[:item]).to include(:name) }
      it("items[0]") { expect(json[:items][0]).to be nil }
      it("items[1]") { expect(json[:items][1]).to include(:name) }
    end
  end

  describe "#generate_csv" do
    let(:lines) { controller.generate_csv(columns, items, options).split("\n") }
    let(:columns) { [:string, :integer, :boolean, :date, :datetime] }
    let(:items) { build_list(:csv_item, 10) }
    let(:options) { }
    before { allow(controller).to receive(:model).and_return(CsvItem) }

    describe "ヘッダ" do
      subject { lines.first }

      context "encoding指定なし" do
        it { should eq "\xEF\xBB\xBF" + columns.map{|c| CsvItem.human_attribute_name(c)}.join(",") }
      end

      context "encoding sjis指定" do
        let(:options) { {encoding: "sjis"} }
        its(:encoding) { should eq Encoding::SJIS }
      end

      context "header=false" do
        let(:options) { {header: false} }
        it("ヘッダが出力されないこと") { expect(lines.size).to eq 10 }
      end
    end

    describe "データ" do
      subject { lines.shift; lines }
      it { expect(subject.size).to eq 10 }
      it { should include columns.map{|c| items[4].send(c)}.join(",") }

      context "csv_column_booleanが定義されているとき" do
        let(:item) { build(:csv_item) }
        let(:items) { [item] }
        before { controller.define_singleton_method(:csv_column_boolean) {|item| "aaa"} }
        it { expect(subject.first.split(",")[2]).to eq "aaa" }
      end
    end
  end
end
