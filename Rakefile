require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

desc 'Run tests'
task default: [:rspec, :cucumber]

# Because https://github.com/eventmachine/eventmachine/issues/34
if ENV['TRAVIS'] && RUBY_PLATFORM =~ /java/
  ENV['CUCUMBER_PRO_URL']="ws://results.cucumber.pro/ws"
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = ""
  t.cucumber_opts = "--format Cucumber::Pro --out cucumber-pro.log" if ENV['CUCUMBER_PRO_TOKEN']
  t.cucumber_opts << "--format pretty"
end

task :rspec do
  sh 'rspec'
end

desc 'Run repeated tests to check for async bugs'
task :soak, :repetitions do |task, args|
  reps = args[:repetitions] || 10
  results = reps.to_i.times.map do
    `cucumber`
    print $? == 0 ? '.' : 'x'
    $?
  end
  num_failed = results.count { |r| r != 0 }
  fail "#{num_failed}/#{reps} failed" if num_failed > 0
end
