# frozen_string_literal: true

require "set_as_primary/version"
require "active_support/concern"

module SetAsPrimary
  # class Error < StandardError; end
  extend ActiveSupport::Concern

  included do
    instance_eval do
      class_attribute :sap_primary_flag_attribute
      class_attribute :sap_owner_key
      class_attribute :sap_polymorphic_key

      before_save :unset_old_primary
      before_save :set_primary

      def set_as_primary(arg, owner_key: nil, polymorphic_key: nil)
        # TODO Arg should be present in DB as well.
        raise "Wrong Attribute" unless arg.is_a? Symbol

        if owner_key.present? && polymorphic_key.present?
          raise "Either provide `owner_key` or `polymorphic_key`!"
        end

        self.sap_primary_flag_attribute = arg
        self.sap_owner_key              = owner_key
        self.sap_polymorphic_key        = polymorphic_key
      end
    end
  end

  private
    def unset_old_primary
      klass = self.class

      return unless self.public_send(klass.sap_primary_flag_attribute)
      options = {}

      if klass.sap_owner_key.present?
        owner_id = self.public_send(klass.sap_owner_key)
        options[klass.sap_owner_key] = owner_id
      else
        owner = self.public_send(klass.sap_polymorphic_key)
        owner_id = "#{klass.sap_polymorphic_key}_id"
        owner_type = "#{ownerklass.sap_polymorphic_key}_type"

        options[owner_id] = owner.id
        options[owner_type] = owner_type
      end


      scope = self.class.where(options)

      unless new_record?
        scope = scope.where("id != ?", id)
      end

      # TODO: Change hardcoded primary attribute.
      scope.update_all(primary: false, updated_at: Time.current)
    end

    def set_primary
      klass = self.class

      options = {}
      if klass.sap_owner_key.present?
        owner_id = self.public_send(klass.sap_owner_key)
        options[klass.sap_owner_key] = owner_id
      else
        owner = self.public_send(klass.sap_polymorphic_key)
        owner_id = "#{klass.sap_polymorphic_key}_id"
        owner_type = "#{klass.sap_polymorphic_key}_type"

        options[owner_id] = owner.id
        options[owner_type] = owner_type
      end

      count = self.class.where(options).count

      if (count == 1 && !new_record?) || (count == 0 && new_record?)
        self.public_send("#{klass.sap_primary_flag_attribute}=", true)
      end
    end
end
