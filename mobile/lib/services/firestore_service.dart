import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reading_analytics.dart';
import '../models/swipe.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _readingSessionsCollection = 'reading_sessions';
  static const String _swipeLogsCollection = 'swipe_logs';
  static const String _userPreferencesCollection = 'user_preferences';
  static const String _analyticsCollection = 'analytics';

  // Reading Sessions
  Future<void> saveReadingSession(ReadingSession session) async {
    try {
      await _firestore
          .collection(_readingSessionsCollection)
          .doc(session.id)
          .set(session.toMap());
    } catch (e) {
      throw Exception('Failed to save reading session: $e');
    }
  }

  Future<void> updateReadingSession(ReadingSession session) async {
    try {
      await _firestore
          .collection(_readingSessionsCollection)
          .doc(session.id)
          .update(session.toMap());
    } catch (e) {
      throw Exception('Failed to update reading session: $e');
    }
  }

  Future<ReadingSession?> getReadingSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(_readingSessionsCollection)
          .doc(sessionId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return ReadingSession.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get reading session: $e');
    }
  }

  Stream<List<ReadingSession>> getUserReadingSessions(String userId) {
    return _firestore
        .collection(_readingSessionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReadingSession.fromMap(doc.data()))
            .toList());
  }

  // Swipe Logs
  Future<void> saveSwipeLog(SwipeLog swipeLog) async {
    try {
      await _firestore
          .collection(_swipeLogsCollection)
          .doc(swipeLog.id)
          .set(swipeLog.toMap());
    } catch (e) {
      throw Exception('Failed to save swipe log: $e');
    }
  }

  Stream<List<SwipeLog>> getUserSwipeLogs(String userId) {
    return _firestore
        .collection(_swipeLogsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SwipeLog.fromMap(doc.data()))
            .toList());
  }

  // User Preferences
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _firestore
          .collection(_userPreferencesCollection)
          .doc(userId)
          .set({
        ...preferences,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user preferences: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(_userPreferencesCollection)
          .doc(userId)
          .get();
      
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user preferences: $e');
    }
  }

  Stream<Map<String, dynamic>?> watchUserPreferences(String userId) {
    return _firestore
        .collection(_userPreferencesCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  // Analytics Events
  Future<void> logAnalyticsEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      await _firestore
          .collection(_analyticsCollection)
          .add({
        'userId': userId,
        'eventType': eventType,
        'eventData': eventData,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': null, // Can be set if needed
        'appVersion': null, // Can be set from package info
      });
    } catch (e) {
      throw Exception('Failed to log analytics event: $e');
    }
  }

  // Real-time Reading Stats
  Stream<Map<String, dynamic>> getUserReadingStats(String userId) {
    return _firestore
        .collection(_readingSessionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs
          .map((doc) => ReadingSession.fromMap(doc.data()))
          .toList();

      // Calculate stats
      int totalSessions = sessions.length;
      int totalDuration = sessions.fold(0, (sum, session) => sum + session.durationMinutes);
      int booksRead = sessions.map((s) => s.bookId).toSet().length;
      
      DateTime? lastReadDate;
      if (sessions.isNotEmpty) {
        lastReadDate = sessions
            .map((s) => s.startTime)
            .reduce((a, b) => a.isAfter(b) ? a : b);
      }

      return {
        'totalSessions': totalSessions,
        'totalDurationMinutes': totalDuration,
        'booksRead': booksRead,
        'lastReadDate': lastReadDate,
        'averageSessionLength': totalSessions > 0 ? totalDuration / totalSessions : 0,
      };
    });
  }

  // Offline support - batch operations
  Future<void> batchWriteWhenOnline(List<Map<String, dynamic>> operations) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var operation in operations) {
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String;
        final data = operation['data'] as Map<String, dynamic>;
        final operationType = operation['type'] as String; // 'set' or 'update'
        
        final docRef = _firestore.collection(collection).doc(docId);
        
        if (operationType == 'set') {
          batch.set(docRef, data);
        } else if (operationType == 'update') {
          batch.update(docRef, data);
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to execute batch operations: $e');
    }
  }

  // Clear user data (for GDPR compliance)
  Future<void> clearUserData(String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      // Delete reading sessions
      final sessionsQuery = await _firestore
          .collection(_readingSessionsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in sessionsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete swipe logs
      final swipeLogsQuery = await _firestore
          .collection(_swipeLogsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in swipeLogsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user preferences
      batch.delete(_firestore.collection(_userPreferencesCollection).doc(userId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
    }
  }
}