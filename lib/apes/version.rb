#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

# A tiny JSON API framework for Ruby on Rails.
module Apes
  # The current version of apes, according to semantic versioning.
  #
  # @see http://semver.org
  module Version
    # The major version.
    MAJOR = 1

    # The minor version.
    MINOR = 0

    # The patch version.
    PATCH = 1

    # The current version of apes.
    STRING = [MAJOR, MINOR, PATCH].compact.join(".")
  end
end
