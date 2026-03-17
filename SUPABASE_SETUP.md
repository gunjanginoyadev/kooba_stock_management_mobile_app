# Supabase backend setup

This app uses [Supabase](https://supabase.com) as the backend (auth, database, storage). Follow these steps once to get your project running.

---

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in (or create an account).
2. Click **New project**.
3. Choose your organization, set a **Project name** (e.g. `kooba-stock`), set a **Database password** (save it somewhere safe), and pick a **Region**.
4. Click **Create new project** and wait for the project to be ready.

---

## 2. Get your API credentials

1. In the Supabase Dashboard, open your project.
2. Go to **Project Settings** (gear icon in the left sidebar) â†’ **API**.
3. Youâ€™ll see:
   - **Project URL** (e.g. `https://xxxxx.supabase.co`)
   - **anon public** key (long string under â€œProject API keysâ€)

---

## 3. Add credentials to the app

1. Open **`lib/core/config/supabase_config.dart`** in this project.
2. Replace the placeholders:
   - `supabaseUrl` â†’ your **Project URL**
   - `supabaseAnonKey` â†’ your **anon public** key

Example:

```dart
static const String supabaseUrl = 'https://abcdefgh.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**Important:** Do not commit real keys to a public repo. For production, use environment variables or CI secrets and pass them via `--dart-define` or a similar approach.

---

## 4. Enable Email auth (for login with email/password)

1. In Supabase Dashboard go to **Authentication** â†’ **Providers**.
2. Ensure **Email** is enabled (it is by default).
3. Optionally under **Email**:
   - Turn **â€œConfirm emailâ€** on if you want users to verify their email before signing in.
   - Set **â€œSecure email changeâ€** as you prefer.

After this, the app can use **Sign up** and **Sign in with email/password** once we wire the auth bloc to Supabase.

---

## 4b. Create tables for stock items (Add item / Manage items)

If you see **"could not find the table public.items"**, the tables have not been created yet. Create them once:

1. Open your **Supabase project** in the dashboard (the same project whose URL and anon key are in `supabase_config.dart`).
2. In the left sidebar click **SQL Editor**.
3. Click **New query**.
4. Open the file **`supabase/RUN_THIS_IN_SQL_EDITOR.sql`** in this project, copy **all** of its contents, and paste into the SQL Editor.
5. Click **Run** (or press Ctrl+Enter). You should see "Success. No rows returned."
6. Confirm: in the left sidebar open **Table Editor**; you should see **item_categories** and **items**.

After this, **Add item** and **Manage items** will work.

---

## 5. Run the app

- If the credentials in `supabase_config.dart` are set (not `YOUR_SUPABASE_...`), Supabase is initialized when the app starts.
- If they are still placeholders, the app will run but Supabase features (auth, database) will not work until you add the real URL and anon key.

---

## 6. Email rate limits (register, reset password)

Supabase limits how many emails can be sent per project:

- **Built-in email (default)**: about **3â€“4 emails per hour** for the whole project. Sign-up confirmations and password resets both count. Youâ€™ll see **â€œemail rate limit exceededâ€** (429) when you hit it.
- **You cannot remove or increase this limit** while using the built-in mailer on the free plan. It is fixed.

The app shows a friendly message when this happens: *â€œToo many emails sent. Please wait an hour and try againâ€¦â€*.

---

## 6b. Remove the limit (free): use custom SMTP

To avoid the strict built-in limit **without paying Supabase**, use **custom SMTP**. Supabase will then send auth emails (sign-up, reset password) through your provider. Many providers have a **free tier** (e.g. 100â€“300 emails/day).

### Step 1: Pick a free SMTP provider

Create an account and get SMTP details (host, port, username, password). Examples:

| Provider | Free tier | Get SMTP / API |
|----------|-----------|-----------------|
| **Resend** | 3,000 emails/month | [Resend + Supabase](https://resend.com/docs/send-with-supabase-smtp) |
| **Brevo** (Sendinblue) | 300 emails/day | [Brevo SMTP](https://help.brevo.com/hc/en-us/articles/7924908994450-Send-transactional-emails-using-Brevo-SMTP) |
| **SendGrid** | 100 emails/day | [SendGrid SMTP](https://www.twilio.com/docs/sendgrid/for-developers/sending-email/getting-started-smtp) |
| **Mailtrap** | Testing only (no real delivery) | Good for dev; use Resend/Brevo for real users |

You need: **SMTP host**, **port** (usually 587), **username**, **password**, and a **sender email** (e.g. `noreply@yourdomain.com` or the address the provider gives you).

### Step 2: Configure custom SMTP in Supabase

1. Open your project in the [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to **Project Settings** (gear) â†’ **Auth** â†’ scroll to **SMTP Settings**.
3. Enable **Custom SMTP** and fill in:
   - **Sender email**: e.g. `noreply@yourdomain.com` (must be allowed by your provider).
   - **Sender name**: e.g. `Kooba Stock`.
   - **Host**: e.g. `smtp.resend.com` (from your provider).
   - **Port**: usually `587` (TLS).
   - **Username / Password**: from your provider (often an API key as password).
4. Save.

After this, Supabase sends **all** auth emails (sign-up, reset password) via your SMTP. The built-in 3â€“4/hour limit no longer applies; your providerâ€™s limits apply instead (and you can often send 100+ per day on free tiers).

### Step 3 (optional): Adjust rate limit in Supabase

With custom SMTP enabled, Supabase still applies a default of about **30 emails/hour**. You can raise it:

1. In the Dashboard go to **Authentication** â†’ **Rate Limits**.
2. Find **Email** (or â€œEmails sentâ€) and increase the value as needed (e.g. 100/hour for development).

You still cannot change the limit for the **built-in** mailer; this only applies when **custom SMTP** is configured.

---

## 6c. Resend.com step-by-step (recommended)

If you use [Resend](https://resend.com) (as in your dashboard), follow this to send Supabase auth emails through Resend and avoid the built-in rate limit.

### In Resend (resend.com)

1. **Create an API key**
   - In the left sidebar click **API Keys** (or stay on **Onboarding**).
   - Click **Add API Key**.
   - Name it (e.g. `Supabase Auth`), copy the key (it starts with `re_`). You wonâ€™t see it again, so save it somewhere safe.

2. **Sender address**
   - **Option A â€“ Testing:** Use Resendâ€™s test sender: `onboarding@resend.dev`. No domain setup needed.
   - **Option B â€“ Production:** In the sidebar go to **Domains**, add and verify your domain, then use e.g. `noreply@yourdomain.com` as the sender in Supabase.

### In Supabase

1. Open your project â†’ **Project Settings** (gear) â†’ **Auth**.
2. Scroll to **SMTP Settings** and enable **Custom SMTP**.
3. Fill in exactly:

| Field          | Value                |
|----------------|----------------------|
| **Sender email** | `onboarding@resend.dev` (testing) or `noreply@yourdomain.com` (after domain verify) |
| **Sender name**  | `Kooba Stock` (or your app name) |
| **Host**        | `smtp.resend.com`    |
| **Port**        | `465`                |
| **Username**    | `resend`             |
| **Password**    | Your Resend API key (`re_...`) |

4. Save.

After this, Supabase sends all auth emails (sign-up, reset password) via Resend.

### If you see "Error sending recovery email" or "unexpected_failure"

Supabase returns this when the email could not be sent (usually SMTP/Resend config). Check:

1. **Supabase** â†’ **Project Settings** â†’ **Auth** â†’ **SMTP Settings**: Custom SMTP enabled; Sender email exactly `onboarding@resend.dev`; Host `smtp.resend.com`, Port `465`; Username `resend`; Password = your full Resend API key (starts with `re_`), no extra spaces.
2. **Resend**: API key is active; for testing, `onboarding@resend.dev` needs no verified domain.
3. **Supabase** â†’ **Logs** (or **Authentication** â†’ **Logs**): open the failed request to see the underlying SMTP error.

The built-in Supabase email rate limit no longer applies when using Resend; Resend free tier (e.g. 3,000 emails/month) applies instead.


---

## 7. Login when email is not verified

If **â€œConfirm emailâ€** is **on** in Authentication â†’ Providers â†’ Email:

- Supabase **blocks sign-in** until the user has clicked the confirmation link. `signInWithPassword` returns an error like **â€œEmail not confirmedâ€**.
- The app turns this into: *â€œPlease verify your email first. Check your inbox for the confirmation link, then try again.â€*

If **â€œConfirm emailâ€** is **off**:

- Users can sign in right after sign-up; no verification step.

---

## What you need to provide now

To proceed with integrations, have ready:

| Item | Where to find it |
|------|-------------------|
| **Supabase Project URL** | Project Settings â†’ API â†’ Project URL |
| **Supabase anon key** | Project Settings â†’ API â†’ anon public |
| **Email auth** | Authentication â†’ Providers â†’ Email (enabled) |

Once these are set in `supabase_config.dart`, we can:

- Connect **login/register** to Supabase Auth (email + password).
- Add **database tables** (e.g. items, stock in/out, categories) and wire the app to them.
- Optionally use **Storage** for profile pictures or documents.

If you use a **custom Supabase URL** (self-hosted), use that URL and its anon key in the same config file.
