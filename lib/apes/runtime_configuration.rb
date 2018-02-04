#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Apes
  # Internal class to handle runtime configuration.
  class RuntimeConfiguration
    class << self
      # Returns the root directory of apes.
      # @return [String]
      def root
        Pathname.new(Gem.loaded_specs["apes"].full_gem_path).to_s
      end

      # Returns the current Rails root directory.
      #
      # @param default [String] The fallback if Rails configuration is invalid.
      # @return [String] The current Rails root directory.
      def rails_root(default = nil)
        fetch_with_fallback(default) { Rails.root.to_s }
      end

      # Returns the current RubyGems root directory.
      #
      # @param default [String] The fallback if RubyGems configuration is invalid.
      # @return [String] The current RubyGems root directory.
      def gems_root(default = nil)
        fetch_with_fallback(default) { Pathname.new(Gem.loaded_specs["lazier"].full_gem_path).parent.to_s }
      end

      # Returns the current Rails environment.
      #
      # @param default [String] The fallback environment if Rails configuration is invalid.
      # @return [String] The the current Rails environment.
      def environment(default = "development")
        fetch_with_fallback(default) { Rails.env }
      end

      # Check if Rails is in development environment.
      #
      # @return [Boolean] `true` if Rails is in `development` environment, `false` otherwise.
      def development?
        environment == "development"
      end

      # Returns the JWT token used by Apes. This should be defined in the Rails secrets.yml file.
      #
      # @param default [String] The fallback if no valid secret is found in Rails secrets file.
      # @return [String] The JWT token used by Apes.
      def jwt_token(default = "secret")
        fetch_with_fallback(default) { Rails.application.secrets.jwt }
      end

      # Returns the CORS source used by Apes. This should be defined in the Rails secrets.yml file.
      #
      # @param default [String] The fallback if no valid CORS source is found in Rails secrets file.
      # @return [String] The CORS source used by Apes.
      def cors_source(default = "http://localhost")
        fetch_with_fallback(default) { Rails.application.secrets.cors_source }
      end

      # Returns a map where keys are tags and values are strftime compliant formats.
      #
      # @param default [String] The fallback if no valid configuration is found in Rails.
      # @return [Hash] A object describing valid timestamps formats.
      def timestamp_formats(default = {})
        fetch_with_fallback(default) { Rails.application.config.timestamp_formats }
      end

      private

      def fetch_with_fallback(default)
        yield
      rescue
        default
      end
    end
  end
end
