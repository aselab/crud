module Crud
  class ApplicationController < ApiController
    if self < ActionController::API
      def self.inherited(child)
        raise "should be 'class #{child} < Crud::ApiController'"
      end
    else
      helper BootstrapHelper
      helper_method :model, :model_name, :model_key, :resources, :resource, :columns,
        :stored_params, :stored_params_keys_for_search, :stored_params_keys_for_advanced_search,
        :cancel_path, :sort_key?, :sort_key, :sort_order, :search_keyword, :search_values, :search_operators,
        :advanced_search?, :columns_for_advanced_search, :index_actions, :can?, :cannot?, :crud_action, :modal?,
        :selectable?, :serializer, :serialization_scope, :crud_form_options
    end

    def index(&format_block)
      super do |format|
        format_block.try(:call, format)
        format.html { render "index.html" }
        format.js { render "index.js" }
        format.form { render "index.form" }
      end
    end

    def show(&format_block)
      super do |format|
        format_block.try(:call, format)
        format.html { render "show.html" }
        format.js { render "show.js" }
      end
    end

    def new(&format_block)
      super do |format|
        format_block.try(:call, format)
        format.any(:html, :js) { render_edit }
      end
    end

    def edit(&format_block)
      super do |format|
        format_block.try(:call, format)
        format.html { render "edit.html" }
        format.js { render "edit.js" }
      end
    end

    def create(&format_block)
      super do |success, error|
        if success
          respond_with_condition(format_block, success, true)
          success.any(:html, :js) { redirect_after_success notice: message(:successfully_created, :name => model_name) }
        else
          respond_with_condition(format_block, error, false)
          error.any(:html, :js) { render_edit :unprocessable_entity }
        end
      end
    end

    def update(&format_block)
      super do |success, error|
        if success
          respond_with_condition(format_block, success, true)
          success.any(:html, :js) { redirect_after_success notice: message(:successfully_updated, :name => model_name) }
        else
          respond_with_condition(format_block, error, false)
          error.any(:html, :js) { render_edit :unprocessable_entity }
        end
      end
    end

    def destroy(&format_block)
      super do |success, error|
        if success
          respond_with_condition(format_block, success, true)
          success.any(:html, :js) { redirect_after_success notice: message(:successfully_deleted, :name => model_name) }
        else
          respond_with_condition(format_block, error, false)
          error.any(:html, :js) { redirect_to request.referer, alert: resource.errors.full_messages.join(", ") }
        end
      end
    end

    protected

    def do_index
      super unless request.format.form?
    end

    def do_page
      params.delete(:page) if params[:page] == "false" && (request.format.html? || request.format.js?)
      super
    end
    #
    # CRUDの画面遷移で保持するパラメータのkey
    #
    def stored_params_keys
      [:controller, :action, :term, :sort_key, :sort_order, :page, :per, :container]
    end

    #
    # 保持するパラメータ
    #
    # stored_params => stored_params_keysに一致するパラメータのみ返す
    # stored_params(:a, :b) => :a, :bのパラメータのみ返す
    # stored_params(:a, :b, :c => 1, :d => 2) => :a, :bのパラメータに{:c => 1, :d => 2}をマージした結果を返す
    #
    def stored_params(*args)
      overwrites = args.extract_options!
      keys = args.blank? ? stored_params_keys : args
      params.to_unsafe_hash.symbolize_keys.extract!(*keys).merge(overwrites)
    end

    def stored_params_keys_for_search
      [:sort_key, :sort_order, :per, :container, :modal_target, :multiple]
    end

    def index_actions
      [:show, :edit, :destroy]
    end

    def set_defaults
      super
      @title = t("crud.action_title." + crud_action.to_s, :name => model_name)
      @remote = request.format.js? || (request.format.form? && params[:container])
      @remote_link = params[:remote] == "true" if params[:remote]
    end

    def modal?
      @modal ||= self.class.include?(Crud::ModalPickerController)
    end

    def cancel_path
      url_for(stored_params(action: :index))
    end

    def set_redirect_to(url)
      @redirect_to_url = url
    end

    # 作成，更新，削除成功後のリダイレクト先
    def redirect_after_success(options)
      options = { status: 303 }.merge(options)
      redirect_to(@redirect_to_url || cancel_path, options)
    end

    def message(key, options = nil)
      @message || t("crud.message." + key.to_s, options)
    end

    def render_edit(status = :ok)
      render action: "edit", status: status, layout: !request.xhr?
    end

    def columns_for_index
      request.format.html? || request.format.js? ? model_columns : super
    end

    def crud_form_options
      {}
    end
  end
end
