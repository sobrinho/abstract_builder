# AbstractBuilder

AbstractBuilder gives you a simple DSL for declaring structures that beats manipulating giant hash structures. This is particularly helpful when the generation process is fraught with conditionals and loops.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'abstract_builder'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install abstract_builder

## Usage

AbstractBuilder gives you a simple DSL for declaring structures:

```ruby
builder = AbstractBuilder.new
builder.(company, :name, :created_at, :updated_at)
builder.size company.employees.count
builder.merge! company.metadata

builder.address do |address_builder|
  address_builder.street company.address.street
  address_builder.number company.address.number
end

builder.phones company.phones do |phone_builder, phone|
  phone_builder.number phone.number
  phone_builder.contact phone.contact
end

builder.data!
{
  :name => "...",
  :created_at => "...",
  :updated_at => "...",
  :size => "...",
  :metadata => { ... },
  :address => {
    :street => "...",
    :number => "..."
  },
  :phones => [
    {
      :number => "...",
      :contact => "..."
    }
  ]
}
```

Alternatively, you can use the low-level API for declaring complex structures:

```ruby
builder = AbstractBuilder.new

company.block! company.uuid do |block_builder|
  block_builder.name company.name

  company.phones.each do |phone|
    builder.set! "phone_number_#{phone.index}", phone.number
  end

  company.messages.each_slice(2).each_with_index do |messages, index|
    builder.array! "messages_#{index}", messages do |message_builder, message|
      message_builder.content message.content
    end
  end
end

builder.data!
{
  "461d84cf-039e-4b86-9e92-8f04cce19a1d" => {
    :name => "...",
    :phone_number_0 => "...",
    :phone_number_1 => "..."
    :messages_0 => [
      {
        :content => "..."
      },
      {
        :content => "..."
      }
    ],
    :messages_1 => [
      {
        :content => "..."
      }
    ]
  },
}
```

Since the AbstractBuilder is abstract to the data protocol, you may serialize the result into any protocol you want:

```ruby
JSON.dump(builder.data!)
YAML.dump(builder.data!)
MessagePack.pack(builder.data!)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `abstract_builder.gemspec`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sobrinho/abstract_builder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AbstractBuilder project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sobrinho/abstract_builder/blob/master/CODE_OF_CONDUCT.md).
