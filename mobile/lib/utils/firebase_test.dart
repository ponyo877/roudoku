import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

class FirebaseTest {
  static Future<void> testFirebaseInitialization() async {
    try {
      print('Testing Firebase initialization...');
      
      // Test Firebase initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
      
      // Test Firebase Auth instance
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth instance created');
      
      // Test project configuration
      final app = Firebase.app();
      print('✅ Firebase app: ${app.name}');
      print('✅ Project ID: ${app.options.projectId}');
      
      // Test anonymous auth availability (without signing in)
      print('Testing anonymous authentication availability...');
      try {
        // This will fail if anonymous auth is not enabled but won't cause app crash
        await auth.signInAnonymously();
        print('✅ Anonymous authentication is working');
        await auth.signOut();
      } catch (e) {
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'operation-not-allowed':
              print('❌ Anonymous authentication is not enabled in Firebase console');
              print('   Please enable it in: Firebase Console > Authentication > Sign-in methods > Anonymous');
              break;
            case 'network-request-failed':
              print('❌ Network error - check internet connection');
              break;
            default:
              print('❌ Anonymous auth error: ${e.code} - ${e.message}');
          }
        } else {
          print('❌ Unexpected error: $e');
        }
      }
      
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }
}