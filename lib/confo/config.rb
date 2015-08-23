require_relative '../confo.rb'

module Confo
  class Config
    include OptionsManager
    include SubconfigsManager
    include DefinitionsManager

    def initialize(options = nil, &block)
      preconfigure
      set(options) if options
      configure(&block) if block
    end

    def configure(*args, &block)
      case args.size
        when 0 then instance_eval(&block) if block
        when 1 then subconfig(args.first, &block)
        when 2 then definition(*args, &block)
      end
      self
    end

    def to_hash
      {}.merge!(options_to_hash).merge!(subconfigs_to_hash).merge!(definition_groups_to_hash)
    end

    # Implements funny DSL.
    # USE IT CAREFUL.
    # USE ONLY WITH PREDEFINED OPTION ACCESSORS!
    #
    # Configure subconfig:
    #   obj.configure :sub { }
    #
    # Configure definition:
    #   obj.configure :thing, :name { }
    #
    # Access option:
    #   obj.foo
    #
    def method_missing(method_name, *args, &block)
      if block
        case args.size
          when 0 then subconfig(method_name, &block)
          when 1 then definition(method_name, args.first, &block)
        end
        self
      else
        option(method_name.to_s.sub(/=+\Z/, ''), *args)
      end
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
  end
end