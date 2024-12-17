# brkmn

[![Build Status](https://circleci.com/gh/berkmancenter/brkmn.svg?style=shield)](https://circleci.com/gh/berkmancenter/brkmn)

**brkmn** is a dirt-simple URL shortener designed to make sharing links a breeze. Powered by Ruby on Rails and PostgreSQL, it's a robust solution for managing and shortening URLs with ease.

## Getting Started

### Development Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/berkmancenter/brkmn.git
   cd brkmn
   ```

2. **Set Up Docker**

   Launch the services using Docker Compose:

   ```bash
   docker-compose up
   ```

3. **Access the App Container**

   Open a bash session in the app container:

   ```bash
   docker-compose exec app bash
   ```

4. **Install Dependencies**

   Inside the container, run:

   ```bash
   bundle install
   yarn install
   ```

5. **Configure Environment Variables**

   Copy the example environment configuration file and edit as necessary:

   ```bash
   cp .env.example .env
   ```

   Add or update the following variables in your  file:

| Environment Variable   | Description                                                                                          | Default Value   |
|------------------------|------------------------------------------------------------------------------------------------------|-----------------|
| `DATABASE_USERNAME`    | The username used for accessing the database.                                                        | None            |
| `DATABASE_PASSWORD`    | The password associated with the database username.                                                  | None            |
| `DATABASE_DB_NAME`     | The name of the database to which the application connects.                                          | None            |
| `DATABASE_HOST`        | The hostname where the database is hosted.                                                           | None            |
| `DATABASE_PORT`        | The port number for the database connection.                                                         | `5432`          |
| `DATABASE_TIMEOUT`     | The timeout setting for database connections, in milliseconds.                                       | `5000`          |
| `USE_FAKEAUTH`         | Set to `true` to bypass CAS authentication for development purposes.                                 | None            |
| `SECRET_KEY_BASE`      | Required in production. Generate using `rails secret`.                                               | None            |
| `ALLOWED_HOSTS`        | Comma-separated list or regex of allowed hosts.                                                      | `localhost`     |
| `CAS_DATA_DIRECTORY`   | Directory for storing CAS data. Used if `USE_FAKEAUTH` is set during development.                    | None            |
| `FOOTER_TEXT`          | Footer text displayed in the application.                                                            | None            |
| `SIDEKIQ_CONCURRENCY`  | Specifies the number of threads Sidekiq uses to process jobs. Falls back to `RAILS_MAX_THREADS` or 5.| `5`             |
| `RAILS_MAX_THREADS`    | Specifies the maximum number of threads for the Rails server. Used if `SIDEKIQ_CONCURRENCY` is not set.| None          |

1. **Database Setup**

   Run database migrations:

   ```bash
   rails db:migrate
   ```

2. **Start the Application**

   Use the following command to start the app in development mode:

   ```bash
   ./bin/dev
   ```

### Testing

Run the test suite using:

```bash
bundle exec rspec
```

## Deployment

### First-Time Setup

Follow the development setup steps above to initialize your environment. Ensure that `ALLOWED_HOSTS` is set to the server hostname.

### Regular Deployment

For each deployment, execute the following:

```bash
git pull
bundle install
yarn install
```

If you have made changes to assets, run:

```bash
rails assets:clobber && rails assets:precompile
```

If there are database schema changes, execute:

```bash
rails db:migrate
```

Finally, restart your application:

```bash
touch tmp/restart.txt
```

## Contributors

- Dan Collis-Puro: [djcp@cyber.law.harvard.edu](mailto:djcp@cyber.law.harvard.edu)
- Flavio Giobergia: [flavio.giobergia@studenti.polito.it](mailto:flavio.giobergia@studenti.polito.it)
- Andromeda Yelton: [ayelton@cyber.harvard.edu](mailto:ayelton@cyber.harvard.edu)
- Peter Hankiewicz: [peter.hankiewicz@gmail.com](mailto:peter.hankiewicz@gmail.com)

## License

Brkmn is open-source software licensed under the MIT License. For more information, visit [MIT License](http://www.opensource.org/licenses/mit-license.php).

## Copyright

© 2012 President and Fellows of Harvard College
