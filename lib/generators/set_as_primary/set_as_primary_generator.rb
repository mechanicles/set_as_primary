# frozen_string_literal: true

require "rails/generators/active_record"

module SetAsPrimary
  module Generators
    class SetAsPrimaryGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)
      argument :table_name, type: :string

      desc "Adds a boolean column 'primary' to the given table."

      def copy_migration
        migration_template "migration.rb", "db/migrate/add_primary_column_to_#{table_name}.rb",
          migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end
    end
  end
end
