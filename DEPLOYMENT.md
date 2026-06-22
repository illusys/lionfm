# Lion FM — Deployment Guide

## Hosting

Production is served from **Vercel** at `https://www.lionfm.online`.  
All cache-control rules, build commands, and SPA rewrites live in **`vercel.json`**.

Firebase is used for backend services only (Auth, Firestore, Storage, Cloud Functions).  
Firebase Hosting is **not** enabled — do not run `firebase deploy --only hosting`.

---

## Production Build Command

```bash
flutter build web --release \
  --pwa-strategy=none \
  --dart-define=PAYSTACK_PUBLIC_KEY=pk_live_... \
  --dart-define=GOOGLE_WEB_CLIENT_ID=748866798356-l2d6q36gp1444loj06jujj0rgkf5aati.apps.googleusercontent.com \
  --dart-define=STREAM_BASE_URL=https://stream.lionfm.online \
  --dart-define=API_BASE_URL=https://api.lionfm.online
```

### Flag reference

| Flag | Purpose |
|---|---|
| `--release` | Minified, tree-shaken output |
| `--pwa-strategy=none` | **Disables the service worker entirely.** Without this, Flutter's offline-first service worker caches `main.dart.js` aggressively and users see stale builds after a deploy. |
| `--dart-define=GOOGLE_WEB_CLIENT_ID` | Google OAuth 2.0 Web Client ID injected into `AppConfig.googleWebClientId`. A hardcoded fallback is already set in `app_config.dart`; this flag lets you rotate the key without a code change. |
| `--dart-define=PAYSTACK_PUBLIC_KEY` | Live Paystack public key (`pk_live_…`). Use `pk_test_…` for staging. |
| `--dart-define=STREAM_BASE_URL` | Base URL of the ICEcast / Icecast-KH stream server. |
| `--dart-define=API_BASE_URL` | Base URL of any REST API endpoints. |

---

## Cache-Control Strategy

Defined in `vercel.json`. Rules are evaluated in order; later rules for the same path override earlier ones.

| Resource | Cache-Control | Reason |
|---|---|---|
| `index.html` | `no-cache, no-store, must-revalidate` | Entry point — must always return the latest version so browsers pick up new builds immediately |
| `flutter.js` | `no-cache, no-store, must-revalidate` | Flutter engine loader — version-sensitive |
| `flutter_bootstrap.js` | `no-cache, no-store, must-revalidate` | Bootstrap entry — version-sensitive |
| `flutter_service_worker.js` | `no-cache, no-store, must-revalidate` | Moot when `--pwa-strategy=none` is used but kept as a safety net |
| `version.json` | `no-cache, no-store, must-revalidate` | Flutter reads this to detect app updates |
| `manifest.json` | `no-cache, no-store, must-revalidate` | PWA manifest — must reflect latest icon/name changes |
| `assets/**` | `public, max-age=31536000, immutable` | Content-hashed at build time — safe to cache forever |
| `fonts/**` | `public, max-age=31536000, immutable` | Same as assets |

---

## Continuous Deployment

Every push to `main` triggers a Vercel production deployment automatically.  
No manual deploy step is needed — merge to `main` = ship.

### Vercel environment variables

Set these in the Vercel dashboard under **Settings → Environment Variables**:

| Variable | Example value |
|---|---|
| `PAYSTACK_PUBLIC_KEY` | `pk_live_xxxxxxxxxxxxxxxxxxxx` |
| `GOOGLE_WEB_CLIENT_ID` | `748866798356-l2d6q36gp1444loj06jujj0rgkf5aati.apps.googleusercontent.com` |
| `STREAM_BASE_URL` | `https://stream.lionfm.online` |
| `API_BASE_URL` | `https://api.lionfm.online` |

> The `GOOGLE_WEB_CLIENT_ID` variable is optional — the client ID is already hardcoded as the `defaultValue` in `AppConfig.googleWebClientId` and in `web/index.html`. Set it here only if you need to rotate the key without a code deploy.

---

## Firebase Backend

```bash
# Deploy Firestore rules + indexes
firebase deploy --only firestore

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy everything except hosting
firebase deploy --only firestore,functions
```

---

## Pre-deploy checklist

- [ ] `flutter analyze` reports 0 issues
- [ ] Paystack keys are set to `pk_live_…` (not `pk_test_…`)
- [ ] `GOOGLE_WEB_CLIENT_ID` environment variable is set in Vercel (or fallback is current)
- [ ] `stream_config/current.streamUrl` is set in Firestore
- [ ] `admin_config/payments.publicKey` is set in Firestore
