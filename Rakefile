task default: :cucumber

ENV['cucumber_pro_log_path'] = File.dirname(__FILE__) + '/tmp/test.log'

task :cucumber do
  sh 'cucumber'
end

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
