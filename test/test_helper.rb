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

class Admin < ActiveRecord::Base
  has_many :addresses, as: :owner
end

class EmailAddress < ActiveRecord::Base
  include SetAsPrimary
  belongs_to :user

  set_as_primary :primary, :user_id
end

class PhoneNumber < ActiveRecord::Base
  include SetAsPrimary
  belongs_to :user
end

class Address < ActiveRecord::Base
  include SetAsPrimary
  belongs_to :owner, polymorphic: true, touch: true
end

def create_tables
  ActiveRecord::Migration.verbose = false

  ActiveRecord::Migration.create_table :users, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  ActiveRecord::Migration.create_table :admins, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  ActiveRecord::Migration.create_table :email_addresses, force: true do |t|
    t.string :email, null: false
    t.boolean :primary, default: false, null: false
    t.references :user
    t.timestamps
  end

  ActiveRecord::Migration.create_table :phone_numbers, force: true do |t|
    t.integer :number, null: false
    t.boolean :primary, default: false, null: false
    t.references :user
    t.timestamps
  end

  ActiveRecord::Migration.create_table :phone_numbers, force: true do |t|
    t.integer :number, null: false
    t.boolean :primary, default: false, null: false
    t.references :user
    t.timestamps
  end

  ActiveRecord::Migration.create_table :addresses, force: true do |t|
    t.string :address, null: false
    t.boolean :primary, default: false, null: false
    t.integer :owner_id, null: false
    t.string :owner_type, null: false
    t.timestamps
  end
end

def create_dummy_data
  User.create! name: "alice"
  Admin.create! name: "bob"
end

def drop_dummy_data
  User.delete_all
  Admin.delete_all
  EmailAddress.delete_all
  PhoneNumber.delete_all
  Address.delete_all
end

module GemSetupTest
  def test_no_exception_is_raised_if_set_as_primary_method_is_called_with_correct_arguments
    assert_silent { EmailAddress.set_as_primary :primary, :user_id }
  end
end

module MainGemTest
  def setup
    @alice = User.first
  end

  def test_it_sets_primary_to_eamil_address_if_there_is_only_record
    email_address = @alice.email_addresses.create!(email: "alice@example.com")

    assert email_address.primary?
  end

  def test_it_sets_primary_to_new_email_address_where_its_primary_is_set_to_true
    email_address1 = @alice.email_addresses.create!(email: "alice@example.com")
    email_address2 = @alice.email_addresses.create!(email: "alice2@example.com", primary: true)

    assert email_address2.primary?
    assert_not email_address1.reload.primary?
  end

  def test_it_updates_primary_correclty
    email_address1 = @alice.email_addresses.create!(email: "alice@example.com")
    email_address2 = @alice.email_addresses.create!(email: "alice2@example.com", primary: true)
    email_address1.update!(primary: true)

    assert email_address1.primary?
    assert_not email_address2.reload.primary?
  end
end
