#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Apes
  # A useful set of validators.
  module Validators
    # The base validator.
    class BaseValidator < ActiveModel::EachValidator
      # Perform validation on a attribute of a model.
      #
      # @param model [Object] The object to validate.
      # @param attribute [String|Symbol] The attribute to validate.
      # @param value [Object] The value of the attribute.
      def validate_each(model, attribute, value)
        checked = check_valid?(value)
        return checked if checked

        message = options[:message] || options[:default_message]
        destination = options[:additional] ? model.additional_errors : model.errors
        destination[attribute] << message
        nil
      end
    end

    # Validates references (relationships in the JSON API nomenclature).
    class ReferenceValidator < BaseValidator
      # Creates a new validator.
      #
      # @param options [Hash] The options for the validations.
      # @return [Apes::Validators::ReferenceValidator] A new validator.
      def initialize(options)
        @class_name = options[:class_name]
        label = options[:label] || options[:class_name].classify
        super(options.reverse_merge(default_message: "must be a valid #{label} (cannot find a #{label} with id \"%s\")"))
      end

      # Perform validation on a attribute of a model.
      #
      # @param model [Object] The object to validate.
      # @param attribute [String|Symbol] The attribute to validate.
      # @param values [Array] The values of the attribute.
      def validate_each(model, attribute, values)
        values = Serializers::JSON.load(values, false, values)

        values.ensure_array.each do |value|
          checked = @class_name.classify.constantize.find_with_any(value)
          add_failure(attribute, model, value) unless checked
        end
      end

      private

      # :nodoc:
      def add_failure(attribute, record, value)
        message = options[:message] || options[:default_message]
        destination = options[:additional] ? record.additional_errors : record.errors
        destination[attribute] << sprintf(message, value)
      end
    end

    # Validates UUIDs (version 4).
    class UuidValidator < BaseValidator
      # The pattern to recognized a valid UUID version 4.
      VALID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

      # Creates a new validator.
      #
      # @param options [Hash] The options for the validations.
      # @return [Apes::Validators::UuidValidator] A new validator.
      def initialize(options)
        super(options.reverse_merge(default_message: "must be a valid UUID"))
      end

      # Checks if the value is valid for this validator.
      #
      # @param value [Object] The value to validate.
      # @return [Boolean] `true` if the value is valid, false otherwise.
      def check_valid?(value)
        value.blank? || value =~ VALID_REGEX
      end
    end

    # Validates email.
    class EmailValidator < BaseValidator
      # Creates a new validator.
      #
      # @param options [Hash] The options for the validations.
      # @return [Apes::Validators::EmailValidator] A new validator.
      def initialize(options)
        super(options.reverse_merge(default_message: "must be a valid email"))
      end

      # Checks if the value is valid for this validator.
      #
      # @param value [Object] The value to validate.
      # @return [Boolean] `true` if the value is valid, false otherwise.
      def check_valid?(value)
        value.blank? || UrlsParser.instance.email?(value.ensure_string)
      end
    end

    # Validates boolean values.
    class BooleanValidator < BaseValidator
      # Parses a boolean value.
      #
      # @param value [Object] The value to parse.
      # @param raise_errors [Boolean] Whether to raise errors in case the value couldn't be parsed.
      # @return [Boolean|NilClass] A boolean value if parsing succeded, `nil` otherwise.
      def self.parse(value, raise_errors: false)
        raise(ArgumentError, "Invalid boolean value \"#{value}\".") if !value.nil? && !value.boolean? && raise_errors
        value.to_boolean
      end

      # Creates a new validator.
      #
      # @param options [Hash] The options for the validations.
      # @return [Apes::Validators::BooleanValidator] A new validator.
      def initialize(options)
        super(options.reverse_merge(default_message: "must be a valid truthy/falsey value"))
      end

      # Checks if the value is valid for this validator.
      #
      # @param value [Object] The value to validate.
      # @return [Boolean] `true` if the value is valid, false otherwise.
      def check_valid?(value)
        value.blank? || value.boolean?
      end
    end

    # Validates phones.
    class PhoneValidator < BaseValidator
      # The pattern to recognize valid phones.
      VALID_REGEX = /^(
        ((\+|00)\d)? # International prefix
        ([0-9\-\s\/\(\)]{7,}) # All the rest
      )$/mx

      # Creates a new validator.
      #
      # @param options [Hash] The options for the validations.
      # @return [Apes::Validators::PhoneValidator] A new validator.
      def initialize(options)
        super(options.reverse_merge(default_message: "must be a valid phone"))
      end

      # Checks if the value is valid for this validator.
      #
      # @param value [Object] The value to validate.
      # @return [Boolean] `true` if the value is valid, false otherwise.
      def check_valid?(value)
        value.blank? || value =~ VALID_REGEX
      end
    end

    # Validates ZIP codes.
    class ZipCodeValidator < BaseValidator
      # The pattern to recognized valid ZIP codes.
      VALID_REGEX = /^(\d{5}(-\d{1,4})?)$/

      # Creates a new validator.
      #
      # @param options [Hash] The options for the validations.
      # @return [Apes::Validators::ZipCodeValidator] A new validator.
      def initialize(options)
        super(options.reverse_merge(default_message: "must be a valid ZIP code"))
      end

      # Checks if the value is valid for this validator.
      #
      # @param value [Object] The value to validate.
      # @return [Boolean] `true` if the value is valid, false otherwise.
      def check_valid?(value)
        value.blank? || value =~ VALID_REGEX
      end
    end

    # Validates timestamps.
    class TimestampValidator < BaseValidator
      # Parses a timestamp value according to a list of formats.
      #
      # @param value [Object] The value to parse.
      # @param formats [Array|NilClass] A list of valid formats (see strftime). Will fallback to formats defined in Rails configuration.
      # @param raise_errors [Boolean] Whether to raise errors in case the value couldn't be parsed with any format.
      # @return [DateTime|NilClass] A `DateTime` if parsing succeded, `nil` otherwise.
      def self.parse(value, formats: nil, raise_errors: false)
        return value if [ActiveSupport::TimeWithZone, DateTime, Date, Time].include?(value.class)

        formats ||= Apes::RuntimeConfiguration.timestamp_formats.values.dup

        rv = catch(:valid) do
          formats.each do |format|
            parsed = safe_parse(value, format)

            throw(:valid, parsed) if parsed
          end

          nil
        end

        raise(ArgumentError, "Invalid timestamp \"#{value}\".") if !rv && raise_errors
        rv
      end

      # Parses a timestamp without raising exceptions.
      #
      # @param value [String] The value to parse.
      # @return [DateTime|NilClass] A `DateTime` if parsing succeded, `nil` otherwise.
      def self.safe_parse(value, format)
        DateTime.strptime(value, format)
      rescue
        nil
      end

      # Creates a new validator.
      #
      # @param options [Hash] The options for the validations.
      # @return [Apes::Validators::TimestampValidator] A new validator.
      def initialize(options)
        super(options.reverse_merge(default_message: "must be a valid ISO 8601 timestamp"))
      end

      # Checks if the value is valid for this validator.
      #
      # @param value [Object] The value to validate.
      # @return [Boolean] `true` if the value is valid, false otherwise.
      def check_valid?(value)
        value.blank? || TimestampValidator.parse(value, formats: options[:formats])
      end
    end
  end
end
