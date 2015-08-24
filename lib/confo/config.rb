require_relative '../confo.rb'

module Confo
  class Config
    include OptionsManager
    include SubconfigsManager

    attr_reader :behaviour_options

    def initialize(behaviour_options = {}, &block)
      @behaviour_options = behaviour_options
      preconfigure
      configure(&block) if block
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
          else

            # Wants one of the following:
            #   - access subconfig
            #   - access option
            subconfig_exists?(name) ? subconfig(name) : option(normalize_option(name))
          end

        when 1
          arg = args.first

          # Wants to access collection:
          #   object.properties :id {  }
          if (arg.is_a?(String) || arg.is_a?(Symbol)) && subconfig_exists?(name)
            subconfig(name.to_s.pluralize, arg, &block)
          else

            # Wants to access option:
            #   object.cache = :none
            #   object.cache :none
            option(normalize_option(name), arg)
          end

        else
          option(normalize_option(name), *args)
      end
    end

    def to_hash
      {}.merge!(options.to_hash).merge!(subconfigs.to_hash)
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

    def normalize_option(name)
      name.to_s.sub(/=+\Z/, '').to_sym
    end
  end
end