# frozen_string_literal: true

require "rails/generators/active_record"

module SetAsPrimary
  module Generators
    class SetAsPrimaryGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Adds a boolean column 'primary' to the given table."

      def copy_migration
        migration_template "migration.rb", "db/migrate/add_primary_column_to_#{plural_name.downcase}",
          migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
