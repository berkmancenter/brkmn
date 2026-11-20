# brkmn documentation

brkmn is a shared URL shortener. Signed-in users can create and manage short
links, inspect click counts, collaborate on link destinations, and use the same
features from a token-authenticated JSON API.

## Guides

- [Application functionality](app-functionality.md) describes the website,
  roles and permissions, link lifecycle, sharing workflow, account access, and
  API-token administration.
- [API documentation](api/README.md) is the starting point for API clients. It
  includes authentication, endpoint, error, rate-limit, token-management, and
  server-configuration guides.
- [OpenAPI specification](api/openapi.yaml) is the machine-readable API v1
  contract.

## Audience

| If you want to... | Start with... |
| --- | --- |
| Shorten and manage links in the website | [Managing links](app-functionality.md#managing-links) |
| Let another user edit a link | [Sharing and access requests](app-functionality.md#sharing-and-access-requests) |
| Understand what each role can do | [Roles and permissions](app-functionality.md#roles-and-permissions) |
| Create or manage an API token | [API tokens](app-functionality.md#api-tokens) |
| Integrate a script or application | [API quick start](api/README.md#quick-start) |
| Give an external user API access | [Tokens for external users](api/external-users.md) |
| Configure the API in production | [API server configuration](api/configuration.md) |
