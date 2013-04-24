module Crud
  module BootstrapHelper
    def nav(type, options, &block)
      content_tag :ul, :class => "nav #{type}" do
        block.call(Context::Nav.new(self, options))
      end
    end

    def nav_tabs(options = nil, &block)
      nav("nav-tabs", options, &block)
    end

    def nav_pills(options = nil, &block)
      nav("nav-pills", options, &block)
    end

    module Context
      class Base
        attr_reader :context, :context_options

        def initialize(context, context_options)
          @context = context
          @context_options = context_options || {}
        end
      end

      class Nav < Base
        def method_missing(name, *args)
          options = args.extract_options!
          html_options = options.delete(:wrapper_options)
          context.content_tag :li, context.send(name, *args, options), html_options
        end

        def item(label, url_options, opts = {})
          p = url_params(url_options)
          wrapper_options = opts.delete(:wrapper_options) || {}
          wrapper_options[:class] ||= "active" if active?(p)
          link_to(label, {:wrapper_options => wrapper_options}.merge(context_options).merge(p).merge(opts))
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
