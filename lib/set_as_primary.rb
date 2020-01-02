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
      class_attribute :_primary_flag_attribute, :_owner_key, :_force_primary

      def set_as_primary(primary_flag_attribute = :primary, options = {})
        if primary_flag_attribute.is_a?(Hash)
          options = primary_flag_attribute
          primary_flag_attribute = :primary
        end

        configuration = { owner_key: nil, force_primary: true }

        configuration.update(options) if options.is_a?(Hash)

        handle_setup_errors(primary_flag_attribute, configuration)

        self._primary_flag_attribute = primary_flag_attribute
        self._owner_key = configuration[:owner_key]
        self._force_primary = configuration[:force_primary]
      end

      private
        def handle_setup_errors(primary_flag_attribute, configuration)
          if !primary_flag_attribute.is_a?(Symbol)
            raise SetAsPrimary::Error, "Wrong attribute! Please provide attribute in symbol type."
          end

          owner_key = configuration[:owner_key]

          if owner_key.present? && reflect_on_association(owner_key).nil?
            raise ActiveRecord::AssociationNotFoundError.new(self, owner_key)
          end
        end
    end
  end

  private
    def unset_old_primary
      return unless self.public_send(self.class._primary_flag_attribute)

      scope = self.class.where(scope_options) if scope_options.present?

      scope = scope.where("id != ?", id) unless new_record?

      scope.update_all(self.class._primary_flag_attribute => false)
    end

    def force_primary
      count = self.class.where(scope_options).count

      if (count == 1 && !new_record?) || (count == 0 && new_record?)
        self.public_send("#{self.class._primary_flag_attribute}=", true)
      end
    end

    def scope_options
      return nil if self.class._owner_key.nil?

      @scope_option ||= if self.class.reflect_on_association(self.class._owner_key).options[:polymorphic]
        polymorphic_condition_options
      else
        owner_id = "#{self.class._owner_key}_id".to_sym
        { owner_id => self.public_send(owner_id) }
      end
    end

    def polymorphic_condition_options
      owner = self.public_send(self.class._owner_key)

      {
        "#{self.class._owner_key}_id".to_sym =>  owner.id,
        "#{self.class._owner_key}_type".to_sym => owner.class.name
      }
    end
end
