# frozen_string_literal: true

require "set_as_primary/version"
require "active_support/concern"

module SetAsPrimary
  class Error < StandardError; end

  extend ActiveSupport::Concern

  included do
    instance_eval do
      class_attribute :_primary_flag_attribute, :_owner_key, :_polymorphic_key

      def set_as_primary(primary_flag_attribute = :primary, options = {})
        configuration = { owner_key: nil, polymorphic_key: nil }
        configuration.update(options) if options.is_a?(Hash)

        handle_setup_errors(primary_flag_attribute, configuration)

        self._primary_flag_attribute = primary_flag_attribute
        self._owner_key              = configuration[:owner_key]
        self._polymorphic_key        = configuration[:polymorphic_key]
      end

      before_save :unset_old_primary
      before_save :set_primary

      private
        def handle_setup_errors(primary_flag_attribute, configuration)
          if !primary_flag_attribute.is_a?(Symbol)
            raise SetAsPrimary::Error, "Wrong attribute! Please provide attribute in symbol type"
          end

          if configuration.values.all?(&:present?)
            raise SetAsPrimary::Error, "Either provide `#{configuration.keys.first}` or `#{configuration.keys.last}` option"
          end
        end
    end
  end

  private
    def unset_old_primary
      klass   = self.class

      return unless self.public_send(klass._primary_flag_attribute)

      options = {}

      if klass._owner_key.present?
        owner_id = self.public_send(klass._owner_key)
        options[klass._owner_key] = owner_id
      else
        options = polymorphic_condition_options
      end

      scope = self.class.where(options)

      unless new_record?
        scope = scope.where("id != ?", id)
      end

      # TODO: Change hardcoded primary attribute.
      options = {}
      options[klass._primary_flag_attribute] = false
      options[:updated_at] = Time.current
      scope.update_all(options)
    end

    def set_primary
      klass   = self.class
      options = {}

      if klass._owner_key.present?
        owner_id = self.public_send(klass._owner_key)
        options[klass._owner_key] = owner_id
      else
        options = polymorphic_condition_options
      end

      count = self.class.where(options).count

      if (count == 1 && !new_record?) || (count == 0 && new_record?)
        self.public_send("#{klass._primary_flag_attribute}=", true)
      end
    end

    def polymorphic_condition_options
      raise_association_not_found_error

      owner = self.public_send(self.class._polymorphic_key)
      owner_id = "#{self.class._polymorphic_key}_id".to_sym
      owner_type = "#{self.class._polymorphic_key}_type".to_sym

      options = {}
      options[owner_id] = owner.id
      options[owner_type] = owner.class.name

      options
    end

    def raise_association_not_found_error
      unless self.class._reflect_on_association(self.class._polymorphic_key)
        raise ActiveRecord::AssociationNotFoundError.new(self, self.class._polymorphic_key)
      end
    end
end
