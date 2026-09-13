# frozen_string_literal: true

require "json"

# Monkey patch JSON.parse to accept a hash as the second argument instead of raising ArgumentError
# This fixes a bug where ActiveSupport::JSON.decode in Rails 8.1 calls JSON.parse(json, options)
# which throws an ArgumentError in Ruby 3.3 with json 3.0+
module JSON
  class << self
    alias_method :original_parse, :parse

    def parse(source, opts = {})
      # If opts is a hash (positional argument), we pass it as keyword arguments (**opts)
      # to the original parse method which expects keyword arguments in json 3.0+
      original_parse(source, **opts)
    end
  end
end
