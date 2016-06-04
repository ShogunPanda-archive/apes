#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "lazier"
require "mustache"
require "jwt"
require "jbuilder"
require "active_model"
require "rails"
require "rails-api/action_controller/api"

require "apes/version" unless defined?(Apes::Version)
require "apes/runtime_configuration"

require "apes/errors"
require "apes/urls_parser"
require "apes/pagination_cursor"

require "apes/serializers"
require "apes/validators"
require "apes/model"

require "apes/concerns/errors"
require "apes/concerns/pagination"
require "apes/concerns/request"
require "apes/concerns/response"
require "apes/controller"

Lazier.load!(:object, :string)

ActiveSupport.on_load(:action_controller) do
  prepend_view_path(Apes::RuntimeConfiguration.root + "/views") if respond_to?(:prepend_view_path)
end

ActiveSupport.on_load(:action_view) do
  include Apes::Concerns::Response
  include Apes::Concerns::Pagination
end
