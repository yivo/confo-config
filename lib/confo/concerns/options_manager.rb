module Confo
  module OptionsManager
    extend ActiveSupport::Concern

    # Get all options at once
    #   component.options => {option: 'value'}
    #
    def options
      data.reduce({}) do |memo, name, value|
        memo[name.to_sym] = callable_without_arguments?(value) ? value.call : value
        memo
      end
    end

    # Get option by name
    #   component.get(:option)    => 'value'
    #   component.get('option')   => 'value'
    #
    # Value which responds to call and has zero arguments
    # will be called and its result will be returned
    #
    #   component.set :option, -> { 'value' }
    #   component.get(:option)    => 'value'
    #
    #   component.set :option, -> (arg) { 'value' }
    #   component.get(:option)    => -> (arg) { 'value' }
    #
    def get(option)
      value = data[option]
      callable_without_arguments?(value) ? value.call : value
    end

    # Alias for `get`
    #   component[:option] => 'value'
    #   component['option'] => 'value'
    alias [] get

    # If you expect computed value you can pass arguments to it
    def result_of(option, *args)
      Confo.result_of(data[option], *args)
    end

    # Set option by name
    #   component.set(:option, 'value')
    #   component.set('option', 'value')
    def set(arg, option_value = nil)
      if arg.kind_of?(Hash)
        arg.each { |key, value| data[key] = value }
      else
        data[arg] = option_value
      end
      self
    end

    # Alias for `set`
    alias []= set

    # Sets option only if it is not set yet
    def set_at_first(option_name, option_value)
      set(option_name, option_value) unless set?(option_name)
      self
    end

    # Option accessor in functional style
    #   component.option(:option, 'value')
    #   component.option(:option)   => 'value'
    def option(option, *args)
      args.size > 0 ? set(option, args.first) : get(option)
    end

    # Check if option is set
    def set?(option)
      data.has_key?(option)
    end

    # Unset option
    def unset(option)
      data.delete(option)
    end

    def keys
      data.reduce([]) do |memo, k, v|
        memo << convert_key(k)
        memo
      end
    end

    # Implements funny DSL
    #   component.configure do
    #     option 'value'
    #     foo 'bar'
    #   end
    def method_missing(method_name, *args, &block)
      option(method_name.to_s.sub(/=+\Z/, ''), *args)
    end

    protected

    def data
      @options ||= ActiveSupport::HashWithIndifferentAccess.new
    end

    def callable_without_arguments?(obj)
      obj.respond_to?(:call) && (!obj.respond_to?(:arity) || obj.arity == 0)
    end
  end
end