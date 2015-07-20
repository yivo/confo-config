module Confo
  module SubconfigsManager
    extend ActiveSupport::Concern if defined?(Rails)

    module ClassMethods

      attr_reader :subconfigs

      def subconfig(name, options = nil)
        @subconfigs ||= {}
        subconfig_options = @subconfigs[name] || {name: name}
        subconfig_options.merge!(options) if options
        @subconfigs[name] = subconfig_options
        define_subconfig_reader(subconfig_options)
        subconfig_options
      end

      protected

      def define_subconfig_reader(subconfig_options)
        define_method(subconfig_options[:name]) do |&block|
          subconfig(subconfig_options[:name], &block)
        end
      end
    end

    def subconfigs
      if self.class.subconfigs
        self.class.subconfigs.reduce({}) do |memo, pair|
          name = pair.first
          memo[name] = send(name)
          memo
        end
      end || {}
    end

    def subconfig(name, &block)
      @subconfigs ||= {}
      unless subconfig = @subconfigs[name]
        subconfig_options = self.class.subconfigs[name]
        subconfig_class   = lookup_subconfig_class(subconfig_options)
        subconfig         = @subconfigs[name] = build_subconfig(subconfig_class)
      end
      subconfig.configure(&block) if block
      subconfig
    end

    protected

    def build_subconfig(subconfig_class)
      subconfig_class.new
    end

    def lookup_subconfig_class(subconfig_options)
      if class_name = subconfig_options[:class_name]
        class_name.to_s.camelize
      else
        guess_subconfig_class_name(subconfig_options)
      end.constantize
    end

    def guess_subconfig_class_name(subconfig_options)
      "#{subconfig_options[:name].to_s.camelize}Config"
    end
  end
end