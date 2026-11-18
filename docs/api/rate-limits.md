# Rate limits

Each token can make a limited number of requests in a fixed time window. By default that is **300 requests every 5 minutes**. Your brkmn site may use different numbers; the response headers always show the real values.

* The limit is per token, not per account or IP address. Two tokens have separate limits.
* Every endpoint counts towards the same limit, including `/api/v1/me`.
* Windows are fixed: the count resets at the time in `X-RateLimit-Reset`, not on a rolling basis.

## Response headers

Successful responses include:

| Header | Meaning |
| --- | --- |
| `X-RateLimit-Limit` | Requests allowed per window |
| `X-RateLimit-Remaining` | Requests left in the current window |
| `X-RateLimit-Reset` | When the window resets, as a Unix timestamp in seconds |

## When you go over the limit

The API answers `429 Too Many Requests` with a `Retry-After` header giving the seconds until the window resets:

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 42
X-RateLimit-Limit: 300
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1795000200
Content-Type: application/json

{"error":{"code":"rate_limited","message":"Rate limit of 300 requests per 300 seconds exceeded. Retry in 42 seconds."}}
```

Wait at least `Retry-After` seconds before sending more requests with that token. For example, in Python:

```python
import time
import requests

def brkmn_get(url, token):
    while True:
        response = requests.get(url, headers={"Authorization": f"Bearer {token}"})
        if response.status_code != 429:
            return response
        time.sleep(int(response.headers.get("Retry-After", "1")))
```

## Staying under the limit

* Use `per_page=100` when listing URLs, so you need fewer requests.
* Find a URL by short code with `?shortened=...` rather than paging through every URL.
* Cache results you have already fetched, instead of asking for them again.
* Watch `X-RateLimit-Remaining` in long-running jobs and slow down before it reaches zero.
