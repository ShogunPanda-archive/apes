#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Apes
  # A cursor that can be sent to the client, received unmodified and retrieved later to paginate results.
  #
  # @attribute value
  #   @return [String] The value obtain from previous pagination. It can either be the value of the first or last element in previous iteration.
  # @attribute use_offset
  #   @return [Boolean] Whether to use offset based pagination rather than collection fields values.
  # @attribute direction
  #   @return [IO|String] Which page to get in this iteration.
  # @attribute size
  #   @return [IO|String] The size of the pagination page.
  class PaginationCursor
    # The default size of a pagination page.
    DEFAULT_SIZE = 25

    # Format to serialize timestamp when using them for pagination.
    TIMESTAMP_FORMAT = "%FT%T.%6N%z".freeze

    attr_accessor :value, :use_offset, :direction, :size

    # Creates a new cursor.
    #
    # @param params [Hash] The request parameters.
    # @param field [Symbol] The parameters field where to lookup for the serialized cursor.
    # @param count_field [Symbol] The parameters field where to lookup for the overriding cursor size.
    # @return [Apes::PaginationCursor] A new cursor instance.
    def initialize(params = {}, field = :page, count_field = :count)
      begin
        payload = JWT.decode(params[field], jwt_secret, true, {algorithm: "HS256", verify_aud: true, aud: "pagination"}).dig(0, "sub")

        extract_payload(payload)
      rescue
        default_payload
      end

      # Sanitization
      sanitize(count_field, params)
    end

    # Get the operator (`>` or `<`) for the query according to the direction and the provided ordering.
    #
    # @param order [Symbol] The order to use.
    # @return [String] The operator to use for the query.
    def operator(order)
      if direction == "next"
        order == :asc ? ">" : "<" # Descending order means newer results first
      else
        order == :asc ? "<" : ">" # Descending order means newer results first
      end
    end

    # Verifies whether a specific page might exist for the given collection.
    #
    # @param page [String] The page to check. It can be `first`, `next`, `prev` or `previous`.
    # @param collection [Enumerable] The collection to analyze.
    # @return [Boolean] Returns `true` if the page might exist for the collection, `false` otherwise.
    def might_exist?(page, collection)
      case page.to_s
      when "first" then true
      when "next" then collection.present?
      else value.present? && collection.present? # Previous
      end
    end

    # Serializes the cursor to send it to the client.
    #
    # @param collection [Enumerable] The collection to analyze.
    # @param page [String] The page to return. It can be `first`, `next`, `prev` or `previous`.
    # @param field [Symbol] When not using offset based pagination, the field to consider for generation.
    # @param size [Fixnum] The number of results to advance when using offset based pagination.
    # @param use_offset [Boolean] Whether to use offset based pagination.
    # @return [String] The serialized cursor.
    def save(collection, page, field: :id, size: nil, use_offset: nil)
      size ||= self.size
      use_offset = self.use_offset if use_offset.nil?
      direction, value = use_offset ? update_with_offset(page, size) : update_with_field(page, collection, field)

      value = value.strftime(TIMESTAMP_FORMAT) if value.respond_to?(:strftime)

      JWT.encode({aud: "pagination", sub: {value: value, use_offset: use_offset, direction: direction, size: size}}, jwt_secret, "HS256")
    end
    alias_method :serialize, :save

    private

    # :nodoc:
    def default_payload
      @value = nil
      @direction = "next"
      @size = 0
      @use_offset = false
    end

    # :nodoc:
    def extract_payload(payload)
      @value = payload["value"]
      @direction = payload["direction"]
      @size = payload["size"]
      @use_offset = payload["use_offset"]
    end

    # :nodoc:
    def sanitize(count_field, params)
      @direction = "next" unless ["prev", "previous"].include?(@direction)
      @size = params[count_field].to_integer if params[count_field].present?
      @size = DEFAULT_SIZE if @size < 1
    end

    # :nodoc:
    def update_with_field(type, collection, field)
      case type.ensure_string
      when "next"
        direction = "next"
        value = collection.last&.send(field)
      when "prev", "previous"
        direction = "previous"
        value = collection.first&.send(field)
      else # first
        direction = "next"
        value = nil
      end

      [direction, value]
    end

    # :nodoc:
    def update_with_offset(type, size)
      case type.ensure_string
      when "next"
        direction = "next"
        value = self.value + size
      when "prev", "previous"
        direction = "previous"
        value = [0, self.value - size].max
      else # first
        direction = "next"
        value = nil
      end

      [direction, value]
    end

    def jwt_secret
      Apes::RuntimeConfiguration.jwt_token
    end
  end
end
