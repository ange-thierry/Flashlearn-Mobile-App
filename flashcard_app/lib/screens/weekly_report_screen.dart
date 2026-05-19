import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notif_scaffold.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  bool _sendingEmail = false;

  Future<void> _emailReport({
    required String userName,
    required int totalCards,
    required int taken,
    required int passed,
    required int streak,
    required String rangeLabel,
  }) async {
    final email = AuthService().userEmail;
    if (email == null) {
      _showSnack('No email address found. Please sign in with an email account.', error: true);
      return;
    }
    setState(() => _sendingEmail = true);
    final ok = await EmailService().sendWeeklyReport(
      toEmail: email,
      userName: userName,
      totalCards: totalCards,
      quizzesTaken: taken,
      quizzesPassed: passed,
      streak: streak,
      dateRange: rangeLabel,
    );
    if (!mounted) return;
    setState(() => _sendingEmail = false);
    _showSnack(
      ok ? 'Report sent to $email' : 'Failed to send email. Check your connection.',
      error: !ok,
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: error ? AppTheme.hard : AppTheme.easy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final days = prov.last7Days;
    final dailyCards = prov.dailyCards;
    final totalCards = prov.totalCardsThisWeek;
    final taken = prov.quizzesTakenThisWeek;
    final passed = prov.quizzesPassedThisWeek;
    final streak = prov.streak;

    // Max cards in any day (for bar scaling)
    final maxCards = days.map((d) => dailyCards[d] ?? 0).fold(0, (a, b) => a > b ? a : b);

    // Date range label
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 6));
    final rangeLabel =
        '${_month(weekStart.month)} ${weekStart.day} – ${_month(now.month)} ${now.day}, ${now.year}';

    // Pass rate
    final passRate = taken > 0 ? ((passed / taken) * 100).round() : 0;

    return NotifScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 44, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEEKLY REPORT',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: const Color(0xFF888780), letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 4),
                        Text('Your Progress',
                            style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 2),
                        Text(rangeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  // Email button
                  GestureDetector(
                    onTap: _sendingEmail
                        ? null
                        : () => _emailReport(
                              userName: prov.auth.displayName,
                              totalCards: totalCards,
                              taken: taken,
                              passed: passed,
                              streak: streak,
                              rangeLabel: rangeLabel,
                            ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: _sendingEmail
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                            )
                          : const Icon(Icons.email_outlined, size: 18, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0DDD8)),
                      ),
                      child: const Icon(Icons.close, size: 18, color: AppTheme.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Summary Stats ─────────────────────────────────────────────
              Row(
                children: [
                  _statCard(context, '$totalCards', 'Cards\nStudied', Icons.style_outlined,
                      AppTheme.primary),
                  const SizedBox(width: 10),
                  _statCard(context, '$passed/$taken', 'Quizzes\nPassed',
                      Icons.check_circle_outline, AppTheme.easy),
                  const SizedBox(width: 10),
                  _statCard(context, '$streak', 'Day\nStreak', Icons.local_fire_department,
                      AppTheme.normal),
                ],
              ),
              const SizedBox(height: 24),

              // ── 7-Day Activity Chart ──────────────────────────────────────
              _sectionHeader(context, '📅 Daily Activity', 'Cards studied per day'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0DDD8), width: 0.5),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 110,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: days.map((date) {
                          final count = dailyCards[date] ?? 0;
                          final fraction = maxCards > 0 ? count / maxCards : 0.0;
                          final isToday = date == days.last;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (count > 0)
                                    Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isToday ? AppTheme.primary : const Color(0xFF888780),
                                      ),
                                    ),
                                  const SizedBox(height: 3),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    height: count == 0 ? 4 : (fraction * 90).clamp(4, 90),
                                    decoration: BoxDecoration(
                                      color: count == 0
                                          ? const Color(0xFFE8E6E2)
                                          : isToday
                                              ? AppTheme.primary
                                              : AppTheme.accent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: days.map((date) {
                        final d = DateTime.parse(date);
                        final isToday = date == days.last;
                        return Expanded(
                          child: Text(
                            _dayLabel(d.weekday),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                              color: isToday ? AppTheme.primary : const Color(0xFF888780),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Quiz Performance ──────────────────────────────────────────
              _sectionHeader(context, 'Quiz Performance', 'This week\'s assessment results'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0DDD8), width: 0.5),
                ),
                child: taken == 0
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No assessments taken yet this week.\nComplete a quiz to see your stats here!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF888780)),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Pass rate bar
                          Row(
                            children: [
                              const Text('Pass Rate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(
                                '$passRate%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: passRate >= 60 ? AppTheme.easy : AppTheme.hard,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: passRate / 100,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFF0EDE8),
                              valueColor: AlwaysStoppedAnimation(
                                  passRate >= 60 ? AppTheme.easy : AppTheme.hard),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Quiz log
                          ...prov.quizLog.reversed
                              .where((q) {
                                final cutoff = DateTime.now().subtract(const Duration(days: 7));
                                return DateTime.tryParse(q['date'] as String)?.isAfter(cutoff) ?? false;
                              })
                              .take(5)
                              .map((q) => _quizLogRow(q)),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // ── Streak ────────────────────────────────────────────────────
              _sectionHeader(context, 'Streak', 'Keep studying daily!'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF9500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 44, color: Color(0xFFCC8822)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streak-Day Streak',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          streak == 0
                              ? 'Start studying to build your streak!'
                              : streak < 3
                                  ? 'Great start! Keep it going!'
                                  : streak < 7
                                      ? "You're on fire! Almost a week!"
                                      : 'Incredible dedication!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tips ──────────────────────────────────────────────────────
              _sectionHeader(context, '💡 Study Tips', 'Based on your activity'),
              const SizedBox(height: 14),
              ..._tips(totalCards, passRate, streak).map((tip) => _tipRow(tip)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
          BuildContext context, String value, String label, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Color(0xFF888780), height: 1.3),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeader(BuildContext context, String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(sub, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ],
      );

  Widget _quizLogRow(Map<String, dynamic> q) {
    final passed = q['passed'] as bool;
    final pct = q['pct'] as int;
    final field = (q['field'] as String).toUpperCase();
    final level = (q['level'] as String);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: passed ? AppTheme.easy.withValues(alpha: 0.1) : AppTheme.hard.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              passed ? '✓ PASS' : '✗ FAIL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: passed ? AppTheme.easy : AppTheme.hard,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$field · ${level[0].toUpperCase()}${level.substring(1)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.dark),
            ),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: passed ? AppTheme.easy : AppTheme.hard,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(String tip) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
            Expanded(
              child: Text(tip, style: const TextStyle(fontSize: 13, color: AppTheme.dark, height: 1.5)),
            ),
          ],
        ),
      );

  List<String> _tips(int cards, int passRate, int streak) {
    final tips = <String>[];
    if (cards == 0) {
      tips.add('Study at least 5 cards a day to build strong memory retention.');
    } else if (cards < 10) {
      tips.add('Try to study 10+ cards daily — consistency beats intensity!');
    } else {
      tips.add('Great study volume this week! Keep the momentum going.');
    }
    if (passRate < 60) {
      tips.add('Review the study cards before taking assessments to improve your pass rate.');
    } else {
      tips.add('Strong quiz performance! Challenge yourself with harder levels.');
    }
    if (streak == 0) {
      tips.add('Start your streak today — even 5 minutes of study counts!');
    } else if (streak < 7) {
      tips.add('You\'re building a habit. Daily reminders are set at 8:00 PM to help.');
    } else {
      tips.add('Amazing streak! Spaced repetition is now working at maximum effectiveness.');
    }
    return tips;
  }

  String _dayLabel(int weekday) => const ['', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][weekday];

  String _month(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}
