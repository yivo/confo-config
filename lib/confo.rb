require 'confo/version'
require 'confo/concerns/options_manager'
require 'confo/concerns/subconfigs_manager'
require 'confo/config'
require 'confo/preconfigurator'

module Confo
  class << self
    def result_of(value, *args)
      value = self.option(option)
      value.respond_to?(:call) ? value.call(*args[0...value.arity]) : value
    end
  end
end

unless defined?(Rails)
  class String
    def demodulize(path)
      path = path.to_s
      if i = path.rindex('::')
        path[(i + 2)..-1]
      else
        path
      end
    end
  end
end