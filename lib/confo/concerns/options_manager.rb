module Confo
  module OptionsManager
    extend ActiveSupport::Concern if defined?(Rails)

    def options
      @options ||= {}
    end

    def option(name, *args)
      if args.present?
        options[name.to_sym] = args.first
      else
        options[name.to_sym]
      end
    end

    def [](option_name)
      option(option_name)
    end

    def []=(option_name, option_value)
      option(option_name, option_value)
    end

    def fetch(option, *args)
      Confo.result_of(self.option(option), *args)
    end

    def method_missing(name, *args, &block)
      name = name.to_s.sub(/=+\Z/, '')
      option(name, *args)
    end
  end
end