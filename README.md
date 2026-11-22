# CSC 4360 Homework 02 – Message Board

**Student:** Cuong Mai  
**Pathway:** Undergraduate  
**Platform:** Android

## Project Description

This is a Flutter message board app using Firebase Authentication and Cloud Firestore. Users can register, log in, and create, view, edit, and delete messages. Firebase Security Rules make sure users can only edit or delete their own messages.

## Features

- Splash screen while Firebase loads
- User registration, login, and logout
- User profiles saved in Firestore
- Create, read, update, and delete messages
- Real-time message updates
- Security rules to protect user data and messages
- Error handling for failed operations

## Setup and Run

1. Install Flutter and Firebase tools.
2. Enable Email/Password Authentication and Cloud Firestore in Firebase.
3. Run these commands:

```bash
flutter pub get
flutterfire configure
flutter run
```

4. Publish the security rules from `firestore.rules` in Firebase Console.

## Firebase Database

The app uses two Firestore collections:

- **users:** Stores UID, first name, last name, role, and registration date.
- **messages:** Stores message text, author information, creation time, and edit time.

## Security

- Users must be signed in to view messages.
- Users can only edit or delete their own messages.
- Users can only access their own profiles.
- Firestore Security Rules enforce these restrictions.

## Additional Features

**Spice #1 – Firebase Emulator Suite**

Used local Firebase emulators to test authentication and messages without affecting the real database.

**Spice #2 – Security Rules Testing**

Automated tests verify that users cannot access or modify data without permission.

**Spice #4 – Duplicate Message Prevention**

Firestore transactions prevent duplicate messages from being created when posting multiple times.

## Testing

Tested registration, login, logout, message creation, editing, deleting, real-time updates, and security restrictions.

Screenshots and test results are included in the evidence document.

## Build APK

```bash
flutter build apk --release
```

APK location:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## AI Usage

AI assistance was used during development and is disclosed in the evidence document.