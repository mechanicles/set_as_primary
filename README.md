# SetAsPrimary

The simplest way to handle primary or default flag to your models.

Supports PostgreSQL, MySQL, and SQLite.

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

In your Rails application, you might have models like EmailAddress, PhoneNumber, Address, etc, which belong to User/Person model. There, you might need to set primary email address, primary phone number, or default address for a user, and this gem will help you to handle that.

Examples:

```ruby
class User < ApplicationRecord
  has_many :email_addresses
  has_many :phone_numbers
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
``` 

You just need to include `SetAsPrimary` in your model where you want to handle primary flag. 
Then pass your primary flag with required association keys, i.e., `owner_key` for  class helper method `set_as_primary`.

Default primary flag is `primary` and you can use another too (but make sure that flag should be boolean column type column).

If your model does not have primary key, then you can add it by running following command in your rails project.

```ssh
rails generate set_as_primary your_table_name
```

#### force_primary

```ruby
class Address < ApplicationRecord
  include SetAsPrimary
  belongs_to :user

  set_as_primary :default, owner_key: :user, force_primary: false
 end
```

By default `force_primary` option is set to `true`. If this option is `true`, then it will automatically set record as primary when
there is only one record in the table. If you don't want this flow then set it as `false`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/set_as_primary. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SetAsPrimary project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/set_as_primary/blob/master/CODE_OF_CONDUCT.md).
