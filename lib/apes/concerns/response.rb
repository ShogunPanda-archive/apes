#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Apes
  module Concerns
    # JSON API response handling module.
    module Response
      attr_accessor :included

      # Returns the template to use to render a object.
      #
      # @param object [Object] The object to render.
      # @return [String] The template to use.
      def response_template_for(object)
        return @object_template if @object_template
        object = object.first if object.respond_to?(:first)
        object.class.name.underscore.gsub("/", "_")
      end

      # Returns the metadata for the current response.
      #
      # @param default [Object] Fallback data if nothing is found.
      # @return [HashWithIndifferentAccess|Object|Nil] The metadata for the current response.
      def response_meta(default = nil)
        @meta || default || HashWithIndifferentAccess.new
      end

      # Returns the data for the current response.
      #
      # @param default [Object] Fallback data if nothing is found.
      # @return [HashWithIndifferentAccess|Object|Nil] The data for the current response.
      def response_data(default = nil)
        @data || default || HashWithIndifferentAccess.new
      end

      # Returns the linked objects for the current response.
      #
      # @param default [Object] Fallback data if nothing is found.
      # @return [HashWithIndifferentAccess|Object|Nil] The linked objects for the current response.
      def response_links(default = nil)
        @links || default || HashWithIndifferentAccess.new
      end

      # Returns the included (side-loaded) objects for the current response.
      #
      # @param default [Object] Fallback data if nothing is found.
      # @return [HashWithIndifferentAccess|Object|Nil] The included objects for the current response.
      def response_included(default = nil)
        controller.included || default || HashWithIndifferentAccess.new
      end

      # Adds an object to the included (side-load) set.
      #
      # @param object [Object] The object to include.
      # @param template [String] The template to use for rendering.
      # @return [HashWithIndifferentAccess] A hash of objects to include. Keys are a template:id formatted strings, values are `[object, template]` pairs.
      def response_include(object, template = nil)
        controller.included ||= HashWithIndifferentAccess.new
        controller.included[sprintf("%s:%s", response_template_for(object), object.to_param)] = [object, template]
        controller.included
      end

      # Serializes a timestamp.
      #
      # @param timestamp [DateTime] The timestamp to serialize.
      # @return [String] The serialized timestamp.
      def response_timestamp(timestamp)
        timestamp.safe_send(:strftime, "%FT%T.%L%z")
      end
    end
  end
end
