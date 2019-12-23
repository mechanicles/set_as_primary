# frozen_string_literal: true

require "set_as_primary/version"
require "active_support/concern"

module SetAsPrimary
  class Error < StandardError; end

  extend ActiveSupport::Concern

  included do
    before_save :unset_old_primary
    before_save :force_primary, if: -> { self.class._force_primary }

    instance_eval do
      class_attribute :_primary_flag_attribute, :_owner_key,
                      :_polymorphic_key, :_force_primary

      def set_as_primary(primary_flag_attribute = :primary, options)
        configuration = { owner_key: nil, polymorphic_key: nil, force_primary: true }

        configuration.update(options) if options.is_a?(Hash)

        handle_setup_errors(primary_flag_attribute, configuration)

        self._primary_flag_attribute = primary_flag_attribute
        self._owner_key = configuration[:owner_key]
        self._polymorphic_key = configuration[:polymorphic_key]
        self._force_primary = configuration[:force_primary]
      end

      private
        def handle_setup_errors(primary_flag_attribute, configuration)
          if !primary_flag_attribute.is_a?(Symbol)
            raise SetAsPrimary::Error, "Wrong attribute! Please provide attribute in symbol type."
          end

          owner_key = configuration[:owner_key]
          polymorphic_key = configuration[:polymorphic_key]

          if (owner_key.present? && polymorphic_key.present?) || (owner_key.nil? && polymorphic_key.nil?)
            raise SetAsPrimary::Error, "Either provide `owner_key` or `polymorphic_key` option."
          end
        end
    end
  end

  private
    def unset_old_primary
      return unless self.public_send(self.class._primary_flag_attribute)

      scope = self.class.where(scope_options)

      scope = scope.where("id != ?", id) unless new_record?

      options = {}
      options[self.class._primary_flag_attribute] = false
      options[:updated_at] = Time.current
      scope.update_all(options)
    end

    def force_primary
      count = self.class.where(scope_options).count

      if (count == 1 && !new_record?) || (count == 0 && new_record?)
        self.public_send("#{self.class._primary_flag_attribute}=", true)
      end
    end

    def scope_options
      options = {}

      if self.class._owner_key.present?
        options[self.class._owner_key] = self.public_send(self.class._owner_key)
      else
        options = polymorphic_condition_options
      end

      options
    end

    def polymorphic_condition_options
      raise_association_not_found_error

      owner = self.public_send(self.class._polymorphic_key)
      owner_key = "#{self.class._polymorphic_key}_id".to_sym
      owner_type = "#{self.class._polymorphic_key}_type".to_sym

      options = {}
      options[owner_key] = owner.id
      options[owner_type] = owner.class.name

      options
    end

    def raise_association_not_found_error
      unless self.class._reflect_on_association(self.class._polymorphic_key)
        raise ActiveRecord::AssociationNotFoundError.new(self, self.class._polymorphic_key)
      end
    end
end
