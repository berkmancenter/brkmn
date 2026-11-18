# URLs

## The URL object

Every endpoint that returns URLs uses this shape:

```json
{
  "id": 123,
  "shortened": "spring-report",
  "short_url": "https://brkmn.example.org/spring-report",
  "to": "https://example.org/a/very/long/page",
  "auto_generated": false,
  "clicks": 57,
  "qr_code_url": "https://brkmn.example.org/api/v1/urls/123/qr",
  "owner": { "id": 42, "email": "you@example.org" },
  "owned_by_you": true,
  "permissions": { "update": true, "destroy": true },
  "last_edited_by": { "id": 42, "email": "you@example.org" },
  "last_edited_at": "2026-11-18T10:02:11.000Z",
  "created_at": "2026-11-18T09:30:00.000Z",
  "updated_at": "2026-11-18T10:02:11.000Z"
}
```

| Field | Type | Description |
| --- | --- | --- |
| `id` | integer | Use this in `/api/v1/urls/{id}` paths. |
| `shortened` | string | The short code. |
| `short_url` | string | The full short link to share. |
| `to` | string | The destination the short link redirects to. |
| `auto_generated` | boolean | `true` if brkmn picked the short code, `false` if it was chosen. |
| `clicks` | integer | How many times the short link has been followed. |
| `qr_code_url` | string | API address of the QR code image. See [Get a QR code](#get-a-qr-code). |
| `owner` | object or `null` | The account that created the URL. `null` for old URLs with no owner. |
| `owned_by_you` | boolean | Whether the token's account owns the URL. |
| `permissions.update` | boolean | Whether this token can change the destination. |
| `permissions.destroy` | boolean | Whether this token can delete the URL. |
| `last_edited_by` | object or `null` | Who last changed the destination. |
| `last_edited_at` | string or `null` | When the destination was last changed. |
| `created_at`, `updated_at` | string | Timestamps. |

`permissions` takes both the account's rights and the token's access level into account. For a read-only token, both values are always `false`.

## Who can change a URL

The API uses the same rules as the website:

| | Read | Change destination | Delete |
| --- | --- | --- | --- |
| Owner | Yes | Yes | Yes |
| Editor (someone the owner shared the link with) | Yes | Yes | No |
| Any other account | Yes | No | No |
| Superadmin | Yes | Yes | Yes |

Changes also need a token with **Read & write** access. Anything else gets `403`.

## List URLs

```
GET /api/v1/urls
```

Returns URLs, newest first.

| Query parameter | Default | Description |
| --- | --- | --- |
| `scope` | `mine` | `mine`: URLs you own plus URLs shared with you as an editor. `all`: every URL on the site. |
| `search` | | Only URLs whose short code or destination contains this text (not case-sensitive). |
| `shortened` | | Only the URL with exactly this short code. |
| `page` | `1` | Page number, starting at 1. |
| `per_page` | `25` | URLs per page, from 1 to 100. Larger values are reduced to 100. |

```bash
curl "https://brkmn.example.org/api/v1/urls?search=report&per_page=50" \
  -H "Authorization: Bearer $BRKMN_TOKEN"
```

```json
{
  "urls": [
    { "id": 123, "shortened": "spring-report", "...": "..." }
  ],
  "meta": { "page": 1, "per_page": 50, "total_pages": 1, "total_count": 1 }
}
```

To fetch everything, keep requesting the next `page` until `page` equals `total_pages`. A page past the end returns an empty `urls` list.

> **Note:** To find a URL by its short code, use `?shortened=spring-report`. Add `scope=all` if you don't own it.

| Status | When |
| --- | --- |
| `200` | Success |
| `400` | `scope` is not `mine` or `all`, or `page` is not a positive number |

## Get a URL

```
GET /api/v1/urls/{id}
```

Any token can read any URL, as on the website.

```bash
curl https://brkmn.example.org/api/v1/urls/123 -H "Authorization: Bearer $BRKMN_TOKEN"
```

```json
{ "url": { "id": 123, "shortened": "spring-report", "...": "..." } }
```

| Status | When |
| --- | --- |
| `200` | Success |
| `404` | No URL has this ID |

## Create a URL

```
POST /api/v1/urls
```

Needs a **Read & write** token. The new URL belongs to the token's account.

| Body field | Required | Description |
| --- | --- | --- |
| `url.to` | Yes | The destination. If it has no `http://` or `https://`, brkmn adds `https://`. |
| `url.shortened` | No | Your own short code. Leave it out to get a random six-letter code. |

You can also send the fields without the `url` wrapper, for example `{"to": "https://example.org"}`.

```bash
curl https://brkmn.example.org/api/v1/urls \
  -H "Authorization: Bearer $BRKMN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": {"to": "https://example.org/a/very/long/page", "shortened": "spring-report"}}'
```

The response is `201 Created`, with the new URL in the body and its API address in the `Location` header:

```json
{
  "url": {
    "id": 124,
    "shortened": "spring-report",
    "short_url": "https://brkmn.example.org/spring-report",
    "to": "https://example.org/a/very/long/page",
    "auto_generated": false,
    "clicks": 0,
    "...": "..."
  }
}
```

**Rules for `to`**

* Must be a valid URL, with no spaces.
* Can be up to 10 KB long.
* Can't point to `localhost` or to the brkmn short domain itself.

**Rules for `shortened`**

* Must not already be in use.
* Must not clash with a page on the brkmn site (such as `urls` or `api_tokens`).
* Can only use letters, digits, `-`, `_`, `.`, and `*`. Short codes are case-sensitive.

| Status | When |
| --- | --- |
| `201` | Created |
| `400` | The body has no `url` fields, or is not valid JSON |
| `403` | The token is read-only |
| `422` | A field breaks one of the rules above. See [Validation errors](errors.md#validation-errors). |

## Update a URL

```
PATCH /api/v1/urls/{id}
```

Changes the destination. Needs a **Read & write** token and permission to change the URL (owner, editor, or superadmin).

| Body field | Required | Description |
| --- | --- | --- |
| `url.to` | Yes | The new destination. Same rules as when creating. |

```bash
curl -X PATCH https://brkmn.example.org/api/v1/urls/123 \
  -H "Authorization: Bearer $BRKMN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": {"to": "https://example.org/the/new/page"}}'
```

The response is `200` with the updated URL. `last_edited_by` and `last_edited_at` change only when the destination actually changes.

> **Note:** Short codes can't be changed, because links that are already shared would break. Sending a different `shortened` value returns `422`. To use a new code, create a new URL.

| Status | When |
| --- | --- |
| `200` | Updated |
| `400` | The body has no `url` fields, or is not valid JSON |
| `403` | The token is read-only, or the account can't change this URL |
| `404` | No URL has this ID |
| `422` | The new destination is invalid, or the request tried to change `shortened` |

## Delete a URL

```
DELETE /api/v1/urls/{id}
```

Deletes the URL. The short link stops working straight away. Needs a **Read & write** token, and only the owner or a superadmin can delete. Editors can't.

```bash
curl -X DELETE https://brkmn.example.org/api/v1/urls/123 -H "Authorization: Bearer $BRKMN_TOKEN"
```

| Status | When |
| --- | --- |
| `204` | Deleted. The response has no body. |
| `403` | The token is read-only, or the account can't delete this URL |
| `404` | No URL has this ID |

## Get a QR code

```
GET /api/v1/urls/{id}/qr
```

Returns a PNG image (about 400 × 400 pixels) of a QR code for the URL's `short_url`. Any token can use it.

```bash
curl https://brkmn.example.org/api/v1/urls/123/qr \
  -H "Authorization: Bearer $BRKMN_TOKEN" \
  -o spring-report-qr.png
```

> **Warning:** This endpoint needs the `Authorization` header like every other one. You can't use `qr_code_url` directly as the `src` of an `<img>` tag. Download the image with your token and serve your own copy.

| Status | When |
| --- | --- |
| `200` | The PNG image (`Content-Type: image/png`) |
| `404` | No URL has this ID |
