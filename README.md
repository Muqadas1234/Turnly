# Turnly - Hospital Token & Queue Management App

Flutter + Firebase, MVVM architecture, GetX for state management.

## Setup
1. Install Flutter, then inside this folder run:
   `flutter create . --project-name turnly`
   (adds the android/ and ios/ folders; your lib/ and pubspec.yaml stay as they are)
2. `flutter pub get`
   (package versions in pubspec.yaml may need `flutter pub upgrade` depending on your Flutter version)
3. `dart pub global activate flutterfire_cli` then `flutterfire configure`
4. If FlutterFire generates `firebase_options.dart`, pass `DefaultFirebaseOptions.currentPlatform`
   to `Firebase.initializeApp` in lib/main.dart
5. `flutter run`

## Structure (MVVM)
```
lib/
  main.dart
  models/       data classes (user, hospital, doctor, department, token, family member)
  services/     Firebase communication (auth, firestore, notifications, cloud functions)
  viewmodels/   business logic & state (GetxController)
  views/        UI screens: auth/, patient/, manager/, admin/
  widgets/      reusable UI components
  utils/        constants, routes, bindings, helpers
functions/      Firebase Cloud Functions (TypeScript) - TODO stubs
docs/           Project plan PDF
```
Flow: View shows UI -> ViewModel handles logic -> Model holds data -> Service talks to Firebase.
