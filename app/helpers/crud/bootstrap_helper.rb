module Crud
  module BootstrapHelper
    BOOTSTRAP_ALERT_CLASS = {
      error: "danger",
      alert: "warning",
      notice: "success"
    }

    def bootstrap_flash_messages(mapping = nil)
      mapping = BOOTSTRAP_ALERT_CLASS.merge(mapping || {})
      flash.map do |type, message|
        c = mapping.fetch(type.to_sym, type.to_s)
        content = %Q[<button class="close" data-dismiss="alert">&times;</button>#{message}].html_safe
        content_tag :div, content, class: "alert alert-#{c} alert-dismissable"
      end.reduce(&:+)
    end

    def nav(type, &block)
      content_tag :ul, :class => "nav #{type}" do
        block.call(Context::Nav.new(self))
      end
    end

    def nav_tabs(&block)
      nav("nav-tabs", &block)
    end

    def nav_pills(&block)
      nav("nav-pills", &block)
    end

    def active_tab
      @active_tab
    end

    module Context
      class Base
        attr_reader :context

        def initialize(context)
          @context = context
        end
      end

      class Nav < Base
        attr_accessor :disable_active

        def method_missing(name, *args)
          wrapper {context.send(name, *args)}
        end

        def wrapper(options = nil, &block)
          context.content_tag :li, block.call, options
        end

        def item(name, url, active_params = nil, options = {})
          label = name.is_a?(Symbol) ? I18n.t("crud.tab.#{name.to_s}") : name
          url = context.url_for(url)
          wrapper_options = options.delete(:wrapper_options) || {}
          if active?(url, name, active_params)
            wrapper_options[:class] = "active #{wrapper_options[:class]}"
          end
          wrapper(wrapper_options) {context.link_to(label, url, options)}
        end

        def dropdown(label, active_params = nil, options = {}, &block)
          active = active_params && active_params.all? {|k, v| context.params[k] == v}
          wrapper_options = {:class => "dropdown #{options.delete(:class)} #{active ? "active" : ""}"}.merge(options)
          self.disable_active = true
          result = wrapper(wrapper_options) do
            <<-HTML.html_safe
              <a class="dropdown-toggle" href="#" data-toggle="dropdown">
                #{label}<b class="caret"></b>
              </a>
              <ul class="dropdown-menu">
                #{context.capture(context, &block)}
              </ul>
            HTML
          end
          self.disable_active = false
          result
        end

        private
        def same_url?(a, b)
          a.split("?").first == b.split("?").first
        end

        def active?(url, key, matcher = nil)
          matcher ||= url
          if disable_active
            false
          elsif tab = context.active_tab
            tab == key
          elsif matcher.is_a?(Proc)
            matcher.call
          elsif matcher.is_a?(Hash)
            matcher.all?{|k, v| context.params[k] == v.to_s}
          else
            same_url?(context.url_for(context.params), matcher)
          end
        end
      end
    end
  end
end
