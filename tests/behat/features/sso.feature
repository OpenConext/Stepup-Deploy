Feature: A user signs in on a service provider
  In order to login on a service provider
  As a user
  I must verify the second factor after authenticating with an identity provider

  Scenario: A user logs in using single-signon
    Given a service provider configured for single-signon
     When I visit the service provider
      And I authenticate with the identity provider
      And I verify the second factor
     Then I am logged on the service provider

  Scenario: A user cancels the second factor authentication
    Given a service provider configured for single-signon
     When I visit the service provider
      And I authenticate with the identity provider
      And I cancel the second factor authentication
     Then I see an error at the service provider

  Scenario: A user logs in using single-signon without second factor requirement
    Given a service provider configured for single-signon
      And the service provider requires no second factor
     When I visit the service provider
      And I authenticate with the identity provider
     Then second factor authentication is not initiated
      And I am logged on the service provider
