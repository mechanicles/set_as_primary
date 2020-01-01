# SetAsPrimary

The simplest way to handle the primary or default flag (:white_check_mark:) to
your Rails models.

Supports PostgreSQL, MySQL, and SQLite.

[Demo Rails application](https://cryptic-lake-90495.herokuapp.com/) |
[Demo Rails application GitHub repository](https://github.com/mechanicles/set_as_primary_rails_app)

[![Build Status](https://travis-ci.org/mechanicles/set_as_primary.svg?branch=master)](https://travis-ci.org/mechanicles/set_as_primary)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'set_as_primary'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install set_as_primary

## Usage

In your Rails application, you might have models like EmailAddress, PhoneNumber,
Address, etc., which belong to the User/Person model or polymorphic model. There,
you might need to set a primary email address, primary phone number, or default
address for a user, and this gem helps you to do that.

It also supports a single model with no association context. 

Examples:

```ruby
class User < ApplicationRecord
  has_many :email_addresses
  has_many :addresses, as: :owner
end

class EmailAddress < ApplicationRecord
  include SetAsPrimary
  belongs_to :user

  set_as_primary :primary, owner_key: :user
 end

class Address < ApplicationRecord
  include SetAsPrimary
  belongs_to :owner, polymorphic: true

  set_as_primary :primary, owner_key: :owner
end

# Single model with no owner/association context.
class Post < ApplicationRecord
  include SetAsPrimary
  
  set_as_primary :primary
end
``` 

You need to include `SetAsPrimary` module in your model where you want to handle the primary flag.
Then to `set_as_primary` class helper method, pass your primary flag attribute. You might need to pass
 association key `owner_key` if you wan to consider owner (association) context.

**Note:**  Default primary flag attribute is `primary`, and you can use another one too like `default` but
make sure that flag should be present in the table and should be a boolean data type column.

#### Migration

If your table does not have the primary flag column, then you can add it by running 
following command in your rails project:

```ssh
rails generate set_as_primary your_table_name flag_name
```

Example:

If you want to add a `primary` column to your `posts` table, then you can run command like this:

```shell
rails generate set_as_primary posts primary
```

Then migration gets created like this:

```ruby
class AddPrimaryColumnToPosts < ActiveRecord::Migration[6.0]
  def change
    add_column :posts, :primary, :boolean, default: false, null: false
    # NOTE: Please uncomment following line if you want only one 'true' (constraint) in the table.
    # add_index :posts, :primary, unique: true, where: "(posts.primary IS TRUE)"
  end
end
```

If you want to create a primary column to `email_addresses` table, then you can run command like this:

```shell
rails generate set_as_primary email_addresses primary user
```

Then it creates migration like this:

```ruby
class AddPrimaryColumnToEmailAddresses < ActiveRecord::Migration[6.0]
  def change
    add_column :email_addresses, :primary, :boolean, default: false, null: false
    # NOTE: Please uncomment following line if you want only one 'true' (constraint) in the table.
    # add_index :email_addresses, %i[user_id, primary], unique: true, where: "(email_addresses.primary IS TRUE)"
  end
end
```
You might have seen extra commented lines there. These lines are there for handling the unique constraint. Currently, these lines get created only for `PostgreSQL` adapter as it supports partial index.

Please note that here we have passed an extra option `user` in the command that is nothing button the owner/association name. This extra option helps to handle the unique index constraint.

**Note:** Partial indexes are only supported for PostgreSQL and SQLite 3.8.0+. But I also found that SQLite gives a syntax error so currently this gem only supports PostgreSQL.

**Even if we don't have constraint (only one 'true' constraint in the table), this gem takes care of it by updating all related records as `false` if the current record is set to `true.`**

Once migration file gets created, don't forget to run `rails db:migrate` to create an actual column in the table.

#### force_primary

```ruby
class Address < ApplicationRecord
  include SetAsPrimary
  belongs_to :user

  set_as_primary :default, owner_key: :user, force_primary: false
 end
```

By default `force_primary` option is set to `true`. If this option is `true`,
then it automatically sets record as primary when there is only one record in
the table. If you don't want this flow, then set it as `false`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at 
https://github.com/mechanicles/set_as_primary. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to adhere
to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the 
[MIT License](https://opensource.org/licenses/MIT).