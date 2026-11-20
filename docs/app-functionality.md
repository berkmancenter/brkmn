# Application functionality

brkmn turns long HTTP or HTTPS destinations into short, shareable links. It is
also a shared directory of links: authenticated users can browse destinations
and click counts, owners can delegate editing, and superadmins can manage the
whole installation.

## Roles and permissions

The website distinguishes visitors, signed-in users, editors, link owners, and
superadmins.

| Capability | Visitor | Signed-in user | Editor | Owner | Superadmin |
| --- | --- | --- | --- | --- | --- |
| Follow a short link | Yes | Yes | Yes | Yes | Yes |
| Browse destinations and click counts | No | Yes | Yes | Yes | Yes |
| Create a link | No | Yes | Yes | Yes | Yes |
| Open a link's QR code | No | Yes | Yes | Yes | Yes |
| Request edit access | No | Yes | Already has access | Already has access | Already has access |
| Change the destination | No | No | Yes | Yes | Yes |
| Delete the link | No | No | No | Yes | Yes |
| Share or remove edit access | No | No | No | Yes | Yes |
| Resolve access requests | No | No | No | Yes | Yes |
| Manage every API token | No | No | No | No | Yes |

An **editor** is a user to whom the owner has granted edit access. Editing does
not transfer ownership and does not grant permission to delete or reshare the
link. A superadmin can manage links belonging to any user.

## Following short links

A short link is public and does not require an account. Visiting
`https://<brkmn-host>/<short-code>` redirects to its saved destination and
increments its click count. Concurrent visits are counted atomically.

An unknown code returns a not-found page instead of redirecting. Deleting a
link makes its old short URL return that page immediately.

## Managing links

The main page is available to authenticated users and has a creation form plus
two independently paginated lists:

- **My URLs** contains links the current user owns and links shared with them
  as an editor.
- **All URLs** contains the other links in the installation.

Each row shows the short code, destination, creation time, and click count. The
row actions let an eligible user copy the short URL, open its QR code, edit or
delete the link, and open sharing and activity details.

### Create a link

Enter a destination and, optionally, a custom short code.

- A destination must be an HTTP or HTTPS URL with a host and may be up to 10 KB.
- If the scheme is omitted, brkmn adds `https://`.
- Surrounding spaces and duplicate leading HTTP/HTTPS schemes are normalized.
- Destinations pointing to `localhost` or the configured brkmn short domain are
  rejected to avoid unsafe or recursive redirects.
- A blank short code produces a random six-letter uppercase code.
- A custom code is case-sensitive and must be unique. It may use letters,
  digits, `-`, `_`, `.`, and `*`, and it cannot conflict with an application
  route or public file.

The user who creates the link becomes its owner.

### Search, sort, and paginate

Search matches the short code or destination without regard to letter case and
filters both lists. It treats `%` and `_` as ordinary text rather than wildcard
characters.

Both lists share the selected sort column and direction. Links can be sorted by
short code, destination, creation time, or clicks. Each list keeps its own page,
so paging through one does not move the other. Page, sort, and scroll state are
preserved across normal edit and delete workflows.

### Edit a link

Owners, editors, and superadmins can change a destination. The short code stays
fixed so previously shared links continue to work. brkmn records who made the
latest destination change and when; this activity is visible in the details
dialog to users who can edit the link.

The website opens the edit form in a dialog when JavaScript is available and
has a regular edit page as a fallback. Validation errors leave the saved
destination unchanged.

### Delete a link

Only the owner or a superadmin can delete a link. The website asks for
confirmation first. Deletion also removes its collaborator and access-request
records.

### Copy and QR code

The copy action writes the full short URL to the browser clipboard. The QR
action opens an approximately 400 by 400 pixel PNG that encodes the same short
URL.

### Bookmarklet

The **Shorten on &lt;host&gt;** link in the header can be dragged to the browser's
bookmarks toolbar. Running it from another page opens brkmn with that page's URL
already filled into the creation form. The user must be signed in to complete
the action.

## Sharing and access requests

The sharing and details dialog is the center of the collaboration workflow.

### Grant edit access

An owner or superadmin can enter the email address of an existing brkmn user.
Granting access:

- adds the link to the editor's **My URLs** list;
- lets the editor change the destination but not the short code;
- sends the editor an email notification; and
- approves any existing access request from that user.

An address without an existing account cannot be added as an editor.

### Remove edit access

An owner or superadmin can remove an editor. The user loses edit permission and
receives an email notification. Any pending request from the same user is
denied.

### Request edit access

A signed-in user who cannot edit a link can request access from its details
dialog. The owner receives an email and can approve or deny the request.

- Approval grants editor access and emails the requester.
- Denial emails the requester without granting access.
- A pending request is not sent twice.
- After a denial, the requester must wait 24 hours before asking again.

Only an owner or superadmin can resolve requests; requesters cannot approve
their own request.

## Accounts and sign-in

An installation selects one website authentication mode with
`DEVISE_AUTH_TYPE`.

| Mode | Behavior |
| --- | --- |
| `db` | Email/password registration, email confirmation, password reset, remember-me, and email unlock workflows. |
| `cas` | CAS single sign-on; users are created when they first authenticate. Signing out also signs out from CAS. |
| `saml` | SAML single sign-on; user attributes are mapped from the assertion and access can optionally require group membership. |
| `headers` | A trusted authenticating proxy supplies `X-Auth-Email` and `X-Auth-Name` on every website request. No website sign-out link is shown. |

In database mode, passwords must contain at least 12 characters. An account is
locked after 10 failed attempts and can be unlocked by email or automatically
after one hour. Authentication form submissions are also rate-limited to 10
attempts in three minutes.

API-only accounts created for external integrations cannot sign in to the
website or request a password reset. If the same person later authenticates
through CAS, SAML, or a trusted header proxy, the account becomes a regular
website account without invalidating its API tokens.

## API tokens

Every signed-in user can open **Settings → API tokens** and create tokens for
their own account.

- Tokens can be **Read-only** or **Read & write**.
- A token can expire after 7, 30, 90, 180, or 365 days, or have no expiration.
- The plaintext value is shown once. brkmn stores a SHA-256 fingerprint, not
  the recoverable secret.
- Regenerating a token invalidates the old value and restarts its configured
  lifetime.
- Revoking a token disables it permanently.
- The token list shows its prefix, status, creation and last-use times, and
  expiry.

Read & write controls what the token may attempt; the account's normal link
permissions still apply. For example, an editor with a read & write token can
change a shared link but cannot delete it.

### Superadmin token management

Superadmins have two additional settings pages:

- **All tokens** lists every token, with search and filters for status and user
  type. A superadmin can revoke any token but cannot reveal its value.
- **External users** creates an API-only account and emails a single-use token
  claim link to a person who cannot sign in to the website.

An external claim link expires after 72 hours. Opening it does not consume it;
the recipient must press the reveal button. The API token's lifetime begins
when it is collected. Sending a new claim link immediately invalidates any
current token value.

See the [API documentation](api/README.md) for token handling and integration
details, and [tokens for external users](api/external-users.md) for the full
administrative workflow.

## JSON API

The versioned JSON API under `/api/v1` supports:

- checking the account and token with `GET /api/v1/me`;
- listing and searching links;
- reading, creating, updating, and deleting links; and
- downloading short-link QR codes.

API requests use `Authorization: Bearer <token>` and do not use website cookies.
Read operations accept either token access level. Mutations require a read &
write token and the corresponding account permission. Requests are rate-limited
per token; the default is 300 requests per five-minute fixed window.

Start with the [API quick start](api/README.md#quick-start), or use the
[OpenAPI specification](api/openapi.yaml).

## Interface preferences and operational endpoints

- Users can switch between the modern and classic themes. The choice is kept
  in a browser cookie for one year.
- On screens narrower than 1152 pixels the header shows only **Search** and a
  **Menu** button. The menu holds the signed-in email, the bookmarklet, the
  theme switch, **Settings** and **Sign out**.
- The application publishes a web app manifest and icon metadata for browsers.
- `GET /up` is a health endpoint for load balancers and uptime checks. It
  returns success when Rails boots normally.
- When Sidekiq's web interface is enabled, it is mounted at `/sidekiq`; access
  to that operational interface should be restricted by the deployment.
