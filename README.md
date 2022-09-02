# Banking App API

*****
## Contents

- [Assumptions](#assumptions) 
- [Dependencies](#dependencies)
- [Project Setup](#project-setup)

## Assumptions

- Authentication and Authorization are not required
- Bank names are unique
- Account names inside a bank are unique
- Inter bank transactions are not allowed
- Date field in transaction cannot be in the past
- Transactions can records with date in future will be marked pending and processed on their respective dates.
- Only non duplicate transactions with dates in future can be updated
- Bank can also be sender or recepient of transaction depicting cash deposits, service charges and other deductions
- Effects of duplicate marked transactions are reverted if it was processed previously.
- System should not allow updation of duplicate records.

## Dependencies

- Bundler v2
- Ruby 3.0.0
- Ruby on Rails 6.1.x
- PostgreSQL 13
- Redis >= 4.2
- Gems:
    - [money-rails](https://github.com/RubyMoney/money-rails) | Money and Currency Handling
    - [sidekiq](https://github.com/mperham/sidekiq) | Background Jobs
    - [redis-mutex](https://github.com/kenn/redis-mutex) | Locking Semantics
    - [paper-trail](https://github.com/paper-trail-gem/paper_trail) | Track Changes
    - [paranoia](https://github.com/rubysherpas/paranoia) | Soft Deletion
    - [rubocop](https://github.com/rubocop/rubocop) | Ruby Code Analyzer
    - [rspec-rails](https://github.com/rspec/rspec-rails) | Testing Framework
    - [rspec-sidekiq](https://github.com/philostler/rspec-sidekiq) | Worker Tests
    - [timecops](https://github.com/travisjeffery/timecop) | Time Freezing
    - [factory-bot-rails](https://github.com/thoughtbot/factory_bot_rails) | Factories
    - [faker](https://github.com/faker-ruby/faker)) | Fake Data
    - [simplecov](https://github.com/simplecov-ruby/simplecov)) | Code Coverage Analysis
    - [whenever](https://github.com/javan/whenever) | Cron Jobs

## Setting up the development environment

1.  Get the code. Clone this git repository and check out the latest release:

    ```bash
    git clone repo
    cd project
    ```

2.  Install the required gems by running the following command in the project root directory:

    ```bash
    bundle install
    ```

3.  Create an `environment_variables.yml` file by copying the example database configuration:

    ```bash
    touch config/environment_variables.yml
    ```

4.  Add your database configuration details to `environment_variables.yml`. You will probably only need to fill in the password for the database(s).

Example config:

    development:
      DATABASE_NAME: ""
      DATABASE_USERNAME: ""
      DATABASE_PASSWORD: ""
      DATABASE_HOST: ""


5.  Create and populate database with seeds using:
  ```
  rails db:create db:migrate db:seed
  ```

6. To write your crontab file for your jobs
  ```
  whenever --update-crontab
  ```

7.  Run server:

    `rails server` or `rails s`
