# frozen_string_literal: true

module Scheemer
  module DSL
    PARAMS_MODES = %i[flat wrapped].freeze

    def self.extended(entity)
      entity.extend(Schema::DSL)
      entity.extend(Params::DSL)
      entity.include(InstanceMethods)
    end

    def params_mode(mode, root: nil)
      unless PARAMS_MODES.include?(mode)
        raise ArgumentError, "Expected params mode to be one of: #{PARAMS_MODES.join(', ')}"
      end
      raise ArgumentError, "Expected wrapped params mode to specify a root" if mode == :wrapped && root.nil?
      raise ArgumentError, "Flat params mode does not accept a root" if mode == :flat && root

      @params_mode_configuration = { mode:, root: root&.to_sym }.freeze
    end

    def params_mode_configuration
      @params_mode_configuration || { mode: :legacy }.freeze
    end

    def call(params, data = {})
      new(params, data).to_h
    end
  end

  module InstanceMethods
    def initialize(params, data = {})
      all_params = (params.respond_to?(:permit!) ? params.permit! : params).to_h
      permitted = self.class.validate_schema!(all_params)

      root_node = extract_root_node(permitted.to_h)

      super(root_node, data.to_h)
    end

    private

    def extract_root_node(permitted)
      configuration = self.class.params_mode_configuration

      case configuration[:mode]
      when :flat
        permitted
      when :wrapped
        permitted.fetch(configuration[:root])
      else
        permitted.values.first
      end
    end
  end
end

require_relative "scheemer/errors"
require_relative "scheemer/params"
require_relative "scheemer/schema"
require_relative "scheemer/version"
