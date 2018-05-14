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

      self.icon = ActiveSupport::OrderedOptions.new

      self.icon.modal_picker = "fas fa-th-list"
      self.icon.advanced_search = "fas fa-filter"
      self.icon.search = "fas fa-search"
      self.icon.sort = "fas fa-sort text-muted"
      self.icon.sort_asc = "fas fa-sort-up"
      self.icon.sort_desc = "fas fa-sort-down"
      self.icon.new = "fas fa-plus"
      self.icon.show = "fas fa-sticky-note"
      self.icon.edit = "fas fa-edit"
      self.icon.destroy = "fas fa-trash"
      self.icon.left = "fas fa-chevron-left"
      self.icon.right = "fas fa-chevron-right"
    end
  end
end
