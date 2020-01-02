# frozen_string_literal: true

require "set_as_primary/version"
require "active_support/concern"

module SetAsPrimary
  class Error < StandardError; end

  extend ActiveSupport::Concern

  included do
    before_save :unset_old_primary
    before_save :force_primary, if: -> { _klass._force_primary }

    instance_eval do
      class_attribute :_primary_flag_attribute, :_owner_key, :_force_primary

      def set_as_primary(primary_flag_attribute = :primary, options = {})
        if primary_flag_attribute.is_a?(Hash)
          options = primary_flag_attribute; primary_flag_attribute = :primary
        end

        configuration = { owner_key: nil, force_primary: true }

        configuration.update(options) if options.is_a?(Hash)

        _handle_setup_errors(primary_flag_attribute, configuration)

        self._primary_flag_attribute = primary_flag_attribute
        self._owner_key = configuration[:owner_key]
        self._force_primary = configuration[:force_primary]
      end

      private
        def _handle_setup_errors(primary_flag_attribute, configuration)
          if !primary_flag_attribute.is_a?(Symbol)
            raise SetAsPrimary::Error, "wrong argument type (expected Symbol)"
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
      return unless public_send(_klass._primary_flag_attribute)

      scope = _klass.where(_scope_options) if _scope_options.present?

      scope = scope.where("id != ?", id) unless new_record?

      scope.update_all(_klass._primary_flag_attribute => false)
    end

    def force_primary
      count = _klass.where(_scope_options).count

      if (count == 1 && !new_record?) || (count == 0 && new_record?)
        public_send("#{_klass._primary_flag_attribute}=", true)
      end
    end

    def _scope_options
      return nil if _klass._owner_key.nil?

      @_scope_options ||= if _klass.reflect_on_association(_klass._owner_key).options[:polymorphic]
        _polymorphic_condition_options
      else
        owner_id = "#{_klass._owner_key}_id".to_sym
        { owner_id => public_send(owner_id) }
      end
    end

    def _polymorphic_condition_options
      owner = self.public_send(self.class._owner_key)

      {
        "#{_klass._owner_key}_id".to_sym =>  owner.id,
        "#{_klass._owner_key}_type".to_sym => owner.class.name
      }
    end

    def _klass
      self.class
    end
end
