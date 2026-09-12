# StyleDrop Privacy Policy

> **⚠️ TEMPLATE — ACTION REQUIRED BEFORE PUBLISHING**
> 1. Replace every `[BRACKETED]` value (contact email, company name, URL).
> 2. **Verify the proxy retention claim** against your actual deployed
>    Cloudflare Worker/Pages code (it must not log or persist request bodies).
> 3. Host this policy at a **public URL** (e.g. GitHub Pages or your website)
>    and paste that URL into Play Console → App content → Privacy policy.
> Last updated: September 12, 2026 · Version 1.0

StyleDrop ("we", "us", "our") is an AI wardrobe stylist app for Android and
iOS. This policy explains what data the app collects, why, and the choices
you have. By using StyleDrop you agree to this policy.

## Who we are

[COMPANY / DEVELOPER NAME]
Contact: [PRIVACY@EMAIL] · [WEBSITE URL]

## Data we collect

### 1. Account data (Firebase Authentication)
When you sign in with Google, Apple, Email/Password, or continue as a Guest,
Google Firebase Authentication processes your name, email address, profile
photo URL, and a unique user ID. Guest (anonymous) sessions are tied to a
random ID with no personal details.

### 2. Wardrobe and outfit data (Cloud Firestore)
The items you add (category, type, color, style, fit, brand, wear counts),
outfits you save or plan, and your style preferences ("Style DNA") are stored
in Google Cloud Firestore. Documents are namespaced under your user ID and
protected by security rules that allow only you to read or write your own
data. Photos are **not** uploaded to Firestore — only lightweight metadata.

### 3. Photos you take or choose (AI clothing detection)
If you add a wardrobe item with a photo, the photo is sent over an encrypted
connection to our processing service (a Cloudflare-hosted endpoint) to
automatically detect its category, color, and style attributes. The photo is
forwarded to an AI vision provider (OpenAI) solely to generate those
attributes. Photos are processed on servers in the EU with **no data
retention** — they are not stored after the analysis response is returned,
and they are never shared with anyone else. If AI detection is unavailable,
the app uses a local fallback and your photo never leaves your device.

### 4. Location (weather feature, optional)
To give weather-aware outfit recommendations, the app may request your device
location (coarse or fine, your choice at the OS permission prompt). Your
coordinates are sent only to the Open-Meteo weather API to fetch the current
forecast and city name for display. We do not store, log, or otherwise
process your location, and you can deny the permission — the app then uses a
non-personal simulated reading.

### 5. Data stored on your device
Your wardrobe library, outfits, preferences, theme choice, and usage counters
are cached locally on your device (Hive / app storage). Local notifications
(reminders and rain alerts) are scheduled on-device; we do not send push
notifications.

### 6. Automatic data
The app does not include analytics or advertising SDKs. The app's interface
fonts are provided by the Google Fonts service, which may receive your IP
address when the font files are downloaded.

## How we use data

- Provide the app: sign-in, wardrobe catalog, outfit generation, cross-device
  sync, weather-based recommendations.
- Improve results: AI-detected item attributes feed better outfit suggestions.
- We do **not** sell personal data or use it for advertising.

## What we share

| Provider | Purpose | Data involved |
|---|---|---|
| Google Firebase (Auth, Firestore) | Accounts & cloud sync | Name, email, photo URL, wardrobe metadata |
| Cloudflare (our proxy endpoint) | Secure AI detection relay | Photo bytes (transient) |
| OpenAI (via proxy) | Vision analysis of your photo | Photo bytes (transient) |
| Open-Meteo | Weather + city name | Coordinates (query only, not stored by us) |
| Apple / Google | Social sign-in | Account identity tokens |

## Data retention and deletion

- Your cloud data persists while your account exists, so it can sync across
  your devices.
- **Delete everything at any time** from inside the app:
  **Profile → Delete account**. This permanently removes your Firebase Auth
  account, your Firestore documents (wardrobe, outfits, profile), and the
  local cache on the device. This cannot be undone.
- You can also request deletion by emailing [PRIVACY@EMAIL] from the address
  associated with your account; we will complete the request within 30 days.
- Photos sent for AI detection are not retained after analysis.
- Guest data lives only on your device; clearing app data or deleting your
  guest account removes it entirely.

## Your rights

Depending on your region (e.g. GDPR, Philippine Data Privacy Act of 2012),
you may have rights to access, correct, export, or delete your personal data,
and to object to or restrict processing. Email [PRIVACY@EMAIL] to exercise
them.

## Children

StyleDrop is not directed at children under 13 (or the equivalent minimum age
in your jurisdiction), and we do not knowingly collect their data. The Play
Console target-audience setting for this app excludes young children.

## Security

Data is encrypted in transit (TLS). Cloud data is protected by per-user
Firestore security rules. We never embed sensitive API keys in the app
binary — AI requests go through our server-side proxy.

## Changes to this policy

We will update this page and the "last updated" date when the policy changes.
Material changes will also be announced in the app where practical.
