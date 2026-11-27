# 🏥 Turnly - Implementation Summary & Tech Stack Documentation

---

## 1. 🛠️ Tech Stack & Architecture Overview

| Layer | Technology | Version / Purpose |
|---|---|---|
| **Mobile App (Frontend)** | **Flutter (Dart SDK 3.3+)** | Cross-platform UI for iOS and Android |
| **Architecture Pattern** | **MVVM (Model-View-ViewModel)** | Clean separation of business logic and UI presentation |
| **State Management & Routing** | **GetX (`get: ^4.6.6`)** | Reactive state (`.obs`, `Obx`), route navigation, and dependency injection |
| **Backend Server** | **Node.js + Express.js** | Lightweight REST API server running on port `3000` |
| **Database** | **Neon Cloud PostgreSQL** | Cloud-hosted serverless SQL database with SSL connection |
| **Password Hashing** | **bcryptjs** | Salted hashing algorithm for user credentials storage |
| **Session Authentication** | **JSON Web Tokens (JWT)** | Stateless Bearer token auth (`Authorization: Bearer <token>`) |
| **Email Verification** | **Nodemailer (Gmail SMTP)** | Automated sending of 6-digit OTP codes for account verification |
| **Push Notifications** | **Firebase Cloud Messaging (FCM)** | Client-side FCM token generation stored in PostgreSQL for queue alerts |
| **Local Client Storage** | **shared_preferences** | Persistent on-device storage for JWT tokens and user session data |
| **Version Control** | **Git & GitHub** | Collaborative team workflow hosted on branch `dev` |

> **Important Architecture Clarification:** Firebase is **not** used as a backend database (Firestore was eliminated) nor for user authentication (Firebase Auth was eliminated). Authentication is entirely handled by our own custom Express API and stored in Neon PostgreSQL. Firebase is used exclusively for **Firebase Cloud Messaging (FCM)** token acquisition.

---

## 2. 🗄️ Database Architecture (Neon PostgreSQL Schema)

A complete relational database model was created in Neon PostgreSQL consisting of **7 tables**:

### 1. `users` Table
Stores identity, role, and authentication credentials.
- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR 100, NOT NULL)
- `email` (VARCHAR 150, UNIQUE, NOT NULL)
- `password_hash` (TEXT, NOT NULL) — Salted bcrypt hash
- `role` (VARCHAR 20, NOT NULL, DEFAULT `'patient'`) — Values: `'patient'`, `'manager'`, `'admin'`
- `hospital_id` (INTEGER, REFERENCES hospitals(id)) — Nullable, populated for hospital managers
- `fcm_token` (TEXT) — Device FCM token for push notifications
- `is_verified` (BOOLEAN, DEFAULT `false`) — Email verification gate
- `created_at` (TIMESTAMP, DEFAULT `NOW()`)
- `updated_at` (TIMESTAMP, DEFAULT `NOW()`)
*(Note: Phone column was removed to simplify signup).*

### 2. `email_otps` Table
Handles temporary verification codes for account creation.
- `id` (SERIAL PRIMARY KEY)
- `user_id` (INTEGER, REFERENCES users(id) ON DELETE CASCADE)
- `otp_code` (VARCHAR 6, NOT NULL)
- `is_used` (BOOLEAN, DEFAULT `false`)
- `expires_at` (TIMESTAMP, NOT NULL) — Set to 10 minutes from creation
- `created_at` (TIMESTAMP, DEFAULT `NOW()`)

### 3. `hospitals` Table
Stores hospital registrations and administrative status.
- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR 200, NOT NULL)
- `address` (TEXT)
- `city` (VARCHAR 100)
- `phone` (VARCHAR 20)
- `email` (VARCHAR 150)
- `logo_url` (TEXT)
- `status` (VARCHAR 20, DEFAULT `'pending'`) — Values: `'pending'`, `'approved'`, `'rejected'`, `'suspended'`
- `manager_id` (INTEGER, REFERENCES users(id))
- `latitude` (DECIMAL 10,8)
- `longitude` (DECIMAL 11,8)
- `created_at` (TIMESTAMP, DEFAULT `NOW()`)
- `updated_at` (TIMESTAMP, DEFAULT `NOW()`)

### 4. `departments` Table
Clinical wings within each hospital (e.g., Cardiology, OPD, Pediatrics).
- `id` (SERIAL PRIMARY KEY)
- `hospital_id` (INTEGER, REFERENCES hospitals(id) ON DELETE CASCADE)
- `name` (VARCHAR 100, NOT NULL)
- `description` (TEXT)
- `created_at` (TIMESTAMP, DEFAULT `NOW()`)

### 5. `doctors` Table
Doctor profiles associated with hospitals and departments.
- `id` (SERIAL PRIMARY KEY)
- `hospital_id` (INTEGER, REFERENCES hospitals(id) ON DELETE CASCADE)
- `department_id` (INTEGER, REFERENCES departments(id) ON DELETE SET NULL)
- `name` (VARCHAR 100, NOT NULL)
- `specialization` (VARCHAR 100)
- `qualification` (VARCHAR 200)
- `experience_years` (INTEGER)
- `photo_url` (TEXT)
- `avg_consult_minutes` (INTEGER, DEFAULT `10`) — Average time used for queue time calculations
- `is_available` (BOOLEAN, DEFAULT `true`)
- `created_at` (TIMESTAMP, DEFAULT `NOW()`)

### 6. `tokens` Table
Appointment and live token bookings for patients.
- `id` (SERIAL PRIMARY KEY)
- `token_number` (INTEGER, NOT NULL) — Sequenced queue number for the day
- `patient_id` (INTEGER, REFERENCES users(id))
- `doctor_id` (INTEGER, REFERENCES doctors(id))
- `hospital_id` (INTEGER, REFERENCES hospitals(id))
- `department_id` (INTEGER, REFERENCES departments(id))
- `patient_name` (VARCHAR 100) — Allows booking for self or family
- `status` (VARCHAR 20, DEFAULT `'waiting'`) — Values: `'waiting'`, `'serving'`, `'done'`, `'cancelled'`, `'skipped'`
- `booking_date` (DATE, DEFAULT `CURRENT_DATE`)
- `estimated_time` (TIME)
- `called_at` (TIMESTAMP)
- `completed_at` (TIMESTAMP)
- `created_at` (TIMESTAMP, DEFAULT `NOW()`)

### 7. `family_members` Table
Linked family profiles for multi-patient booking under one account.
- `id` (SERIAL PRIMARY KEY)
- `user_id` (INTEGER, REFERENCES users(id) ON DELETE CASCADE)
- `name` (VARCHAR 100, NOT NULL)
- `relation` (VARCHAR 50)
- `age` (INTEGER)
- `created_at` (TIMESTAMP, DEFAULT `NOW()`)

---

## 3. 🔌 Backend REST API Endpoints (Node.js & Express)

All routes are mounted under `/api/auth` with JSON body parsing and CORS enabled.

### 1. `POST /api/auth/signup`
- **Access:** Public
- **Request Body:**
  ```json
  {
    "name": "Ali Raza",
    "email": "ali@example.com",
    "password": "password123",
    "role": "patient",
    "fcm_token": "device_fcm_token_optional"
  }
  ```
- **Process Logic:**
  1. Validates presence of `name`, `email`, `password`, and `role`.
  2. Restricts `role` to `'patient'` or `'manager'`.
  3. Checks if `email` exists:
     - If exists and verified: returns HTTP `409 Conflict`.
     - If exists but unverified: purges stale OTPs and user record to allow fresh registration.
  4. Hashes password using `bcrypt.genSalt(10)`.
  5. Inserts user into PostgreSQL with `is_verified = false`.
  6. Generates a cryptographically secure 6-digit numeric OTP.
  7. Inserts OTP into `email_otps` with `expires_at = NOW() + 10 minutes`.
  8. Dispatches verification email via Nodemailer.
- **Success Response:** HTTP `201 Created`
  ```json
  {
    "success": true,
    "message": "Verification code sent to your email",
    "user": { "id": 1, "email": "ali@example.com", "name": "Ali Raza" }
  }
  ```

### 2. `POST /api/auth/verify-otp`
- **Access:** Public
- **Request Body:**
  ```json
  {
    "email": "ali@example.com",
    "otp_code": "482916"
  }
  ```
- **Process Logic:**
  1. Queries user by email.
  2. Queries `email_otps` for matching `user_id`, matching `otp_code`, `is_used = false`, and `expires_at > NOW()`.
  3. If invalid or expired, returns HTTP `400 Bad Request`.
  4. Updates OTP record to `is_used = true`.
  5. Updates user record to `is_verified = true`.
  6. Signs and returns a JWT token (`jwt.sign({ userId, role }, JWT_SECRET, { expiresIn: '7d' })`).
- **Success Response:** HTTP `200 OK`
  ```json
  {
    "success": true,
    "message": "Email verified successfully",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
    "user": { "id": 1, "name": "Ali Raza", "email": "ali@example.com", "role": "patient" }
  }
  ```

### 3. `POST /api/auth/resend-otp`
- **Access:** Public
- **Request Body:**
  ```json
  {
    "email": "ali@example.com"
  }
  ```
- **Process Logic:**
  1. Verifies user exists and is not already verified.
  2. Marks all existing active OTPs for the user as `is_used = true`.
  3. Generates and stores a new 6-digit OTP code valid for 10 minutes.
  4. Sends clean verification email.
- **Success Response:** HTTP `200 OK`
  ```json
  {
    "success": true,
    "message": "Code resent to your email"
  }
  ```

### 4. `POST /api/auth/login`
- **Access:** Public
- **Request Body:**
  ```json
  {
    "email": "ali@example.com",
    "password": "password123",
    "fcm_token": "latest_device_token_optional"
  }
  ```
- **Process Logic:**
  1. Finds user by email in PostgreSQL.
  2. Enforces email verification: If `is_verified == false`, blocks login with HTTP `403 Forbidden` and `{ requiresVerification: true }`.
  3. Compares plaintext password with stored hash via `bcrypt.compare`.
  4. If `fcm_token` is provided, updates `users.fcm_token` and `updated_at`.
  5. Issues signed JWT authentication token.
- **Success Response:** HTTP `200 OK`
  ```json
  {
    "success": true,
    "message": "Login successful",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
    "user": { "id": 1, "name": "Ali Raza", "email": "ali@example.com", "role": "patient" }
  }
  ```

### 5. `GET /api/auth/profile`
- **Access:** Protected (Requires `Authorization: Bearer <jwt_token>`)
- **Process Logic:**
  1. `verifyToken` middleware decodes JWT and populates `req.userId` and `req.userRole`.
  2. Queries user record omitting password hash.
- **Success Response:** HTTP `200 OK`
  ```json
  {
    "success": true,
    "user": { "id": 1, "name": "Ali Raza", "email": "ali@example.com", "role": "patient", "hospital_id": null, "created_at": "..." }
  }
  ```

### 6. `PUT /api/auth/profile`
- **Access:** Protected (Requires `Authorization: Bearer <jwt_token>`)
- **Request Body:** `{ "name": "Ali Raza Updated" }`
- **Process Logic:** Updates name in PostgreSQL and returns updated record.

---

## 4. 📱 Flutter Frontend Implementation

### 1. Centralized Theme System (`lib/utils/app_colors.dart`)
Hardcoded colors were eliminated across the application in favor of a unified professional design palette:
- `AppColors.primary` = `Color(0xFF1A237E)` (Deep Indigo)
- `AppColors.primaryLight` = `Color(0xFF3949AB)`
- `AppColors.primaryDark` = `Color(0xFF0D1642)`
- `AppColors.primaryExtraLight` = `Color(0xFFE8EAF6)`
- `AppColors.background` = `Color(0xFFF8FAFC)`
- `AppColors.surface` = `Colors.white`
- `AppColors.border` = `Color(0xFFE2E8F0)`
- `AppColors.textPrimary` = `Color(0xFF0F172A)`
- `AppColors.textSecondary` = `Color(0xFF64748B)`
- `AppColors.textHint` = `Color(0xFF94A3B8)`
- `AppColors.success` = `Color(0xFF10B981)`
- `AppColors.error` = `Color(0xFFEF4444)`

### 2. HTTP & Session Service Layer (`lib/services/api_service.dart`)
- **Dynamic URL Resolution:** Automatically maps network hosts:
  - Android Emulator: `http://10.0.2.2:3000/api`
  - Web / Desktop / Simulator: `http://localhost:3000/api`
- **Storage Management:** Encapsulates `SharedPreferences` for `jwt_token` and `user_data` caching.
- **Header Builder:** Injects `Authorization: Bearer <token>` into protected requests.

### 3. Business Logic Layer (`lib/viewmodels/auth_viewmodel.dart`)
- Implements GetX controller handling reactive states (`isLoading`, `selectedRole`, `currentUser`).
- Automatically captures FCM device token before calling signup/login APIs:
  ```dart
  Future<String?> _getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
  ```

### 4. Screen Architecture & User Flow

```
SplashView
   │
   ├── (Already Logged In with valid JWT) ──► HomeView (Patient) / ManagerDashboardView
   │
   └── (New / Signed Out User)
          │
          ▼
   RoleSelectionView
          │
          ├── [Tap "Hospital Manager"] ──► ManagerDashboardView (Clean Module Placeholder)
          │
          └── [Tap "Patient"]
                 │
                 ▼
          SignupView ◄──(Switch link)──► LoginView
                 │                              │
                 ▼                              ▼
              OtpView                       HomeView
                 │                    (4-Tab Bottom Navigation)
                 ▼                              ▲
          OtpSuccessView                        │
                 │                              │
                 └──────► (Go to Log in) ───────┘
```

#### Screen Details:
1. **`SplashView` (`lib/views/auth/splash_view.dart`):**
   - Brand logo and tagline with synchronized scale and fade transition animations.
   - Automatically executes `authVm.checkAuth()` after 2.5 seconds.
2. **`RoleSelectionView` (`lib/views/auth/role_selection_view.dart`):**
   - Clean two-card layout for **Patient** and **Hospital Manager**.
   - Tapping Hospital Manager navigates directly to the dedicated empty manager dashboard screen.
   - Tapping Patient triggers the auth pipeline.
3. **`SignupView` (`lib/views/auth/signup_view.dart`):**
   - Form fields: **Full Name**, **Email**, and **Password** (obscure toggle with eye icon).
   - Phone field removed as requested.
   - Privacy acknowledgment checkbox.
   - Top-left back button safely resets stack to Role Selection via `Get.offAllNamed(AppRoutes.roleSelection)`.
4. **`OtpView` (`lib/views/auth/otp_view.dart`):**
   - Clean 6-box numeric entry using `PinCodeTextField`.
   - Auto-submits on completion of 6th digit.
   - 60-second active countdown timer with interactive "Resend code" button.
5. **`OtpSuccessView` (`lib/views/auth/otp_success_view.dart`):**
   - Success badge with elastic icon animation.
   - Directs verified users back to the Login screen with prominent **"Go to Log in"** button.
6. **`LoginView` (`lib/views/auth/login_view.dart`):**
   - Email & password entry.
   - On success, saves JWT and redirects user directly to the **HomeView** (not profile).
7. **`HomeView` (`lib/views/patient/home_view.dart`):**
   - Features persistent bottom navigation bar with 4 tabs:
     1. **Home (`patient_home_tab.dart`):** Clean placeholder for upcoming hospital directory.
     2. **My Tokens (`my_tokens_view.dart`):** Clean placeholder for active token queues.
     3. **Alerts (`alerts_view.dart`):** Clean placeholder for real-time turn alerts.
     4. **Profile (`profile_view.dart`):** Displays user initials avatar, full name, email, role badge, and working Logout dialog.

---

## 5. 📧 Email Template Design (`backend/config/email.js`)
Configured with Nodemailer over Gmail SMTP (`EMAIL_USER`, `EMAIL_PASS`):
- **Subject Line:** `${otpCode} is your Turnly verification code` (immediate code visibility).
- **Template Style:** Clean, minimal, mobile-responsive typography (no heavy gradients or colorful boxes).
- **Security:** Clear 10-minute expiry disclosure.
- **Fallback:** Includes plaintext `text` attribute for clients that disable HTML.

---

## 6. 🐙 Version Control & Team Workflow

- **Remote GitHub Repository:** `https://github.com/Muqadas1234/Turnly.git`
- **Primary Working Branch:** `dev`
- **Security Isolation:**
  - The `backend/.env` file containing the Neon database connection string, JWT secrets, and Gmail app credentials was strictly maintained in `.gitignore`.
  - Confirmed via `git ls-files | Select-String "\.env"` returning zero tracked files.
- **Collaboration Pattern:**
  - The repository has been shared via collaborator invite.
  - Teammate clones via `git clone https://github.com/Muqadas1234/Turnly.git` and switches to `git checkout dev`.
  - Future tasks will branch off `dev` using feature branches (e.g., `feature/manager-doctors`, `feature/token-booking`) and merge back into `dev` via Pull Requests.
