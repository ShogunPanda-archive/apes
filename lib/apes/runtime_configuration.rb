#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Apes
  # Internal class to handle runtime configuration.
  class RuntimeConfiguration
    # Returns the JWT token used by Apes. This should be defined in the Rails secrets.yml file.
    #
    # @param default [String] The fallback if no valid secret is found in Rails.
    # @return [String] The JWT token used by Apes.
    def self.jwt_token(default = "secret")
      Rails.application.secrets.jwt
    rescue
      default
    end

    # Returns a map where keys are tags and values are strftime compliant formats.
    #
    # @param default [String] The fallback if no valid configuration is found in Rails.
    # @return [Object] A object describing valid timestamps formats.
    def self.timestamp_formats(default = {})
      Rails.application.config.timestamp_formats
    rescue
      default
    end

    # Returns the current Rails root directory.
    #
    # @param default [String] The fallback if Rails configuration is invalid.
    # @return [Object] The current Rails root directory.
    def self.rails_root(default = nil)
      Rails.root
    rescue
      default
    end

    # Returns the current RubyGems root directory.
    #
    # @param default [String] The fallback if RubyGems configuration is invalid.
    # @return [Object] The current RubyGems root directory.
    def self.gems_root(default = nil)
      Pathname.new(Gem.loaded_specs["lazier"].full_gem_path).parent.to_s
    rescue
      default
    end
  end
end
