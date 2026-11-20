# Server configuration

## Upgrading

The API adds two database migrations: an `api_tokens` table, and an `api_only` column on `users`. Run them when you deploy:

```bash
bin/rails db:migrate
```

It also adds the `rack-cors` gem, so run `bundle install` (or rebuild your Docker image).

## Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `API_RATE_LIMIT` | `300` | Requests each token may make per window |
| `API_RATE_LIMIT_PERIOD` | `300` | Window length in seconds |
| `API_CORS_ORIGINS` | `*` | Comma-separated list of websites allowed to call the API from browser JavaScript, such as `https://tools.example.org,https://intranet.example.org`. `*` allows any site. Set it to an empty value to turn CORS off. |
| `HOST` | `example.com` | Host name used in links in emails, including the single-use links for external users. It must be your site's public host name. |

### Rate limit storage

Rate limit counters are kept in the Rails cache.

* With no cache configured, Rails uses a file cache in `tmp/cache`. That works for a single server.
* If you run brkmn on several servers or containers that don't share a `tmp` folder, configure a shared cache (for example memcached or Redis) with `config.cache_store`. Otherwise each server counts separately.
* If the cache store is `:null_store`, rate limits are not enforced.

### CORS

Allowing every origin (`*`) is safe from a cross-site request forgery point of view: the API only accepts tokens in the `Authorization` header and never uses cookies, so another website can't act as a signed-in user. Restrict `API_CORS_ORIGINS` if you only want your own tools to call the API from browsers.

## Email

Superadmins' **Create token for external user** and **Send new link** actions send email through the background job queue (Sidekiq in production). Make sure:

* Sidekiq is running.
* SMTP is configured (the `SMTP_*` variables).
* `HOST` is set, so the links point at your site.

Email links use `https://` unless `RAILS_DISABLE_SSL` is set.

## Header authentication

If brkmn runs behind an authenticating proxy (`DEVISE_AUTH_TYPE=headers`), the proxy must let these paths through **without** its own sign-in:

* `/api/*`: API clients authenticate with tokens, not through the proxy, and external users collect their tokens under `/api/token_claim` because they have no proxy account.

## Security notes

* **No plaintext secrets stored:** brkmn stores only SHA-256 fingerprints of tokens and claim links.
* **Claim links:** the token in a claim link is sent as a `token` query parameter, which Rails replaces with `[FILTERED]` in request logs. The claim pages are served with `Cache-Control: no-store` and `Referrer-Policy: no-referrer`.
* **Claim emails in the job queue:** while a claim email waits in the queue, the job's arguments (including the link) are stored in Redis. If delivery fails, Sidekiq keeps the job in its retry or dead sets. The link is single-use and expires after 72 hours either way.
* **API-only accounts** can't sign in to the website or receive password reset emails. Signing in through CAS, SAML, or the header-authentication proxy turns them into regular accounts.
