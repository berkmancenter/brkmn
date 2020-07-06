# UPGRADE.md

## To do
These are instructions specific to the Rails 3.2 upgrade; this file can be
removed when that is done.

- test the LDAP integration on dev
  - it's not covered in the test file
  - and you needed to update the net-ldap library because of deprecations
- remove `config/initializers/secret_token.rb`
- set `ENV['SECRET_KEY_BASE']` using `rake secret`
- install yarn
- `rails db:migrate`
- check SSL situation

## FYI
- All existing cookies will be automatically invalidated.
