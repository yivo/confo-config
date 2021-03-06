# frozen_string_literal: true
module Confo
  class Preconfigurator
    include Singleton

    def preconfigure(config)
      raise PreconfiguratorNotImplementedError
    end
  end

  class PreconfiguratorNotImplementedError < ::StandardError
  end
end
