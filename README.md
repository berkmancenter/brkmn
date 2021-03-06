# brkmn

A dirt-simple URL shortener.

## Links

* http://cyber.law.harvard.edu
* https://github.com/berkmancenter/brkmn

## System requirements
* ruby 2.7.1
* bundler
* rvm
* yarn
* postgres 9

## Development

* `rvm use 2.7.1@brkmn --create`
* (Optional, but convenient) Create a .ruby-gemset file with the name of your gemset.
* `bundle install`
* Copy `config/database.yml.postgres` to `config/database.yml` and set up your database accordingly
* Copy `config/ldap.yml.example` to `config/ldap.yml` and fill in locally appropriate values.
* Copy `config/secrets.yml.example` to `config/secrets.yml` and fill in the `secret_key_base` values for dev/test.
* Add the following to .env:
  * `USE_FAKEAUTH` (optional; set to to `true` if you want to bypass LDAP for development; any username/password will work; cannot be used in production).
  * `SECRET_KEY_BASE` (required in production, optional otherwise; use `rails secret` to generate a value).
  * `ALLOWED_HOST` (localhost is allowed by default; anything else must be explicit; may be a single string or a regex)
* `rails db:migrate`

Test with `rails test`.

## Troubleshooting

### PG::Error
brkmn is not compatible with postgres 10. If you are using pg10, you will see `ActiveRecord::StatementInvalid: PG::Error: ERROR: column "increment_by" does not exist`.

## Deployment

* The first time
  * Follow the steps above for development.
  * Make sure you've set the server hostname in ALLOWED_HOST.
* Every time
  * `git pull`
  * `bundle install`
  * `rails assets:clobber && rails assets:precompile` if assets changes
  * `rails db:migrate` if db schema changes
  * `touch tmp/restart.txt`

Version 1.1 does not use any Apache or NGiNX server level authentication. Using `net-ldap`, authentication is handled in the application using Ruby. If you are upgrading from the initial release (v1.0) please remove any authentication done at a webserver level and configure the authentication sources via `config/ldap.yml`.

## Contributors

* Dan Collis-Puro: djcp@cyber.law.harvard.edu
* Flavio Giobergia: flavio.giobergia@studenti.polito.it
* Andromeda Yelton: ayelton@cyber.harvard.edu

## License

brkmn is licensed under the terms of Rails itself - the MIT license: http://www.opensource.org/licenses/mit-license.php

## Copyright

2012-2020 President and Fellows of Harvard College
