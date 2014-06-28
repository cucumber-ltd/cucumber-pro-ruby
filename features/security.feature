@announce
Feature: Security

  Scenario: Bad access token
    Given a git repo
    And a feature "features/test.feature" with:
      """
      Feature:
        Scenario:
          Given passing
      """
    When I set the environment variables to:
      | variable           | value         |
      | CUCUMBER_PRO_TOKEN | invalid-token |
    And I run `cucumber -f Cucumber::Pro -o /dev/null -f pretty`
    And the stderr should contain "Access denied"
