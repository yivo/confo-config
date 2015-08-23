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
        new_options   = @subconfigs_options[name] || {}

        new_options.merge!(options)

        new_options[:name]          = name
        @subconfigs_options[name]   = new_options

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
        define_method(subconfig_name) do |&block|
          subconfig(subconfig_name, &block)
        end
      end
    end

    def subconfigs
      subconfig_names = self.class.subconfigs_options.keys
      subconfig_names += @subconfig_instances.keys if @subconfig_instances
      subconfig_names.reduce({}) do |memo, subconfig_name|
        memo[subconfig_name] = subconfig(subconfig_name)
        memo
      end
    end

    def subconfigs_to_hash
      subconfigs = self.subconfigs
      subconfigs.each { |name, instance| subconfigs[name] = instance.to_hash }
      subconfigs
    end

    def subconfig(subconfig_name, &block)
      @subconfig_instances  ||= {}
      subconfig_name          = subconfig_name.to_sym
      subconfig_instance      = @subconfig_instances[subconfig_name]

      unless subconfig_instance
        subconfig_options = self.class.subconfigs_options[subconfig_name]

        subconfig_instance = if subconfig_options
          subconfig_class = lookup_subconfig_class(subconfig_options)
          build_args      = [subconfig_class, subconfig_options]
          send(:build_subconfig, *build_args[0...method(:build_subconfig).arity])
        else
          default_subconfig_class.new
        end

        @subconfig_instances[subconfig_name] = subconfig_instance
      end
      subconfig_instance.configure(&block) if block
      subconfig_instance
    end

    protected

    def build_subconfig(subconfig_class, subconfig_options)
      subconfig_class.new
    end

    def default_subconfig_class
      Config
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