task default: :cucumber

task :cucumber do
  ENV['cucumber_pro_log_path'] = File.dirname(__FILE__) + '/tmp/test.log'
  sh 'cucumber'
end
