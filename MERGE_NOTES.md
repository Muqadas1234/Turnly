# Turnly – unified version (merge of `Turnly.zip` + `Turnly_3.zip`)

Verified against the backend repo (Turnly-Backend, `MERGE-NOTES.md`): the server exposes both
route families; `/api/tokens`, `/api/queue`, `/api/hospitals` are canonical, `/api/patient/*` is legacy.

## Decisions
| Area | Source | Notes |
|---|---|---|
| Brand colour | A | One teal family. `tealPrimary*`, `adminPrimary*`, `accent*`, `darkGreen*` are aliases of `primary*` in `app_colors.dart`. Re-theme by editing 4 values. |
| Splash | B, recoloured | All 46 colours hue-shifted violet -> teal (saturation/lightness/alpha kept). |
| Patient/manager data layer | B | Canonical routes. A's `patient/*` calls kept in `ApiService` (`getPatientHospitals`, `bookTokenByHospital`, ...), unused by screens. |
| Patient VM | B + A logic | A's stale-response guards, permanent city chips, search resets city, doctor auto-select. |
| Manager VM | B + A | B polling/validation/clean defaults; A base64 uploads + prefill; dashboard parsing fixed for `{stats:{tokens_issued,in_queue,served,avg_consult_minutes,doctors}}`. |
| Auth VM | B + A | Single `_completeAuth`; role-mismatch guard; push start; A's forgot/reset/change password + profile name. |
| Auth flow | merged | After OTP: manager -> hospital-status routing, patient -> success screen -> Home (already signed in), admin -> panel. |
| Admin | A | Role screen is A's (Patient + Hospital Manager only). Admin accounts can still log in: the role-mismatch check skips them. |
| Screens | real over mock | A's static mockups (my_token, my_tokens, queue_control, ...) dropped for B's data-driven ones. A's real registration upload / profile / settings kept. |
| Repo hygiene | | `firebase_options.dart` removed from `.gitignore`; `.gitattributes` forces LF; machine-specific/generated files excluded. |

After copying: `flutter pub get` (adds file_picker, url_launcher, web_socket_channel to the lock).
