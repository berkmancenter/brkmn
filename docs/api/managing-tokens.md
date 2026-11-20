# Managing your tokens

Anyone who can sign in to brkmn can create API tokens for their own account. Click **Settings** at the top right of any page, then open the **API tokens** tab.

## Create a token

1. Under **Create a token**, fill in:
   * **Name:** what the token is for, such as `Zapier` or `CI script`. You'll see this name in the token list.
   * **Access:** **Read-only** (the default) or **Read & write**. See [Access levels](authentication.md#access-levels).
   * **Expires after:** 7, 30, 90 (the default), 180, or 365 days, or **No expiration**.
2. Click **Create token**.
3. Copy the token with the **Copy** button and store it somewhere safe, such as a password manager.

> **Warning:** The token is shown **only once**. If you leave or reload the page without copying it, regenerate the token to get a new value.

The page also shows a `curl` command you can run to check that the token works.

Create a separate token for each app or script. That way you can revoke one without breaking the others.

## Your token list

| Column | Shows |
| --- | --- |
| **Name** | The name you gave the token |
| **Token** | The first characters of the token, such as `brkmn_a1B2c3…`, so you can tell which one an app uses |
| **Access** | Read-only or Read & write |
| **Status** | **Active**, **Expired**, or **Revoked** (with who revoked it and when) |
| **Created** | When the token was created |
| **Last used** | When the token was last used (updated at most every 5 minutes), or **Never** |
| **Expires** | When it stops working, or **Never** |

## Regenerate a token

Click **Regenerate** to replace a token's value, for example if it may have leaked or it has expired.

* The old value stops working straight away. Update every app that uses it.
* The new value is shown once, like a new token.
* The name and access level stay the same, and the expiry starts again from today with the same length (for example, 90 more days).

## Revoke a token

Click **Revoke** to switch a token off permanently. Apps using it get `401` errors from then on.

Revoked tokens stay in the list, marked with who revoked them and when, but they can't be used or regenerated again. Create a new token if you need one.

> **Note:** Superadmins can see and revoke every token on the site, including yours. They can never see a token's value.
