import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _sendingEmail = false;

  // ── Email report ────────────────────────────────────────────────────────────
  Future<void> _sendReport(AppProvider prov) async {
    final email = AuthService().userEmail;
    if (email == null) {
      _snack('No email address found.', error: true);
      return;
    }
    setState(() => _sendingEmail = true);

    final now = DateTime.now();
    final dayKeys = prov.last7Days;
    final rangeLabel = dayKeys.isNotEmpty
        ? '${dayKeys.first} – ${_fmt(now)}'
        : _fmt(now);

    final ok = await EmailService().sendWeeklyReport(
      toEmail: email,
      userName: prov.auth.displayName,
      totalCards: prov.totalCardsThisWeek,
      quizzesTaken: prov.quizzesTakenThisWeek,
      quizzesPassed: prov.quizzesPassedThisWeek,
      streak: prov.streak,
      dateRange: rangeLabel,
    );
    if (!mounted) return;
    setState(() => _sendingEmail = false);
    _snack(ok ? 'Report sent to $email ✓' : 'Failed to send. Check connection.', error: !ok);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: error ? AppTheme.hard : AppTheme.easy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _studyTime(int cards) {
    final seconds = cards * 30;
    final m = seconds ~/ 60;
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final name     = prov.auth.displayName;
    final email    = prov.auth.userEmail ?? '';
    final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final streak   = prov.streak;
    final cards    = prov.totalCardsThisWeek;
    final quizTaken  = prov.quizzesTakenThisWeek;
    final quizPassed = prov.quizzesPassedThisWeek;
    final unlocked = prov.achievements.where((a) => a.isUnlocked).length;
    final totalA   = prov.achievements.length;
    final certs    = prov.fieldFinalsPassed.length;

    // 7-day activity
    final now   = DateTime.now();
    final daily = prov.dailyCards;
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return daily[key] ?? 0;
    });
    final maxBar = last7.isEmpty ? 1 : math.max(1, last7.reduce((a, b) => a > b ? a : b));

    // Weekly mastery
    final mastery = quizTaken > 0 ? (quizPassed / quizTaken) : 0.0;
    final top = MediaQuery.of(context).viewPadding.top;
    final bot = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3730A3), Color(0xFF5B5FEF), Color(0xFF7C4DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, top + 12, 20, 28),
              child: Column(
                children: [
                  // Back row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.arrow_back_ios_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Back', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                      const Spacer(),
                      const Text('My Stats', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      const SizedBox(width: 72),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Profile
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
                  ],
                  const SizedBox(height: 14),
                  // Quick streak + cards row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HeaderStat(Icons.local_fire_department_rounded, '$streak', 'Day Streak'),
                      Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25), margin: const EdgeInsets.symmetric(horizontal: 18)),
                      _HeaderStat(Icons.style_rounded, '$cards', 'Cards / Week'),
                      Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25), margin: const EdgeInsets.symmetric(horizontal: 18)),
                      _HeaderStat(Icons.school_rounded, '$certs', 'Certifications'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, bot + 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── KPI grid ────────────────────────────────────────────────
                _sectionLabel('OVERVIEW'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    _KpiTile(Icons.style_rounded,                  '$cards',             'Cards/Week',   AppTheme.primary),
                    _KpiTile(Icons.timer_rounded,                  _studyTime(cards),    'Study Time',   const Color(0xFF7C4DFF)),
                    _KpiTile(Icons.quiz_rounded,                   '$quizPassed',        'Quizzes Passed', AppTheme.easy),
                    _KpiTile(Icons.emoji_events_rounded,           '$unlocked/$totalA',  'Badges',       AppTheme.achieve),
                    _KpiTile(Icons.local_fire_department_rounded,  '$streak',            'Day Streak',   AppTheme.normal),
                    _KpiTile(Icons.school_rounded,                 '$certs',             'Certs',        AppTheme.cyan),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Study activity chart ─────────────────────────────────────
                _sectionLabel('STUDY ACTIVITY — LAST 7 DAYS'),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bar_chart_rounded, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          const Text('Daily Cards Studied', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F0E17))),
                          const Spacer(),
                          Text('Total: $cards', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: last7.asMap().entries.map((e) {
                            final val  = e.value;
                            final frac = val / maxBar;
                            const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            final isToday = e.key == 6;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (val > 0)
                                      Text('$val', style: TextStyle(
                                        fontSize: 9, fontWeight: FontWeight.w700,
                                        color: isToday ? AppTheme.primary : const Color(0xFF7C4DFF),
                                      )),
                                    const SizedBox(height: 2),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      height: 64 * frac + (val > 0 ? 4 : 2),
                                      decoration: BoxDecoration(
                                        gradient: val > 0
                                            ? LinearGradient(
                                                colors: isToday
                                                    ? [AppTheme.primary, AppTheme.accent]
                                                    : [const Color(0xFF5B5FEF), const Color(0xFF7C4DFF)],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              )
                                            : null,
                                        color: val > 0 ? null : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      dayLabels[e.key],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                        color: isToday ? AppTheme.primary : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Weekly mastery ring ───────────────────────────────────────
                _sectionLabel('WEEKLY MASTERY'),
                const SizedBox(height: 12),
                _card(
                  child: Row(
                    children: [
                      // Ring chart
                      SizedBox(
                        width: 96, height: 96,
                        child: CustomPaint(
                          painter: _RingPainter(
                            progress: mastery.clamp(0.0, 1.0),
                            trackColor: const Color(0xFFEEEEFF),
                            fillColor: AppTheme.primary,
                          ),
                          child: Center(
                            child: Text(
                              '${(mastery * 100).round()}%',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F0E17)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quiz Performance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F0E17))),
                            const SizedBox(height: 8),
                            _MasteryRow(Icons.check_circle_rounded, '$quizPassed Passed', AppTheme.easy),
                            const SizedBox(height: 6),
                            _MasteryRow(Icons.cancel_rounded, '${quizTaken - quizPassed} Failed', AppTheme.hard),
                            const SizedBox(height: 6),
                            _MasteryRow(Icons.quiz_rounded, '$quizTaken Total', const Color(0xFF6B7280)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Badges section ───────────────────────────────────────────
                _sectionLabel('BADGES — $unlocked / $totalA EARNED'),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalA > 0 ? unlocked / totalA : 0,
                          backgroundColor: const Color(0xFFEEEEFF),
                          valueColor: const AlwaysStoppedAnimation(AppTheme.achieve),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Badge grid
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: prov.achievements.map((a) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: a.isUnlocked
                                  ? AppTheme.achieve.withValues(alpha: 0.12)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: a.isUnlocked
                                    ? AppTheme.achieve.withValues(alpha: 0.40)
                                    : const Color(0xFFE5E7EB),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  a.isUnlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                                  size: 14,
                                  color: a.isUnlocked ? AppTheme.achieve : const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  a.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: a.isUnlocked ? const Color(0xFF0F0E17) : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Send weekly report ────────────────────────────────────────
                _sectionLabel('WEEKLY REPORT'),
                const SizedBox(height: 12),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.email_rounded, size: 20, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Email Weekly Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F0E17))),
                                const SizedBox(height: 3),
                                Text(
                                  email.isNotEmpty ? 'Will be sent to $email' : 'No email address on file',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Report preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9E8FF), width: 0.8),
                        ),
                        child: Column(
                          children: [
                            _ReportRow('Cards Studied', '$cards this week'),
                            _ReportRow('Quizzes Passed', '$quizPassed / $quizTaken'),
                            _ReportRow('Day Streak',     '$streak days'),
                            _ReportRow('Study Time',     _studyTime(cards)),
                            _ReportRow('Badges',         '$unlocked / $totalA earned'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _sendingEmail ? null : () => _sendReport(prov),
                            splashColor: Colors.white.withValues(alpha: 0.20),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF5B5FEF), Color(0xFF7C4DFF)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: _sendingEmail
                                    ? const Center(child: SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send_rounded, size: 16, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Send Weekly Report', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 0.7),
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE9E8FF), width: 0.8),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: child,
  );
}

// ── Header stat widget ─────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _HeaderStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10)),
    ],
  );
}

// ── KPI tile ──────────────────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _KpiTile(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE9E8FF), width: 0.8),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Mastery row ────────────────────────────────────────────────────────────────

class _MasteryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MasteryRow(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ],
  );
}

// ── Report row ─────────────────────────────────────────────────────────────────

class _ReportRow extends StatelessWidget {
  final String label, value;
  const _ReportRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F0E17))),
      ],
    ),
  );
}

// ── Ring painter ───────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor, fillColor;
  const _RingPainter({required this.progress, required this.trackColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const strokeW = 10.0;
    final radius = (math.min(size.width, size.height) - strokeW) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeW);

    if (progress > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false,
          Paint()
            ..color = fillColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
