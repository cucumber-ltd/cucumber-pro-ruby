# Cucumber Pro Client Gem
[![Build Status](https://travis-ci.org/cucumber-ltd/cucumber-pro-ruby.svg?branch=master)](https://travis-ci.org/cucumber-ltd/cucumber-pro-ruby.svg?branch=master)

This gem provides a formatter for Cucumber that publishes results to
the [Cucumber Pro](https://cucumber.pro) web service.

## Usage

Add the following line to your gemfile:

    gem 'cucumber-pro'

Now run Cucumber using the `Cucumber::Pro` formatter. First, set the following
environment variables:

    export CUCUMBER_PRO_TOKEN=<your auth token from https://app.cucumber.pro/my/profile>
    export CI=true
    export CUCUMBER_PRO_LOG_FILE=cucumber-pro.log

On Windows, use `SET` instead of `export`.

    cucumber -f Cucumber::Pro -f pretty

This will set up a connection to the Cucumber Pro server and stream results as
your tests run.
