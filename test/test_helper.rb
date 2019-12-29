# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:default)
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

class Person < ActiveRecord::Base
  has_many :addresses, as: :owner
end

class EmailAddress < ActiveRecord::Base
  include SetAsPrimary
  belongs_to :user

  set_as_primary :primary, owner_key: :user
end

class PhoneNumber < ActiveRecord::Base
  include SetAsPrimary
  belongs_to :user

  set_as_primary :default, owner_key: :user
end

class Address < ActiveRecord::Base
  include SetAsPrimary
  belongs_to :owner, polymorphic: true

  set_as_primary :primary, owner_key: :owner
end

class Post < ActiveRecord::Base
  include SetAsPrimary

  set_as_primary
end

def create_tables
  ActiveRecord::Migration.verbose = false

  ActiveRecord::Migration.create_table :users, force: true do |t|
    t.string :name, null: false
    t.timestamps
  end

  ActiveRecord::Migration.create_table :people, force: true do |t|
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
    t.string :number, null: false
    t.boolean :default, default: false, null: false
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

  ActiveRecord::Migration.create_table :posts, force: true do |t|
    t.string :title, null: false
    t.text :content, null: false
    t.boolean :primary, default: false, null: false
    t.timestamps
  end
end

def create_dummy_data
  User.create! name: "Alice"
  Person.create! name: "Jane"
end

def drop_dummy_data
  User.delete_all
  Person.delete_all
  EmailAddress.delete_all
  Address.delete_all
  Post.delete_all
end

module GemSetupTest
  def test_no_exception_is_raised_if_set_as_primary_method_is_called_with_correct_arguments
    assert_silent { EmailAddress.set_as_primary :primary, owner_key: :user }
  end

  def test_default_primary_flag_attribute_should_be_primary
    assert_equal :primary, EmailAddress._primary_flag_attribute
  end

  def test_primary_flag_attribute_should_get_set_properly
    assert_equal :default, PhoneNumber._primary_flag_attribute
  end

  def test_attributes_should_get_set_properly
    assert_equal :primary, EmailAddress._primary_flag_attribute
    assert_equal :user, EmailAddress._owner_key
    assert EmailAddress._force_primary # By default this attribute will be true.

    assert_equal :primary, Address._primary_flag_attribute
    assert_equal :owner, Address._owner_key
  end

  def test_force_primary_attribute_should_be_false
    EmailAddress.set_as_primary :primary, owner_key: :user, force_primary: false
    assert_not EmailAddress._force_primary
  ensure
    # NOTE: We are making sure that it will set force_primary back to `true` so other
    # tests get passed.
    EmailAddress.set_as_primary :primary, owner_key: :user, force_primary: true
  end
end

module SingleModelWithNoAssociationTests
  def test_it_sets_primary_to_post_if_there_is_one_record
    post = Post.create!(title: "post 1", content: "content 1")

    assert post.primary?
  end

  def test_if_force_primary_is_set_to_false_then_it_should_not_force_primary_for_single_record
    Post.set_as_primary force_primary: false

    post = Post.create!(title: "post 1", content: "content 1")

    assert_equal 1, Post.count
    assert_not post.primary?
  ensure
    Post.set_as_primary
  end

  def test_it_updates_primary_correctly
    post1 = Post.create!(title: "post 1", content: "content 1")

    assert post1.primary?

    post2 = Post.create!(title: "post 2", content: "content 2", primary: true)

    assert post2.primary?
    assert_not post1.reload.primary?
  end
end

module SimpleAssocationTests
  def test_it_sets_primary_to_email_address_if_there_is_only_one_record
    alice = User.first

    email_address = alice.email_addresses.create!(email: "alice@example.com")

    assert email_address.primary?
  end

  def test_it_sets_primary_to_new_email_address_where_its_primary_is_set_to_true
    alice = User.first

    email_address1 = alice.email_addresses.create!(email: "alice@example.com")
    email_address2 = alice.email_addresses.create!(email: "alice2@example.com", primary: true)

    assert_not email_address1.reload.primary?
    assert email_address2.primary?
  end

  def test_it_updates_primary_correctly
    alice = User.first

    email_address1 = alice.email_addresses.create!(email: "alice@example.com")
    email_address2 = alice.email_addresses.create!(email: "alice2@example.com", primary: true)
    email_address1.update!(primary: true)

    assert email_address1.primary?
    assert_not email_address2.reload.primary?
  end

  def test_if_force_primary_is_set_to_false_then_it_should_not_force_primary_for_single_record
    EmailAddress.set_as_primary :primary, owner_key: :user, force_primary: false

    alice = User.first

    email_address1 = alice.email_addresses.create!(email: "alice@example.com")
    assert_not email_address1.primary?
    assert_equal 1, alice.email_addresses.count
  ensure
    EmailAddress.set_as_primary :primary, owner_key: :user, force_primary: true
  end
end

module PolymorphicAssociationTests
  def test_it_sets_primary_to_the_address_if_there_is_only_one_address_record
    alice = User.first

    address = alice.addresses.create!(data: "Pune, India")

    assert_equal 1, alice.addresses.count
    assert address.primary?
  end

  def test_it_updates_the_primary_for_new_record_where_it_is_set_to_true
    alice = User.first

    address1 = alice.addresses.create!(data: "Pune, India")
    address2 = alice.addresses.create!(data: "Mumbai, India", primary: true)

    assert address2.primary?
    assert_not address1.reload.primary?
  end

  def test_it_updates_primary_correctly
    alice = User.first
    jane = Person.first

    alice_address1 = alice.addresses.create!(data: "Pune, India")
    jane_address1 = jane.addresses.create!(data: "Mumbai, India")

    assert alice_address1.primary?
    assert jane_address1.primary?

    jane_address2 = jane.addresses.create!(data: "Bengaluru, India", primary: true)

    assert alice_address1.reload.primary?
    assert_not jane_address1.reload.primary?
    assert jane_address2.primary?
  end

  def test_if_force_primary_is_set_to_false_then_it_should_not_force_primary_for_single_record
    Address.set_as_primary :primary, owner_key: :owner, force_primary: false

    alice = User.first

    address1 = alice.addresses.create!(data: "Pune, India")
    assert_not address1.primary?
  ensure
    Address.set_as_primary :primary, owner_key: :owner, force_primary: true
  end
end

module ExceptionsTests
  def test_wrong_argument_error
    e = assert_raise(SetAsPrimary::Error) {
      EmailAddress.set_as_primary "primary", owner_key: :user
    }

    assert_equal("Wrong attribute! Please provide attribute in symbol type.", e.message)
  end

  def test_error_with_wrong_owner_key
    e = assert_raise(ActiveRecord::AssociationNotFoundError) {
      EmailAddress.set_as_primary :primary, owner_key: :person
    }

    assert_equal("Association named 'person' was not found on Class; perhaps you misspelled it?", e.message)
  end
end
