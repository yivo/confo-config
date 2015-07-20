module Confo
  class Config
    include OptionsManager
    include SubconfigsManager

    def initialize
      preconfigure
    end

    def configure(&block)
      instance_eval(&block) if block
      self
    end

    def to_hash
      {}.merge(options).merge(subconfigs)
    end

    protected

    def preconfigure
      klass = lookup_preconfigurator_class
      klass.instance.preconfigure(self) if klass
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