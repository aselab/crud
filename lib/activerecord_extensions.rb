require 'active_support/concern'

module ActiveRecordExtensions
  module Base
    extend ActiveSupport::Concern
    included do
      scope :none, where("1 = 0")
    end
  end

  module Relation
    extend ActiveSupport::Concern
    def or(relation)
      table.engine.where(self.where_values.reduce(:and).or(relation.where_values.reduce(:and)))
    end

    def sub
      table.engine.where("#{table.name}.id" => self)
    end
  end

  class Railtie < ::Rails::Railtie #:nodoc:
    initializer "activerecord_extensions" do
      ActiveRecord::Relation.send(:include, Relation)
    end
  end
end
