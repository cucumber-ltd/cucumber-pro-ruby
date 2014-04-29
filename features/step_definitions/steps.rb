Before do
  write_file 'features/step_definitions/steps.rb', <<-END
Given(/pass/) { }
Given(/fail/) { fail }
  END
end

After do
  terminate_processes!
end

Given(/^a git repo$/) do
  run "git init"
  run "git commit --allow-empty"
  run "git remote add origin #{repo_url}"
end

Given(/^a feature with:$/) do |content|
  write_file 'features/test.feature', content
end

Then(/^the results service should receive the results:$/) do |results|
  results_messages = results_service.messages.select { |msg|
    msg.key?('mime_type')
  }
  expected_statuses = results.hashes.map { |row| row['status'] }
  sleeping(0.1).seconds.between_tries.failing_after(30).tries do
    results_messages.length.should == results.hashes.length
  end
  actual_statuses = results_messages.map { |msg|
    msg['body']['status']
  }
  expect( actual_statuses ).to eq expected_statuses
end

require 'anticipate'
World(Anticipate)
