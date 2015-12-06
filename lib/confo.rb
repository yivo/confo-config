require 'active_support/all'
require 'confo/version'
require 'confo/concerns/options_manager'
require 'confo/concerns/subconfigs_manager'
require 'confo/config'
require 'confo/collection'
require 'confo/preconfigurator'

module Confo
  class << self
    def result_of(value, *args)
      if value.respond_to?(:call)
        _args_ = value.arity < 0 ? args : args[0...value.arity]
        value.call(*args)
      else
        value
      end
    end

    def callable_without_arguments?(obj)
      obj.respond_to?(:call) && (!obj.respond_to?(:arity) || obj.arity == 0)
    end

    def convert_to_hash(value)
      if value.respond_to?(:to_hash)
        value.to_hash
      elsif value.is_a?(Array)
        value.map { |e| convert_to_hash(e) }
      else
        value
      end
    end

    def call_method_with_floating_arguments(object, method, *args)
      callable      = object.method(method)
      arity         = callable.arity
      resized_args  = arity < 0 ? args : args[0...arity]
      callable.call(*resized_args)
    end

    alias call call_method_with_floating_arguments
  end
end