#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Apes
  # Some utility extensions to ActiveModel.
  module Model
    extend ActiveSupport::Concern

    class_methods do
      # Find a object by using the UUID, a handle or model specific definitions (defined using SECONDARY_KEY or SECONDARY_QUERY constants).
      # Raise exception when nothing is found.
      #
      # @param id [Object] The value to find.
      # @return [Object] The first found model.
      def find_with_any!(id)
        if id =~ Validators::UuidValidator::VALID_REGEX
          find(id)
        elsif defined?(self::SECONDARY_KEY)
          find_by!(self::SECONDARY_KEY => id)
        elsif defined?(self::SECONDARY_QUERY)
          find_by!(self::SECONDARY_QUERY, {id: id})
        else
          find_by!(handle: id)
        end
      end

      # Find a object by using the UUID, a handle or model specific definitions (defined using SECONDARY_KEY or SECONDARY_QUERY constants).
      #
      # @param id [Object] The value to find.
      # @return [Object] The first found model.
      def find_with_any(id)
        find_with_any!(id)
      rescue ActiveRecord::RecordNotFound
        nil
      end

      # Performs a search on the model.
      #
      # @param params [Hash] The list of params for the query.
      # @param query [ActiveRecord::Relation|NilClass] A model query to further scope, if any.
      # @param fields [Array] The model fields where to perform search on.
      # @param start_only [Boolean] Whether only match that starts with the searched value rather than just containing it.
      # @param parameter [Symbol|NilClass] The field in `params` which contains the value to search. Will fallback to `params[:filter][:query]` (using `.dig`).
      # @param placeholder [Symbol] The placeholder to use in prepared statement. Useful to avoid collisions. Default is `query`.
      # @param method [Symbol] The operator to use for searching. Everything different from `or` will fallback to `and`.
      # @param case_sensitive [Boolean] Whether to perform case sensitive search. Default is `false`.
      # @return [ActiveRecord::Relation] A query relation object.
      def search(params: {}, query: nil, fields: ["name"], start_only: false, parameter: nil, placeholder: :query, method: :or, case_sensitive: false)
        query ||= where({})
        value = parameter ? params[parameter] : params.dig(:filter, :query)
        return query if value.blank?

        value = "#{value}%"
        value = "%#{value}" unless start_only

        method = method.to_s == "or" ? " OR " : " AND "
        operator = case_sensitive ? "LIKE" : "ILIKE"

        sql = fields.map { |f| "#{f} #{operator} :#{placeholder}" }.join(method)
        query.where(sql, {placeholder => value})
      end
    end

    # A list of manually managed errors for the model.
    #
    # @return [ActiveModel::Errors] A list of manually managed errors for the model.
    def additional_errors
      @additional_errors ||= ActiveModel::Errors.new(self)
    end

    # Perform validations on the model and makes sure manually added errors are included.
    def run_validations!
      errors.messages.merge!(additional_errors.messages)
      super
    end

    # A list of automatically and manually added errors for the model.
    #
    # @return [ActiveModel::Errors] A list of automatically and manually added errors for the model.
    def all_validation_errors
      additional_errors.each do |field, error|
        errors.add(field, error)
      end

      errors.each do |field|
        errors[field].uniq!
      end

      errors
    end
  end
end
