# frozen_string_literal: true

require "set_as_primary/version"
require "active_support/concern"

module SetAsPrimary
  class Error < StandardError; end
  extend ActiveSupport::Concern

  included do
    instance_eval do
      class_attribute :sap_primary_flag_attribute
      class_attribute :sap_owner_key
      class_attribute :sap_polymorphic_key

      before_save :unset_old_primary
      before_save :set_primary

      def set_as_primary(primary_flag_attribute = :primary, options = {})
        configuration = { owner_key: nil, polymorphic_key: nil }
        configuration.update(options) if options.is_a?(Hash)

        handle_setup_errors(primary_flag_attribute, configuration)

        self.sap_primary_flag_attribute = primary_flag_attribute
        self.sap_owner_key              = configuration[:owner_key]
        self.sap_polymorphic_key        = configuration[:polymorphic_key]
      end

      private
        def handle_setup_errors(primary_flag_attribute, configuration)
          if !primary_flag_attribute.is_a?(Symbol)
            raise SetAsPrimary::Error, "Wrong attribute for primary flag attribute"
          end

          if configuration.values.all?(&:present?)
            raise SetAsPrimary::Error, "Either provide `#{configuration.keys.first}` or `#{configuration.keys.last}`!"
          end
        end
    end
  end

  private
    def unset_old_primary
      klass   = self.class

      return unless self.public_send(klass.sap_primary_flag_attribute)

      options = {}

      if klass.sap_owner_key.present?
        owner_id = self.public_send(klass.sap_owner_key)
        options[klass.sap_owner_key] = owner_id
      else
        options = polymorphic_condition_options
      end

      scope = self.class.where(options)

      unless new_record?
        scope = scope.where("id != ?", id)
      end

      # TODO: Change hardcoded primary attribute.
      options = {}
      options[klass.sap_primary_flag_attribute] = false
      options[:updated_at] = Time.current
      scope.update_all(options)
    end

    def set_primary
      klass   = self.class
      options = {}

      if klass.sap_owner_key.present?
        owner_id = self.public_send(klass.sap_owner_key)
        options[klass.sap_owner_key] = owner_id
      else
        options = polymorphic_condition_options
      end

      count = self.class.where(options).count

      if (count == 1 && !new_record?) || (count == 0 && new_record?)
        self.public_send("#{klass.sap_primary_flag_attribute}=", true)
      end
    end

    def polymorphic_condition_options
      raise_association_not_found_error

      owner = self.public_send(self.class.sap_polymorphic_key)
      owner_id = "#{self.class.sap_polymorphic_key}_id".to_sym
      owner_type = "#{self.class.sap_polymorphic_key}_type".to_sym

      options = {}
      options[owner_id] = owner.id
      options[owner_type] = owner.class.name

      options
    end

    def raise_association_not_found_error
      unless self.class._reflect_on_association(self.class.sap_polymorphic_key)
        raise ActiveRecord::AssociationNotFoundError.new(self, self.class.sap_polymorphic_key)
      end
    end
end
