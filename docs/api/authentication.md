# Authentication

Every API request needs an API token. A token acts as the brkmn account it belongs to, so it can do what that account can do on the website, limited by the token's access level.

## Getting a token

* **If you can sign in to brkmn:** create one under **Settings → API tokens**. See [Managing your tokens](managing-tokens.md).
* **If you can't:** a brkmn superadmin can create a token for your email address. You'll get an email with a single-use link to collect it. See [Collecting a token you were sent](collecting-a-token.md).

## Sending the token

Send the token in the `Authorization` header of every request, using the `Bearer` scheme:

```http
GET /api/v1/urls HTTP/1.1
Host: brkmn.example.org
Authorization: Bearer brkmn_...
```

> **Warning:** Tokens in the URL (for example `?access_token=...`) are ignored, and the request fails with `401`. URLs end up in server logs, browser history, and `Referer` headers, so they are not a safe place for a secret.

The API never uses website cookies. Being signed in to brkmn in your browser does not authenticate API requests.

## Token format

Tokens look like `brkmn_` followed by 40 letters and digits, for example `brkmn_a1B2c3...`.

* The fixed `brkmn_` prefix makes leaked tokens easy to spot. If you run a secret scanner, you can add the pattern `brkmn_[1-9A-HJ-NP-Za-km-z]{40}`.
* The brkmn website shows only the first 12 characters of each token (such as `brkmn_a1B2c3…`), so you can tell your tokens apart.
* brkmn stores only a fingerprint (SHA-256 hash) of each token. Nobody, including administrators, can look up a token's value after it has been shown to you.

## Access levels

| Access level | Can read URLs | Can create, change, and delete URLs |
| --- | --- | --- |
| **Read-only** | Yes | No |
| **Read & write** | Yes | Yes, where the account is allowed to |

A read-only token gets `403` with the code `insufficient_scope` when it tries to make a change.

Even with a read & write token, the account's permissions still apply. See [Who can change a URL](urls.md#who-can-change-a-url).

> **Security warning:** A token created by a superadmin account has superadmin powers through the API: it can change and delete anyone's URLs. Give such tokens read-only access unless they really need to make changes.

## Expiry

Each token either expires after a set number of days (7, 30, 90, 180, or 365) or never expires.

* An expired token gets `401` with a message saying when it expired.
* Regenerating a token gives it a new value and starts its lifetime again.

## Checking a token

`GET /api/v1/me` returns the account and token you are using. It's a cheap way to check a token before running a longer job.

```bash
curl https://brkmn.example.org/api/v1/me -H "Authorization: Bearer $BRKMN_TOKEN"
```

```json
{
  "user": { "id": 42, "email": "you@example.org", "username": "you@example.org", "superadmin": false },
  "token": {
    "id": 7,
    "name": "Newsletter script",
    "prefix": "brkmn_a1B2c3",
    "access_level": "read_write",
    "expires_at": "2027-02-16T09:17:42.000Z",
    "last_used_at": "2026-11-18T09:20:03.000Z",
    "created_at": "2026-11-18T09:17:42.000Z"
  }
}
```

| Field | Meaning |
| --- | --- |
| `token.access_level` | `read_only` or `read_write` |
| `token.expires_at` | When the token stops working, or `null` if it never expires |
| `token.last_used_at` | When the token was last used. Updated at most every 5 minutes. |

## Authentication errors

| Status | `error.code` | When |
| --- | --- | --- |
| `401` | `missing_token` | No `Authorization` header, or not a `Bearer` token |
| `401` | `invalid_token` | The token doesn't exist, was revoked, or was regenerated |
| `401` | `invalid_token` | The token has expired. The message includes the expiry time. |
| `403` | `insufficient_scope` | A read-only token tried to make a change |

`401` responses include a `WWW-Authenticate: Bearer realm="brkmn"` header, as described in [RFC 6750](https://www.rfc-editor.org/rfc/rfc6750). See [Errors](errors.md) for the response format.

## Keeping tokens safe

* **Store tokens like passwords:** in a password manager, or in your platform's secret store (for example GitHub Actions secrets).
* **Use one token per app or script,** with a name that says what it is for. You can then revoke one without breaking the others.
* **Choose the least access that works:** read-only unless the script makes changes, and an expiry date unless you have a reason not to.
* **Never commit a token to a repository** or paste it into a chat or ticket.
* **If a token might have leaked, revoke it** (or regenerate it) under **Settings → API tokens** straight away.

## Calling the API from a browser

The API supports [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS), so JavaScript running on other websites can call it. Which sites are allowed depends on how your brkmn site is configured; by default any site can call it.

Anyone who can open a web page can read the token in its JavaScript. Only put a token in browser code when the page is used solely by the token's owner (for example a personal or internal tool), and prefer read-only tokens there.

Browser clients can read these response headers: `Location`, `Retry-After`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`, and `X-RateLimit-Reset`.
