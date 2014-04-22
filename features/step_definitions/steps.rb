Given(/^a git repo$/) do
  run "git init"
  run "git commit --allow-empty"
  run "git remote add origin #{repo_url}"
end

Then(/^the results service should receive one passing result$/) do
  sleeping(0.1).seconds.between_tries.failing_after(30).tries do
    results_service.messages.length.should == 1
  end
  results_service.messages.first['body']['status'].should == "passed"
end

require 'anticipate'
World(Anticipate)

