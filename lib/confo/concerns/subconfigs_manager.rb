module Confo
  module SubconfigsManager
    extend ActiveSupport::Concern

    module ClassMethods
      def includes_config(arg, options = {})
        @subconfigs_options ||= {}

        # Support different syntaxes:
        #   includes_config :actions
        #   includes_config of: :actions
        #   includes_config for: :actions
        name          = (arg.kind_of?(Hash) ? arg[:of] || arg[:for] : arg).to_sym
        new_options   = @subconfigs_options[name]
        new_options ||= { name: name, fallback_class_name: 'Confo::Config' }
        new_options.merge!(options)

        @subconfigs_options[name] = new_options

        define_subconfig_reader(name, new_options)
        self
      end

      def subconfigs_options
        all_options = @subconfigs_options ? @subconfigs_options.dup : {}
        if superclass.respond_to?(:subconfigs_options)
          superclass.subconfigs_options.each do |name, options|
            new_options = {}
            new_options.merge!(options[name]) if options[name]
            new_options.merge!(options)
            options[name] = new_options
          end
        end
        all_options
      end

      def define_subconfig_reader(subconfig_name, subconfig_options)
        define_method(subconfig_name) do |options = nil, overrides = nil, &block|
          subconfig_internal(subconfig_name, options, overrides, &block)
        end
      end
    end

    def subconfigs
      unless @all_subconfigs_loaded
        self.class.subconfigs_options.each { |name, options| subconfig(name) }
        @all_subconfigs_loaded = true
      end
      subconfig_instances
    end

    def subconfig(subconfig_name, options = nil, overrides = nil, &block)
      respond_to?(subconfig_name) ?
        send(subconfig_name, options, overrides, &block) :
        subconfig_internal(subconfig_name, options, overrides, &block)
    end

    def subconfig_exists?(subconfig_name)
      subconfig_instances.exists?(subconfig_name)
    end

  protected

    def subconfig_instances
      @subconfig_instances ||= Collection.new
    end

    def subconfig_internal(subconfig_name, options = nil, overrides = nil, &block)
      unless subconfig_exists?(subconfig_name)
        subconfig_options   = self.class.subconfigs_options[subconfig_name].try(:dup) || {}
        subconfig_options.merge!(overrides) if overrides

        subconfig_class     = Confo.call(self, :subconfig_class, subconfig_name, subconfig_options)
        subconfig_instance  = Confo.call(self, :construct_subconfig, subconfig_class, subconfig_options)

        subconfig_instance.set(:name, subconfig_name) unless subconfig_instance.kind_of?(Collection)
        subconfig_instances.set(subconfig_name, subconfig_instance)
      end
      subconfig_instance = subconfig_instances.get(subconfig_name)
      subconfig_instance.set(options)       if options
      subconfig_instance.configure(&block)  if block
      subconfig_instance
    end

    def construct_subconfig(subconfig_class)
      subconfig_class.new
    end

    def subconfig_class(subconfig_name, subconfig_options)
      if class_name = subconfig_options[:class_name]
        class_name.camelize
      else
        guess_subconfig_class_name(subconfig_name)
      end.safe_constantize || subconfig_options.fetch(:fallback_class_name, 'Confo::Config').constantize
    end

    def guess_subconfig_class_name(subconfig_name)
      "#{subconfig_name.to_s.camelize}Config"
    end
  end
end