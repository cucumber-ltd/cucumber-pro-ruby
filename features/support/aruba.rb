require 'aruba/cucumber'

Before do
  # ensure Cucumber's Ruby process can require the plugin as though it were a gem
  path = File.expand_path(File.dirname(__FILE__) + '/../../lib')
  set_env 'RUBYLIB', path
end

Before do
  @aruba_timeout_seconds = 5
end
