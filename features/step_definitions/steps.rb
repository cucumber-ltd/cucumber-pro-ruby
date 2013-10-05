Given(/^a git repo with remote "(.*?)" at "(.*?)"$/) do |remote_name, remote_url|
  run 'git init'
  run "git remote add #{remote_name} #{remote_url}"
end
