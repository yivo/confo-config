module Confo
  module OptionsManager
    extend ActiveSupport::Concern if defined?(Rails)

    def options
      @options ||= {}
    end

    def get(option, *args)
      respond_to?(option) ? send(option) : Confo.result_of(options[option.to_sym], *args)
    end

    def set(option_name, option_value)
      if respond_to?(method_name = "#{option_name}=")
        send(method_name, option_value)
      else
        options[option_name.to_sym] = option_value
      end
      self
    end

    def option(option, *args)
      args.size > 0 ? set(option, args.first) : get(option)
    end

    def [](option_name)
      get(option_name)
    end

    def []=(option_name, option_value)
      set(option_name, option_value)
    end

    def set?(option)
      options.has_key?(option.to_sym)
    end

    def unset(option)
      options.delete(option.to_sym)
    end

    def method_missing(method_name, *args, &block)
      option(method_name.to_s.sub(/=+\Z/, ''), *argd)
    end
  end
end