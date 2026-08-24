# Privacy Policy for Noto

**Last updated:** August 24, 2026   
**Contact:** xevonlabs@gmail.com

---

## 1. Overview & Core Philosophy
At **Xevon Labs**, we believe your personal notes, thoughts, and ideas should remain private and entirely under your control. **Noto** is built as an **offline-first** application. We do not sell, rent, monetize, or scan your personal content.

---

## 2. Information We Collect and Process

### A. Your Notes and Content (100% Offline)
* **Local Storage:** All note titles, bodies, color themes, creation timestamps, and reminder schedules are stored exclusively on your local device using an encrypted/isolated SQLite database.
* **No Cloud Sync of Notes:** Your notes are never transmitted to our servers or any third-party cloud infrastructure.

### B. Anonymous Technical Telemetry
To ensure app stability, monitor adoption, and diagnose performance issues, Noto sends minimal, non-personally identifiable telemetry to our secure Supabase backend:
* **Installation Identifier:** A randomly generated UUID (v4) created upon initial installation. This identifier is not linked to your name, email, phone number, or Google account.
* **Coarse Locale / Country Code:** Derived from your device's operating system locale setting (e.g., `US`, `PK`, `GB`) without accessing GPS or fine location hardware.
* **Device Platform:** Operating system name (e.g., `Android`, `iOS`).
* **Timestamp & Heartbeat:** Timestamp of initial launch and an anonymous heartbeat update when the app is active.

---

## 3. Device Permissions and Why We Need Them

Noto only requests standard Android/iOS permissions necessary to deliver core features:

| Permission | Technical Name | Purpose |
| :--- | :--- | :--- |
| **Notifications** | `POST_NOTIFICATIONS` | Delivers local reminder alerts that you explicitly schedule for specific notes. |
| **Exact Alarms** | `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Ensures reminder notifications fire at the exact chosen minute, even when your device enters battery-saving (Doze) mode. |
| **Reboot Rescheduling** | `RECEIVE_BOOT_COMPLETED` | Automatically restores your scheduled local alarms after your phone restarts. |
| **Haptics & Vibration** | `VIBRATE` | Provides tactile vibration feedback on button taps and alarm notifications. |
| **Network Access** | `INTERNET` / `ACCESS_NETWORK_STATE` | Transmits anonymous heartbeat/active telemetry to Supabase. |

---

## 4. Third-Party Services
We use **Supabase** (Supabase Inc.) to host our backend database for anonymous usage counts and telemetry. Supabase adheres to industry-standard security protocols, including encryption in transit (HTTPS/TLS 1.3) and at rest (AES-256).

---

## 5. Data Retention & Deletion
* **Local Data:** You have full control over your data. You can delete individual notes at any time, or clear all app data / uninstall the app to instantly and permanently erase all local notes.
* **Telemetry Data:** Stored anonymously without personal identifying attributes. If you wish to purge your anonymous installation record, contact us at `support@xevonlabs.com` with your installation ID.

---

## 6. Children's Privacy
Noto does not knowingly collect or solicit personal information from children under the age of 13. The application is rated for general audiences and contains no age-restricted or harmful content.

---

## 7. Changes to This Privacy Policy
We may update our Privacy Policy periodically. Any modifications will be reflected by updating the "Last updated" date at the top of this document and will be made available within the app settings.

---

## 8. Contact Us
If you have questions, feedback, or concerns regarding this Privacy Policy:
* **Email:** xevonlabs@gmail.com 
* **Developer Organization:** Xevon Labs  
* **Website:** https://xevonlabs.com
