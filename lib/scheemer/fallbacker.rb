# frozen_string_literal: true

require_relative "extensions/hash"

module Scheemer
  module Fallbacker
    extend self

    using Extensions::Bury

    def apply(params, fallbacks) # rubocop:todo Metrics/MethodLength
      cloned_params = params.dup

      fallbacks.each do |(path, value)|
        keys = path.to_s.split(".").map(&:to_sym)

        next if deep_key?(params, keys)

        if value.respond_to?(:call)
          cloned_params.bury(*keys, value.call)
        else
          cloned_params.bury(*keys, value)
        end
      end

      cloned_params
    end

    private

    def deep_key?(hash, keys)
      if keys.one?
        hash.key?(*keys)
      else
        parent_path = keys[0...-1]

        !!hash.dig(*parent_path)&.key?(keys.last)
      end
    end
  end
end
