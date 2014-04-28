@announce
Feature: Publish results

  Scenario: Single passing step
    Given a git repo
    And a feature with:
      """
      Feature:
        Scenario:
          Given passing

        Scenario:
          Given failing
      """
    When I run `cucumber -f Cucumber::Pro -o /dev/null -f pretty`
    Then the results service should receive the results:
      | status |
      | passed |
      | failed |

