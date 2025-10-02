# Ana Bas (Anabas)

Simple offline Flutter app that shows **today's sessions**, **tasks**, and a **quote banner**.
Designed for a single phone (no cloud), Dark Mode, package name `com.franco.anabas`.

## What I included
- `lib/main.dart` — main app source (Dark UI, Banner + Tabs)
- `pubspec.yaml` — dependencies (shared_preferences)
- `.github/workflows/flutter-build.yml` — GitHub Actions workflow to auto-build APK

## How to use (push to GitHub & get APK via Actions)
1. Create a new GitHub repository (public or private).
2. Upload all files in this ZIP to the repository root (keep the `.github` folder).
3. Push to `main` branch.
4. Go to **Actions** tab in the repo → select **Flutter APK Build** workflow → click **Run workflow** (or push to main).
5. After the workflow finishes, download the artifact `anabas-apk`.

> The workflow runs `flutter create --org com.franco.anabas .` to ensure Android folder exists and the package name is set to `com.franco.anabas`.

## If you want me to also:
- Generate an APK for you and upload here, say `Build for me` — I'll build and provide the APK file.
- Change label texts to Franco or customize branding — tell me the texts.

## Notes
- The workflow uses Flutter action to install Flutter on runner — no need for you to install Flutter locally.
- If you prefer CI that automatically signs the APK, we can add signing keys (requires secure storage of keystore).

Enjoy — Ana Bas 👣