# frozen_string_literal: true

class JobSuperClass < Struct.new(:perform_should_raise)
  include DelayedJobChainableHooks

  @called_callbacks = []

  class << self
    attr_accessor :called_callbacks
  end

  before_job_attempt do
    JobSuperClass.called_callbacks << :super_before_job_attempt
  end

  after_job_attempt do
    JobSuperClass.called_callbacks << :super_after_job_attempt
  end

  after_job_success do
    JobSuperClass.called_callbacks << :super_after_job_success
  end

  after_job_failure do
    JobSuperClass.called_callbacks << :super_after_job_failure
  end

  after_job_attempt_error do |_|
    JobSuperClass.called_callbacks << :super_after_job_attempt_error
  end

  def perform
    JobSuperClass.called_callbacks << :perform
    raise 'Test failure' if perform_should_raise
  end
end

class JobSubClass < JobSuperClass
  before_job_attempt do
    JobSuperClass.called_callbacks << :sub_before_job_attempt
  end

  after_job_attempt do
    JobSuperClass.called_callbacks << :sub_after_job_attempt
  end

  after_job_success do
    JobSuperClass.called_callbacks << :sub_after_job_success
  end

  after_job_failure do
    JobSuperClass.called_callbacks << :sub_after_job_failure
  end

  after_job_attempt_error do |_|
    JobSuperClass.called_callbacks << :sub_after_job_attempt_error
  end
end

class JobSubClassWithOverriddenMethods < JobSuperClass
  # Include the module again to make sure multiple includes don't screw things up
  include DelayedJobChainableHooks

  before_job_attempt do
    JobSuperClass.called_callbacks << :sub_before_job_attempt
  end

  after_job_attempt do
    JobSuperClass.called_callbacks << :sub_after_job_attempt
  end

  after_job_success do
    JobSuperClass.called_callbacks << :sub_after_job_success
  end

  after_job_failure do
    JobSuperClass.called_callbacks << :sub_after_job_failure
  end

  after_job_attempt_error do |_|
    JobSuperClass.called_callbacks << :sub_after_job_attempt_error
  end

  def success
    JobSuperClass.called_callbacks << :success
  end

  def error
    JobSuperClass.called_callbacks << :error
  end

  def failure
    JobSuperClass.called_callbacks << :failure
  end
end

class JobWithExplodingCallbacks < Struct.new(:exploding_hook_name)
  include DelayedJobChainableHooks

  [
    :before_job_attempt,
    :after_job_attempt,
    :after_job_success,
    :after_job_attempt_error,
    :after_job_failure
  ].each do |hook_name|
    send(hook_name) do
      raise 'Test Exception' if exploding_hook_name == hook_name
    end
  end

  def perform
    # Don't do anything
  end
end
