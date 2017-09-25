# DelayedJobChainableHooks

DelayedJob lifecyle hooks that allow multiple definitions across modules or parent/child classes.

DelayedJob has [built-in *job-level* hook methods](https://github.com/collectiveidea/delayed_job#hooks) that support defining a callback on a given Job class.
It also has a plugin system that allows adding lifecycle behavior *globally* to Delayed::Worker.

What about when you want to share hook methods across job clases but not apply them globally?

One option is to use modules or job-class inheritance. While this works it has the downside that you might overwrite a hook.
If you realize that the method has a previous definition you can call `super` but it is error prone.

This gem provides an alternative: chainable hook methods. They use different names so that you can use them alongside the existing DelayedJob hooks.

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

### Example

For a subset of our DelayedJobs we want to provide a polling endpoint so that
when API clients make a request that enqueues work to be processed in the background,
they can check back on the status of that work and adjust the UI accordingly.

First we create the module to support that behavior, `ClientVisibleJob`.
It includes `DelayedJobExtendedCallbacks`. In it we maintain job status in
an ActiveRecord model named `ClientJobStatus`.

Note that we define the hooks by passing blocks to the methods provided by this gem,
unlike base DelayedJob where you implement the hook methods in the standard Ruby way using `def`.

```
module ClientVisibleJob
  extend ActiveSupport::Concern
  include DelayedJobChainableHooks

  included do
    attr_accessor :client_status_id

    after_job_success do
      client_status.update!(status: :completed)
    end

    after_job_failure do
      client_status.update!(status: :failed)
    end
  end

  def initialize(*args)
    @client_status = ClientJobStatus.create!(status: :running)
    self.client_status_id = @client_status.id
    super
  end

  def client_status
    @client_status ||= ClientJobStatus.find(client_status_id)
  end
end
```

Now `ClientVisibleJob` may be included in specific job classes. Those classes
may define their own versions of the hook methods but the ones defined in
`ClientVisibleJob` will still execute.

```
class MakeSouffleJob

  include ClientVisibleJob

  def perform
    whip_egg_whites
    mix_egg_whites_into_yokes
    place_in_baking_dish
    bake
  end

  before_job_attempt do
    Delayed::Worker.logger.info("Let's make a souffle.")
  end

  after_job_success do
    Delayed::Worker.logger.info("Souffle has risen!")
  end

  after_job_failure do
    Delayed::Worker.logger.warn("Souffle has fallen!")
  end
end
```

Code that enqueues this work, for example a web request handler, can treat `MakeSouffleJob`
as a `ClientVisibleJob` and provide a status polling endpoint to clients.

```
def post
  job = MakeSouffleJob.new
  Delayed::Job.enqueue(job)

  render status: :accepted, json: { status: "/souffle-status/#{job.client_status_id}" }
end
```

Other jobs that we want to make pollable can follow the same pattern.


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

