module DelayedJobChainableHooks
  class Plugin < Delayed::Plugin

    # Set callbacks that are available via the Delayed Job lifecycle mechanism
    callbacks do |lifecycle|
      lifecycle.before(:perform) do |_, job|
        payload = Plugin.payload_object(job)
        Plugin.safe_run_hooks(payload, :before_job_attempt, job)
      end

      lifecycle.around(:invoke_job) do |job, *args, &block|
        payload = Plugin.payload_object(job)
        begin
          block.call(job, *args)
          Plugin.run_hooks(payload, :after_job_success)
        rescue => error
          Plugin.run_hooks(payload, :after_job_attempt_error, error)
          raise error
        end
      end

      lifecycle.after(:perform) do |_, job|
        payload = Plugin.payload_object(job)
        Plugin.safe_run_hooks(payload, :after_job_attempt, job)
      end

      lifecycle.after(:failure) do |_, job|
        payload = Plugin.payload_object(job)
        Plugin.safe_run_hooks(payload, :after_job_failure)
      end
    end

    def self.payload_object(job)
      payload = job.payload_object
      if payload.is_a?(Delayed::PerformableMethod)
        payload.object
      else
        payload
      end
    end

    def self.safe_run_hooks(object, hook_name, *args)
      run_hooks(object, hook_name, *args)
    rescue => error
      DelayedJobChainableHooks.logger.warn("Failed to run hook #{hook_name} on #{object.class}: #{error.message}")
    end

    def self.run_hooks(object, hook_name, *args)
      object.run_hook(hook_name, *args) if object.is_a?(DelayedJobChainableHooks)
    end
  end
end
