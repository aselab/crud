module Crud
  module ModalPickerController
    extend ActiveSupport::Concern

    included do
      default_paginates_per 10
    end

    protected

    def model
      @model ||= self.class.superclass.name.sub(/Controller$/, "").singularize.constantize
    end

    def set_defaults
      super
      @title = t("crud.message.modal_picker_title", :name => model_name)
    end

    def index_actions
      []
    end

    def stored_params_keys
      super + [:modal_target, :multiple, :op, :v, :type]
    end
  end
end
