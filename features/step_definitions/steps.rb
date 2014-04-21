Given(/^a git repo$/) do
  run "git init"
  run "git commit --allow-empty"
  run "git remote add origin #{repo_url}"
end

Then(/^the results service should receive one passing result$/) do
  results_service.messages.length.should == 1
  results_service.messages.first.body.status.should == "passing"
end

