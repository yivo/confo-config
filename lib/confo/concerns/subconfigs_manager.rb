module Confo
  module SubconfigsManager
    extend ActiveSupport::Concern

    module ClassMethods
      def subconfig(name, options = nil)
        @subconfigs ||= {}
        subconfig_options = @subconfigs[name] || {name: name}
        subconfig_options.merge!(options) if options
        @subconfigs[name] = subconfig_options
        define_subconfig_reader(name)
        subconfig_options
      end

      def subconfigs_options
        subconfigs = @subconfigs ? {}.merge(@subconfigs) : {}
        if superclass.respond_to?(:subconfigs_options)
          superclass.subconfigs_options.each do |name, options|
            new_options = {}
            new_options.merge!(subconfigs[name]) if subconfigs[name]
            new_options.merge!(options)
            subconfigs[name] = new_options
          end
        end
        subconfigs
      end

      protected

      def define_subconfig_reader(subconfig_name)
        define_method(subconfig_name) do |&block|
          subconfig(subconfig_name, &block)
        end
      end
    end

    def subconfigs
      self.class.subconfigs_options.reduce({}) do |memo, pair|
        name = pair.first
        memo[name] = subconfig(name)
        memo
      end
    end

    def subconfig(name, &block)
      @subconfigs ||= {}
      unless subconfig = @subconfigs[name]
        subconfig_options = self.class.subconfigs_options[name]
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