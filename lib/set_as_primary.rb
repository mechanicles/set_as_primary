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

      before_save :unset_old_primary
      before_save :set_primary

      def set_as_primary(arg, owner_key)
        # TODO Arg should be present in DB as well.
        raise "Wrong Attribute" unless arg.is_a? Symbol

        self.sap_primary_flag_attribute = arg
        self.sap_owner_key = owner_key
      end
    end
  end

  private
    def unset_old_primary
      klass = self.class

      return unless self.public_send(klass.sap_primary_flag_attribute)
      owner_id = self.public_send(klass.sap_owner_key)

      options = {}
      options[klass.sap_owner_key] = owner_id

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
      options[klass.sap_owner_key] = self.public_send(klass.sap_owner_key)

      count = self.class.where(options).count

      if (count == 1 && !new_record?) || (count == 0 && new_record?)
        self.public_send("#{klass.sap_primary_flag_attribute}=", true)
      end
    end
end
