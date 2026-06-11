# ALUDISCO

ALUDISCO is a centralized, mobile-native platform built with Flutter designed for the African Leadership University (ALU) student, alumni, club organizer, and academic team community.

## Platform Overview
Students currently rely on fragmented WhatsApp groups and email threads to learn about hackathons, internships, workshops, and campus events. **ALUDISCO** consolidates these fragmented touchpoints into a single app that feels native to how ALU students think about community building.

The app is built around three core pillars:
1. **Effortless Opportunity Discovery**: A curated feed where authorized users can post events, internships, and announcements. Other community members can RSVP, react, and comment directly within the app.
2. **Learning in Public**: A dedicated stream for achievement posts, reflecting ALU's emphasis on public progress tracking and peer accountability.
3. **Genuine Connection**: Topic-specific **Community Spaces** (subreddit-style discussion forums scoped to the ALU context) and **Mutual-Follow Gated Direct Messaging** for authentic networking.

---

## Features
- **Curated Opportunity Feed** with event details, locations, RSVP management, and calendar integrations.
- **Achievement Sharing Feed** for peer recognition.
- **Community Spaces**: Discussion boards categorized by interest (e.g., `#startups`, `#career`, `#tech-builds`, `#campus-life`, `#alumni-connect`).
- **Mutual-Follow Gated Chat & Direct Messaging**.
- **Local SQLite Database (`sqflite`)** with pre-seeded mock users, posts, chats, and notifications for offline-first responsiveness and easy demoing.

---

## How to Run the App

### Prerequisites
Before running the application, make sure you have the following installed:
1. **Flutter SDK** (`>=3.3.0 <4.0.0` is recommended). Follow the [Flutter Install Guide](https://docs.flutter.dev/get-started/install).
2. **Dart SDK** (bundled with Flutter).
3. **Android Studio** (for Android emulator) or **Xcode** (for iOS simulator, macOS only).
4. An Emulator/Simulator or a physical debugging device connected.

### Installation Steps

1. **Clone the Repository** (or navigate to the project root):
   ```bash
   cd /path/to/ALUDISCO
   ```

2. **Install Dependencies**:
   Fetch the necessary packages listed in `pubspec.yaml` (such as `sqflite`, `provider`, `path_provider`, etc.):
   ```bash
   flutter pub get
   ```

3. **Verify Connected Devices**:
   Make sure you have at least one emulator/simulator or physical device connected:
   ```bash
   flutter devices
   ```

4. **Run the Application**:
   Launch the app in debug mode on your active device:
   ```bash
   flutter run
   ```

---

## Testing & Demo Accounts
For ease of development and presentation, the application's local database is pre-seeded with mock users and content (defined in `lib/data/database_helper.dart`).

### How to Sign In
1. Open the app and tap **Sign In** or **Sign up with ALU email**.
2. Enter one of the pre-seeded ALU email addresses, or create a new one using an `@alustudent.com` or `@alueducation.com` address.
3. A simulated OTP will be triggered. Enter the mock OTP code: **`1989`** to complete verification.

### Pre-seeded Demo Accounts
You can log in directly using these emails and the OTP code **`1989`**:
- **Alumni/Mentor Profile**: `knyawakira@alueducation.com` (Kevin Nyawakira - Software Engineer at Google)
- **Club/Organizer Profile**: `techclub@alustudent.com` (ALU Tech Club)
- **Student Profile**: `dkuzo@alustudent.com` (Divine Kuzo - Year 3 Software Engineering)
- **Student Profile**: `pudongo@alustudent.com` (Paul Udongo - Year 2 Global Challenges)
- **Alumni/Mentor Profile**: `jkamanzi@alueducation.com` (Jimmy Kamanzi - Product Manager at Flutterwave)

---

## Project Structure
A quick roadmap of the codebase:
- `lib/main.dart`: Entry point of the app, initializes the `AppState` and sets up the theme.
- `lib/state/app_state.dart`: Manages global state including active user, feed lists, DMs, notifications, and interaction logic.
- `lib/data/database_helper.dart`: Configures the SQLite database schemas and seeds the mock environment.
- `lib/screens/`: Contains all screen layouts and page flows:
  - `screens/auth/`: Sign in, registration, verification (`welcome_screen.dart`, `verification_screen.dart`).
  - `screens/home/`: Opportunity and achievement feeds.
  - `screens/chat/`: Mutual-follow DM rooms and Space chat channels.
  - `screens/spaces/`: Listing and viewing specific `#topic` spaces.
  - `screens/profile/`: User profile updates, skills, goals, and portfolio links.

---

## Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
