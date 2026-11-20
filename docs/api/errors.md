# Errors

## Error format

Every error response is JSON with an `error` object:

```json
{
  "error": {
    "code": "insufficient_scope",
    "message": "This token is read-only. Use a read & write token to make changes."
  }
}
```

* `code` is stable and meant for your code to check.
* `message` is for people. Its wording may change.
* `details` appears only on validation errors. See below.

## Status codes

| Status | `error.code` | Meaning | What to do |
| --- | --- | --- | --- |
| `400` | `bad_request` | A parameter is missing or invalid, or the body isn't valid JSON | Fix the request. `message` says what is wrong. |
| `401` | `missing_token` | No token was sent | Send `Authorization: Bearer <token>`. See [Authentication](authentication.md). |
| `401` | `invalid_token` | The token is unknown, revoked, regenerated, or expired | Get a new token or regenerate this one. |
| `403` | `insufficient_scope` | A read-only token tried to make a change | Use a read & write token. |
| `403` | `forbidden` | The account isn't allowed to do this, such as an editor deleting a URL | See [Who can change a URL](urls.md#who-can-change-a-url). |
| `404` | `not_found` | The URL doesn't exist, or the endpoint doesn't exist | Check the ID and the path. |
| `422` | `validation_failed` | The data broke a rule | Fix the fields listed in `details`. |
| `429` | `rate_limited` | Too many requests | Wait for `Retry-After` seconds. See [Rate limits](rate-limits.md). |
| `500` | | Something went wrong on the server | Retry later. If it keeps happening, contact your brkmn administrators. |

## Validation errors

A `422` response lists every problem in `details`, keyed by field name:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "To must be a valid url and Shortened (spring-report) is already in use. Please choose another.",
    "details": {
      "to": ["must be a valid url"],
      "shortened": ["(spring-report) is already in use. Please choose another."]
    }
  }
}
```

Messages you may see:

| Field | Message |
| --- | --- |
| `to` | `can't be blank` |
| `to` | `must be a valid url` |
| `to` | `cannot be 'localhost' or '<short domain>'.` |
| `to` | `is too long (maximum is 10240 characters)` |
| `shortened` | `(<code>) is already in use. Please choose another.` |
| `shortened` | `(<code>) conflicts with a valid site URL. Please choose another.` |
| `shortened` | `contains invalid URL characters.` |
| `shortened` | `can't be changed` (when updating) |
