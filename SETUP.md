# Codex Catalogue — Manual Firebase & GitHub Setup Guide

Follow these steps to connect your live Firebase project and zero-cost GitHub asset repository.

---

## 1. Firebase Project & FlutterFire Configuration

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a project (e.g., `codex-catalogue`).
2. **Authentication**:
   - Navigate to **Build → Authentication → Sign-in method**.
   - Enable **Email/Password**.
3. **Cloud Firestore**:
   - Navigate to **Build → Firestore Database** and click **Create database** (start in Production mode).
4. **Link Flutter App**:
   ```powershell
   cd C:\Users\natha\OneDrive\Documents\Mobile-Dev\codex_catalouge
   dart pub global activate flutterfire_cli
   flutterfire configure --project=codexcatalouge-71307
   ```
   - This generates `lib/firebase_options.dart` and `android/app/google-services.json`.
   - In `lib/main.dart`, if you prefer passing `DefaultFirebaseOptions.currentPlatform`, import `firebase_options.dart` and pass `options: DefaultFirebaseOptions.currentPlatform` to `Firebase.initializeApp(...)`.

---

## 2. Firestore Security Rules & Initial Lore Config

1. In Firebase Console → **Firestore Database → Rules**, paste the contents of `firebase/firestore.rules` and click **Publish**.
2. Create the initial configuration document at **`lore_config/catalogue_settings`**:
   - `organizationName` (string): `"Codex Catalogue"`
   - `leaderTitle` (string): `"The Puppeteer"`
   - `labelFormat` (string): `"Artifact [{NUMBER}]"`
   - `downvoteThreshold` (number): `-10`
   - `anomalyClasses` (array of strings): `["Beneficial", "Harmless", "Cursed", "Dangerous"]`
   - `historicalOrigins` (array of strings): `["Ancient Egypt", "Rome", "Athens", "Mesopotamia", "Modern Era", "Multiverse"]`

---

## 3. Promoting Your First Admin ("The Overseer")

1. Sign up in the app using your email and password (this creates `users/{yourUid}` with `role: "READER"`).
2. In Firebase Console → **Firestore Database → Data → `users/{yourUid}`**, update:
   - `role`: `"ADMIN"` (or `"MODERATOR"` for Inquisitors, `"AUTHOR"` for Clairvoyance scribes)
   - `inUniverseRole`: `"The Overseer"` (or `"The Puppeteer"`)
3. The **Open Puppeteer's Council** button and **GitHub Asset Staging Config** will immediately unlock in the **Sanctum** tab.

---

## 4. Zero-Cost GitHub Relic Image Pipeline Setup

1. Create a **public** GitHub repository to host approved relic illustrations (e.g., `your-username/codex-catalogue-assets`).
2. Go to **GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**:
   - **Repository access**: Select **Only select repositories** → pick your public asset repo.
   - **Permissions → Repository permissions → Contents**: Set to **Read and write**.
   - Copy the generated `github_pat_...` token.
3. Configure in the app:
   - Sign in as an **Admin** (`role == "ADMIN"`), open the **Sanctum** tab, and fill in the **GitHub Relic Repository Config** card (`Owner`, `Repo`, `Branch`, and `Fine-Grained PAT`), OR
   - Create a Firestore document at **`admin_secrets/github`** with fields:
     - `owner`: `"your-github-username"`
     - `repo`: `"codex-catalogue-assets"`
     - `branch`: `"main"`
     - `pat`: `"github_pat_..."`
   - `firebase/firestore.rules` restricts `admin_secrets/github` strictly to `ADMIN` and `MODERATOR` roles.
