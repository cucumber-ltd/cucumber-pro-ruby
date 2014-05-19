require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

desc 'Run tests'
task default: [:rspec, :cucumber]

task :cucumber do
  sh 'cucumber'
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
