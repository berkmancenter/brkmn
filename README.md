[![Build Status](https://circleci.com/gh/berkmancenter/brkmn.svg?style=shield)](https://circleci.com/gh/berkmancenter/brkmn)

# brkmn

A dirt-simple URL shortener.

## System requirements
* ruby 2.7.x+
* postgres 9.x+

## Development

* `docker-composer up`
* `docker-compose exec website bash`
* `bundle install`
* Copy `.env.example` to `.env` and set up your database accordingly
* Add the following to .env:
  * `USE_FAKEAUTH` (optional; set to to `true` if you want to bypass CAS for development; any username/password will work; cannot be used in production).
  * `SECRET_KEY_BASE` (required in production, optional otherwise; use `rails secret` to generate a value).
  * `ALLOWED_HOST` (localhost is allowed by default; anything else must be explicit; may be a single string or a regex)
  * `CAS_DATA_DIRECTORY` (required in production, directory for storing CAS data, in development use `USE_FAKEAUTH`)
* `rails db:migrate`
* `rails s -b 0.0.0.0`

Test with `rails test`.

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

Version `>= 1.1` does not use any Apache or NGiNX server level authentication. Using `CAS`, authentication is handled in the application using Ruby. If you are upgrading from the initial release (v1.0) please remove any authentication done at a webserver level.

## Contributors

* Dan Collis-Puro: djcp@cyber.law.harvard.edu
* Flavio Giobergia: flavio.giobergia@studenti.polito.it
* Andromeda Yelton: ayelton@cyber.harvard.edu
* Peter Hankiewicz: peter.hankiewicz@gmail.com

## License

brkmn is licensed under the terms of Rails itself - the MIT license: http://www.opensource.org/licenses/mit-license.php

## Copyright

© 2012 President and Fellows of Harvard College
