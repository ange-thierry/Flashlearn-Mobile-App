import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LevelCard extends StatelessWidget {
  final String level;
  final int levelIndex;
  final bool isLocked;
  final bool isDone;
  final int studiedCount;
  final VoidCallback onStudy;
  final VoidCallback onAssess;

  const LevelCard({
    super.key,
    required this.level,
    required this.levelIndex,
    required this.isLocked,
    required this.isDone,
    required this.studiedCount,
    required this.onStudy,
    required this.onAssess,
  });

  static const _labels = {'easy': 'Easy', 'normal': 'Normal', 'hard': 'Hard'};
  static const _colors = {
    'easy':   AppTheme.easy,
    'normal': AppTheme.normal,
    'hard':   AppTheme.hard,
  };
  static const _bgs = {
    'easy':   Color(0xFFDCFCE7),
    'normal': Color(0xFFFFF7ED),
    'hard':   Color(0xFFFEE2E2),
  };
  static const _levelIcons = [
    Icons.sentiment_satisfied_alt_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_very_dissatisfied_rounded,
  ];
  static const _prevLabels = ['', 'Easy', 'Normal'];

  @override
  Widget build(BuildContext context) {
    final color = _colors[level]!;
    final bg    = _bgs[level]!;
    final pct   = (studiedCount / 10).clamp(0.0, 1.0);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isLocked ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone ? color.withValues(alpha: 0.40) : const Color(0xFFE9E8FF),
            width: isDone ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDone
                  ? color.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card accent strip ──────────────────────────────────────
              if (isDone)
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.5)],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Level icon badge
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : isLocked
                                    ? Icons.lock_rounded
                                    : _levelIcons[levelIndex],
                            size: 22,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _labels[level]!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F0E17),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '10 study cards · assessment',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        ),
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDone
                                ? color.withValues(alpha: 0.12)
                                : const Color(0xFFF4F4FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDone ? 'Done ✓' : '${(pct * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDone ? color : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isDone ? 1.0 : pct,
                        backgroundColor: const Color(0xFFF4F4FF),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                    if (!isLocked) ...[
                      const SizedBox(height: 12),
                      // Action buttons
                      Row(
                        children: [
                          // Study Cards button
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: onStudy,
                                splashColor: color.withValues(alpha: 0.10),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.style_rounded,
                                            size: 14, color: color),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Study',
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Assessment button
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: onAssess,
                                splashColor:
                                    Colors.white.withValues(alpha: 0.20),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.quiz_rounded,
                                            size: 14,
                                            color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Assessment',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 12, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 5),
                          Text(
                            'Complete ${_prevLabels[levelIndex]} to unlock',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
