$logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
$logger.debug '--- starting tests ---'

# For some reason JRuby / ChildProcess won't let us delete an environment variable, 
# but it will let us overwrite it, so we make do with that.
Before do
  if RUBY_PLATFORM =~ /java/
    set_env 'CUCUMBER_PRO_TOKEN', ''
  else
    ENV.delete('CUCUMBER_PRO_TOKEN')
  end
end
