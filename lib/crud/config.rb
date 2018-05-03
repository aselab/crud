module Crud
  class << self
    def configure
      yield config
    end

    def config
      @config ||= Config.new
    end
  end

  class Config < ActiveSupport::OrderedOptions
    def initialize
      self.simple_form = ActiveSupport::OrderedOptions.new

      # simple_formのvalid_classを有効にするかどうか
      # https://github.com/plataformatec/simple_form/pull/1553
      self.simple_form.use_valid_class = false
    end
  end
end
