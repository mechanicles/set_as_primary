# frozen_string_literal: true

require_relative "test_helper"

class TestSqlite < ActiveSupport::TestCase
  # include GemSetupTest
  include SimpleAssocationTests
  include PolymorphicAssociationTests
  # include ExcpetionsTest
  # include SearchTest
  # include JoinTest

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
