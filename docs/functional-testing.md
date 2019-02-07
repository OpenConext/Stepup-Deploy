# Functional testing
* Test type: Smoke testing, End to end testing
* Software: Behat, Mink

**Platform requirements**

* Database: MariaDB (test database loaded with fixtures) 
* PHP: ^7.1 (due to Symfony, could be made to be PHP 5 compatible)

## End to end tests (Behat)
Stepup is a challenging application suite to provide functional (end to end) tests for. For example, running tests
for the SelfService application yield requests to at least three different other applications/services outside of 
SelfService. These being the Middleware, Gatweay, an IdP, and possibly a number of GSSP tokens. 

The choice to create tests in Stepup-Deploy seemed a logical choice. As this is the place where the Stepup platform can 
be built for different purposes (production, development and testing).

### Fine grained authorization use cases
The use cases written for the FGA (fine grained authorization) features are clustered in features that test a certain
use case described in the RFC document on the wiki. 

These tests comprise of a scenario that sets up the institution configuration and the required users to perform ample
tests. After setting up these requirements, additional scenarios test of the specific details the use case was intended
for. The 'set up' scenario was first captured in a backgrounds or scenario outlines, but these concepts did not fit well. 
The background will run before every scenario, making the scenarios painfully slow.  

### Running the tests

**Requirements**
* Development environment is provisioned with test databases
* Stepup runs in test mode (Behat will take care of this)
* Keys are configured for the test environment (overrides can be set in `fixtures/sp_key_overrides.json`) defaults are set that should work out of the box.
* Tests are run from the guest machine 
   * `$ cd /vagrant/deploy/tests/behat`
   * `$ vendor/bin/behat`

Running the tests is as easy as running the `behat` command in the `/tests/behat` folder

### Design decisions

A combination of getting things done and trying to be somewhat future proof where the main concerns while engineering the smoke tests. There are quite a lot of things that could be improved upon. And we might have to do this if we want to run these tests on Travis.

1. Behat was chosen as the test runner for the e2e/smoke tests. The Mink driver with Goutte where selected for their ease of use. The limitation of this choice is that no JavaScript can be tested.
2. Uses the test environments:
   1. The test environment of the other Stepup apps are used to test the smoke tests against. Getting the applications to switch to the correct environment during test. A testcookie solution was chosen.
   2. On every run of a scenario, a fresh event stream is replayed on the MW and GW databases.
   3. SP's and IdP's use a replacement set of test certificates. These are set in the `config_test.php` files of the different Stepup apps. But also projected in the `gateway_test` database `saml_entities` table (see `fixtures/sp_key_overrides.json` and `fixtures/bin/override_sp_public_key`). Finally the test SP/IdP resets its certificates based on the existence of the `testcookie` cookie. The `fixtures/test_{private|public)_key.(key|crt)` files are referenced to in the `config_test.yml` files of the different Stepup apps. 
3. We chose to run the tests on the guest, as this will make running tests during deployment easier, and removes extra requirements on the host machine.  
4. Before each scenario the test databases are flushed. The event stream tables are inserted and an event replay is performed. We would love to have more control in this aspect. See todo list.

## Developing tests

...

## Future wishes, todo
* Have the dummy GSSP device in the dev machine by default
* ~~Provide a message bird sms service test double to be able to test sms registrations~~
* Be able to run these test on Travis
* Be able to bootstrap the application (and event stream) using behat [backgrounds](http://docs.behat.org/en/v2.5/guides/1.gherkin.html#backgrounds)
* Perform tests directly on the Middleware API's. Behat might not be the best candidate for this