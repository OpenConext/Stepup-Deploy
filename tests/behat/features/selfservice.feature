Feature: A user manages his tokens in the selfservice portal
  In order to use a second factor token
  As a user
  I must be able to manage my second factor tokens

  Scenario: A user registers a token in selfservice
    Given I am logged in into the selfservice portal
     When I register a new SMS token
      And I verify my e-mail address
      And I vet my second factor at the information desk
