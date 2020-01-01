# frozen_string_literal: true

require "rails/generators/active_record"

module SetAsPrimary
  module Generators
    class SetAsPrimaryGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("templates", __dir__)

      desc "Adds a user defined boolean column to the given table."

      argument :table_name, type: :string
      argument :flag_name, type: :string 
      argument :owner_key, type: :string, default: ''

      def copy_migration
        migration_template "migration.rb", "db/migrate/add_primary_column_to_#{table_name}.rb",
          migration_version: migration_version,
          index_on: index_on
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      def index_on
        if owner_key.present?
          klass = table_name.classify.constantize
          owner_association = klass.reflect_on_association(owner_key.to_sym)

          if owner_association.nil?
            raise ActiveRecord::AssociationNotFoundError.new(klass, owner_key)
          end
          
          owner_id_key = "#{owner_key}_id"
          
          if owner_association.options[:polymorphic]
            owner_type_key = "#{owner_key}_type"
            "%i[#{owner_id_key}, #{owner_type_key}, #{flag_name}]"
          else
            "%i[#{owner_id_key}, #{flag_name}]"
          end
        else
          ":#{flag_name}"
        end
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end
    end
  end
end
