# Collecting a token you were sent

If you don't have an account on the brkmn website, a brkmn administrator can set up API access for your email address. Here's how to collect your token.

## 1. Find the email

Look for an email with the subject **"Your <site> API access token"**. It tells you:

* who set up your access
* the token's name and access level (**Read-only** or **Read & write**)
* how long the token will last once you collect it
* any note the administrator added about what the token is for

The email does not contain the token itself, only a link to collect it.

## 2. Open the link within 72 hours

Click **Get your API token**. The page shows your token's details and a **Show my token** button.

Opening the link doesn't use it up, so it's safe if your email system checks links before you open them.

## 3. Show and copy the token

Click **Show my token**, then copy the token with the **Copy** button and store it somewhere safe, such as a password manager or your platform's secret store.

> **Warning:** The token is shown **only once**, and the link stops working as soon as you click the button. If you lose the token, ask the administrator who set up your access to send you a new link.

The page also shows a `curl` command you can run to check that the token works. Then head to the [Quick start](README.md#quick-start).

## If the link doesn't work

| The page says | What it means | What to do |
| --- | --- | --- |
| "This link expired on …" | More than 72 hours have passed | Ask the administrator to send a new link. |
| "This link is invalid or has already been used" | The token was already collected, or a newer link was sent | Use the token you collected, or ask for a new link. |

## About your account

Your account can use the API only. It can't sign in to the brkmn website: trying shows "This account can only use the API".

If your organization later gives you access to brkmn through single sign-on with the same email address, your account becomes a regular one, and your token keeps working.
