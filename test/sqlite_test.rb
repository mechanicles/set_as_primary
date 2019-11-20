# frozen_string_literal: true

require_relative "test_helper"

class TestSqlite < Minitest::Test
  # include GemSetupTest
  include MainGemTest
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
