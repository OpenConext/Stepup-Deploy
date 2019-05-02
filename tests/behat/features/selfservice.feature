Feature: A user manages his tokens in the selfservice portal
  In order to use a second factor token
  As a user
  I must be able to manage my second factor tokens

  Scenario: A user registers a token in selfservice
    Given I am logged in into the selfservice portal
     When I register a new SMS token
      And I verify my e-mail address
      And I vet my second factor at the information desk

  Scenario: After token registration, the token can be viewed on the token overview page
    Given I am logged in into the selfservice portal as "joe-a1"
    Then I visit the "overview" page in the selfservice portal
     Then I should see "The following tokens are registered for your account."
      And I should see "SMS"
      And I should see "Test a token"
