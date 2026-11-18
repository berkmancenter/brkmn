# Tokens for external users

Superadmins can see every API token on the site, revoke any of them, and give API access to people who can't sign in to brkmn, such as partners or contractors.

Click **Settings** at the top right of any page, then open **All tokens**. Only superadmins see the **All tokens** and **External users** tabs.

## The token list

The list shows every token on the site, newest first, 50 per page.

| Column | Shows |
| --- | --- |
| **User** | The account's email. **External** marks API-only accounts created for external users. |
| **Token** | The token's name, its first characters, and any note |
| **Access** | Read-only or Read & write |
| **Status** | **Active**, **Awaiting collection** (with when the link expires), **Link expired**, **Expired**, or **Revoked** (with who revoked it and when) |
| **Created** | When it was created, and by whom if a superadmin created it for someone else |
| **Last used** | When it was last used (updated at most every 5 minutes) |
| **Expires** | When it stops working. For tokens not yet collected: how long it will last once collected. |

### Filters

* **Search** matches the user's email, the token's name or note, and the token's first characters. Use it to find the token behind a leaked value: search for its first 12 characters, such as `brkmn_a1B2c3`.
* **Status:** Active, Awaiting collection, Expired, or Revoked.
* **User type:** **Internal** (regular brkmn accounts) or **External (API-only)**.

## Create a token for an external user

1. Open **Settings**, then the **External users** tab.
2. Fill in:
   * **Email address:** where the token will be sent. It must not belong to any brkmn account yet.
   * **Token name:** what the token is for, such as `Partner newsletter integration`.
   * **Note / purpose:** optional. It's included in the email and shown in the token list.
   * **Access:** **Read-only** (the default) or **Read & write**.
   * **Expires after:** 7, 30, 90 (the default), 180, or 365 days. External tokens always expire.
3. Click **Create and send email**.

brkmn then:

* creates an **API-only account** for the email address. It can't sign in to the website, and it never gets password reset emails.
* creates the token, which shows as **Awaiting collection** in the list.
* emails the person a **single-use link** to collect the token. The link expires after 72 hours. The email is sent by the background job queue, usually within a few seconds.

The token's lifetime starts when the person collects it, not when you create it. You never see the token's value, and it is never sent by email. What the person sees is described in [Collecting a token you were sent](collecting-a-token.md).

### When the email address already has an account

brkmn refuses to create the token and tells you why:

* **The address belongs to a regular account.** That person can sign in and create their own token under **Settings → API tokens**.
* **The address already has external API access.** Use **Send new link** on their existing token instead.

## Send new link

**Send new link** appears next to external users' tokens that haven't been revoked. It emails the person a fresh 72-hour link. Use it when:

* their link expired before they used it
* they lost their token
* their token expired
* their token may have leaked

> **Warning:** Sending a new link stops the current token value working straight away. Any app using it gets `401` errors until the person collects the new token and updates the app.

The token keeps its name, note, and access level. Its lifetime starts again when the new link is used.

If the email can't be queued (for example, the job queue is down), brkmn says so. Try **Send new link** again later.

## Revoke a token

Click **Revoke** next to any token, internal or external, to switch it off permanently. Revoked tokens stay in the list with who revoked them and when.

Regular users regenerate their own tokens under **Settings → API tokens**. Superadmins can't regenerate other people's tokens, because that would show them the new value.

## When an external user signs in through single sign-on

If someone with an API-only account later signs in through your single sign-on (CAS, SAML, or an authenticating proxy) with the same email address, their account becomes a regular one. Their tokens keep working, and the **External** badge disappears.
