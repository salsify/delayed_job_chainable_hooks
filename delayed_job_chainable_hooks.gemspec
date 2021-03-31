# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed_job_chainable_hooks/version'

Gem::Specification.new do |spec|
  spec.name          = 'delayed_job_chainable_hooks'
  spec.version       = DelayedJobChainableHooks::VERSION
  spec.authors       = ['Salsify, Inc']
  spec.email         = ['engineering@salsify.com']

  spec.summary       = 'Implement DelayedJob hook methods in multiple modules/job classes ' \
                       'without overriding previous definitions.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/salsify/delayed_job_chainable_hooks'

  spec.license       = 'MIT'


  # Set 'allowed_push_post' to control where this gem can be published.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'activesupport', '>= 5.2'
  spec.add_dependency 'delayed_job', '>= 4.1'
  spec.add_dependency 'delayed_job_active_record'
  spec.add_dependency 'hooks'

  spec.add_development_dependency 'activerecord', '>= 5.2'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'overcommit'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '>= 3.8'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'salsify_rubocop', '~> 1.0.2'
  spec.add_development_dependency 'simplecov'
end
