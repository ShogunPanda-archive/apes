#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Apes
  # A ready to use controller for JSON API applications.
  #
  # @attribute [r] current_account
  #   @return [Object] The current account making the request
  # @attribute [r] cursor
  #   @return [Apes::PaginationCursor] The pagination cursor for this request.
  # @attribute [r] request_cursor
  #   @return [Apes::PaginationCursor] The original pagination cursor sent from the client.
  class Controller < ActionController::API
    include ActionController::ImplicitRender
    include ActionView::Layouts
    include Apes::Concerns::Request
    include Apes::Concerns::Response
    include Apes::Concerns::Pagination
    include Apes::Concerns::Errors

    layout "general"
    before_filter :request_handle_cors
    before_filter :request_validate

    attr_reader :current_account, :cursor, :request_cursor

    # Exception handling
    rescue_from Exception, with: :error_handle_exception
    # This allows to avoid to declare all the views
    rescue_from ActionView::MissingTemplate, with: :render_default_views

    # Returns the default URL options for this request.
    # It ensures that the host is always included and that is set properly in development mode.
    #
    # @return [Hash] Default URL options for the request.
    def default_url_options
      rv = {only_path: false}
      rv = {host: request_source_host} if Apes::RuntimeConfiguration.development?
      rv
    end

    # Tiny handle to handle CORS OPTIONS requests. It just renders nothing as headers are handle in Apes::Concerns::Response module.
    #
    # To enable this route, add the following to the routes.rb:
    #
    #     # This is to enable AJAX cross domain
    #     match '*path', to: 'application#handle_cors', via: :options
    def handle_cors
      render(nothing: true, status: :no_content)
    end

    # Default handler to render errors.
    #
    # @param status [Symbol|Fixnum] The HTTP error code to return.
    # @param errors [Array] The list of occurred errors.
    def render_error(status, errors)
      @errors = errors
      status_code = status.is_a?(Fixnum) ? status : Rack::Utils::SYMBOL_TO_STATUS_CODE.fetch(status.to_sym, 500)
      render("errors/#{status_code}", status: status)
    end

    private

    # :nodoc:
    def render_default_views(exception)
      if defined?(@objects)
        render "/collection"
      elsif defined?(@object)
        render "/object"
      else
        error_handle_exception(exception)
      end
    end
  end
end
