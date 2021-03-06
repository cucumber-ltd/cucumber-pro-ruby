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
  run_simple "git init"
  run_simple "git config user.email \"test@test.com\""
  run_simple "git config user.name \"Test user\""
  run_simple "git commit --allow-empty -m 'Initial commit'"
  run_simple "git remote add origin #{repo_url}"
  # TODO: this is an experiment to fix flickering build on CI. May not be required.
  # wait for the git repo to be created before continuing
  eventually do
    run "git config --get remote.origin.url" do |process|
      expect(process.output.strip).to eq repo_url
    end
  end
end

Given(/^a feature "(.*?)" with:$/) do |path, content|
  write_file path, content
end

Then(/^the results service should receive a header$/) do
  eventually do
    expect(results_service.messages.length).to be > 0
  end
  expect(results_service.messages.first['repo_url']).to eq repo_url
end

Then(/^the results service should receive these ([\w\-]+) results:$/) do |type, results|
  expected_results = results.hashes
  actual_results = eventually {
    results = results_service.messages.select { |msg| msg['mime_type'] =~ /#{type}/ }
    expect( results.length ).to eq expected_results.length
    results
  }
  expected_statuses = expected_results.map { |result| [result['status'], result['path'], result['location'].to_i ] }
  actual_statuses = actual_results.map { |result| [result['body']['status'], result['path'], result['location']] }
  expect( actual_statuses ).to eq expected_statuses
end

require 'anticipate'
module Eventually
  include Anticipate
  def eventually(&block)
    result = nil
    sleeping(0.1).seconds.between_tries.failing_after(30).tries do
      result = block.call
    end
    result
  end
end
World(Eventually)
