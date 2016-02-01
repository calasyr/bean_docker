# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bean_docker/version'

Gem::Specification.new do |spec|
  spec.name          = "bean_docker"
  spec.version       = BeanDocker::VERSION
  spec.authors       = ["Alan Brown"]
  spec.email         = ["abrown@smartzip.com"]

  spec.summary       = %q{Launch a new Docker container running bash on an Elastic Beanstalk instance. }
  spec.description   = %q{Install this gem directly on an Elastic Beanstalk instance that is running Amazon 
    Linux and Docker.  The environment variables you set for the default instance are used to start the 
    new container.  Useful for running rake tasks in your production environment.}
  spec.homepage      = "https://www.smartzip.com"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
