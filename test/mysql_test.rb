# frozen_string_literal: true

require "test_helper"
require "active_record/connection_adapters/mysql2_adapter"

class MysqlTest < ActiveSupport::TestCase
  include GemSetupTest
  include SimpleAssocationTests
  include PolymorphicAssociationTests
  include ExceptionsTests

  def setup
    super
    @@setup ||= begin
                  ActiveRecord::Base.establish_connection adapter: "mysql2", database: "set_as_primary_test", username: "root"
                  create_tables
                end

    create_dummy_data
    true
  end

  def teardown
    drop_dummy_data
  end
end
