# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Analyze (must be 0 issues before any commit or deploy)
flutter analyze

# Web release build (standard)
flutter build web --release \
  --pwa-strategy=none \
  --dart-define=GOOGLE_WEB_CLIENT_ID=748866798356-l2d6q36gp1444loj06jujj0rgkf5aati.apps.googleusercontent.com

# Web release build with all runtime flags
flutter build web --release \
  --pwa-strategy=none \
  --dart-define=PAYSTACK_PUBLIC_KEY=pk_live_... \
  --dart-define=GOOGLE_WEB_CLIENT_ID=748866798356-... \
  --dart-define=STREAM_BASE_URL=https://stream.lionfm.online \
  --dart-define=API_BASE_URL=https://api.lionfm.online

# Android signed release APK (requires android/key.properties)
flutter build apk --release

# Run tests
flutter test
flutter test test/request_model_test.dart   # single test file

# Firebase backend deploy
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions
firebase deploy --only firestore,functions   # both at once

# Paystack secret (Cloud Functions only — never in app code)
firebase functions:config:set paystack.secret="sk_test_..."
```

`--pwa-strategy=none` is mandatory for web builds. Flutter's offline-first service worker caches `main.dart.js` aggressively and causes users to see stale builds.

## Architecture

### Dual-audience app in one Flutter project

There are two completely separate user experiences, each with its own GoRouter `ShellRoute`:

- **Listener shell** (`AppShell`) — bottom nav bar, `/` through `/events`. Public-facing radio app.
- **Admin shell** (`AdminShell`) — sidebar nav, `/admin/**`. Station management portal. Reached by long-pressing "About Lion FM" in Settings → navigates to `/admin-login`.

Both shells live in `lib/core/navigation/app_router.dart`. The router's `redirect` guard reads `adminUserProvider` and redirects unauthenticated admin routes to `/admin-login`.

### State management (Riverpod)

All providers are in `lib/providers/`. Key providers:

- `audioHandlerProvider` — singleton `LionFMAudioHandler`; all playback goes through it. Do **not** create raw `AudioPlayer` instances anywhere else.
- `adminUserProvider` — `StreamProvider<AdminUser?>` that watches Firebase Auth + reads the `users` Firestore doc for role. Also drives the GoRouter refresh notifier.
- `liveStreamUrlProvider` — `StreamProvider<String>` watching `stream_config/current.streamUrl` in Firestore. The stream URL is Firestore-controlled, not hardcoded.
- `authStateProvider` — listener-side Firebase Auth state (separate from admin auth).

### Audio pipeline

`lib/data/services/audio_service.dart` — `LionFMAudioHandler` is the single audio pipeline. It handles three source types (`liveRadio`, `podcast`, `ad`) and transitions between them (preroll ad → episode). All `AudioPlayer.setAudioSource()` calls must include a `tag: MediaItem(...)` because `just_audio_background` (Android/iOS lock screen controls) asserts its presence. Use `AudioSource.uri(Uri.parse(url), tag: MediaItem(...))` — never `_player.setUrl(url)` directly.

### Two auth systems

1. **Listener auth** — standard Firebase Auth (Google, email, Apple, Facebook). Managed by `AuthService` + `authStateProvider`. Listeners can use the app as guests (`isGuestModeProvider = true`).
2. **Admin auth** — Firebase Auth sign-in + role lookup in `users/{uid}.role`. Role enum: `superAdmin > stationManager > broadcaster > unnAdmin`. Managed by `adminUserProvider`. The `users` collection is the source of truth; `admin_invites/{email}` drives onboarding via `onAdminUserCreate` Cloud Function.

### Firestore collections

Tenant-scoped (station data): `shows`, `podcasts`, `podcast_feeds`, `news`, `requests`, `ads`, `events`, `tickets`, `chat_messages`, `chat_config`, `banned_users`, `notification_queue`, `analytics`, `admin_config`.

Global: `users`, `mail`, `stream_config`, `revenue`, `payment_attempts`, `admin_audit_logs`, `admin_invites`.

Rules are in `firestore.rules`. Helper functions (`isSuperAdmin()`, `isStationManager()`, `isBroadcaster()`) gate writes; most public collections allow unrestricted reads.

### Cloud Functions (`functions/index.js`, Node 18)

- `sendNotification` — Firestore trigger on `notification_queue/{docId}`, sends FCM.
- `onAdminUserCreate` — Auth trigger, wires role from `admin_invites` into `users/{uid}` on first sign-in.
- `getAdminBootstrapStatus` — callable; returns `{ needsFirstTimeSetup }` for first-run flow.
- `initPaystackTransaction` / `verifyPaystackPayment` / `paystackWebhook` — Paystack payment flow. Secret key lives only in Functions config (`paystack.secret`), never in the app.

### Hosting + CI

Hosted on **Vercel** at `lionfm.online`. Firebase Hosting is **not** used — never run `firebase deploy --only hosting`. Every push to `main` triggers a Vercel production deploy automatically. Build script for CI is `build.sh` (downloads pinned Flutter, builds web).

Runtime flags (`PAYSTACK_PUBLIC_KEY`, `GOOGLE_WEB_CLIENT_ID`, `STREAM_BASE_URL`, `API_BASE_URL`) are injected as `--dart-define` at build time and read from `lib/core/constants/app_config.dart`. The Google Web Client ID has a hardcoded fallback so local builds work without the flag.

### Design system

Colors: `lib/core/constants/app_colors.dart` — Midnight Gold palette. Primary accent `lionGold (#F5A623)`, surfaces `bg0–bg4` (warm dark scale). Many legacy aliases exist for backwards compatibility; prefer the canonical names (`bg0`, `lionGold`, etc.).

Theme: `AppTheme.dark` in `lib/core/theme/app_theme.dart` — single static dark theme applied globally. Material 3, Google Fonts (Inter + Space Grotesk).

### Android release signing

`android/key.properties` (git-ignored) points to `/Users/benedictbassey/lionfm-upload-keystore.jks`. The `build.gradle` signing config reads from this file; if it doesn't exist the release config silently skips signing.
