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

### Running the tests

**Requirements**
* Development environment is provisioned with test databases
* Stepup runs in test mode
* Tests are run from the host machine

Running the tests is as easy as running the `behat` command in the `/tests/behat` folder

## Developing tests



## Future wishes, todo
* Be able to run these test on Travis
* Be able to bootstrap the application (and event stream) using behat [backgrounds](http://docs.behat.org/en/v2.5/guides/1.gherkin.html#backgrounds)
* Perform tests directly on the Middleware API's. Behat might not be the best candidate for this