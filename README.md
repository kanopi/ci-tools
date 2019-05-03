# Kanopi CI Tools

[![CircleCI](https://circleci.com/gh/kanopi/ci-tools.svg?style=svg&circle-token=8c1ca43a0262e89eedc1b7b2eeef96bdc15c1390)](https://circleci.com/gh/kanopi/ci-tools)
[![](https://images.microbadger.com/badges/image/kanopi/ci.svg)](https://microbadger.com/images/kanopi/ci "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/kanopi/ci.svg)](https://microbadger.com/images/kanopi/ci "Get your own version badge on microbadger.com")

CI Tools can be used for helping test code and functional behavior.

## What's Installed

### Services

* Apache 2.4.x
* PHP 7.2.x
* MariaDB 10.x

### Tools

* Ruby
* Node
* PHP_CodeSniffer
  * [Drupal / Drupal Practice](https://www.drupal.org/docs/develop/standards)
  * [WordPress](https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards)
  * [PHP Compatability](https://github.com/PHPCompatibility/PHPCompatibility)
* Drush
* Drupal Console
* WP-CLI
* Terminus
* Platform.sh CLI
* Lighthouse
* Axe

### Browsers

* Chrome
* Firefox

## Configuration

### Variables

Variables can be used for accessing and setting specific pieces of data within the container. Located below are the variables that can be used for setting in the container and they will be used for helping make sure the tools run properly.

Name                        | Default Value        | Description
----------------------------|----------------------|------------------------------
APACHE_DOCUMENTROOT         | /var/www/docroot     | Apache Document Root
SECRET_TERMINUS_TOKEN       | (empty)              | Terminus CLI (Pantheon) Token
SECRET_ACAPI_EMAIL          | (empty)              | Acquia API Email
SECRET_ACAPI_KEY            | (empty)              | Acquia API Key
GITHUB_USER                 | (empty)              | Github User
GITHUB_PASSWORD             | (empty)              | Github Password
SECRET_PLATFORMSH_CLI_TOKEN | (empty)              | Platform.sh Token

## Using with CircleCI

The main overall puprose of this is to include it with CircleCI builds and help facilitate in auditing the quality of code that is released. Provided is a sample of how to include it within your CirleCI configuration. Also are samples of how to use the services for testing.

### Config.yml

* TBD

### Examples

* TBD

## How to Contribute

Helping out is greatly appreciated. Ways to contribute are:

* Adding in specific tools that help the overall productivity of the team.
* Updating documentation and versions of provided tools.
* Writing additional tests to help make sure the released product is stable.

### Testing

The CI Tools uses BATS (Bash Automated Testing System) for running tests. Therefore, any feature that is added must contain an accompanying test.

For more information on how to use BATS see [How To Use BATS To Test Your Command Line Tools](https://www.engineyard.com/blog/bats-test-command-line-tools), also take a moment to look at the [sstephenson/bats](https://github.com/sstephenson/bats) repo as this is the main place to see how tests are written.
