Feature: A user authenticates with a service provider configured for second-factor-only
  In order to login on a service provider
  As a user
  I must verify the second factor without authenticating with an identity provider

  Scenario: A user logs in using SFO
    Given a service provider configured for second-factor-only
    When I visit the service provider
    And I verify the second factor
    Then I am logged on the service provider
