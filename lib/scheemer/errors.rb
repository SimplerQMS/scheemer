# frozen_string_literal: true

module Scheemer
  class Error < StandardError; end

  class DuplicateSchemaError < Error
    def message
      <<~MSG.squish
        The schema has already been defined.
        Search your code, you know it to be true."
      MSG
    end
  end

  class InvalidSchemaError < Error
    def initialize(result)
      super

      @result = result
    end

    def message
      "#{title}: #{violations}"
    end

    def violations
      @result.errors.to_h
    end

    private

    def title
      "The submitted request does not satisfy the following requirements"
    end
  end
end
