#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Apes
  # A set of common serializers.
  module Serializers
    # Comma separated serialized value.
    class List
      # Loads serialized data.
      #
      # @param data [String] The serialized data.
      # @return [Array] A array of values.
      def self.load(data)
        return data if data.is_a?(Array)
        data.ensure_string.tokenize
      end

      # Serializes data.
      #
      # @param data [Object] The data to serialize.
      # @return [String] Serialized data.
      def self.dump(data)
        data.ensure_array.compact.map(&:to_s).join(",")
      end
    end

    # JSON encoded serialized value.
    class JSON
      # Saves serialized data.
      #
      # @param data [String] The serialized data.
      # @param raise_errors [Boolean] Whether to raise decoding errors.
      # @param default [Object] A fallback value to return when not raising errors.
      # @return [Object] A deserialized value.
      def self.load(data, raise_errors = false, default = {})
        data = ActiveSupport::JSON.decode(data)
        data = data.with_indifferent_access if data.is_a?(Hash)
        data
      rescue => e
        raise(e) if raise_errors
        default
      end

      # Saves serialized data.
      #
      # @param data [Object] The data to serialize.
      # @return [String] Serialized data.
      def self.dump(data)
        ActiveSupport::JSON.encode(data.as_json)
      end
    end

    # JWT encoded serialized value.
    class JWT
      class << self
        # Loads serialized data.
        #
        # @param serialized [String] The serialized data.
        # @param raise_errors [Boolean] Whether to raise decoding errors.
        # @param default [Object] A fallback value to return when not raising errors.
        # @return [Object] A deserialized value.
        def load(serialized, raise_errors = false, default = {})
          data = ::JWT.decode(serialized, jwt_secret, true, {algorithm: "HS256", verify_aud: true, aud: "data"}).dig(0, "sub")
          data = data.with_indifferent_access if data.is_a?(Hash)
          data
        rescue => e
          raise(e) if raise_errors
          default
        end

        # Saves serialized data.
        #
        # @param data [Object] The data to serialize.
        # @return [String] Serialized data.
        def dump(data)
          ::JWT.encode({aud: "data", sub: data.as_json}, jwt_secret, "HS256")
        end

        #:nodoc:
        def jwt_secret
          Apes::RuntimeConfiguration.jwt_token
        end
      end
    end
  end
end
