# frozen_string_literal: true

require_relative "test_helper"

class SqliteTest < ActiveSupport::TestCase
  include GemSetupTest
  include SingleModelWithNoAssociationTests
  include SimpleAssocationTests
  include PolymorphicAssociationTests
  include ExceptionsTests

  print_test_adapter_info 'sqlite'

  def setup
    super
    @@setup ||= begin
                  ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
                  create_tables
                end

    create_dummy_data
    true
  end

  def teardown
    drop_dummy_data
  end
end
