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

#### Accounts, services and the admin panel

Sign-in and sign-up use Supabase Auth (email + password); the app already reads
the project from `supabase.env.json`, so no further code changes are needed.
In the Supabase dashboard, keep **Authentication > Providers > Email** enabled
with "Confirm email" on.

Google sign-in is also available on the subscriber and admin sign-in screens.
Before using it:

1. Enable **Authentication > Providers > Google** in Supabase and enter the
   Google OAuth Web client ID and client secret.
2. In Google Cloud Console, add Supabase's callback URL shown on that provider
   settings page as an authorized redirect URI.
3. In **Authentication > URL Configuration > Redirect URLs**, allow
   `io.supabase.flutter://login-callback/` for Android/iOS, and the exact web
   app base URL (including its path if hosted under a repository subpath).
4. For Android/iOS, Google OAuth returns through the `io.supabase.flutter`
   app-link scheme already declared in the platform configuration.

Google users are created by Supabase Auth. To give a Google account admin
rights, set its `raw_app_meta_data.role` to `admin` as described below, then
sign out and back in so Supabase issues a token with the updated role.

Access is per service (general / oncology / pediatric surgery, OB-GYN and
pediatrics clinics). Users request services after signing in and an admin
approves them. Run, in the SQL editor:

3. [`20261118_service_access.sql`](supabase/migrations/20261118_service_access.sql)
   creates `service_access`, the `is_app_admin()` / `has_service()` helpers and
   replaces the open `anon` policies above with per-service policies.

Create the first admin by flagging an existing account:

```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role": "admin"}'
where email = 'admin@example.com';
```

The admin panel opens with five quick taps on the logo on the first screen
(it asks for an admin sign-in). To let admins create accounts with a password
from the panel, deploy the Edge Function:

```bash
supabase functions deploy admin-create-user
```

Without it, the panel can still approve requests and pre-approve e-mails.

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
