Feature: Publish results

  Scenario: Single passing step
    Given a git repo with remote "origin" at "git@github.com:cucumber-ltd/cucumber-pro-test.git"
    Given a file named "features/step_definitions/steps.rb" with:
      """
      Given(/pass/) { }
      """
    And a file named "features/pass.feature" with:
      """
      Feature: Test feature
        Scenario: Test scenario
          Given passing
      """
    When I run `cucumber -f Cucumber::Pro`
    Then the "api/github/cucumber-ltd/cucumber-pro-test/results" endpoint should receive JSON:
      """
      [
        { 
          "path":"features/pass.feature",
          "line":3,
          "status":"passed",
          "rev":"4", 
          "run":"123"
        }
      ]
      """

