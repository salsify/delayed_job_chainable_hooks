# frozen_string_literal: true

describe DelayedJobChainableHooks do
  before do
    spec_dir = File.dirname(__FILE__)
    require "#{spec_dir}/fixtures/job_classes"

    JobSuperClass.called_callbacks.clear
    Delayed::Worker.reset
    Delayed::Worker.plugins << DelayedJobChainableHooks::Plugin
    Delayed::Worker.setup_lifecycle
    Delayed::Worker.max_attempts = 1
  end

  after do
    Delayed::Worker.plugins = []
    Delayed::Worker.reset
  end

  it "has a version number" do
    expect(DelayedJobChainableHooks::VERSION).not_to be nil
  end

  describe "for job that doesn't override delayed job callbacks" do
    it "invokes callbacks in the correct order for job success" do
      Delayed::Job.enqueue(JobSubClass.new(false))
      Delayed::Worker.new.work_off(1)
      expect(JobSuperClass.called_callbacks).to eq [:super_before_job_attempt, :sub_before_job_attempt,
                                                    :perform,
                                                    :super_after_job_success, :sub_after_job_success,
                                                    :super_after_job_attempt, :sub_after_job_attempt]
    end

    it "invokes callbacks in the correct order for job failure" do
      Delayed::Job.enqueue(JobSubClass.new(true))
      Delayed::Worker.new.work_off(1)
      expect(JobSuperClass.called_callbacks).to eq [:super_before_job_attempt, :sub_before_job_attempt,
                                                    :perform,
                                                    :super_after_job_attempt_error, :sub_after_job_attempt_error,
                                                    :super_after_job_failure, :sub_after_job_failure,
                                                    :super_after_job_attempt, :sub_after_job_attempt]
    end
  end

  describe "for job that does override delayed job callbacks" do
    it "invokes callbacks in the correct order for job success" do
      Delayed::Job.enqueue(JobSubClassWithOverriddenMethods.new(false))
      Delayed::Worker.new.work_off(1)
      expect(JobSuperClass.called_callbacks).to eq [:super_before_job_attempt, :sub_before_job_attempt,
                                                    :perform, :success,
                                                    :super_after_job_success, :sub_after_job_success,
                                                    :super_after_job_attempt, :sub_after_job_attempt]
    end

    it "invokes callbacks in the correct order for job failure" do
      Delayed::Job.enqueue(JobSubClassWithOverriddenMethods.new(true))
      Delayed::Worker.new.work_off(1)
      expect(JobSuperClass.called_callbacks).to eq [:super_before_job_attempt, :sub_before_job_attempt,
                                                    :perform, :error,
                                                    :super_after_job_attempt_error, :sub_after_job_attempt_error,
                                                    :failure,
                                                    :super_after_job_failure, :sub_after_job_failure,
                                                    :super_after_job_attempt, :sub_after_job_attempt]
    end
  end

  describe "for job callbacks that throw exceptions" do
    [
      :before_job_attempt,
      :after_job_attempt,
      :after_job_success,
      :after_job_attempt_error,
      :after_job_failure
    ].each do |hook_name|
      it "doesn't throw an exception if #{hook_name} throws an exception" do
        Delayed::Job.enqueue(JobWithExplodingCallbacks.new(hook_name))

        expect { Delayed::Worker.new.work_off(1) }.not_to raise_error
      end
    end
  end
end
