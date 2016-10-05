module ApplicationHelper
  def orm_models
    %w[User Group Misc MiscBelonging].map {|name| orm_model(name)}
  end

  def orm_model(name)
    module_name = session[:model] == "Mongoid" ? "Mongo" : "Ar"
    "#{module_name}::#{name}".constantize
  end

  def header_links
    content_tag :ul, class: "nav navbar-nav" do
      orm_models.each do |model|
        concat content_tag(:li, link_to(model.model_name.human, polymorphic_path(model)))
      end
    end
  end

  def locale_select
    options = ["en", "ja"].map {|locale| [t("dummy.locale.#{locale}"), locale]}
    select_setting("lang", options_for_select(options, I18n.locale))
  end

  def orm_select
    select_setting("orm", options_for_select(["ActiveRecord", "Mongoid"], session[:model]))
  end

  def login_user_select
    select_setting("login_user", options_from_collection_for_select(orm_model("User").all, :id, :name, session[:user_id]), true)
  end

  def select_setting(name, options, include_blank = false)
    content_tag(:div, class: "form-group") do
      label_tag(name, t("dummy.#{name}")) + select_tag(name, options, class: "form-control", include_blank: include_blank) +
        javascript_tag(<<-EOT)
          $("##{name}").change(function() {
            $.post("/", $(this).closest("form").serialize()).then(function() { location.href = "/"; });
          });
        EOT
    end
  end
end
