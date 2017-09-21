describe DelayedJobChainableHooks do
  before do
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
end
