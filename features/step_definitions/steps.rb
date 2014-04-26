Given(/^a git repo$/) do
  run "git init"
  run "git commit --allow-empty"
  run "git remote add origin #{repo_url}"
end

Then(/^the results service should receive the results:$/) do |results|
  expected_statuses = results.hashes.map { |row| row['status'] }
  sleeping(0.1).seconds.between_tries.failing_after(30).tries do
    results_service.messages.length.should == results.hashes.length
  end
  actual_statuses = results_service.messages.map { |msg| msg['body']['status'] }
  expect( actual_statuses ).to eq expected_statuses
end

require 'anticipate'
World(Anticipate)

