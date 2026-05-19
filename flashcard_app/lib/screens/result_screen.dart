import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notif_scaffold.dart';
import '../data/fields_data.dart';
import '../utils/icon_helper.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _nameDialogShown = false;

  // ── Full-name prompt ────────────────────────────────────────────────────────
  void _maybePromptFullName(AppProvider prov) {
    if (_nameDialogShown || prov.hasExplicitFullName) return;
    _nameDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showNameSheet(prov);
    });
  }

  void _showNameSheet(AppProvider prov) {
    final ctrl = TextEditingController(text: prov.fullName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('🏅 Your Certificate Is Ready!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              const Text(
                'Enter your full name exactly as it should appear on the certificate.',
                style: TextStyle(fontSize: 13, color: Color(0xFF5F5E5A), height: 1.5),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. Jean Pierre Habimana',
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF0FDF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFBBF7D0), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _saveName(ctx, ctrl, prov),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveName(ctx, ctrl, prov),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save & Generate Certificate',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
            ),  // Column
          ),    // SingleChildScrollView
        ),
      ),
    );
  }

  void _saveName(BuildContext ctx, TextEditingController ctrl, AppProvider prov) {
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    prov.setFullName(name);
    Navigator.pop(ctx);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  List<String> _suggestions(int pct, List wrongQuestions) {
    final tips = <String>[];
    if (pct == 100) {
      tips.add('Perfect score! Outstanding mastery of this topic.');
      tips.add('Consider challenging yourself with the next level.');
    } else if (pct >= 80) {
      tips.add(
          'Excellent work! A few more practice rounds will get you to 100%.');
      tips.add('Focus on the question(s) you missed to close the gap.');
    } else if (pct >= 60) {
      tips.add('Good progress! You passed, but there is room to improve.');
      tips.add(
          'Review the wrong answers below, then re-read the related study cards.');
    } else if (pct >= 40) {
      tips.add(
          'Keep going — you are close to passing (60%). Review each wrong answer carefully.');
      tips.add('Return to the study cards for this level before retrying.');
    } else {
      tips.add(
          'Start from the beginning. Go through all study cards for this level again.');
      tips.add(
          'Take your time understanding each concept before retrying the assessment.');
    }
    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final r = prov.lastResult;
    if (r == null) {
      return const Scaffold(body: Center(child: Text('No result')));
    }

    final wrongAnswers = r.answers.where((a) => !a.isCorrect).toList();
    final suggestions = _suggestions(r.percentage, wrongAnswers);
    final trend = prov.performanceTrend;
    final isCourseComplete = r.isFinalExam && r.passed;
    final grad = isCourseComplete ? fieldGradient(r.fieldId) : <Color>[];

    if (isCourseComplete) _maybePromptFullName(prov);

    return NotifScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          children: [
            // ── Result header ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              decoration: BoxDecoration(
                gradient: isCourseComplete
                    ? LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: isCourseComplete
                    ? null
                    : (r.passed ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB)),
              ),
              child: Column(
                children: [
                  if (isCourseComplete) ...[
                    // Celebration badge
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDFB84A), Color(0xFF8B6914)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2.5),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: Icon(fieldIconData(r.fieldId), size: 32, color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    isCourseComplete
                        ? '🎉 Course Complete!'
                        : (r.isFinalExam ? 'Exam Complete!' : 'Assessment Done!'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isCourseComplete ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isCourseComplete
                        ? 'You\'ve mastered all of ${prov.selectedField?.name ?? ''}!'
                        : (r.passed ? 'Passed!' : 'Keep practicing'),
                    style: TextStyle(
                      fontSize: 13,
                      color: isCourseComplete ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF5F5E5A),
                    ),
                  ),
                  if (r.timeTaken > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isCourseComplete ? 0.18 : 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '  Completed in ${_formatTime(r.timeTaken)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCourseComplete ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF5F5E5A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Score stats ──────────────────────────────────────────
                  Row(
                    children: [
                      _stat('Score', '${r.percentage}%',
                          r.percentage >= 60 ? AppTheme.easy : AppTheme.hard),
                      const SizedBox(width: 10),
                      _stat('Correct', '${r.score}', AppTheme.easy),
                      const SizedBox(width: 10),
                      _stat('Wrong', '${r.total - r.score}', AppTheme.hard),
                      if (r.timeTaken > 0) ...[
                        const SizedBox(width: 10),
                        _stat('Time', _formatTime(r.timeTaken),
                            AppTheme.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Certificate card (final exam passed) ────────────────
                  if (isCourseComplete) ...[
                    const SizedBox(height: 16),
                    _buildCertificateCard(context, prov, r.fieldId),
                  ],

                  // ── Performance trend ────────────────────────────────────
                  if (trend.length >= 2) ...[
                    _sectionLabel('PERFORMANCE TREND'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFE0DDD8), width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: trend.asMap().entries.map((e) {
                              final pct = e.value;
                              final isLast = e.key == trend.length - 1;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${(pct * 100).round()}%',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isLast
                                              ? AppTheme.primary
                                              : const Color(0xFF888780),
                                          fontWeight: isLast
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 500),
                                        height: 60 * pct + 4,
                                        decoration: BoxDecoration(
                                          color: pct >= 0.6
                                              ? AppTheme.easy.withValues(alpha: 
                                                  isLast ? 1.0 : 0.5)
                                              : AppTheme.hard.withValues(alpha: 
                                                  isLast ? 1.0 : 0.5),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Last 7 quiz scores (newest on right)',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xFF888780)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Improvement suggestions ──────────────────────────────
                  _sectionLabel('IMPROVEMENT TIPS'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: r.passed
                          ? const Color(0xFFF0F8E8)
                          : const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: r.passed
                              ? AppTheme.easy.withValues(alpha: 0.3)
                              : AppTheme.normal.withValues(alpha: 0.4),
                          width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: suggestions
                          .map((s) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.passed ? '💡' : '',
                                      style:
                                          const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF3D3D3D),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Answer review ────────────────────────────────────────
                  _sectionLabel('ANSWER REVIEW'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFE0DDD8), width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...r.answers.asMap().entries.map((e) => Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 11),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.value.isCorrect ? '' : '',
                                        style:
                                            const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              e.value.question,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1A1A2E),
                                                height: 1.4,
                                              ),
                                            ),
                                            if (!e.value.isCorrect) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '✓  ${e.value.correct}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.easy,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              if (e.value.chosen.isNotEmpty)
                                                Text(
                                                  '✗  ${e.value.chosen}',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.hard),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (e.key < r.answers.length - 1)
                                  const Divider(
                                      height: 0,
                                      color: Color(0xFFF5F3F0)),
                              ],
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Actions ──────────────────────────────────────────────

                  // Retry button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(
                              color: AppTheme.primary, width: 1.5),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => prov.retryLastQuiz(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Retry Quiz',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Final exam CTA
                  if (prov.allLevelsComplete && !r.isFinalExam)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A2E)),
                          onPressed: () {
                            prov.clearResult();
                            prov.startFinalExam();
                            Navigator.pushReplacementNamed(
                                context, '/quiz');
                          },
                          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.school_rounded, size: 16, color: Colors.white), SizedBox(width: 6), Text('Take Final Exam', style: TextStyle(color: Colors.white))]),
                        ),
                      ),
                    ),

                  // Achievements shortcut
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBA7517),
                          side: const BorderSide(
                              color: Color(0xFFBA7517), width: 1),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pushNamed(
                            context, '/achievements'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.emoji_events_rounded, size: 16, color: Color(0xFFBA7517)), SizedBox(width: 6), Text('View Achievements ')]),
                            Text(
                              '(${prov.achievements.where((a) => a.isUnlocked).length}/${prov.achievements.length})',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFBA7517)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        prov.clearResult();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/field-home',
                          (route) =>
                              route.settings.name == '/fields',
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Back to Dashboard'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateCard(BuildContext context, AppProvider prov, String fieldId) {
    final grad = fieldGradient(fieldId);
    final fieldClr = fieldColor(fieldId);
    final cert = prov.lastCertificate;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/certificate'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC9B87A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC9B87A).withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gold top strip
            Container(
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B6914), Color(0xFFDFB84A), Color(0xFF8B6914)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
            Row(
              children: [
                // Badge icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: grad),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: fieldClr.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Icon(fieldIconData(fieldId), size: 26, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CERTIFICATE EARNED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B6914),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Certificate of Completion',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                      if (cert != null)
                        Text(
                          cert.id,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF888780), fontFamily: 'monospace'),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8942F)),
              ],
            ),
            const SizedBox(height: 12),
            // Email status row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: prov.certEmailSent
                    ? AppTheme.easy.withValues(alpha: 0.07)
                    : const Color(0xFFFFFBF0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: prov.certEmailSent
                      ? AppTheme.easy.withValues(alpha: 0.25)
                      : const Color(0xFFE8DDB5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    prov.certEmailSent ? Icons.mark_email_read_rounded : Icons.email_outlined,
                    size: 14,
                    color: prov.certEmailSent ? AppTheme.easy : const Color(0xFFB8942F),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prov.certEmailSent
                          ? 'Certificate emailed to ${prov.auth.userEmail ?? "you"}'
                          : prov.certEmailSending
                              ? 'Sending certificate to your email…'
                              : 'Tap to view your certificate',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: prov.certEmailSent ? AppTheme.easy : const Color(0xFFB8942F),
                      ),
                    ),
                  ),
                  if (prov.certEmailSending)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB8942F)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // "View Full Certificate" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/certificate'),
                icon: const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.white),
                label: const Text('View Full Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B6914),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF888780),
          letterSpacing: 0.5,
        ),
      );

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFFE0DDD8), width: 0.5),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF888780)),
              ),
            ],
          ),
        ),
      );
}
