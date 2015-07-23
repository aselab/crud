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

  describe "#json_errors_options" do
    subject { FakeObject.new.json_errors_options(category) }
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
end
