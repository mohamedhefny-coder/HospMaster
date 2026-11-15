# HospMaster

HospMaster is a Flutter/Dart starter application for managing hospitals,
outpatient clinics, appointments, patient records, and waiting lists.

## Included MVP features

- Arabic RTL and English user interface.
- Responsive layout for mobile and web.
- Local role switching: administrator, receptionist, doctor, and patient.
- Operational overview with appointments, waiting patients, beds, and doctors.
- Live local waiting-list management with a "call next" action.
- Appointment scheduling that adds the patient to the waiting list.
- Searchable local patient records.

The current data is local demonstration data. Do not use it to store real
patient data.

## Supported targets

The project is generated for Android, iOS, and web.

## Running locally

```bash
flutter pub get
flutter run
```

### Surgery department with Supabase

The imported surgery department reads its waiting list from the authorized
Supabase project. Do not store the project URL or public key in source files.
Pass them when running the application:

```bash
flutter run \
  --dart-define=HOSPMASTER_SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=HOSPMASTER_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

Alternatively, copy `supabase.env.example.json` to `supabase.env.json` (ignored
by Git), fill in the values, and run
`flutter run --dart-define-from-file=supabase.env.json` or use the
"HospMaster (Supabase)" VS Code launch configuration. Only use the publishable
(anon) key; never put a `sb_secret_`/service_role key in the app.

Without these values, the surgery waiting-list card displays an explicit setup
message and does not attempt a connection.

#### Patient records (general and oncology surgery)

Patients added from the surgery departments are stored in Supabase. Run these
in the Supabase SQL editor, in order:

1. [`20261025_surgery_patients.sql`](supabase/migrations/20261025_surgery_patients.sql)
   creates the `surgery_patients` table.
2. [`20261025_surgery_patient_files.sql`](supabase/migrations/20261025_surgery_patient_files.sql)
   creates the private `surgery_patient_files` bucket for photos and attachments.

The policies allow the `anon` role because the app has no login yet — tighten
them before storing real patient data.

To launch a specific target:

```bash
flutter run -d chrome
flutter run -d android
```

## Verification

```bash
flutter analyze
flutter test
flutter build web
```
