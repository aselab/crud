require 'spec_helper'

describe Crud::Serialization do
  module Mongo
    class Category
      include Mongoid::Document
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
    let(:category) { Mongo::Category.new(items: items) }
    let(:items) { [Mongo::Item.new(name: "item1"), Mongo::Item.new] }
    before { category.valid? }
                                         
    it "status should be :unprocessable_entity" do
      expect(subject[:status]).to be :unprocessable_entity
    end

    context "json" do
      let(:json) { subject[:json] }
    end
  end
end
