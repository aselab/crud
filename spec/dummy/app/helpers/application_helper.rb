module ApplicationHelper
  def orm_models
    names = %w[User Group Misc MiscBelonging MiscHabtm]
    names.push("MiscThrough") unless session[:model] == "Mongoid"
    names.map {|name| orm_model(name)}
  end

  def orm_model(name)
    module_name = session[:model] == "Mongoid" ? "Mongo" : "Ar"
    "#{module_name}::#{name}".constantize
  end

  def header_links
    content_tag :ul, class: "navbar-nav mr-auto" do
      orm_models.each do |model|
        concat content_tag(:li, link_to(model.model_name.human, polymorphic_path(model), class: "nav-link"), class: "nav-item")
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
      label_tag(name, t("dummy.#{name}"), class: "mx-2") + select_tag(name, options, class: "form-control", include_blank: include_blank) +
        javascript_tag(<<-EOT)
          $("##{name}").change(function() {
            $.post("/", $(this).closest("form").serialize()).then(function() { location.href = "/"; });
          });
        EOT
    end
  end

  def file_input_options
    { as: :bootstrap_filestyle }
  end

  def misc_input_options
    { as: :select2, url: polymorphic_path(orm_model("Misc")), label_method: :string }
  end

  def misc_html(resource, value)
    link_to value.string, value, remote: @remote
  end

  def misc_belongings_input_options
    { as: :select2 }
  end

  def misc_habtms_input_options
    { as: :select2 }
  end
end
