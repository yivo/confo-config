module Confo
  module OptionsManager
    extend ActiveSupport::Concern

    module ClassMethods

      # Define option accessors.
      def option_accessor(*names)
        names.each do |name|
          define_option_functional_accessor(name)
          define_option_writer(name)
        end
      end

      def define_option_functional_accessor(name)
        define_method("#{name}") do |*args|
          if args.size > 0
            raw_set(name, args.first)
            self
          else
            raw_get(name)
          end
        end
      end

      def define_option_writer(name)
        define_method("#{name}=") do |value|
          raw_set(name, value)
          self
        end
      end
    end

    # Returns option value:
    #   obj.get(:option)    => 'value'
    #   obj.get('option')   => 'value'
    #
    #   obj.set :option, -> { 'value' }
    #   obj.get(:option)    => 'value'
    #
    #   obj.set :option, -> (arg) { 'value' }
    #   obj.get(:option)    => -> (arg) { 'value' }
    def get(option)
      public_get(option)
    end

    # Alias for +get+.
    alias [] get

    protected

    # Method to get an option.
    # If there is an option accessor defined then it will be used.
    # In other cases +raw_get+ will be used.
    def public_get(option)
      respond_to?(option) ? send(option) : raw_get(option)
    end

    # Internal method to get an option.
    # If value is callable without arguments
    # it will be called and result will be returned.
    def raw_get(option)
      value = data[option]
      Confo.callable_without_arguments?(value) ? value.call : value
    end

    public

    # Sets option:
    #   obj.set(:option, 'value')
    #   obj.set('option', 'value')
    #   obj.set({ foo: '1', bar: '2', baz: -> { 3 } })
    def set(arg, *args)
      if arg.kind_of?(Hash)
        arg.each { |k, v| public_set(k, v) }
      elsif args.size > 0
        public_set(arg, args.first)
      end
      self
    end

    # Alias for +set+.
    alias []= set

    protected

    # Method to set an option.
    # If there is an option accessor defined then it will be used.
    # In other cases +raw_set+ will be used.
    def public_set(option, value)
      method = "#{option}="
      respond_to?(method) ? send(method, value) : raw_set(option, value)
    end

    # Internal method to set option.
    def raw_set(option, value)
      data[option] = value
    end

    public

    # Sets option only if it is not set yet:
    #   obj.set_at_first(:option, 1)
    #   obj.get(:option)      => 1
    #   obj.set_at_first(:option, 2)
    #   obj.get(:option)      => 1
    def set_at_first(*args)
      set?(*args)
      self
    end

    # Alias for +set_at_first+.
    alias init set_at_first

    # Option accessor in functional style:
    #   obj.option(:option, 'value')
    #   obj.option(:option)   => 'value'
    def option(option, *args)
      args.size > 0 ? set(option, args.first) : get(option)
    end

    # Checks if option is set.
    # Works similar to set if value passed but sets only uninitialized options.
    def set?(arg, *rest_args)
      if arg.kind_of?(Hash)
        arg.each { |k, v| set(k, v) unless set?(k) }
        nil
      elsif rest_args.size > 0
        set(arg, rest_args.first) unless set?(arg)
        true
      else
        data.has_key?(arg)
      end
    end

    # If you expect computed value you can pass arguments to it:
    #   obj.set :calculator, -> (num) { num * 2 }
    #   obj.result_of :calculator, 2    => 4
    def result_of(option, *args)
      Confo.result_of(get(option), *args)
    end

    # Unsets option.
    def unset(option)
      data.delete(option)
      self
    end

    # Returns option names as array of symbols.
    def keys
      data.reduce([]) do |memo, k, v|
        memo << k.to_sym
        memo
      end
    end

    # Returns option values as array.
    def values
      data.values
    end

    # Returns all options at once.
    #   obj.options => { option: 'value' }
    def options
      data.reduce({}) do |memo, pair|
        option        = pair.first.to_sym
        memo[option]  = get(option)
        memo
      end
    end

    def options_to_hash
      options = self.options
      options.each { |option, value| options[option] = value.to_hash }
      options
    end

    protected

    def data
      @data ||= ActiveSupport::HashWithIndifferentAccess.new
    end
  end
end