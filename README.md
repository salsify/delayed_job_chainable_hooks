# DelayedJobChainableHooks

Implement DelayedJob lifecyle hook methods without overriding previous definitions.

DelayedJob has built-in *job-level* hook methods that support defining a callback on a given Job class.
It also has a plugin system that allows adding lifecycle behavior *globally* to Delayed::Worker.

What about when you want to share hook methods across jobs, but not apply them globally?

One option is to use modules or job-class inheritance. While this works it has the downside that you might overwrite a hook.
If you realize that the method has a previous definition you can call `super` but it is error prone.

This gem provides an alternative: chainable hook methods.

Inspired by [this blog post](https://www.salsify.com/blog/engineering/delayed-jobs-callbacks-and-hooks-in-rails).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayed_job_chainable_hooks'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delayed_job_chainable_hooks

## Usage

Currently it supports the following:

- `before_job_attempt`
- `after_job_attempt_error`
- `after_job_failure`
- `after_job_success`
- `after_job_attempt`

Pass any of these a block in a module or job superclass. The block will be executed at the appropriate point during the job's lifecycle.
Optionally pass do the same in a second module or subclass. Both the first and second blocks will be called during the job's lifecycle.


### Logging

By default this gem will use DelayedJob's built-in `Delayed::Worker.logger`. If you want this gem to log somewhere else, set it as follows in a Rails initializer or wherever works for you.

```
DelayedJobChainableCallbacks.logger = Logger.new('my-log-file')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

### Release (maintainers only)

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org)
.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/salsify/delayed_job_chainable_hooks.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

