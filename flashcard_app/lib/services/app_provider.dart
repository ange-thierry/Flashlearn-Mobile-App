import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../data/fields_data.dart';
import '../data/study_card_data.dart';
import '../data/assessment_data.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';

class AppProvider extends ChangeNotifier {
  final NotificationService _notifService = NotificationService();
  final AuthService _authService = AuthService();
  final _uuid = const Uuid();

  // ── Study State ────────────────────────────────────────────────────────────
  List<FieldModel> _fields = builtInFields;
  FieldModel? _selectedField;
  String _currentLevel = 'easy';
  int _cardIndex = 0;
  Map<int, String> _cardAnswers = {};
  List<String> _completedLevels = [];
  int _streak = 0;
  QuizResult? _lastResult;
  bool _isQuizMode = false;
  bool _isFinalExam = false;
  String _quizLevel = 'easy';
  List<AssessmentQuestion> _quizQuestions = [];
  int _quizIndex = 0;
  List<QuizAnswer> _quizAnswers = [];

  // ── New State ──────────────────────────────────────────────────────────────
  Set<String> _bookmarkedCards = {};
  List<StudyHistoryEntry> _studyHistory = [];
  List<Achievement> _achievements = _buildAchievements();
  Achievement? _justUnlocked;
  DateTime? _quizStartTime;
  Set<String> _fieldFinalsPassed = {};
  Map<String, List<String>> _fieldCompletedLevels = {};

  // ── Admin Content (Firestore) ──────────────────────────────────────────────
  // fieldId → level → list of {q, a} cards
  final Map<String, Map<String, List<Map<String, String>>>> _adminStudyCards = {};
  // fieldId → level → list of {q, a, opts} MCQ questions
  final Map<String, Map<String, List<Map<String, dynamic>>>> _adminMcqQuestions = {};
  // fieldId → list of {q, a, opts} final-exam questions
  final Map<String, List<Map<String, dynamic>>> _adminFinalQuestions = {};
  StreamSubscription? _adminCardsSub;
  StreamSubscription? _adminMcqSub;
  StreamSubscription? _adminFinalSub;
  StreamSubscription? _adminNotifSub;
  final Set<String> _shownAdminNotifIds = {};

  // ── Certificate State ──────────────────────────────────────────────────────
  CertificateInfo? _lastCertificate;
  bool _certEmailSent = false;
  bool _certEmailSending = false;

  // ── User Full Name (for certificates) ─────────────────────────────────────
  String? _fullName;

  // ── Theme State ────────────────────────────────────────────────────────────
  bool _isDarkMode = false;

  // ── Weekly Stats (persisted) ────────────────────────────────────────────────
  Map<String, int> _dailyCards = {};
  List<Map<String, dynamic>> _quizLog = [];

  AppProvider() {
    _loadStats();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  List<FieldModel> get fields => _fields;
  FieldModel? get selectedField => _selectedField;
  String get currentLevel => _currentLevel;
  int get cardIndex => _cardIndex;
  Map<int, String> get cardAnswers => _cardAnswers;
  List<String> get completedLevels => _completedLevels;
  int get streak => _streak;
  QuizResult? get lastResult => _lastResult;
  bool get isQuizMode => _isQuizMode;
  bool get isFinalExam => _isFinalExam;
  List<AssessmentQuestion> get quizQuestions => _quizQuestions;
  int get quizIndex => _quizIndex;
  bool get allLevelsComplete => _completedLevels.length >= 3;
  bool get isAdmin => _authService.isAdmin;
  bool get isDarkMode => _isDarkMode;
  AuthService get auth => _authService;
  NotificationService get notifService => _notifService;

  // ── New Getters ────────────────────────────────────────────────────────────
  bool get hasAnsweredCurrentCard => _cardAnswers.containsKey(_cardIndex);
  Set<String> get bookmarkedCards => Set.unmodifiable(_bookmarkedCards);
  Achievement? get justUnlocked => _justUnlocked;
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  List<StudyHistoryEntry> get studyHistory => List.unmodifiable(_studyHistory);
  Set<String> get fieldFinalsPassed => Set.unmodifiable(_fieldFinalsPassed);
  CertificateInfo? get lastCertificate => _lastCertificate;
  bool get certEmailSent => _certEmailSent;
  bool get certEmailSending => _certEmailSending;

  List<String> completedLevelsForField(String fieldId) =>
      List.unmodifiable(_fieldCompletedLevels[fieldId] ?? []);

  String get currentCardBookmarkKey {
    if (_selectedField == null) return '';
    return '${_selectedField!.id}:$_currentLevel:$_cardIndex';
  }

  bool get isCurrentCardBookmarked =>
      _bookmarkedCards.contains(currentCardBookmarkKey);

  int get totalQuizzesPassed =>
      _quizLog.where((q) => q['passed'] == true).length;

  List<double> get performanceTrend {
    final recent = _quizLog.reversed.take(7).toList().reversed.toList();
    return recent.map((q) => ((q['pct'] as num).toInt() / 100.0)).toList();
  }

  List<String> get weakTopics {
    final counts = <String, int>{};
    for (final q in _quizLog) {
      if ((q['pct'] as num).toInt() < 60) {
        final key = '${q['field']}:${q['level']}';
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.take(3).toList();
  }

  // ── Weekly Stats Getters ──────────────────────────────────────────────────
  Map<String, int> get dailyCards => _dailyCards;
  List<Map<String, dynamic>> get quizLog => List.unmodifiable(_quizLog);

  int get totalCardsThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _dailyCards.entries
        .where((e) => DateTime.tryParse(e.key)?.isAfter(cutoff) ?? false)
        .fold(0, (sum, e) => sum + e.value);
  }

  int get quizzesTakenThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _quizLog
        .where((q) =>
            DateTime.tryParse(q['date'] as String)?.isAfter(cutoff) ?? false)
        .length;
  }

  int get quizzesPassedThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _quizLog
        .where((q) =>
            (DateTime.tryParse(q['date'] as String)?.isAfter(cutoff) ??
                false) &&
            q['passed'] == true)
        .length;
  }

  List<String> get last7Days {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
  }

  // ── Persistence Keys ───────────────────────────────────────────────────────
  // Base names — never used directly; always accessed via the _kXxxUser getters
  // which append the current user's UID so each account gets its own data.
  static const _kDailyCards   = 'daily_cards_v1';
  static const _kQuizLog      = 'quiz_log_v1';
  static const _kStreak       = 'streak_v1';
  static const _kBookmarks    = 'bookmarks_v1';
  static const _kAchievements = 'achievements_v1';
  static const _kStudyHistory = 'study_history_v1';
  static const _kFieldFinals  = 'field_finals_v1';
  static const _kFieldLevels  = 'field_levels_v1';
  static const _kFullName     = 'full_name_v1';
  static const _kDarkMode     = 'dark_mode_v1';

  // Unique ID for the signed-in user (Firebase UID > demo email > fallback)
  String get _uid {
    final uid = _authService.currentUser?.uid;
    if (uid != null) return uid;
    final demo = _authService.demoEmail;
    if (demo != null) return demo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'guest';
  }

  String get _kDailyCardsUser   => '${_kDailyCards}_$_uid';
  String get _kQuizLogUser      => '${_kQuizLog}_$_uid';
  String get _kStreakUser       => '${_kStreak}_$_uid';
  String get _kBookmarksUser    => '${_kBookmarks}_$_uid';
  String get _kAchievementsUser => '${_kAchievements}_$_uid';
  String get _kStudyHistoryUser => '${_kStudyHistory}_$_uid';
  String get _kFieldFinalsUser  => '${_kFieldFinals}_$_uid';
  String get _kFieldLevelsUser  => '${_kFieldLevels}_$_uid';
  String get _kFullNameUser     => '${_kFullName}_$_uid';

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();

    final dc = prefs.getString(_kDailyCardsUser);
    if (dc != null) {
      final m = jsonDecode(dc) as Map<String, dynamic>;
      _dailyCards = m.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    final ql = prefs.getString(_kQuizLogUser);
    if (ql != null) {
      _quizLog = (jsonDecode(ql) as List).cast<Map<String, dynamic>>();
    }

    _streak = prefs.getInt(_kStreakUser) ?? 0;

    final bk = prefs.getString(_kBookmarksUser);
    if (bk != null) {
      _bookmarkedCards = Set<String>.from(jsonDecode(bk) as List);
    }

    final ach = prefs.getString(_kAchievementsUser);
    if (ach != null) {
      final achMap = jsonDecode(ach) as Map<String, dynamic>;
      for (int i = 0; i < _achievements.length; i++) {
        final ts = achMap[_achievements[i].id];
        if (ts != null) {
          final dt = DateTime.tryParse(ts as String);
          if (dt != null) {
            _achievements[i] = _achievements[i].copyWith(unlockedAt: dt);
          }
        }
      }
    }

    final hist = prefs.getString(_kStudyHistoryUser);
    if (hist != null) {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      _studyHistory = (jsonDecode(hist) as List)
          .map((m) => StudyHistoryEntry.fromMap(m as Map<String, dynamic>))
          .where((e) => e.studiedAt.isAfter(cutoff))
          .toList();
    }

    final ff = prefs.getString(_kFieldFinalsUser);
    if (ff != null) {
      _fieldFinalsPassed = Set<String>.from(jsonDecode(ff) as List);
    }

    final fl = prefs.getString(_kFieldLevelsUser);
    if (fl != null) {
      final m = jsonDecode(fl) as Map<String, dynamic>;
      _fieldCompletedLevels = m.map((k, v) => MapEntry(k, List<String>.from(v as List)));
    }

    final fn = prefs.getString(_kFullNameUser);
    if (fn != null && fn.isNotEmpty) _fullName = fn;

    _isDarkMode = prefs.getBool(_kDarkMode) ?? false;

    notifyListeners();
    // Sync to Firestore on every startup so admin can see all active users,
    // even for sessions that were already logged in before going through login.
    _syncToFirestore();
    _startAdminNotifListener();
  }

  void _startAdminNotifListener() {
    // Admin users send notifications — they don't need to receive them here.
    if (isAdmin) return;

    _adminNotifSub?.cancel();
    // Show notifications sent in the last 24 h that this session hasn't seen.
    final since = DateTime.now().subtract(const Duration(hours: 24));
    _adminNotifSub = FirestoreService()
        .adminNotificationsSince(since)
        .listen(
      (snap) {
        for (final doc in snap.docs) {
          if (_shownAdminNotifIds.contains(doc.id)) continue;
          _shownAdminNotifIds.add(doc.id);
          final d     = doc.data();
          final title = d['title'] as String? ?? 'Admin Message';
          final body  = d['body']  as String? ?? '';
          final type  = d['type']  as String? ?? 'announcement';
          _notifService.addNotification(
            type: _mapAdminNotifType(type),
            title: title,
            body: body,
          );
        }
      },
      // Silently swallow Firestore auth / index errors so the app never crashes.
      onError: (_) {},
      cancelOnError: false,
    );
  }

  NotifType _mapAdminNotifType(String type) => switch (type) {
    'reminder'    => NotifType.dailyReminder,
    'new_content' => NotifType.newContent,
    'alert'       => NotifType.admin,
    _             => NotifType.admin, // 'announcement' and anything else
  };

  // Call this right after a successful login to wipe in-memory state and
  // reload from the newly signed-in user's storage partition.
  Future<void> reloadForCurrentUser() async {
    _dailyCards = {};
    _quizLog = [];
    _streak = 0;
    _bookmarkedCards = {};
    _achievements = _buildAchievements();
    _studyHistory = [];
    _fieldFinalsPassed = {};
    _fieldCompletedLevels = {};
    _selectedField = null;
    _currentLevel = 'easy';
    _cardIndex = 0;
    _cardAnswers = {};
    _completedLevels = [];
    _lastResult = null;
    _justUnlocked = null;
    _lastCertificate = null;
    _certEmailSent = false;
    _certEmailSending = false;
    _fullName = null;
    _shownAdminNotifIds.clear();
    await _loadStats();
    _syncToFirestore();
  }

  void _syncToFirestore() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final recentQuizzes = _quizLog.reversed.take(10).map((q) => Map<String, dynamic>.from(q)).toList();
    FirestoreService().syncUserProfile(
      uid: uid,
      displayName: _authService.displayName,
      email: _authService.userEmail ?? '',
      streak: _streak,
      cardsThisWeek: totalCardsThisWeek,
      quizzesPassedTotal: totalQuizzesPassed,
      badgesUnlocked: _achievements.where((a) => a.isUnlocked).length,
      certifications: _fieldFinalsPassed.length,
      dailyCards: Map.from(_dailyCards),
      fieldFinalsPassed: _fieldFinalsPassed.toList(),
      fieldCompletedLevels: Map.fromEntries(
        _fieldCompletedLevels.entries.map((e) => MapEntry(e.key, List<String>.from(e.value))),
      ),
      recentQuizzes: recentQuizzes,
    );
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDailyCardsUser, jsonEncode(_dailyCards));

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _quizLog = _quizLog
        .where((q) =>
            DateTime.tryParse(q['date'] as String)?.isAfter(cutoff) ?? false)
        .toList();
    await prefs.setString(_kQuizLogUser, jsonEncode(_quizLog));
    await prefs.setInt(_kStreakUser, _streak);
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBookmarksUser, jsonEncode(_bookmarkedCards.toList()));
  }

  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, String>{};
    for (final a in _achievements) {
      if (a.isUnlocked) map[a.id] = a.unlockedAt!.toIso8601String();
    }
    await prefs.setString(_kAchievementsUser, jsonEncode(map));
  }

  Future<void> _saveStudyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _studyHistory =
        _studyHistory.where((e) => e.studiedAt.isAfter(cutoff)).toList();
    await prefs.setString(
        _kStudyHistoryUser,
        jsonEncode(_studyHistory.map((e) => e.toMap()).toList()));
  }

  Future<void> _saveFieldFinals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFieldFinalsUser, jsonEncode(_fieldFinalsPassed.toList()));
  }

  Future<void> _saveFieldLevels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFieldLevelsUser,
        jsonEncode(_fieldCompletedLevels.map((k, v) => MapEntry(k, v))));
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _recordCardStudied() {
    _dailyCards[_todayKey] = (_dailyCards[_todayKey] ?? 0) + 1;
    _saveStats();
  }

  void _recordStudyHistory(bool wasCorrect) {
    if (_selectedField == null) return;
    _studyHistory.add(StudyHistoryEntry(
      fieldId: _selectedField!.id,
      level: _currentLevel,
      cardIndex: _cardIndex,
      wasCorrect: wasCorrect,
      studiedAt: DateTime.now(),
    ));
    _saveStudyHistory();
  }

  // ── Achievement Definitions ────────────────────────────────────────────────
  static List<Achievement> _buildAchievements() => [
        Achievement(
            id: 'streak_7',
            name: '7-Day Study Streak',
            description: 'Study for 7 consecutive days',
            icon: 'fire'),
        Achievement(
            id: 'quiz_champion',
            name: 'Quiz Champion',
            description: 'Pass 5 or more quizzes',
            icon: 'trophy'),
        Achievement(
            id: 'fast_learner',
            name: 'Fast Learner',
            description: 'Complete a quiz in under 60 seconds',
            icon: 'bolt'),
        Achievement(
            id: 'first_bookmark',
            name: 'First Bookmark',
            description: 'Bookmark your first card',
            icon: 'bookmark'),
        Achievement(
            id: 'perfect_score',
            name: 'Perfect Score',
            description: 'Score 100% on any quiz',
            icon: 'grade'),
        Achievement(
            id: 'math_expert',
            name: 'Mathematics Expert',
            description: 'Pass the Mathematics final exam',
            icon: 'calculate'),
        Achievement(
            id: 'science_expert',
            name: 'Science Expert',
            description: 'Pass the Science final exam',
            icon: 'science'),
        Achievement(
            id: 'history_expert',
            name: 'History Expert',
            description: 'Pass the History final exam',
            icon: 'history'),
        Achievement(
            id: 'geography_expert',
            name: 'Geography Expert',
            description: 'Pass the Geography final exam',
            icon: 'geography'),
        Achievement(
            id: 'literature_expert',
            name: 'Literature Expert',
            description: 'Pass the Literature final exam',
            icon: 'literature'),
        Achievement(
            id: 'cs_expert',
            name: 'CS Expert',
            description: 'Pass the Computer Science final exam',
            icon: 'cs'),
      ];

  void _checkAchievements({
    int? quizTimeSecs,
    int? quizPct,
    bool? finalExamPassed,
    String? fieldId,
  }) {
    bool anyUnlocked = false;
    Achievement? lastUnlocked;

    void tryUnlock(String id) {
      final idx = _achievements.indexWhere((a) => a.id == id);
      if (idx < 0 || _achievements[idx].isUnlocked) return;
      _achievements[idx] =
          _achievements[idx].copyWith(unlockedAt: DateTime.now());
      _notifService.addNotification(
        type: NotifType.achievement,
        title: 'Achievement Unlocked!',
        body:
            '${_achievements[idx].name}: ${_achievements[idx].description}',
      );
      lastUnlocked = _achievements[idx];
      anyUnlocked = true;
    }

    if (_streak >= 7) tryUnlock('streak_7');
    if (totalQuizzesPassed >= 5) tryUnlock('quiz_champion');
    if (quizTimeSecs != null && quizTimeSecs > 0 && quizTimeSecs < 60) {
      tryUnlock('fast_learner');
    }
    if (quizPct != null && quizPct == 100) tryUnlock('perfect_score');
    if (_bookmarkedCards.isNotEmpty) tryUnlock('first_bookmark');
    if (finalExamPassed == true && fieldId != null) {
      tryUnlock('${fieldId}_expert');
    }

    if (anyUnlocked) {
      _justUnlocked = lastUnlocked;
      _saveAchievements();
    }
  }

  void clearJustUnlocked() {
    _justUnlocked = null;
    notifyListeners();
  }

  // ── Certificate ───────────────────────────────────────────────────────────

  void _issueCertificate(String fieldId) {
    final fieldName = _selectedField?.name ?? fieldId;
    final uid = (_authService.currentUser?.uid ?? _uid).padRight(8, '0');
    final certId = 'FL-${fieldId.toUpperCase()}-${uid.substring(0, 8).toUpperCase()}';
    // Use explicitly saved full name; fall back to auth display name.
    final userName = _fullName ?? _authService.displayName;
    _lastCertificate = CertificateInfo(
      id: certId,
      fieldId: fieldId,
      fieldName: fieldName,
      userName: userName,
      issuedAt: DateTime.now(),
    );
    _certEmailSent = false;
    _certEmailSending = true;
    notifyListeners();
    _sendCertEmail(_lastCertificate!);
  }

  Future<void> _sendCertEmail(CertificateInfo cert) async {
    final email = _authService.userEmail;
    if (email == null || email.isEmpty) {
      _certEmailSending = false;
      notifyListeners();
      return;
    }
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final date = '${cert.issuedAt.day} ${months[cert.issuedAt.month - 1]} ${cert.issuedAt.year}';
    final grad = _fieldHexGradient(cert.fieldId);
    final ok = await EmailService().sendCertificate(
      toEmail: email,
      userName: cert.userName,
      fieldName: cert.fieldName,
      certificateId: cert.id,
      completionDate: date,
      fieldGradientStart: grad[0],
      fieldGradientEnd: grad[1],
    );
    _certEmailSent = ok;
    _certEmailSending = false;
    if (ok) {
      _notifService.addNotification(
        type: NotifType.achievement,
        title: 'Certificate Emailed!',
        body: 'Your ${cert.fieldName} certificate has been sent to $email',
      );
    }
    notifyListeners();
  }

  // Returns hex color strings (without #) for a field's gradient.
  List<String> _fieldHexGradient(String fieldId) {
    const map = <String, List<String>>{
      'math':       ['3730A3', '5B5FEF'],
      'science':    ['0D3D2A', '1A6B4A'],
      'history':    ['7C2D12', 'C2410C'],
      'geography':  ['1E3A5F', '2563EB'],
      'literature': ['6B21A8', '9333EA'],
      'cs':         ['064E3B', '059669'],
    };
    return map[fieldId] ?? ['1A1A2E', '3A3A5E'];
  }

  void clearCertificate() {
    _lastCertificate = null;
    _certEmailSent = false;
    _certEmailSending = false;
    notifyListeners();
  }

  // ── Full Name ──────────────────────────────────────────────────────────────

  bool get hasExplicitFullName => _fullName != null && _fullName!.isNotEmpty;
  String get fullName => _fullName ?? _authService.displayName;

  Future<void> setFullName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _fullName = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFullNameUser, trimmed);
    // Update any pending certificate with the new name and re-send email.
    if (_lastCertificate != null) {
      _lastCertificate = CertificateInfo(
        id: _lastCertificate!.id,
        fieldId: _lastCertificate!.fieldId,
        fieldName: _lastCertificate!.fieldName,
        userName: trimmed,
        issuedAt: _lastCertificate!.issuedAt,
      );
      _certEmailSent = false;
      _certEmailSending = true;
      notifyListeners();
      _sendCertEmail(_lastCertificate!);
    } else {
      notifyListeners();
    }
  }

  /// Restores certificate info for a previously completed field (no email re-send).
  void loadCertificateFor(String fieldId) {
    if (!_fieldFinalsPassed.contains(fieldId)) return;
    final fieldName = _fields.firstWhere(
      (f) => f.id == fieldId,
      orElse: () => _fields.first,
    ).name;
    final uid = (_authService.currentUser?.uid ?? _uid).padRight(8, '0');
    final certId = 'FL-${fieldId.toUpperCase()}-${uid.substring(0, 8).toUpperCase()}';
    _lastCertificate = CertificateInfo(
      id: certId,
      fieldId: fieldId,
      fieldName: fieldName,
      userName: _authService.displayName,
      issuedAt: DateTime.now(),
    );
    _certEmailSent = true; // already sent during original exam pass
    _certEmailSending = false;
    notifyListeners();
  }

  // ── Bookmark ──────────────────────────────────────────────────────────────
  void toggleCurrentCardBookmark() {
    final key = currentCardBookmarkKey;
    if (key.isEmpty) return;
    if (_bookmarkedCards.contains(key)) {
      _bookmarkedCards.remove(key);
    } else {
      _bookmarkedCards.add(key);
    }
    _saveBookmarks();
    _checkAchievements();
    notifyListeners();
  }

  void removeBookmark(String key) {
    _bookmarkedCards.remove(key);
    _saveBookmarks();
    notifyListeners();
  }

  // ── Study Cards ───────────────────────────────────────────────────────────
  List<Map<String, String>> get currentStudyCards {
    if (_selectedField == null) return [];
    final fieldId = _selectedField!.id;
    final local = List<Map<String, String>>.from(
      studyCardData[fieldId]?[_currentLevel] ?? [],
    );
    final admin = List<Map<String, String>>.from(
      _adminStudyCards[fieldId]?[_currentLevel] ?? [],
    );
    return [...local, ...admin];
  }

  Map<String, String>? get currentCard {
    final cards = currentStudyCards;
    if (_cardIndex >= cards.length) return null;
    return cards[_cardIndex];
  }

  // ── Field Selection ───────────────────────────────────────────────────────
  void selectField(FieldModel field) {
    _selectedField = field;
    _currentLevel = 'easy';
    _cardIndex = 0;
    _cardAnswers = {};
    _completedLevels = List<String>.from(_fieldCompletedLevels[field.id] ?? []);
    _subscribeToAdminContent(field.id);
    _notifService.addNotification(
      type: NotifType.newContent,
      title: '${field.name} Unlocked',
      body: '30 study cards + MCQ assessments ready. Start with Easy!',
    );
    notifyListeners();
  }

  // ── Admin Content Stream Subscriptions ───────────────────────────────────
  void _subscribeToAdminContent(String fieldId) {
    _adminCardsSub?.cancel();
    _adminMcqSub?.cancel();
    _adminFinalSub?.cancel();

    _adminCardsSub = FirestoreService().adminCardsStream(fieldId).listen(
      (snap) {
        final byLevel = <String, List<Map<String, String>>>{};
        for (final doc in snap.docs) {
          final d = doc.data();
          final level = (d['level'] as String?) ?? 'easy';
          byLevel.putIfAbsent(level, () => []);
          byLevel[level]!.add({
            'q': (d['q'] as String?) ?? '',
            'a': (d['a'] as String?) ?? '',
          });
        }
        _adminStudyCards[fieldId] = byLevel;
        notifyListeners();
      },
      onError: (_) {},
    );

    _adminMcqSub = FirestoreService().adminQuestionsStream(fieldId).listen(
      (snap) {
        final byLevel = <String, List<Map<String, dynamic>>>{};
        for (final doc in snap.docs) {
          final d = doc.data();
          final level = (d['level'] as String?) ?? 'easy';
          byLevel.putIfAbsent(level, () => []);
          byLevel[level]!.add({
            'q': (d['q'] as String?) ?? '',
            'a': (d['a'] as String?) ?? '',
            'opts': List<String>.from((d['opts'] as List?) ?? []),
          });
        }
        _adminMcqQuestions[fieldId] = byLevel;
        notifyListeners();
      },
      onError: (_) {},
    );

    _adminFinalSub = FirestoreService().adminFinalQuestionsStream(fieldId).listen(
      (snap) {
        _adminFinalQuestions[fieldId] = snap.docs.map((doc) {
          final d = doc.data();
          return <String, dynamic>{
            'q': (d['q'] as String?) ?? '',
            'a': (d['a'] as String?) ?? '',
            'opts': List<String>.from((d['opts'] as List?) ?? []),
          };
        }).toList();
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _adminCardsSub?.cancel();
    _adminMcqSub?.cancel();
    _adminFinalSub?.cancel();
    _adminNotifSub?.cancel();
    super.dispose();
  }

  void setLevel(String level) {
    _currentLevel = level;
    _cardIndex = 0;
    _cardAnswers = {};
    notifyListeners();
  }

  // ── Card Navigation ───────────────────────────────────────────────────────
  void nextCard() {
    if (!hasAnsweredCurrentCard) return; // must answer before proceeding
    if (_cardIndex < currentStudyCards.length - 1) {
      _cardIndex++;
      notifyListeners();
    }
  }

  void prevCard() {
    if (_cardIndex > 0) {
      _cardIndex--;
      notifyListeners();
    }
  }

  void markCardCorrect() {
    _cardAnswers[_cardIndex] = 'correct';
    _recordCardStudied();
    _recordStudyHistory(true);
    _checkAchievements();
    notifyListeners();
  }

  void markCardWrong() {
    _cardAnswers[_cardIndex] = 'wrong';
    _recordCardStudied();
    _recordStudyHistory(false);
    notifyListeners();
  }

  void completeStudy() {
    if (_selectedField != null) {
      _notifService.notifyCardStudied(_selectedField!.name, _currentLevel);
    }
    notifyListeners();
  }

  // ── Assessment / Quiz ─────────────────────────────────────────────────────
  void startAssessment(String level) {
    _quizLevel = level;
    _isFinalExam = false;
    _isQuizMode = true;
    _quizIndex = 0;
    _quizAnswers = [];

    final fieldId = _selectedField?.id ?? 'math';
    final rawData = assessmentData[fieldId] ?? assessmentData['math']!;
    final localData = List<Map<String, dynamic>>.from(rawData[level] ?? []);
    final adminData = List<Map<String, dynamic>>.from(
      _adminMcqQuestions[fieldId]?[level] ?? [],
    );
    _quizQuestions = [...localData, ...adminData]
        .map((m) => AssessmentQuestion(
              id: _uuid.v4(),
              fieldId: _selectedField?.id ?? 'math',
              level: level,
              question: m['q'] as String,
              correctAnswer: m['a'] as String,
              options: List<String>.from(m['opts'] as List),
            ))
        .toList()
      ..shuffle(Random());

    _quizStartTime = DateTime.now();
    notifyListeners();
  }

  void startFinalExam() {
    _isFinalExam = true;
    _isQuizMode = true;
    _quizIndex = 0;
    _quizAnswers = [];
    _quizLevel = 'final';

    final fieldId = _selectedField?.id ?? 'math';
    final raw = assessmentData[fieldId] ?? assessmentData['math']!;
    final mixed = <Map<String, dynamic>>[
      ...((raw['easy'] ?? []).take(4)),
      ...((raw['normal'] ?? []).take(3)),
      ...((raw['hard'] ?? []).take(3)),
    ];
    final adminFinal = List<Map<String, dynamic>>.from(
      _adminFinalQuestions[fieldId] ?? [],
    );

    _quizQuestions = [...mixed, ...adminFinal]
        .map((m) => AssessmentQuestion(
              id: _uuid.v4(),
              fieldId: fieldId,
              level: 'final',
              question: m['q'] as String,
              correctAnswer: m['a'] as String,
              options: List<String>.from(m['opts'] as List),
            ))
        .toList()
      ..shuffle(Random());

    _quizStartTime = DateTime.now();
    notifyListeners();
  }

  void answerQuestion(String answer) {
    if (_quizIndex >= _quizQuestions.length) return;
    final current = _quizQuestions[_quizIndex];
    final isCorrect = answer.isNotEmpty && answer == current.correctAnswer;

    _quizAnswers.add(QuizAnswer(
      question: current.question,
      chosen: answer,
      correct: current.correctAnswer,
      isCorrect: isCorrect,
    ));

    if (_quizIndex + 1 >= _quizQuestions.length) {
      _finishQuiz();
    } else {
      _quizIndex++;
      notifyListeners();
    }
  }

  void _finishQuiz() {
    final timeTaken = _quizStartTime != null
        ? DateTime.now().difference(_quizStartTime!).inSeconds
        : 0;

    final score = _quizAnswers.where((a) => a.isCorrect).length;
    final total = _quizAnswers.length;
    final pct = ((score / total) * 100).round();
    final passed = pct >= 60;
    final fieldId = _selectedField?.id ?? '';

    _lastResult = QuizResult(
      answers: List.from(_quizAnswers),
      score: score,
      total: total,
      percentage: pct,
      passed: passed,
      level: _quizLevel,
      isFinalExam: _isFinalExam,
      fieldId: fieldId,
      timeTaken: timeTaken,
    );

    _isQuizMode = false;

    _quizLog.add({
      'date': _todayKey,
      'passed': passed,
      'pct': pct,
      'field': fieldId,
      'level': _quizLevel,
      'timeTaken': timeTaken,
    });

    if (_isFinalExam) {
      _notifService.notifyExamResult(pct, score, total, passed);
      if (passed) {
        _notifService.notifyCourseComplete(_selectedField?.name ?? '');
        _fieldFinalsPassed.add(fieldId);
        _saveFieldFinals();
        _issueCertificate(fieldId);
      }
    } else {
      _notifService.notifyQuizResult(pct, score, total, passed);
      if (passed && !_completedLevels.contains(_quizLevel)) {
        _completedLevels.add(_quizLevel);
        if (fieldId.isNotEmpty) {
          _fieldCompletedLevels[fieldId] = List<String>.from(_completedLevels);
          _saveFieldLevels();
        }
        _streak++;
        _notifService.notifyLevelUnlocked(_quizLevel);
        _notifService.notifyStreakExtended(_streak);
      }
    }

    if (!passed && _quizAnswers.isNotEmpty) {
      final wrongQ = _quizAnswers.firstWhere(
          (a) => !a.isCorrect,
          orElse: () => _quizAnswers.first);
      _notifService.notifyWeakTopic(wrongQ.question);
    }

    _checkAchievements(
      quizTimeSecs: timeTaken,
      quizPct: pct,
      finalExamPassed: _isFinalExam && passed,
      fieldId: fieldId,
    );

    _saveStats();
    _syncToFirestore();
    notifyListeners();
  }

  void retryLastQuiz() {
    if (_lastResult == null) return;
    final wasExam = _lastResult!.isFinalExam;
    final level = _lastResult!.level;
    clearResult();
    if (wasExam) {
      startFinalExam();
    } else {
      startAssessment(level);
    }
  }

  void clearResult() {
    _lastResult = null;
    notifyListeners();
  }

  void retakeField(String fieldId) {
    _fieldFinalsPassed.remove(fieldId);
    _fieldCompletedLevels.remove(fieldId);
    if (_selectedField?.id == fieldId) {
      _completedLevels = [];
      _cardAnswers = {};
      _cardIndex = 0;
      _currentLevel = 'easy';
    }
    _saveFieldFinals();
    _saveFieldLevels();
    notifyListeners();
  }

  void resetForSignOut() {
    _selectedField = null;
    _currentLevel = 'easy';
    _cardIndex = 0;
    _cardAnswers = {};
    _completedLevels = [];
    _isQuizMode = false;
    _isFinalExam = false;
    _quizAnswers = [];
    _lastResult = null;
    _justUnlocked = null;
    _quizStartTime = null;
    _lastCertificate = null;
    _certEmailSent = false;
    _certEmailSending = false;
    notifyListeners();
  }

  // ── Admin CRUD ─────────────────────────────────────────────────────────────
  bool _guardAdmin() {
    if (!isAdmin) {
      _notifService.addNotification(
        type: NotifType.admin,
        title: 'Access Denied',
        body: 'Only $adminEmail can perform this action.',
      );
      return false;
    }
    return true;
  }

  void addField(FieldModel field) {
    if (!_guardAdmin()) return;
    _fields = [..._fields, field];
    _notifService.notifyAdminAction('Field "${field.name}" added successfully.');
    notifyListeners();
  }

  void updateField(FieldModel updated) {
    if (!_guardAdmin()) return;
    _fields = _fields.map((f) => f.id == updated.id ? updated : f).toList();
    _notifService.notifyAdminAction('Field "${updated.name}" updated.');
    notifyListeners();
  }

  void deleteField(String fieldId) {
    if (!_guardAdmin()) return;
    final name = _fields.firstWhere((f) => f.id == fieldId).name;
    _fields = _fields.where((f) => f.id != fieldId).toList();
    _notifService.notifyAdminAction('Field "$name" deleted.');
    notifyListeners();
  }

  void adminUpdateCard(String action) {
    if (!_guardAdmin()) return;
    _notifService.notifyAdminAction(action);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, _isDarkMode);
  }

}
