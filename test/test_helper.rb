# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "set_as_primary"

require "minitest/autorun"
require "minitest/pride"
require "logger"
require "active_record"
require "byebug"

Minitest::Test = Minitest::Unit::TestCase unless defined? (Minitest::Test)

# for debugging
ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT) if ENV["VERBOSE"]

class User < ActiveRecord::Base
  has_many :email_addresses
  has_many :phone_numbers
  has_many :addresses, as: :owner
end

class EmailAddress < ActiveRecord::Base
  include SetAsPrimary
  belongs_to :user

  set_as_primary :primary, owner_key: :user_id
end

class Address < ActiveRecord::Base
  include SetAsPrimary
  belongs_to :owner, polymorphic: true, touch: true

  set_as_primary :primary, polymorphic_key: :owner
end

def create_tables
  ActiveRecord::Migration.verbose = false

  ActiveRecord::Migration.create_table :users, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  ActiveRecord::Migration.create_table :email_addresses, force: true do |t|
    t.string :email, null: false
    t.boolean :primary, default: false, null: false
    t.references :user
    t.timestamps
  end

  ActiveRecord::Migration.create_table :addresses, force: true do |t|
    t.string :data, null: false
    t.boolean :primary, default: false, null: false
    t.integer :owner_id, null: false
    t.string :owner_type, null: false
    t.timestamps
  end
end

def create_dummy_data
  User.create! name: "alice"
end

def drop_dummy_data
  User.delete_all
  EmailAddress.delete_all
  Address.delete_all
end

module GemSetupTest
  def test_no_exception_is_raised_if_set_as_primary_method_is_called_with_correct_arguments
    assert_silent { EmailAddress.set_as_primary :primary, owner_key: :user_id }
  end
end

module SimpleAssocationTests
  def test_it_sets_primary_to_email_address_if_there_is_only_record
    @alice = User.first

    email_address = @alice.email_addresses.create!(email: "alice@example.com")

    assert email_address.primary?
  end

  def test_it_sets_primary_to_new_email_address_where_its_primary_is_set_to_true
    @alice = User.first

    email_address1 = @alice.email_addresses.create!(email: "alice@example.com")
    email_address2 = @alice.email_addresses.create!(email: "alice2@example.com", primary: true)

    assert email_address2.primary?
    assert_not email_address1.reload.primary?
  end

  def test_it_updates_primary_correclty
    @alice = User.first

    email_address1 = @alice.email_addresses.create!(email: "alice@example.com")
    email_address2 = @alice.email_addresses.create!(email: "alice2@example.com", primary: true)
    email_address1.update!(primary: true)

    assert email_address1.primary?
    assert_not email_address2.reload.primary?
  end
end

module PolymorphicAssociationTests
  def test_it_sets_primary_to_the_address_if_there_is_only_one_address_record
    @alice = User.first

    address = @alice.addresses.create!(data: "Pune, India")

    assert_equal 1, @alice.addresses.count
    assert address.primary?
  end

  def test_it_updates_the_primary_for_new_record_where_it_is_set_to_true
    @alice = User.first

    address1 = @alice.addresses.create!(data: "Pune, India")
    address2 = @alice.addresses.create!(data: "Mumbai, India", primary: true)

    assert address2.primary?
    assert_not address1.reload.primary?
  end

  def test_it_updates_primary_correclty_based_on_changes
    @alice = User.first

    address1 = @alice.addresses.create!(data: "Pune, India")
    address2 = @alice.addresses.create!(data: "Mumbai, India", primary: true)
    address1.update!(primary: true)

    assert address1.primary?
    assert_not address2.reload.primary?
  end
end

module ExcpetionsTests
  def test_wrong_argument_error
    e = assert_raise(SetAsPrimary::Error) {
      EmailAddress.set_as_primary "primary", owner_key: :user_id
    }

    assert_equal("Wrong attribute! Please provide attribute in symbol type", e.message)
  end

  def test_error_with_both_configuration_options
    e = assert_raise(SetAsPrimary::Error) {
      EmailAddress.set_as_primary :primary, owner_key: :owner_id, polymorphic_key: :owner
    }

    assert_equal("Either provide `owner_key` or `polymorphic_key` option", e.message)
  end
end
