# Firebase Setup Guide for Aozora StoryWalk

## Prerequisites
- GCP project created and configured
- Firebase CLI installed (`npm install -g firebase-tools`)
- Terraform infrastructure deployed

## Firebase Configuration Steps

### 1. Initialize Firebase Project

```bash
# Login to Firebase
firebase login

# Add Firebase to existing GCP project
firebase projects:addfirebase aozora-storywalk

# Initialize Firebase in the mobile directory
cd mobile
firebase init
```

Select the following services:
- Firestore
- Authentication
- Hosting (optional, for web admin panel)
- Storage

### 2. Configure Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Authentication > Sign-in method
4. Enable the following providers:
   - Email/Password
   - Google Sign-In
   - Apple Sign-In (for iOS)

### 3. Configure Firestore Security Rules

Update `firestore.rules` in the project root:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read books
    match /books/{bookId} {
      allow read: if request.auth != null;
    }
    
    // Allow authenticated users to create swipe logs
    match /swipe_logs/{logId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Allow authenticated users to read/write their sessions
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

Deploy the rules:
```bash
firebase deploy --only firestore:rules
```

### 4. Download Firebase Configuration Files

#### For Android:
1. Go to Project Settings > General
2. Add Android app with package name: `com.aozorastorywalk.roudoku`
3. Download `google-services.json`
4. Place it in `mobile/android/app/`

#### For iOS:
1. Add iOS app with bundle ID: `com.aozorastorywalk.roudoku`
2. Download `GoogleService-Info.plist`
3. Place it in `mobile/ios/Runner/`

### 5. Update Flutter Firebase Configuration

Run the following command in the mobile directory:
```bash
cd mobile
dart run flutterfire_cli:flutterfire configure \
  --project=aozora-storywalk \
  --platforms=android,ios \
  --out=lib/firebase_options.dart
```

### 6. Configure Firebase Cloud Messaging (Optional)

For push notifications:
1. Navigate to Project Settings > Cloud Messaging
2. Note the Server Key and Sender ID
3. For iOS: Upload APNs certificates

### 7. Set up Firebase App Check (Recommended)

For additional security:
1. Navigate to App Check
2. Register your apps
3. Enable enforcement for Firestore and other services

### 8. Environment Variables

Create environment configuration files:

#### `mobile/.env.development`
```
FIREBASE_PROJECT_ID=aozora-storywalk
FIREBASE_AUTH_DOMAIN=aozora-storywalk.firebaseapp.com
FIREBASE_STORAGE_BUCKET=aozora-storywalk.appspot.com
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
FIREBASE_APP_ID=YOUR_APP_ID
```

#### `mobile/.env.production`
```
FIREBASE_PROJECT_ID=aozora-storywalk
FIREBASE_AUTH_DOMAIN=aozora-storywalk.firebaseapp.com
FIREBASE_STORAGE_BUCKET=aozora-storywalk.appspot.com
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
FIREBASE_APP_ID=YOUR_APP_ID
```

### 9. Test Firebase Connection

Create a test script `mobile/lib/utils/firebase_test.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

Future<void> testFirebaseConnection() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Test Firestore connection
    final testDoc = await FirebaseFirestore.instance
        .collection('test')
        .add({'timestamp': FieldValue.serverTimestamp()});
    
    print('Firebase connected successfully! Test doc ID: ${testDoc.id}');
    
    // Clean up
    await testDoc.delete();
  } catch (e) {
    print('Firebase connection error: $e');
  }
}
```

## Troubleshooting

### Common Issues:

1. **Authentication errors**: Ensure SHA-1/SHA-256 fingerprints are added for Android
2. **iOS build errors**: Ensure GoogleService-Info.plist is added to Xcode project
3. **Firestore permission denied**: Check security rules and authentication state
4. **API not enabled**: Enable required APIs in GCP console

### Useful Commands:

```bash
# Check Firebase project
firebase projects:list

# Deploy all Firebase services
firebase deploy

# Deploy specific service
firebase deploy --only firestore
firebase deploy --only auth

# View logs
firebase functions:log
```

## Next Steps

After completing Firebase setup:
1. Test authentication flow in the mobile app
2. Verify Firestore read/write operations
3. Set up monitoring in Firebase Console
4. Configure Firebase Analytics events
5. Implement Firebase Crashlytics for error tracking