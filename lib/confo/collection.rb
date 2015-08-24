module Confo
  class Collection
    include Enumerable

    attr_reader :behaviour_options

    def initialize(behaviour_options = {}, &block)
      @behaviour_options = behaviour_options
      configure(&block) if block
    end

    def define(id, options = nil, construct_options = nil, &block)
      id        = convert_id(id)
      config    = storage[id]
      config  ||= begin
        config_class  = Confo.call(self, :config_class, id, construct_options)
        config        = Confo.call(self, :construct_config, config_class, id, construct_options)
        storage[id]   = config
        config.set(:name, id)
        config
      end

      config.set(options)       if options
      config.configure(&block)  if block
      config
    end

    def get(id)
      define(id)
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
      storage.values
    end

    def to_hash
      storage.reduce({}) do |memo, (id, instance)|
        memo[id] = Confo.convert_to_hash(instance)
        memo
      end
    end

    protected

    def config_class(config_id, config_options)
      config_options.try(:[], :class_name).try(:safe_constantize) || Config
    end

    def construct_config(config_class)
      config_class.new
    end

    def storage
      @storage ||= ActiveSupport::OrderedHash.new
    end

    def convert_id(id)
      id.to_sym
    end
  end
end