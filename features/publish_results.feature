@announce
Feature: Publish results

  Scenario: A couple of scenarios
    Given a git repo
    And a feature "features/test.feature" with:
      """
      Feature:
        Scenario:
          Given passing

        Scenario:
          Given failing
      """
    When I run `cucumber -f Cucumber::Pro -o /dev/null -f pretty`
    Then the results service should receive a header
    And the results service should receive these test-step results:
      | status | path                  | location |
      | passed | features/test.feature | 3        |
      | failed | features/test.feature | 6        |
    And the results service should receive these test-case results:
      | status | path                  | location |
      | passed | features/test.feature | 2        |
      | failed | features/test.feature | 5        |

  Scenario: A scenario outline

    Note that we don't specify how step results will be published. This is because it's hard to get
    a location for steps when a scenario outline executes.

    Given a git repo
    And a feature "features/test.feature" with:
      """
      Feature:
        Scenario Outline:
          Given <result>

          Examples:
          | result  |
          | passing |
          | failing |
      """
    When I run `cucumber -f Cucumber::Pro -o /dev/null -f pretty`
    Then the results service should receive a header
    And the results service should receive these test-case results:
      | status | path                  | location |
      | passed | features/test.feature | 7        |
      | failed | features/test.feature | 8        |

