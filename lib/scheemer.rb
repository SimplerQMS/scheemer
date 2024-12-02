# frozen_string_literal: true

module Scheemer
  module DSL
    def self.extended(entity)
      entity.extend(Schema::DSL)
      entity.extend(Params::DSL)
      entity.include(InstanceMethods)
    end
  end

  module InstanceMethods
    def initialize(params, data = {})
      all_params = (params.respond_to?(:permit!) ? params.permit! : params).to_h
      permitted = self.class.validate_schema!(all_params)

      root_node = permitted.to_h.values.first

      super(root_node, data.to_h)
    end
  end
end

require_relative "scheemer/errors"
require_relative "scheemer/params"
require_relative "scheemer/schema"
require_relative "scheemer/version"
