module ApplicationHelper
  def orm_models
    %w[User Group].map {|name| orm_model(name)}
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
    select_setting("lang", options, I18n.locale)
  end

  def orm_select
    select_setting("orm", ["ActiveRecord", "Mongoid"], session[:model])
  end

  def select_setting(name, options, selected)
    content_tag(:div, class: "form-group") do
      label_tag(name, t("dummy.#{name}")) + select_tag(name, options_for_select(options, selected), class: "form-control") +
        javascript_tag(<<-EOT)
          $("##{name}").change(function() {
            $.post("/", $(this).closest("form").serialize()).then(function() { location.href = "/"; });
          });
        EOT
    end
  end
end
