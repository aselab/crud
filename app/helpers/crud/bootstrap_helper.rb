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
        def method_missing(name, *args)
          wrapper {context.send(name, *args)}
        end

        def wrapper(options = nil, &block)
          context.content_tag :li, block.call, options
        end

        def item(label, url, active_params = nil, options = {})
          url = context.url_for(url)
          active = active_params ? active_params.all?{|k, v| context.params[k] == v} : (context.url_for(context.params) == url)
          wrapper_options = active ? {:class => "active"}.merge(options.delete(:wrapper_options) || {}) : {}
          wrapper(wrapper_options) {context.link_to(label, url, options)}
        end

        def dropdown(label, options = {}, &block)
          wrapper_options = {:class => "dropdown #{options.delete(:class)}"}.merge(options)
          wrapper(wrapper_options) do
            <<-HTML.html_safe
              <a class="dropdown-toggle" href="#" data-toggle="dropdown">
                #{label}<b class="caret"></b>
              </a>
              <ul class="dropdown-menu">
                #{context.capture(context, &block)}
              </ul>
            HTML
          end
        end

        private
        def params(url_options, opts)
          p = url_params(url_options)
          wrapper_options = opts.delete(:wrapper_options) || {}
          wrapper_options[:class] ||= "active" if opts[:active] || active?(p)
          [p, wrapper_options]
        end

        def url_params(arg)
          if arg.is_a?(String)
            controller, action = arg.split("#")
            {:controller => controller, :action => action}
          else
            arg
          end
        end

        def active?(arg)
          url_params(arg).all? {|k, v| context.params[k] == v}
        end
      end
    end
  end
end
