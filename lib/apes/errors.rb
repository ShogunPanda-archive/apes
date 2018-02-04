#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Apes
  # Error used by the framework.
  module Errors
    # The base error.
    class BaseError < RuntimeError
      attr_reader :details

      # Creates a new error.
      #
      # @param details [Object] The details of this error.
      def initialize(details = nil)
        super("")
        @details = details
      end
    end

    # Error raised when the request is not compliant with JSON API specification.
    class BadRequestError < BaseError
    end

    # Error raised when the sent data is not valid.
    class InvalidDataError < BaseError
    end

    # Error raised when the sent data is not missing.
    class MissingDataError < BaseError
    end

    # Error raised when provided authentication is invalid.
    class AuthenticationError < RuntimeError
    end
  end
end
