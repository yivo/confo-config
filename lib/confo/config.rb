require_relative '../confo.rb'

module Confo
  class Config
    include OptionsManager
    include SubconfigsManager

    attr_reader :settings

    def initialize(settings = {}, &block)
      @settings = settings
      preconfigure
      configure(&block) if block
    end

    def with_new_settings(new_settings)
      self.class.new(settings.merge(new_settings)).tap do |new_config|
        if var = @options_storage
          new_config.instance_variable_set(:@options_storage, var.deep_dup)
        end

        if var = @subconfig_instances
          new_config.instance_variable_set(:@subconfig_instances, var.with_new_settings(new_settings))
        end
      end
    end

    def dup(config_settings = {})
      self.class.new(settings.merge(config_settings)).tap do |new_config|
        if var = @options_storage
          new_config.instance_variable_set(:@options_storage, var)
        end

        if var = @subconfig_instances
          new_config.instance_variable_set(:@subconfig_instances, var)
        end
      end
    end

    def deep_dup(config_settings = {})
      with_new_settings(config_settings)
    end

    def configure(*args, &block)
      case args.size

        # Current config configuration:
        #   object.configure {  }
        when 0
          instance_eval(&block) if block
          self

        when 1, 2, 3
          arg1, arg2, arg3  = args
          arg1_hash         = arg1.kind_of?(Hash)

          # Hash-based collection syntax:
          #   object.configure(property: :id) {  }
          #   object.configure(property: :id, {option: :value}) {  }
          #
          # Full definition syntax:
          #   object.configure(:property, :id) {  }
          #   object.configure(:property, :id, {option: :value}) {  }
          if arg1_hash || (args.size == 2 && arg2.kind_of?(Hash) == false)
            subconfig_name  = (arg1_hash ? arg1.keys.first : arg1).to_s.pluralize
            config_id       = arg1_hash ? arg1.values.first : arg2
            options         = arg1_hash ? arg2 : arg3
            subconfig(subconfig_name, options, fallback_class_name: 'Confo::Collection')
              .configure(config_id, &block)
          else

            # Subconfig configuration:
            #   object.configure(:description)
            #   object.configure(:description, {option: :value})
            subconfig(arg1, arg2, &block)
          end

        else self
      end
    end

    def method_missing(name, *args, &block)
      case args.size
        when 0
          if block
            # Wants to configure subconfig:
            #   object.description {  }
            subconfig(name, &block)

          # Wants to access boolean option:
          #   object.property?
          elsif name =~ /^(\w+)\?$/
            !!get($1)

          else
            # Wants one of the following:
            #   - access subconfig
            #   - access option
            subconfig_exists?(name) ? subconfig(name) : option(strip_assignment(name))
          end

        when 1
          arg = args.first

          # Wants to test option value:
          #   object.property?(:value) => options[:property] == :value
          if name =~ /^(\w+)\?$/
            get($1) == arg

          # Wants to access collection:
          #   object.properties :id {  }
          elsif (arg.is_a?(String) || arg.is_a?(Symbol)) && subconfig_exists?(name)
            subconfig(name.to_s.pluralize, arg, &block)

          else
            # Wants to access option:
            #   object.cache = :none
            #   object.cache :none
            option(strip_assignment(name), arg)
          end

        else
          option(strip_assignment(name), *args)
      end
    end

    def to_hash
      options.merge!(subconfigs).to_hash
    end

  protected

    def preconfigure
      preconfigurator_class = lookup_preconfigurator_class
      if preconfigurator_class
        preconfigurator_class.instance.preconfigure(self)
        true
      else
        false
      end
    end

    def lookup_preconfigurator_class
      guess_preconfigurator_class_name.safe_constantize
    end

    def configurable_component_name
      self.class.name.demodulize.sub(/Config\Z/, '')
    end

    def guess_preconfigurator_class_name
      "#{configurable_component_name}Preconfigurator"
    end

    def strip_assignment(name)
      name.to_s.sub(/=+\Z/, '').to_sym
    end
  end
end