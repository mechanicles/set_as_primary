# frozen_string_literal: true

require_relative "test_helper"

class PostgresqlTest < ActiveSupport::TestCase
  include GemSetupTest
  include SingleModelWithNoAssociationTests
  include SimpleAssocationTests
  include PolymorphicAssociationTests
  include ExceptionsTests

  print_test_adapter_info 'postgresql'

  def setup
    super
    @@setup ||= begin
                  ActiveRecord::Base.establish_connection adapter: "postgresql", database: "set_as_primary_test"
                  create_tables
                end

    create_dummy_data
    true
  end

  def teardown
    drop_dummy_data
  end
end
