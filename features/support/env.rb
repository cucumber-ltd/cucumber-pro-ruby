$logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
$logger.debug '--- starting tests ---'
ENV.delete('CUCUMBER_PRO_TOKEN')
