module Acts
module Permissible
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  module ClassMethods
    # アクセス権をビットで定義する
    # {:manage => 0b111, :write => 0b011, :read => 0b001, :default => 0b001}
    def acts_as_permissible(permissions)
      self.class_eval do
        # Todo
      end
    end
  end

  module InstanceMethods
  end

  class Railtie < ::Rails::Railtie #:nodoc:
    initializer "acts_as_permissible" do
      ActiveRecord::Base.send(:include, Acts::Permissible)
    end
  end
end
end
