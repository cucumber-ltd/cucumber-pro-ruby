$logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
$logger.debug '--- starting tests ---'

# You don't normally need this in your test suite, but we need to make sure this environment
# variable has been read so we can delete it, because otherwise it will interfere with other
# parts of our test suite.
require 'cucumber/pro'
Before do
  ENV.delete('CUCUMBER_PRO_TOKEN')
end
