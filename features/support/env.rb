$logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
$logger.debug '--- starting tests ---'
