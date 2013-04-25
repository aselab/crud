module Crud
  module BootstrapHelper
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

        def item(label, url, active_params = nil, options = {})
          url = context.url_for(url)
          wrapper_options = options.delete(:wrapper_options) || {}
          if active?(url, active_params)
            wrapper_options[:class] = "active #{wrapper_options[:class]}"
          end
          wrapper(wrapper_options) {context.link_to(label, url, options)}
        end

        def dropdown(label, options = {}, &block)
          wrapper_options = {:class => "dropdown #{options.delete(:class)}"}.merge(options)
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

        def active?(url, active_params)
          !disable_active && (active_params ?
            active_params.all?{|k, v| context.params[k] == v} :
            same_url?(context.url_for(context.params), url)
          )
        end
      end
    end
  end
end