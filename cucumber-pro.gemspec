# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "cucumber/pro/version"

Gem::Specification.new do |s|
  s.name        = 'cucumber-pro'
  s.version     = Cucumber::Pro::Version
  s.authors     = ["Matt Wynne"]
  s.description = "Client library for publishing results to the Cucumber Pro service"
  s.summary     = "cucumber-pro-#{s.version}"
  s.email       = "hello@cucumber.pro"
  s.homepage    = "https://cucumber.pro"
  s.platform    = Gem::Platform::RUBY
  s.license     = "MIT"
  s.required_ruby_version = ">= 1.9.3"

  s.add_development_dependency 'bundler', '>= 1.3.5'
  s.add_development_dependency 'rake',    '>= 0.9.2'
  s.add_development_dependency 'rspec',   '>= 2.14.1'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'aruba'

  s.rubygems_version = ">= 1.6.1"
  s.files            = `git ls-files`.split("\n").reject {|path| path =~ /\.gitignore$/ }
  s.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"
end
