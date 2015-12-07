module Confo
  class Collection
    include Enumerable

    attr_reader :settings

    def initialize(settings = {}, &block)
      @settings = settings
      configure(&block) if block
    end

    def define(id, options = nil, construct_options = nil, &block)
      id        = convert_id(id)
      config    = storage[id]
      config  ||= begin
        config_class  = Confo.call(self, :config_class, id, construct_options)
        check_config_class!(config_class)
        config        = Confo.call(self, :construct_config, config_class, id, construct_options)
        storage[id]   = config
        config.set(:name, id)
        config
      end

      config.set(options)       if options && config.kind_of?(Config)
      config.configure(&block)  if block
      config
    end

    def get(id)
      id = convert_id(id)
      define(id)
      storage[id]
    end

    def set(id, config)
      storage[convert_id(id)] = config
    end

    alias []  get
    alias []= set

    def configure(*args, &block)
      args.present? ? define(*args).configure(&block) : instance_eval(&block)
    end

    def exists?(id)
      storage[convert_id(id)].present?
    end

    def each(&block)
      storage.each { |k, v| block.call(v) }
    end

    def to_a
      storage.each_with_object([]) do |(id, instance), memo|
        memo << (instance.respond_to?(:to_hash) ? instance.to_hash : instance)
      end
    end

    def to_hash
      storage.each_with_object({}) do |(id, instance), memo|
        memo[id] = Confo.convert_to_hash(instance)
      end
    end

    def method_missing(name, *args, &block)
      if args.empty? && name =~ /^(\w+)\?$/
        exists?($1)
      else
        super
      end
    end

    def with_new_settings(new_settings)
      self.class.new(settings.merge(new_settings)).tap do |new_obj|
        if storage = @storage
          storage.each { |k, v| new_obj.set(k.dup, v.with_new_settings(new_settings) ) }
        end
      end
    end

    def dup(config_settings = {})
      self.class.new(settings.merge(config_settings)).tap do |new_obj|
        if storage = @storage
          new_obj.instance_variable_set(:@storage, storage)
        end
      end
    end

    def deep_dup(config_settings = {})
      with_new_settings(config_settings)
    end

  protected

    def config_class(config_id, config_options)
      config_options.try(:[], :class_name).try(:safe_constantize) || Config
    end

    def construct_config(config_class, config_id, construct_options)
      config_class.new
    end

    def storage
      @storage ||= ActiveSupport::OrderedHash.new
    end

    def convert_id(id)
      id.kind_of?(Symbol) ? id : id.to_sym
    end

    def check_config_class!(config_class)
      raise 'Forbidden config class!' unless (config_class <= Config or config_class <= Collection)
    end
  end
end