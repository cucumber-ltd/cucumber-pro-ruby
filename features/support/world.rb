World Module.new {
  def repo_url
    "git@github.com:cucumber-ltd/cucumber-pro-test"
  end

  def results_service
    FakeResultsService.instance
  end
}
