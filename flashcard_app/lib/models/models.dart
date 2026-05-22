// ─── FIELD MODEL ──────────────────────────────────────────────────────────────
class FieldModel {
  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final String desc;
  final List<String> gradientHex;
  final String? createdBy;      // uid of the user who created this deck (null = built-in/admin)
  final String? createdByName;  // display name of creator

  const FieldModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.desc,
    required this.gradientHex,
    this.createdBy,
    this.createdByName,
  });

  factory FieldModel.fromMap(Map<String, dynamic> map) => FieldModel(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        colorValue: map['colorValue'],
        desc: map['desc'],
        gradientHex: List<String>.from(map['gradientHex'] ?? []),
        createdBy: map['createdBy'] as String?,
        createdByName: map['createdByName'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'colorValue': colorValue,
        'desc': desc,
        'gradientHex': gradientHex,
        if (createdBy != null) 'createdBy': createdBy,
        if (createdByName != null) 'createdByName': createdByName,
      };
}

// ─── STUDY CARD MODEL ─────────────────────────────────────────────────────────
class StudyCardModel {
  final String id;
  final String fieldId;
  final String level; // easy | normal | hard
  final String question;
  final String answer;
  final DateTime createdAt;

  const StudyCardModel({
    required this.id,
    required this.fieldId,
    required this.level,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  factory StudyCardModel.fromMap(Map<String, dynamic> map) => StudyCardModel(
        id: map['id'],
        fieldId: map['fieldId'],
        level: map['level'],
        question: map['question'],
        answer: map['answer'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fieldId': fieldId,
        'level': level,
        'question': question,
        'answer': answer,
        'createdAt': createdAt.toIso8601String(),
      };

  StudyCardModel copyWith({String? question, String? answer}) => StudyCardModel(
        id: id,
        fieldId: fieldId,
        level: level,
        question: question ?? this.question,
        answer: answer ?? this.answer,
        createdAt: createdAt,
      );
}

// ─── ASSESSMENT QUESTION MODEL ────────────────────────────────────────────────
class AssessmentQuestion {
  final String id;
  final String fieldId;
  final String level; // easy | normal | hard | final
  final String question;
  final String correctAnswer;
  final List<String> options;

  const AssessmentQuestion({
    required this.id,
    required this.fieldId,
    required this.level,
    required this.question,
    required this.correctAnswer,
    required this.options,
  });

  factory AssessmentQuestion.fromMap(Map<String, dynamic> map) =>
      AssessmentQuestion(
        id: map['id'],
        fieldId: map['fieldId'],
        level: map['level'],
        question: map['question'],
        correctAnswer: map['correctAnswer'],
        options: List<String>.from(map['options']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fieldId': fieldId,
        'level': level,
        'question': question,
        'correctAnswer': correctAnswer,
        'options': options,
      };
}

// ─── QUIZ ANSWER MODEL ───────────────────────────────────────────────────────
class QuizAnswer {
  final String question;
  final String chosen;
  final String correct;
  final bool isCorrect;

  const QuizAnswer({
    required this.question,
    required this.chosen,
    required this.correct,
    required this.isCorrect,
  });
}

// ─── QUIZ RESULT MODEL ───────────────────────────────────────────────────────
class QuizResult {
  final List<QuizAnswer> answers;
  final int score;
  final int total;
  final int percentage;
  final bool passed;
  final String level;
  final bool isFinalExam;
  final String fieldId;
  final int timeTaken; // seconds

  const QuizResult({
    required this.answers,
    required this.score,
    required this.total,
    required this.percentage,
    required this.passed,
    required this.level,
    required this.isFinalExam,
    required this.fieldId,
    this.timeTaken = 0,
  });
}

// ─── NOTIFICATION MODEL ──────────────────────────────────────────────────────
enum NotifType {
  dailyReminder,
  spacedRep,
  quizResult,
  achievement,
  weakTopic,
  progress,
  newContent,
  admin,
}

class AppNotification {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime timestamp;
  bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
  });

  String get icon => {
        NotifType.dailyReminder: 'alarm',
        NotifType.spacedRep: 'refresh',
        NotifType.quizResult: 'target',
        NotifType.achievement: 'trophy',
        NotifType.weakTopic: 'pin',
        NotifType.progress: 'chart',
        NotifType.newContent: 'sparkle',
        NotifType.admin: 'lock',
      }[type]!;

  String get label => {
        NotifType.dailyReminder: 'Daily Reminder',
        NotifType.spacedRep: 'Review Alert',
        NotifType.quizResult: 'Quiz Result',
        NotifType.achievement: 'Achievement',
        NotifType.weakTopic: 'Weak Topic',
        NotifType.progress: 'Progress',
        NotifType.newContent: 'New Content',
        NotifType.admin: 'Admin',
      }[type]!;

  int get colorValue => {
        NotifType.dailyReminder: 0xFF7F77DD,
        NotifType.spacedRep: 0xFF378ADD,
        NotifType.quizResult: 0xFF1D9E75,
        NotifType.achievement: 0xFFBA7517,
        NotifType.weakTopic: 0xFFD85A30,
        NotifType.progress: 0xFFD4537E,
        NotifType.newContent: 0xFF3B6D11,
        NotifType.admin: 0xFF5C4E8A,
      }[type]!;
}

// ─── USER PROGRESS MODEL ──────────────────────────────────────────────────────
class UserProgress {
  final String fieldId;
  final Map<String, int> studiedCards; // level -> count
  final List<String> completedLevels;
  final bool finalExamPassed;
  int streak;
  DateTime lastStudied;

  UserProgress({
    required this.fieldId,
    required this.studiedCards,
    required this.completedLevels,
    this.finalExamPassed = false,
    this.streak = 0,
    required this.lastStudied,
  });
}

// ─── ACHIEVEMENT MODEL ────────────────────────────────────────────────────────
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Achievement copyWith({DateTime? unlockedAt}) => Achievement(
        id: id,
        name: name,
        description: description,
        icon: icon,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

// ─── CERTIFICATE MODEL ───────────────────────────────────────────────────────
class CertificateInfo {
  final String id;
  final String fieldId;
  final String fieldName;
  final String userName;
  final DateTime issuedAt;

  const CertificateInfo({
    required this.id,
    required this.fieldId,
    required this.fieldName,
    required this.userName,
    required this.issuedAt,
  });
}

// ─── STUDY HISTORY ENTRY ──────────────────────────────────────────────────────
class StudyHistoryEntry {
  final String fieldId;
  final String level;
  final int cardIndex;
  final bool wasCorrect;
  final DateTime studiedAt;

  const StudyHistoryEntry({
    required this.fieldId,
    required this.level,
    required this.cardIndex,
    required this.wasCorrect,
    required this.studiedAt,
  });

  Map<String, dynamic> toMap() => {
        'fieldId': fieldId,
        'level': level,
        'cardIndex': cardIndex,
        'wasCorrect': wasCorrect,
        'studiedAt': studiedAt.toIso8601String(),
      };

  factory StudyHistoryEntry.fromMap(Map<String, dynamic> map) =>
      StudyHistoryEntry(
        fieldId: (map['fieldId'] as String?) ?? '',
        level: (map['level'] as String?) ?? 'easy',
        cardIndex: (map['cardIndex'] as num?)?.toInt() ?? 0,
        wasCorrect: (map['wasCorrect'] as bool?) ?? false,
        studiedAt: DateTime.tryParse(map['studiedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
