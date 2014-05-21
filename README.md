# Cucumber Pro Client Gem
[![Build Status](https://travis-ci.org/cucumber-ltd/cucumber-pro-ruby.svg?branch=master)](https://travis-ci.org/cucumber-ltd/cucumber-pro-ruby.svg?branch=master)

This gem provides a formatter for Cucumber that publishes results to
the [Cucumber Pro](https://cucumber.pro) web service.

## Usage

Add the following line to your gemfile:

```
gem 'cucumber-pro'
```

Now run Cucumber using the `Cucumber::Pro` formatter:

```
CUCUMBER_PRO_TOKEN=<your auth token> cucumber -f Cucumber::Pro -o /dev/null -f pretty
```

This will set up a connection to the Cucumber Pro server and stream results as
your tests run. If you want to see debug output, replace `/dev/null` with the
path to a log file.
