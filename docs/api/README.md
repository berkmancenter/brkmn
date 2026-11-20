# brkmn API

The brkmn API lets scripts and other apps manage short URLs with the same permissions they would have on the website.

* **Base URL:** `https://<your brkmn site>/api/v1`
* **Format:** JSON. Send `Content-Type: application/json` with request bodies.
* **Authentication:** a personal API token in the `Authorization` header. See [Authentication](authentication.md).

> **Note:** The examples use `https://brkmn.example.org`. Replace it with the address of your brkmn site, and keep your token in an environment variable such as `BRKMN_TOKEN` rather than in your code.

## Guides

* [Authentication](authentication.md)
* [URLs](urls.md)
* [Errors](errors.md)
* [Rate limits](rate-limits.md)
* [Managing your tokens](managing-tokens.md)
* [Collecting a token you were sent](collecting-a-token.md)
* [Tokens for external users](external-users.md)
* [Server configuration](configuration.md)

## Quick start

### 1. Get a token

Sign in to brkmn, open **Settings → API tokens**, and create a token. Copy it straight away: it is shown only once. See [Managing your tokens](managing-tokens.md).

If you don't have an account on the website, an administrator can send you a token by email. See [Collecting a token you were sent](collecting-a-token.md).

### 2. Check that the token works

#### curl

```bash
curl https://brkmn.example.org/api/v1/me \
  -H "Authorization: Bearer $BRKMN_TOKEN"
```

#### JavaScript

```javascript
const response = await fetch("https://brkmn.example.org/api/v1/me", {
  headers: { Authorization: `Bearer ${process.env.BRKMN_TOKEN}` },
});
console.log(await response.json());
```

#### Python

```python
import os
import requests

response = requests.get(
    "https://brkmn.example.org/api/v1/me",
    headers={"Authorization": f"Bearer {os.environ['BRKMN_TOKEN']}"},
)
print(response.json())
```

The response shows which account and token you are using:

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

### 3. Shorten a URL

Creating URLs needs a token with **Read & write** access.

#### curl

```bash
curl https://brkmn.example.org/api/v1/urls \
  -H "Authorization: Bearer $BRKMN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": {"to": "https://example.org/a/very/long/page", "shortened": "spring-report"}}'
```

#### JavaScript

```javascript
const response = await fetch("https://brkmn.example.org/api/v1/urls", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${process.env.BRKMN_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    url: { to: "https://example.org/a/very/long/page", shortened: "spring-report" },
  }),
});
const { url } = await response.json();
console.log(url.short_url);
```

#### Python

```python
response = requests.post(
    "https://brkmn.example.org/api/v1/urls",
    headers={"Authorization": f"Bearer {os.environ['BRKMN_TOKEN']}"},
    json={"url": {"to": "https://example.org/a/very/long/page", "shortened": "spring-report"}},
)
print(response.json()["url"]["short_url"])
```

Leave out `shortened` to get a random six-letter code.

## Endpoints

| Method | Path | What it does | Token access |
| --- | --- | --- | --- |
| `GET` | `/api/v1/me` | Shows the token's account and details | Any |
| `GET` | `/api/v1/urls` | Lists URLs | Any |
| `GET` | `/api/v1/urls/{id}` | Gets one URL | Any |
| `POST` | `/api/v1/urls` | Creates a URL | Read & write |
| `PATCH` | `/api/v1/urls/{id}` | Changes a URL's destination | Read & write |
| `DELETE` | `/api/v1/urls/{id}` | Deletes a URL | Read & write |
| `GET` | `/api/v1/urls/{id}/qr` | Gets the QR code as a PNG image | Any |

`PUT` works the same as `PATCH`.

## Conventions

* **Times** are ISO 8601 in UTC, for example `2026-11-18T09:17:42.000Z`.
* **IDs** are integers.
* **Lists** are paginated. See [Listing URLs](urls.md#list-urls).
* **Errors** always have the same shape. See [Errors](errors.md).
* **Rate limits** apply per token. See [Rate limits](rate-limits.md).
