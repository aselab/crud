module Crud
  module Wizard
    extend ActiveSupport::Concern

    included do
      class_attribute :_steps
      helper_method :previous_step, :current_step, :next_step, :back_step?

      prepend_before_action :setup_wizard!, only: [:new, :edit], unless: -> { request.xhr? }
      before_action :process_step, only: [:create, :update]
    end

    def new
      super do |format|
        format.any(:html, :js) { render_wizard }
      end
    end

    def create(&format_block)
      super do |success, error|
        respond_with_render_wizard(success, error)
      end
    end

    def edit
      super do |format|
        format.any(:html, :js) { render_wizard }
      end
    end

    def update (&format_block)
      super do |success, error|
        respond_with_render_wizard(success, error)
      end
    end

    protected

    def respond_with_render_wizard(success, error)
      if success
        if last_step?
          teardown_wizard!
          success.any(:html, :js) { redirect_after_success notice: message(:successfully_created, :name => model_name) }
        else
          next_step! unless params[:next_step] == "false"
          success.any(:html, :js) { render_wizard }
        end
      else
        error.any(:html, :js) { render_wizard :unprocessable_entity }
        error.json { render json: generate_json(resource).merge(errors: json_errors(resource)), status: :unprocessable_entity }
      end
    end

    def do_update
      unless current_step == params[:current_step].try(:to_sym)
        teardown_wizard!
        flash.now[:error] = t("crud.message.invalid_transition")
        return false
      end
      if last_step?
        model.transaction do
          result = resource.save(validate: false) if resource.valid?([crud_action] + self._steps)
          raise ActiveRecord::Rollback unless result
          result
        end
      else
        validate_resource
      end
    end

    def do_create
      do_update
    end

    def validation_keys
      return ["base"] if params[model_key].blank?
      permit_params.keys.map{|key| key.gsub(/_attributes$/, "") } + ["base"]
    end

    # permit_paramsに関係するもののみvalidationをかける
    def validate_resource
      resource.valid?(current_step)
      error_keys = resource.errors.keys.map {|key| key.to_s.split(".").first} & validation_keys.map(&:to_s)
      if error_keys.blank?
        clear_errors(resource)
        true
      else
        false
      end
    end

    def clear_errors(object)
      # 無限ループしないように
      @clear_error_classes ||= []
      return if @clear_error_classes.include?(object.class)
      @clear_error_classes << object.class

      return unless object.is_a?(ActiveModel::Validations)
      object.errors.clear
      if object.respond_to?(:nested_attributes_options)
        object.nested_attributes_options.keys.each do |key|
          Array(object.send(key)).each {|nested| clear_errors(nested)}
        end
      end
    end

    def back_step?
      request.params.has_key?(:back_step)
    end

    def process_step
      if back_step?
        previous_step!
        render_wizard
      else
        send("after_#{current_step}") if respond_to?("after_#{current_step}", true)
      end
    end

    def permit_params_with_session
      @permit_params_with_session ||= params[model_key] ? merge_params(session_params, permit_params) : session_params
    end

    def deep_merge_keys
      []
    end

    def merge_params(a, b)
      a.merge(b).tap do |result|
        deep_merge_keys.each do |key|
          result[key] = a[key].deep_merge(b[key]) if a[key].is_a?(Hash) && b[key].is_a?(Hash)
        end
      end
    end

    def filter_params(params = nil)
      super(params || permit_params_with_session).tap do
        if @update_attributes_params.present?
          raise "autosave association does not supported in wizard"
        end
      end
    end

    def assign_params
      self.session_params = permit_params_with_session
      super
    end

    def setup_wizard!
      self.current_step = self._steps.at(0)
      self.session_params = {}
    end

    def teardown_wizard!
      self.current_step = nil
      self.session_params = nil
    end

    def wizard_step_session_name
      @wizard_step_session_name ||= "#{model.model_name.plural}_step"
    end

    def wizard_params_session_name
      "#{wizard_step_session_name}_params"
    end

    def session_params
      (session[wizard_params_session_name] || {}).with_indifferent_access
    end

    def session_params=(params)
      session[wizard_params_session_name] = params
    end

    def current_step
      unless session[wizard_step_session_name]
        setup_wizard!
      end
      session[wizard_step_session_name].try(:to_sym)
    end

    def current_step=(step)
      session[wizard_step_session_name] = step
    end

    def next_step
      index = current_step_index
      self._steps.at(index + 1) if index
    end

    def next_step!
      self.current_step = next_step
    end

    def previous_step
      index = current_step_index
      self._steps.at(index - 1) if index && index > 0
    end

    def previous_step!
      self.current_step = previous_step
    end

    def last_step?
      return false if request.xhr? || params[:next_step] == "false"
      current_step == self._steps.last
    end

    def current_step_index
      self._steps.index(current_step)
    end

    def render_step(step, options = {})
      unless step.nil?
        template = lookup_context.exists?(step, lookup_context.prefixes) ? step : "edit"
        render template, options
      end
    end

    def render_wizard(status = nil)
      setup_wizard! if current_step.nil?
      render_step(current_step, status: status)
    end

    module ClassMethods
      def steps(*keys)
        self._steps ||= []
        keys.each do |key|
          self._steps.push(key.to_sym)
        end
      end
    end
  end
end
