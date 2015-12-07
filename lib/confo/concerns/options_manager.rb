module Confo
  module OptionsManager
    extend ActiveSupport::Concern

    module ClassMethods

      # Define option accessors.
      def option_accessor(*names)

        # TODO Save list of option names
        names.each do |name|
          define_option_functional_accessor(name)
          define_option_writer(name)
        end
      end

      # TODO Implement
      def readonly_option(*names)

      end

    protected
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
      # TODO Prevent subconfigs here
      respond_to?(option) ? send(option) : raw_get(option)
    end

    # Internal method to get an option.
    # If value is callable without arguments
    # it will be called and result will be returned.
    def raw_get(option)
      value = options_storage[option]
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
      # TODO Prevent subconfigs here
      method = "#{option}="
      respond_to?(method) ? send(method, value) : raw_set(option, value)
    end

    # Internal method to set option.
    def raw_set(option, value)
      options_storage[option] = value
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
        options_storage.has_key?(arg)
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
      options_storage.delete(option)
      self
    end

    # Returns option names as array of symbols.
    def keys
      options_storage.each_with_object([]) do |(k, v), memo|
        memo << k.to_sym
      end
    end

    # Returns option values as array.
    def values
      options_storage.each_with_object([]) do |(k, v), memo|
        memo << get(k)
      end
    end

    # Returns all options at once.
    #   obj.options => { option: 'value' }
    def options
      options_storage.each_with_object({}) do |(k, v), memo|
        memo[k] = get(k)
      end
    end

  protected
    def options_storage
      @options_storage ||= OptionsStorage.new
    end
  end

  class OptionsStorage < ActiveSupport::HashWithIndifferentAccess
  end
end