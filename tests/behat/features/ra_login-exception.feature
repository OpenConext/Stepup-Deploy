Feature: A RAA can only manage R RA(A)'s on the promotion page
  In order to manage RA(A)'s
  As a user
  I must see a sane error  message when I login to RA but I'm not accredited as RA

  Scenario: Provision a institution and a user to promote later on by an authorized institution
    Given a user "joe-a-raa" identified by "urn:collab:person:institution-a.example.com:joe-a-raa" from institution "institution-a.example.com" with UUID "00000000-0000-4000-a000-000000000001"
    And the user "urn:collab:person:institution-a.example.com:joe-a-raa" has a vetted "yubikey" with identifier "00000004"

  Scenario: User "joe-a-raa"  tries to login while not accredited as RAA should be informed
    Given I try to login into the ra portal as "joe-a-raa" with a "yubikey" token
    Then I should see "Error - Access denied"
     And I should see "Authentication was successful, but you are not authorised to use the RA management portal"

