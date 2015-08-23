module Confo
  module DefinitionsManager
    extend ActiveSupport::Concern

    def definition(def_type, def_name, options = nil, &block)
      container     = definitions_of_type(def_type)
      definition    = container[def_name]
      definition  ||= begin
        def_class   = definition_class(def_type, def_name)
        build_definition(def_class, def_type, def_name)
      end

      definition.set(options) if options
      definition.configure(&block) if block

      container[def_name] = definition
    end

    alias define definition

    def definition_class(def_type, def_name)
      Config
    end

    def build_definition(def_class, def_type, def_name)
      def_class.new
    end

    def definition_groups
      @definition_groups ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def definitions_of_type(type)
      definition_groups[type] ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def definition_groups_to_hash
      definition_groups.to_hash
    end
  end
end