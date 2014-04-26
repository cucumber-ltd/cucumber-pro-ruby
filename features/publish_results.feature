@announce
Feature: Publish results

  Scenario: Single passing step
    Given a git repo
    And a file named "features/step_definitions/steps.rb" with:
      """
      Given(/pass/) { }
      Given(/fail/) { fail }
      """
    And a file named "features/pass.feature" with:
      """
      Feature:
        Scenario:
          Given passing
        Scenario:
          Given failing
      """
    When I run `cucumber -f Cucumber::Pro`
    Then the results service should receive the results:
      | status |
      | passed |
      | failed |

