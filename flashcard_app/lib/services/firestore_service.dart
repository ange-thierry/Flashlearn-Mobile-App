import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles all Firestore operations:
/// - Syncing per-user progress so the admin can view every user's stats
/// - Admin-managed extra study cards, MCQ questions, and final exam questions
class FirestoreService {
  static final FirestoreService _i = FirestoreService._();
  factory FirestoreService() => _i;
  FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User Profile Sync ──────────────────────────────────────────────────────

  Future<void> syncUserProfile({
    required String uid,
    required String displayName,
    required String email,
    required int streak,
    required int cardsThisWeek,
    required int quizzesPassedTotal,
    required int badgesUnlocked,
    required int certifications,
    required Map<String, int> dailyCards,
    List<String> fieldFinalsPassed = const [],
    Map<String, List<String>> fieldCompletedLevels = const {},
    List<Map<String, dynamic>> recentQuizzes = const [],
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'streak': streak,
        'cardsThisWeek': cardsThisWeek,
        'quizzesPassedTotal': quizzesPassedTotal,
        'badgesUnlocked': badgesUnlocked,
        'certifications': certifications,
        'dailyCards': dailyCards,
        'fieldFinalsPassed': fieldFinalsPassed,
        'fieldCompletedLevels': fieldCompletedLevels.map((k, v) => MapEntry(k, v)),
        'recentQuizzes': recentQuizzes.take(10).toList(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // silent — don't crash if offline
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get usersStream =>
      _db.collection('users').orderBy('lastSeen', descending: true).snapshots();

  Future<void> removeUserRecord(String uid) =>
      _db.collection('users').doc(uid).delete();

  /// Update displayName in Firestore (does NOT touch Firebase Auth).
  Future<void> updateUserDisplayName(String uid, String displayName) async {
    try {
      await _db.collection('users').doc(uid).update({
        'displayName': displayName,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Toggle the suspended flag on a user record.
  Future<void> setUserSuspended(String uid, {required bool suspended}) async {
    try {
      await _db.collection('users').doc(uid).update({'suspended': suspended});
    } catch (_) {}
  }

  // ── Admin-managed Study Cards ──────────────────────────────────────────────

  Future<String> saveAdminCard({
    required String fieldId,
    required String level,
    required String question,
    required String answer,
    String? docId,
  }) async {
    final ref = docId != null
        ? _db.collection('admin_cards').doc(docId)
        : _db.collection('admin_cards').doc();
    await ref.set({
      'fieldId': fieldId,
      'level': level,
      'q': question,
      'a': answer,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteAdminCard(String docId) =>
      _db.collection('admin_cards').doc(docId).delete();

  Stream<QuerySnapshot<Map<String, dynamic>>> adminCardsStream(String fieldId) =>
      _db
          .collection('admin_cards')
          .where('fieldId', isEqualTo: fieldId)
          .orderBy('updatedAt', descending: false)
          .snapshots();

  // ── Admin-managed MCQ Questions ────────────────────────────────────────────

  Future<String> saveAdminQuestion({
    required String fieldId,
    required String level,
    required String question,
    required String correctAnswer,
    required List<String> options,
    String? docId,
  }) async {
    final ref = docId != null
        ? _db.collection('admin_questions').doc(docId)
        : _db.collection('admin_questions').doc();
    await ref.set({
      'fieldId': fieldId,
      'level': level,
      'q': question,
      'a': correctAnswer,
      'opts': options,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteAdminQuestion(String docId) =>
      _db.collection('admin_questions').doc(docId).delete();

  Stream<QuerySnapshot<Map<String, dynamic>>> adminQuestionsStream(String fieldId) =>
      _db
          .collection('admin_questions')
          .where('fieldId', isEqualTo: fieldId)
          .orderBy('updatedAt', descending: false)
          .snapshots();

  // ── Admin-managed Final Exam Questions ─────────────────────────────────────

  Future<String> saveAdminFinalQuestion({
    required String fieldId,
    required String question,
    required String correctAnswer,
    required List<String> options,
    String? docId,
  }) async {
    final ref = docId != null
        ? _db.collection('admin_final_questions').doc(docId)
        : _db.collection('admin_final_questions').doc();
    await ref.set({
      'fieldId': fieldId,
      'q': question,
      'a': correctAnswer,
      'opts': options,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteAdminFinalQuestion(String docId) =>
      _db.collection('admin_final_questions').doc(docId).delete();

  Stream<QuerySnapshot<Map<String, dynamic>>> adminFinalQuestionsStream(
          String fieldId) =>
      _db
          .collection('admin_final_questions')
          .where('fieldId', isEqualTo: fieldId)
          .orderBy('updatedAt', descending: false)
          .snapshots();

  // ── Admin Notifications ────────────────────────────────────────────────────

  Future<void> saveAdminNotification({
    required String title,
    required String body,
    required String type,
    required String targetType,
    String targetValue = '',
    DateTime? scheduledAt,
  }) async {
    try {
      await _db.collection('admin_notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'targetType': targetType,
        'targetValue': targetValue,
        'scheduled': scheduledAt != null,
        'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt) : null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get adminNotificationsStream =>
      _db
          .collection('admin_notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();

  Future<void> deleteAdminNotification(String docId) =>
      _db.collection('admin_notifications').doc(docId).delete();

  Future<void> saveNotificationRecord({
    required String title,
    required String body,
    required String type,
    required String topic,
  }) async {
    try {
      await _db.collection('admin_notifications').add({
        'title': title,
        'body': body,
        'type': type,
        'topic': topic,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get notificationsHistoryStream =>
      _db
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .limit(20)
          .snapshots();

  /// Streams admin notifications sent after [since] — used by the user app
  /// to show new admin messages in the in-app notification bell.
  /// Using where + orderBy on the same field avoids a composite-index requirement.
  Stream<QuerySnapshot<Map<String, dynamic>>> adminNotificationsSince(DateTime since) =>
      _db
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .where('sentAt', isGreaterThan: Timestamp.fromDate(since))
          .snapshots();

  // ── Reset User Progress ────────────────────────────────────────────────────

  Future<void> resetUserProgress(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'streak': 0,
        'cardsThisWeek': 0,
        'quizzesPassedTotal': 0,
        'badgesUnlocked': 0,
        'certifications': 0,
        'dailyCards': {},
        'fieldFinalsPassed': [],
        'fieldCompletedLevels': {},
        'recentQuizzes': [],
      });
    } catch (_) {}
  }
}
