# brkmn

[![Build Status](https://circleci.com/gh/berkmancenter/brkmn.svg?style=shield)](https://circleci.com/gh/berkmancenter/brkmn)

**brkmn** is a dirt-simple URL shortener designed to make sharing links a breeze. Powered by Ruby on Rails and PostgreSQL, it's a robust solution for managing and shortening URLs with ease.

## Documentation

- [Application functionality](docs/app-functionality.md)
- [API documentation](docs/api/README.md)
- [Documentation index](docs/README.md)

## Development

```bash
./docker/start_dev.sh --demo   # app + database, with demo data to play with
./docker/shell_dev.sh          # shell in the app container
./docker/stop_dev.sh           # stop it (-v also drops the database)
```

The app runs on http://localhost:8507, sent emails show up in Mailcatcher on
http://localhost:8517.

## Demo data

The seeds are demo data: people with different roles, links with clicks and
history, shared links and access requests in every state. Everything you need
to click through the app without making it all by hand.

### Loading it

| What | With Docker | Without Docker |
| --- | --- | --- |
| Load on every start | `./docker/start_dev.sh --demo` | |
| Load (again) | `./docker/seed_dev.sh` | `bin/rails demo:load` |
| Remove and load again | `./docker/seed_dev.sh reset` | `bin/rails demo:reset` |
| Remove | `./docker/seed_dev.sh remove` | `bin/rails demo:remove` |
| Show accounts and things to try | `./docker/seed_dev.sh info` | `bin/rails demo:info` |

A new development database gets the demo data automatically (`db:prepare` runs
the seeds), so does `bin/setup --demo`. To always load it with Docker, put
`SEED_DEMO_DATA=true` in `.env`.

Loading again puts the demo data back to its starting state: edited demo links
get their destination back, answered requests are open again, and links made by
demo users while playing are removed. Your own users and links are never
touched. Demo users are the ones with a `@demo.brkmn.test` email, a demo code
already taken by one of your links is skipped (the report says which).

### Accounts

Every account has the password `brkmn-demo-password`.

| Email | Who |
| --- | --- |
| `admin@demo.brkmn.test` | Ada, superadmin, can edit and delete every link |
| `maya@demo.brkmn.test` | Maya, owns the research links, has access requests to answer |
| `jonas@demo.brkmn.test` | Jonas, owns the event links, can edit some of Maya's |
| `priya@demo.brkmn.test` | Priya, communications, owns the most clicked links |
| `sam@demo.brkmn.test` | Sam, waits for edit access, an older request was denied |
| `lea@demo.brkmn.test` | Lea, new, no links yet, was just denied access |
| `tom@demo.brkmn.test` | Tom, locked after too many wrong passwords |
| `nora@demo.brkmn.test` | Nora, signed up but never confirmed the email |

### Things to try

- Open http://localhost:8507/newsletter: the most clicked link redirects and
  counts the click.
- Log in as Maya and answer the access requests from Sam (`lab-handbook`) and
  Jonas (`survey`) in the share dialog.
- Log in as Jonas and edit `spring-symposium`, Maya gave him edit access.
- Log in as Lea and ask for edit access to `board-minutes`: it was denied two
  hours ago, so she has to wait a day.
- Tom's account is locked. The log in only says "Invalid email or password"
  (paranoid mode doesn't tell why), "Didn't receive unlock instructions?" sends
  the unlock email to Mailcatcher. Nora can get her confirmation email again
  the same way.
- Search for "otter", sort by clicks, page through "All URLs" (120 generated
  links).

### Options

| Variable | Default | |
| --- | --- | --- |
| `DEMO_GENERATED_LINKS` | `120` | how many generated links, e.g. `1000` to test paging |
| `DEMO_PASSWORD` | `brkmn-demo-password` | password of every demo account |
| `DEMO_RANDOM_SEED` | `2012` | another number gives other generated links |

For example `DEMO_GENERATED_LINKS=1000 ./docker/seed_dev.sh reset`.

The data is in [db/seeds/demo_data.yml](db/seeds/demo_data.yml), easy to change
or extend, the code that loads it is in
[lib/brkmn/demo_data.rb](lib/brkmn/demo_data.rb). The same data comes out on
every run, times are relative to today.

The demo accounts have a known password, so the demo data never loads in
production (seeds there do nothing). For a demo server set
`ALLOW_DEMO_DATA=true`.

## Contributors

- Dan Collis-Puro: [djcp@cyber.law.harvard.edu](mailto:djcp@cyber.law.harvard.edu)
- Flavio Giobergia: [flavio.giobergia@studenti.polito.it](mailto:flavio.giobergia@studenti.polito.it)
- Andromeda Yelton: [ayelton@cyber.harvard.edu](mailto:ayelton@cyber.harvard.edu)
- Peter Hankiewicz: [peter.hankiewicz@gmail.com](mailto:peter.hankiewicz@gmail.com)

## License

Brkmn is open-source software licensed under the MIT License. For more information, visit [MIT License](http://www.opensource.org/licenses/mit-license.php).

## Copyright

© 2012 President and Fellows of Harvard College
