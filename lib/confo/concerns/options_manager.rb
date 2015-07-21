module Confo
  module OptionsManager
    extend ActiveSupport::Concern

    module ClassMethods
      # Define option accessors.
      #
      def option(*names)
        names.each do |name|
          define_method("#{name}") do |*args|
            if args.size > 0
              set_value(name, args.first)
              self
            else
              get_value(name)
            end
          end
          define_method("#{name}=") do |value|
            set_value(name, value)
            self
          end
        end
      end

      alias options option
    end

    # Returns all options at once.
    #   obj.options => { option: 'value' }
    #
    def options
      data.reduce({}) do |memo, name, value|
        memo[name.to_sym] = get(name)
        memo
      end
    end

    # Returns option value.
    #   obj.get(:option)    => 'value'
    #   obj.get('option')   => 'value'
    #
    #   obj.set :option, -> { 'value' }
    #   obj.get(:option)    => 'value'
    #
    #   obj.set :option, -> (arg) { 'value' }
    #   obj.get(:option)    => -> (arg) { 'value' }
    #
    def get(option)
      internal_get(option)
    end

    # Alias for +get+.
    #
    alias [] get

    # If you expect computed value you can pass arguments to it.
    #   obj.set :calculator, -> (num) { num * 2 }
    #   obj.result_of :calculator, 2    => 4
    #
    def result_of(option, *args)
      Confo.result_of(get(option), *args)
    end

    # Sets option.
    #   obj.set(:option, 'value')
    #   obj.set('option', 'value')
    #   obj.set({ foo: '1', bar: '2', baz: -> { 3 } })
    #
    def set(arg, value = nil)
      if arg.kind_of?(Hash)
        arg.each { |k, v| internal_set(k, v) }
      else
        internal_set(arg, value)
      end
      self
    end

    # Alias for +set+.
    #
    alias []= set

    # Sets option only if it is not set yet.
    #   obj.set_at_first(:option, 1)
    #   obj.get(:option)      => 1
    #   obj.set_at_first(:option, 2)
    #   obj.get(:option)      => 1
    #
    def set_at_first(*args)
      set?(*args)
      self
    end

    # Alias for +set_at_first+.
    #
    alias init set_at_first
    
    # Option accessor in functional style.
    #   obj.option(:option, 'value')
    #   obj.option(:option)   => 'value'
    #
    def option(option, *args)
      args.size > 0 ? set(option, args.first) : get(option)
    end

    # Checks if option is set.
    # Works similar to set if value passed but sets only uninitialized options.
    #
    def set?(arg, *args)
      if arg.kind_of?(Hash)
        arg.each { |k, v| internal_set(k, v) unless data.has_key?(k) }
        nil
      elsif args.size > 0
        internal_set(arg, args.first) unless data.has_key?(arg)
        true
      else
        data.has_key?(arg)
      end
    end

    # Unsets option.
    #
    def unset(option)
      data.delete(option)
      self
    end

    # Returns option names as array of symbols.
    #
    def keys
      data.reduce([]) do |memo, k, v|
        memo << k.to_sym
        memo
      end
    end

    # Implements funny DSL.
    # USE IT CAREFUL.
    # WORKS BEST WITH PREDEFINED OPTION ACCESSORS!
    #
    #   obj.configure do
    #     foo 1
    #     bar 2
    #   end
    #
    def method_missing(method_name, *args)
      option(method_name.to_s.sub(/=+\Z/, ''), *args)
    end

    # protected

    def data
      @data ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def callable_without_arguments?(obj)
      obj.respond_to?(:call) && (!obj.respond_to?(:arity) || obj.arity == 0)
    end

    # Internal method to set option.
    #
    def set_value(option, value)
      data[option] = value
    end

    # Returns option value.
    # If value is callable without arguments
    # it will be called and result will be returned.
    #
    def get_value(option)
      value = data[option]
      callable_without_arguments?(value) ? value.call : value
    end

    private

    # Internal method to set an option.
    # If there is an option method defined then it will be used.
    # In other cases +set_value+ will be used.
    #
    def internal_set(option, value)
      method_name = "#{option}="
      respond_to?(method_name) ? send(method_name, value) : set_value(option, value)
    end

    # Internal method to get an option.
    # If there is an option method defined then it will be used.
    # In other cases +get_value+ will be used.
    #
    def internal_get(option)
      respond_to?(option) ? send(option) : get_value(option)
    end
  end
end