#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Apes
  # A set of module to handle JSON API in a Rails controller.
  module Concerns
    # Errors handling module.
    module Errors
      # Default map of error handlers
      ERROR_HANDLERS = {
        "ActiveRecord::RecordNotFound" => :error_handle_not_found,
        "Apes::Errors::AuthenticationError" => :error_handle_fordidden,
        "Apes::Errors::InvalidModelError" => :error_handle_invalid_source,
        "Apes::Errors::BadRequestError" => :error_handle_bad_request,
        "Apes::Errors::MissingDataError" => :error_handle_missing_data,
        "Apes::Errors::InvalidDataError" => :error_handle_invalid_data,
        "JSON::ParserError" => :error_handle_invalid_data,
        "ActiveRecord::RecordInvalid" => :error_handle_validation,
        "ActiveRecord::UnknownAttributeError" => :error_handle_unknown_attribute,
        "ActionController::UnpermittedParameters" => :error_handle_unknown_attribute,
        "Apes::Errors::BaseError" => :error_handle_general,
        "Lazier::Exceptions::Debug" => :error_handle_debug
      }.freeze

      # Handles a failed request.
      #
      # @param status [Symbol|Fixnum] The HTTP error code.
      # @param error [Object] The occurred error.
      def fail_request!(status, error)
        raise(::Apes::Errors::BaseError, {status: status, error: error})
      end

      # Default unexpected exception handler.
      #
      # @param exception [Exception] The exception to handle.
      def error_handle_exception(exception)
        handler = ERROR_HANDLERS.fetch(exception.class.to_s, :error_handle_others)
        send(handler, exception)
      end

      # Handles base exceptions.
      #
      # @param exception [Exception] The exception to handle.
      def error_handle_general(exception)
        render_error(exception.details[:status], exception.details[:error])
      end

      # Handles other exceptions.
      #
      # @param exception [Exception] The exception to handle.
      def error_handle_others(exception)
        @exception = exception
        @backtrace = exception.backtrace
           .slice(0, 50).map { |line| line.gsub(Apes::RuntimeConfiguration.rails_root, "$RAILS").gsub(Apes::RuntimeConfiguration.gems_root, "$GEMS") }
        render("errors/500", status: :internal_server_error)
      end

      # Handles debug exceptions.
      #
      # @param exception [Exception] The exception to handle.
      def error_handle_debug(exception)
        render("errors/400", status: 418, locals: {debug: YAML.load(exception.message)})
      end

      # Handles unauthorized requests.
      #
      # @param exception [Exception] The exception to handle.
      def error_handle_fordidden(exception)
        @authentication_error = {error: exception.message.present? ? exception.message : "You don't have access to this resource."}
        render("errors/403", status: :forbidden)
      end

      # Handles requests of missing data.
      def error_handle_not_found(_ = nil)
        render("errors/404", status: :not_found)
      end

      # Handles requests containing invalid data.
      def error_handle_bad_request(_ = nil)
        @reason = "Invalid Content-Type specified. Please use \"#{request_valid_content_type}\" when performing write operations."
        render("errors/400", status: :bad_request)
      end

      # Handles requests that miss data.
      def error_handle_missing_data(_ = nil)
        @reason = "Missing data."
        render("errors/400", status: :bad_request)
      end

      # Handles requests that send invalid data.
      def error_handle_invalid_data(_ = nil)
        @reason = "Invalid data provided."
        render("errors/400", status: :bad_request)
      end

      # Handles requests that send data with unexpected attributes.
      def error_handle_unknown_attribute(exception)
        @errors = exception.is_a?(ActionController::UnpermittedParameters) ? exception.params : exception.attribute
        render("errors/422", status: :unprocessable_entity)
      end

      # Handles requests that send data with invalid attributes.
      def error_handle_validation(exception)
        @errors = exception.record.errors.to_hash
        render("errors/422", status: :unprocessable_entity)
      end
    end
  end
end
