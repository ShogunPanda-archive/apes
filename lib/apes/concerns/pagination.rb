#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Apes
  module Concerns
    # Pagination handling module.
    module Pagination
      # Paginates a collection according to the current cursor.
      #
      # @param collection [ActiveRecord::Relation] The collection to paginate.
      # @param sort_field [Symbol] The field to use for pagination.
      # @param sort_order [Symbol] The order to use for pagination.
      # @return [ActiveRecord::Relation] The paginated collection.
      def paginate(collection, sort_field: :id, sort_order: :desc)
        direction = @cursor.direction
        value = @cursor.value

        # Apply the query
        collection = apply_value(collection, value, sort_field, sort_order)
        collection = collection.limit(@cursor.size).order(sprintf("%s %s", sort_field, sort_order.upcase))

        # If we're fetching previous we reverse the order to make sure we fetch the results adiacents to the previous request,
        # then we reverse results to ensure the order requested
        if direction != "next"
          collection = collection.reverse_order
          collection = collection.reverse
        end

        collection
      end

      # The field to use for pagination.
      #
      # @return [Symbol] The field to use for pagination.
      def pagination_field
        @pagination_field ||= :handle
      end

      # Whether to skip pagination. This is used by template generation.
      #
      # @return [Boolean] `true` if pagination must be skipped in template, `false` otherwise.
      def pagination_skip?
        @skip_pagination
      end

      # Checks if current collection supports pagination. This is used by template generation.
      #
      # @return [Boolean] `true` if pagination is supported, `false` otherwise.
      def pagination_supported?
        @objects.respond_to?(:first) && @objects.respond_to?(:last)
      end

      # Returns the URL a specific page of the current collection.
      #
      # @param page [Symbol] The page to return.
      # @return [String] The URL for a page of the current collection.
      def pagination_url(page = nil)
        exist = @cursor.might_exist?(page, @objects)
        exist ? url_for(request.params.merge(page: @cursor.save(@objects, page, field: pagination_field)).merge(only_path: false)) : nil
      end

      private

      # :nodoc:
      def apply_value(collection, value, sort_field, sort_order)
        if value
          if cursor.use_offset
            collection = collection.offset(value)
          else
            value = DateTime.parse(value, PaginationCursor::TIMESTAMP_FORMAT) if collection.columns_hash[sort_field.to_s].type == :datetime
            collection = collection.where(sprintf("%s %s ?", sort_field, @cursor.operator(sort_order)), value)
          end
        end

        collection
      end
    end
  end
end
