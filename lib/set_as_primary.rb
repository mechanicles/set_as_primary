require "set_as_primary/version"
require 'active_support/concern'

module SetAsPrimary
  class Error < StandardError; end

  included do
    instance_eval do
      before_save :unset_old_primary, if: :primary?
      before_save :set_primary, if: :owner_has_one_email_address?

      def primary_flag_attribute(arg, owner_id)
        # TODO Arg should be present in DB as well.
        raise "Wrong Attribute" unless arg.is_a? Symbol

        @sap_primary_flag_attribute = arg
        @sap_owner_id = owner_id
      end
    end
  end

  module ClassMethods
    private

    def unset_old_primary
      owner_id = self.public_send(@sap_owner_id)

      old_addresses = self.class.where(@sap_owner_id: owner_id, primary: true)

      unless new_record?
        old_addresses = old_addresses.where("id != ?", id)
      end

      old_addresses.update_all(primary: false, updated_at: Time.current)
    end

  end
end
