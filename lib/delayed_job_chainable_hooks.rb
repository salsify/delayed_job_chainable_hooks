require 'delayed_job'
require 'delayed_job_active_record'
require 'hooks'
require 'active_support'
require 'delayed_job_chainable_hooks/version'
require 'delayed_job_chainable_hooks/plugin'

# Top-level gem module
module DelayedJobChainableHooks
  extend ActiveSupport::Concern

  def self.logger
    @logger ||= Delayed::Worker.logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  included do
    include Hooks

    define_hooks :before_job_attempt, :after_job_attempt,
                 :after_job_attempt_error, :after_job_failure, :after_job_success
  end
end
