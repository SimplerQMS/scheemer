# frozen_string_literal: true

require_relative "./fallbacker"

require_relative "./extensions/string"

module Scheemer
  # This handles the conversion from the HTTP linguo (camelCase)
  # to Ruby linguo (snake_case), triggers the children's predefined
  # validations and provides accessors for the top level properties
  # of the incoming hash.
  module Params
    using Extensions::CaseModifier

    module DSL
      def self.extended(entity)
        entity.include(InstanceMethods)
      end

      def on_missing(path:, fallback_to:)
        params_fallbacks[path.to_sym] = fallback_to
      end

      def params_fallbacks
        @params_fallbacks ||= {}
      end
    end

    module InstanceMethods
      def initialize(params, data = {})
        @params = Fallbacker.apply(params, self.class.params_fallbacks)

        validate!(data.to_h) if respond_to?(:validate!)
      end

      def to_h
        @params.to_h.transform_keys { |key| key.to_s.underscore }
      end

      def method_missing(name, *args, &)
        key_name = name.to_sym.camelcase
        return @params.fetch(key_name) if internal_property?(key_name)

        super
      end

      def respond_to_missing?(name, include_private = false)
        key_name = name.camelcase

        internal_property?(name) || super
      end

      def internal_property?(name)
        return unless @params.is_a?(Hash)

        @params.key?(name.camelcase)
      end
    end
  end
end
