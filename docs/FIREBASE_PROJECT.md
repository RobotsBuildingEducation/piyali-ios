# Piyali's independent Firebase project

Provisioned on 2026-10-12 after the user selected a separate Firebase project.

| Resource | Value |
| --- | --- |
| Project name | Piyali |
| Project ID | `piyali-ios` |
| Project number | `861709486546` |
| iOS app | Piyali iPhone |
| Bundle ID | `app.piyali.ios` |
| Firebase iOS App ID | `1:861709486546:ios:edbba9ce75380765bc200b` |
| Firestore database | `(default)` |
| Firestore location | `us-central1` |
| Firestore edition | Standard, native mode, free-tier database |

Open [Firebase Console](https://console.firebase.google.com/project/piyali-ios/overview).

The downloaded iOS configuration is stored locally at `Piyali/Resources/GoogleService-Info.plist`, is gitignored, and is copied into local builds conditionally. The committed Xcode project has no file reference requiring that private local file, so a fresh clone can build offline without it. To download it on another developer machine:

```sh
firebase apps:sdkconfig IOS '1:861709486546:ios:edbba9ce75380765bc200b' \
  --project piyali-ios --out Piyali/Resources/GoogleService-Info.plist
```

Verified with Firebase CLI: the project and registered app are active, and Firestore exists in the listed location. An unauthenticated Firestore REST read returns HTTP 403. No client data was copied from the web project, and its resources and repository were not changed. No billing account, paid API, production rule release or Cloudflare deployment was added in this provisioning step.

Remaining integration work: Firebase authentication bound to the learner's Nostr key, production Firestore rules/indexes, App Check registration, AI Logic provider setup and a Cloudflare worker configured for this project's issuer/audience. The old web worker validates the old Firebase project, so it cannot serve as this project's configured native backend without additional work. Current emulator tests exercise the shared document schemas independently of this production setup.

The main app's web subscription link still points to `piyali.app/subscribe`. Subscription API integration and any dedicated web payment page must be verified for the new backend before claiming live access. StoreKit products and Apple signing setup remain separate requirements.
