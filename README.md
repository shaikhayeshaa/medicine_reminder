# Meditrake

Meditrake is an offline-first Flutter medicine reminder and dose tracking application. It helps users create treatment schedules, receive local reminder notifications, record Taken / Skipped / Missed doses, snooze individual reminders, review historical dose records, and manage ongoing medicines without requiring a backend connection.

## Core Features

- Dashboard for the selected day's dose occurrences
- Total, Pending, Taken, Missed, and Skipped statistics calculated from individual occurrences
- Medicine search by name, description, and type (case-insensitive)
- Date filtering for daily schedules
- Add medicine with name, description, type, strength, start date, optional end date, and multiple custom doses
- Ongoing medicines with a bounded rolling future schedule
- Pause, resume, stop, edit, and delete medicine flows
- Dedicated reminder screen with Taken, Snooze, and Skip actions
- Snooze options: 5, 10, 15, and 30 minutes
- Local notifications with Android/iOS actions where supported
- Notification sound selection, preview, vibration preference, default snooze, and notifications toggle
- History with date/status filters and search
- Immutable historical medicine snapshots so old records remain correct after edits
- Hive-based local persistence
- Startup/resume recovery for overdue doses and rolling future reminders
- Light/dark Material 3 UI with responsive layouts

## Tech Stack

- Flutter / Dart
- Riverpod for state management
- Hive + hive_flutter for offline persistence
- flutter_local_notifications for reminder scheduling and actions
- timezone + flutter_timezone for local-time scheduling
- go_router for navigation
- audioplayers for reminder sound preview
- intl for date/time formatting
- uuid for IDs

## Architecture

The project follows a feature-first Clean Architecture structure:

```text
lib/
├── app/
│   ├── app.dart
│   ├── app_shell.dart
│   └── router.dart
├── core/
│   ├── constants/
│   ├── presentation/widgets/
│   ├── services/
│   └── theme/
└── features/
    ├── dashboard/
    ├── history/
    ├── medicine/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── recovery/
    ├── reminder/
    └── settings/
```

Business flow:

```text
UI
  ↓
Riverpod state/controller
  ↓
Use case
  ↓
Repository abstraction
  ↓
Hive data source / Notification service
```

Business rules such as occurrence generation, Taken/Skip/Snooze actions, history reconciliation, medicine lifecycle operations, and restart recovery are kept outside UI widgets.

## Hive Data Structure

### Medicine

Stores the medicine definition:

- `id`
- `name`
- `description`
- `type`
- `strength`
- `startDate`
- `endDate` (nullable)
- `doses`
- `isActive`
- `createdAt`
- `updatedAt`

### Dose

Each medicine can contain multiple doses:

- `id`
- hour / minute
- `quantity`
- `unit`
- `foodInstruction`

### DoseOccurrence

Every scheduled dose is represented as an individual occurrence:

- `id`
- `medicineId`
- `doseId`
- `scheduledAt`
- dose quantity / unit
- `foodInstruction`
- `status` (`pending`, `taken`, `missed`, `skipped`)
- `actionAt`
- `snoozedUntil`
- `createdAt`
- historical snapshots of medicine name, description, type, and strength

Historical snapshot fields are intentional. If a medicine changes from 500 mg to 1000 mg later, an older 500 mg occurrence remains 500 mg in History.

### Settings

Settings are persisted in Hive and include:

- reminder sound ID
- vibration enabled/disabled
- default snooze duration
- notifications enabled/disabled

## Dose Occurrence Generation

For a bounded treatment, occurrences are generated from the start date through the end date, inclusive.

Example used by the task specification:

```text
10 Aug 2026 → 16 Aug 2026
3 doses/day
= 21 individual dose occurrences
```

For a medicine with no end date, Meditrake does not create unlimited records. It uses a bounded 30-day rolling window and refills the future schedule during recovery.

Occurrence IDs are deterministic from medicine ID, dose ID, and scheduled time. This allows recovery to detect an existing occurrence and avoid creating duplicate dose records.

## Dose Status Rules

- **Pending**: no final action has been recorded and the effective reminder time has not passed.
- **Taken**: records the actual action time.
- **Skipped**: records the actual action time.
- **Missed**: overdue Pending occurrences are reconciled to Missed when app recovery/history reconciliation runs.
- **Snoozed**: the occurrence remains Pending and gets a `snoozedUntil` value. Snoozing one dose does not modify the rest of the medicine schedule.

## Notifications

`NotificationService` uses `flutter_local_notifications` and timezone-aware scheduling.

The implementation includes:

- Android and iOS initialization
- notification permission requests
- Android exact-alarm permission request with inexact fallback where exact scheduling is unavailable
- local timezone initialization
- custom sound selection
- vibration preference
- Taken / Snooze / Skip notification actions
- payload-based navigation to an individual reminder
- stable integer notification IDs derived from occurrence IDs
- cancellation of individual/all reminders
- OS queue synchronization to remove stale reminders and avoid duplicate scheduling
- Android boot receiver configuration
- recovery after app startup/resume

### Android notification resources

Custom sounds are stored in:

```text
android/app/src/main/res/raw/
```

### iOS notification resources

Custom sounds are included in the Runner target and copied as bundle resources.

## App Recovery

Recovery runs when the application starts and when it returns to the foreground.

It:

1. Deactivates completed bounded treatments.
2. Converts overdue Pending occurrences to Missed.
3. Removes future Pending occurrences for paused/stopped medicines.
4. Refills the bounded rolling schedule for active medicines.
5. Uses deterministic IDs to prevent duplicate occurrence creation.
6. Synchronizes future OS reminders with current Hive state and settings.

The app remains offline-first; Hive is the source of truth for medicine and occurrence data.

## Search and Filters

Dashboard and History use the same case-insensitive occurrence search rule. Search checks:

- medicine name
- description
- medicine type

Dashboard supports a specific-date schedule. History supports date filtering plus All / Taken / Missed / Skipped status filters.

## Automated Tests

The `test/` directory covers the main business rules required by the task:

- 10–16 Aug with 3 doses/day generates exactly 21 occurrences
- same start/end date
- custom dose times/quantities/units
- ongoing medicine requires a bounded future window
- 30-day rolling occurrence generation
- deterministic occurrence IDs / duplicate prevention
- historical snapshot generation
- Taken status + action time
- Skipped status + action time
- Snooze 5/10/15/30 minutes
- snoozing one occurrence does not change another
- overdue Pending → Missed
- snoozed occurrence respects `snoozedUntil`
- future Pending occurrences stay out of History
- Dashboard statistics use individual occurrences
- medicine edit preserves historical snapshots
- delete preserves historical records
- pause/resume/stop lifecycle behavior
- restart/recovery idempotency
- notification settings/re-scheduling orchestration
- case-insensitive search
- status badge widget labels

Run all tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

## Setup

### Requirements

- Flutter SDK compatible with this project's `pubspec.yaml`
- Android Studio / Android SDK for Android builds
- Xcode + CocoaPods on macOS for iOS builds

### Install dependencies

```bash
flutter clean
flutter pub get
```

### Generate launcher icons

The icon source is:

```text
assets/icon/app_logo.png
```

Generate Android and iOS icons with:

```bash
dart run flutter_launcher_icons
```

### Run

```bash
flutter run
```

## Pre-Release Verification

Before sending a release build, run:

```bash
dart format lib test
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Then install the release APK on a physical Android device and manually verify:

1. Add a medicine with multiple doses.
2. Test same-day start/end dates.
3. Test a medicine with no end date.
4. Confirm reminder appears with app foregrounded/backgrounded/closed and phone locked where supported.
5. Test Taken, Skip, and all Snooze choices.
6. Confirm an untouched overdue dose becomes Missed after recovery.
7. Edit medicine and confirm old History values remain unchanged.
8. Pause, resume, stop, and delete medicine.
9. Confirm deleted/stale reminders do not fire.
10. Restart the phone, reopen the app, and confirm data/future schedule recovery.
11. Test search, date filter, and History status filters.
12. Test sound preview, sound selection, vibration, default snooze, and notification toggle.
13. Verify light/dark theme readability and small-screen layouts.

## Android Release Signing

The current project configuration still uses the debug signing configuration for the `release` build. This is acceptable only for local/reviewer installation; it is **not** a production Play Store signing setup.

Before publishing to Google Play:

1. Create an upload keystore.
2. Keep keystore credentials outside source control.
3. Configure a proper release signing config in `android/app/build.gradle.kts`.
4. Replace the placeholder application ID `com.example.medicine_reminder` with your own permanent unique application ID before the first store publication.
5. Build and test the signed release artifact.

Do not commit a real keystore or passwords to Git.

## Platform Notes / Limitations

- Exact notification delivery is controlled by Android/iOS platform rules, permissions, battery optimizations, and alarm policies.
- If Android exact-alarm access is unavailable, the app falls back to inexact scheduling instead of crashing the scheduling flow.
- A Flutter app cannot continuously execute Dart code while fully terminated. Hive status reconciliation therefore runs on startup/resume; scheduled local notifications are handled by the operating system.
- Device-restart and terminated-app behavior should always be verified on physical devices before release.
- iOS builds and signing require macOS/Xcode and an Apple development setup.

## Branding

- Display name: **Meditrake**
- Launcher icon source: `assets/icon/app_logo.png`

## License

This repository was created as a Flutter developer task/project submission. Add a project-specific license if the code is intended for distribution beyond the assignment/reviewer context.
