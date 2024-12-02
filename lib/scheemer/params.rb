# frozen_string_literal: true

require_relative "fallbacker"

require_relative "extensions/string"

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

      def multi_slice(key, &block)
        return unless @params.is_a?(Hash)

        slices = [
          ->(name) { name.underscore },
          ->(name) { name.camelcase },
          ->(name) { name }
        ].map { |a| @params.slice(a.call(key)) }
          .reject(&:empty?)

        return if slices.empty?

        slices.first
      end

      def method_missing(name, *args, &)
        slice = multi_slice(name.to_sym)
        return slice.values.first if slice&.any?

        super
      end

      def respond_to_missing?(name, include_private = false)
        multi_slice(name.to_sym)&.any? || super
      end
    end
  end
end
