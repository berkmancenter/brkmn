# UPGRADE.md

## To do
These are instructions specific to the Rails 3.2 upgrade; this file can be
removed when that is done.

- remove `config/initializers/secret_token.rb`
- set `ENV['SECRET_KEY_BASE']` using `rake secret`

## FYI
- All existing cookies will be invalidated.
