# Cucumber Pro Client Gem

This gem provides a formatter for Cucumber that publishes results to the [Cucumber Pro](https://cucumber.pro) web service.

## Usage

Add the following line to your gemfile:

```
gem 'cucumber-pro'
```

Now run Cucumber using the `Cucumber::Pro` formatter:

```
CUCUMBER_PRO_AUTH_TOKEN=<your auth token> CUCUMBER_PRO_PROJECT_URL=https://cucumber.pro/api/foo/bar/results cucumber -f Cucumber::Pro -f pretty
```

