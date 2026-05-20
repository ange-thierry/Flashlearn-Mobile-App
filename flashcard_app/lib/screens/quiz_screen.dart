import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notif_scaffold.dart';
// ── Field gradient helper ────────────────────────────────────────────────────
List<Color> _gradFor(String? levelKey, bool isExam) {
  if (isExam) {
    return [const Color(0xFF0F2417), const Color(0xFF15803D), const Color(0xFF22C55E)];
  }
  return switch (levelKey) {
    'easy'   => [const Color(0xFF064E3B), const Color(0xFF059669), const Color(0xFF34D399)],
    'normal' => [const Color(0xFF7C2D12), const Color(0xFFC2410C), const Color(0xFFFB923C)],
    'hard'   => [const Color(0xFF450A0A), const Color(0xFFB91C1C), const Color(0xFFF87171)],
    _        => [const Color(0xFF1E3A5F), const Color(0xFF2563EB), const Color(0xFF60A5FA)],
  };
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  static const _optionLabels = ['A', 'B', 'C', 'D'];
  static const _questionSeconds = 30;

  String? _selectedAnswer;
  bool _showFeedback = false;
  bool _timedOut = false;
  Timer? _feedbackTimer;
  Timer? _questionTimer;
  int _timeLeft = _questionSeconds;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  late AnimationController _optionEntranceCtrl;
  late AnimationController _cardEntranceCtrl;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), reverseDuration: const Duration(milliseconds: 500));
    _pulse = Tween<double>(begin: 1.0, end: 1.18).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _optionEntranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _cardEntranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _cardEntranceCtrl.forward();
    _startQuestionTimer();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose(); _flipCtrl.dispose();
    _optionEntranceCtrl.dispose(); _cardEntranceCtrl.dispose();
    _questionTimer?.cancel(); _feedbackTimer?.cancel();
    super.dispose();
  }

  void _flipToBack() {
    if (_isFlipped) return;
    SoundService.playFlip();
    _flipCtrl.forward();
    setState(() => _isFlipped = true);
    _optionEntranceCtrl.forward(from: 0);
  }

  void _flipToFront() {
    if (!_isFlipped || _showFeedback) return;
    _flipCtrl.reverse();
    setState(() => _isFlipped = false);
  }

  void _resetFlip() {
    _flipCtrl.reset(); _optionEntranceCtrl.reset(); _cardEntranceCtrl.reset();
    _isFlipped = false;
    _cardEntranceCtrl.forward();
  }

  void _startQuestionTimer() {
    _timeLeft = _questionSeconds; _timedOut = false;
    _questionTimer?.cancel(); _pulseCtrl.stop();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 8 && !_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      if (_timeLeft <= 0) { t.cancel(); _handleTimeout(); }
    });
  }

  void _handleTimeout() {
    if (_showFeedback || _selectedAnswer != null) return;
    _questionTimer?.cancel(); _pulseCtrl.stop();
    _flipToBack();
    setState(() { _timedOut = true; _showFeedback = true; });
    _scheduleAdvance('');
  }

  void _selectAnswer(String answer) {
    if (_showFeedback) return;
    _questionTimer?.cancel(); _pulseCtrl.stop();
    setState(() { _selectedAnswer = answer; _showFeedback = true; _timedOut = false; });
    _scheduleAdvance(answer);
  }

  void _scheduleAdvance(String answer) {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final prov = context.read<AppProvider>();
      prov.answerQuestion(answer);
      if (!mounted) return;
      if (prov.lastResult != null) {
        Navigator.pushReplacementNamed(context, '/result');
      } else {
        setState(() { _selectedAnswer = null; _showFeedback = false; _timedOut = false; });
        _resetFlip();
        _startQuestionTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    if (!prov.isQuizMode || prov.quizQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.quiz_outlined, size: 36, color: Color(0xFF16A34A)),
            ),
            const SizedBox(height: 16),
            const Text('No quiz available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text('Please start a quiz from the field home screen.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(12)),
                child: const Text('Go Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
    }

    final q = prov.quizQuestions[prov.quizIndex];
    final isExam = prov.isFinalExam;
    final levelKey = isExam ? 'easy' : prov.quizQuestions[0].level;
    final grads = _gradFor(levelKey, isExam);
    final accentColor = grads[1];
    final header = isExam ? 'Final Exam' : '${'easy' == levelKey ? 'Easy' : 'normal' == levelKey ? 'Normal' : 'Hard'} Assessment';

    return NotifScaffold(
      showBell: false,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grads, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(children: [
                  // Quit
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.close_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Quit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  const Spacer(),

                  // ── BIG TIMER ────────────────────────────────────────────
                  ScaleTransition(
                    scale: _timeLeft <= 8 ? _pulse : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _timeLeft <= 8
                            ? Colors.red.withValues(alpha: 0.30)
                            : _timeLeft <= 20
                                ? Colors.orange.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        // Circular progress
                        SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            value: _timeLeft / _questionSeconds,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: AlwaysStoppedAnimation(
                              _timeLeft <= 8 ? Colors.red.shade300 : _timeLeft <= 20 ? Colors.orange.shade300 : Colors.white,
                            ),
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Big number
                        Text(
                          '$_timeLeft',
                          style: TextStyle(
                            color: _timeLeft <= 8 ? Colors.red.shade200 : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text('s', style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 11)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  // Left: header + Q number
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(header, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('Question ${prov.quizIndex + 1} of ${prov.quizQuestions.length}',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                  ])),
                  // Score chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                    ),
                    child: Text('${prov.quizIndex + 1}/${prov.quizQuestions.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ]),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (prov.quizIndex + 1) / prov.quizQuestions.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          // ── Content with rounded top corners ─────────────────────────────
          Expanded(
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Timeout banner
                  if (_timedOut)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      color: Colors.red.withValues(alpha: 0.10),
                      child: const Text('⏱  Time\'s up! The correct answer is shown below.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                    ),

                  // Flip hint
                  if (!_isFlipped && !_showFeedback)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      color: accentColor.withValues(alpha: 0.06),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.touch_app_rounded, size: 14, color: accentColor.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text('Tap the card to reveal answer choices',
                            style: TextStyle(fontSize: 11, color: accentColor.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                      ]),
                    ),

                  // ── Flip Card ──────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        14, 12, 14, 14 + MediaQuery.of(context).viewPadding.bottom,
                      ),
                      child: AnimatedBuilder(
                        animation: _flipAnim,
                        builder: (ctx, _) {
                          final val = _flipAnim.value;
                          final showBack = val >= 0.5;
                          final face = showBack
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(math.pi),
                                  child: _buildBack(q, grads, accentColor),
                                )
                              : FadeTransition(
                                  opacity: _cardEntranceCtrl,
                                  child: _buildFront(q, grads, accentColor, prov.quizIndex + 1),
                                );

                          return GestureDetector(
                            onTap: (!showBack && !_showFeedback) ? _flipToBack : null,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(val * math.pi),
                              child: face,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FRONT: Study-card style with gradient ──────────────────────────────────
  Widget _buildFront(AssessmentQuestion q, List<Color> grads, Color accent, int num) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grads,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: grads[1].withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles (study card style)
          Positioned(top: -18, right: -18,
            child: Container(width: 130, height: 130,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle))),
          Positioned(bottom: -22, left: -18,
            child: Container(width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle))),
          Positioned(top: 60, right: -30,
            child: Container(width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle))),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.quiz_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text('QUESTION $num', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    const Spacer(),
                    const Icon(Icons.flip_rounded, size: 14, color: Colors.white60),
                    const SizedBox(width: 4),
                    const Text('Tap to answer', style: TextStyle(fontSize: 10, color: Colors.white60)),
                  ]),
                ),
                const SizedBox(height: 28),

                // Question text
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      q.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom CTA
                GestureDetector(
                  onTap: _showFeedback ? null : _flipToBack,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('See answer choices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white70),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BACK: Options on white card ────────────────────────────────────────────
  Widget _buildBack(AssessmentQuestion q, List<Color> grads, Color accent) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          // Green top bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grads),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back nav + label
                  Row(children: [
                    GestureDetector(
                      onTap: _showFeedback ? null : _flipToFront,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.arrow_back_ios_rounded, size: 11, color: accent),
                          const SizedBox(width: 3),
                          Text('Question', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                      child: Text('Choose your answer', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Options
                  ...q.options.asMap().entries.map((e) => _buildOption(e.value, e.key, q.correctAnswer, accent)),

                  // Feedback bar
                  if (_showFeedback) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedAnswer == q.correctAnswer
                            ? AppTheme.easy.withValues(alpha: 0.08)
                            : const Color(0xFFF8F7F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedAnswer == q.correctAnswer
                              ? AppTheme.easy.withValues(alpha: 0.30)
                              : const Color(0xFFE0DDD8),
                          width: 0.8,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          _selectedAnswer == q.correctAnswer ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded,
                          size: 16,
                          color: _selectedAnswer == q.correctAnswer ? AppTheme.easy : const Color(0xFF5F5E5A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          _selectedAnswer == q.correctAnswer
                              ? 'Correct! Moving to next question…'
                              : _timedOut ? 'Time\'s up — moving on…' : 'Wrong — Next question in a moment…',
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedAnswer == q.correctAnswer ? AppTheme.easy : const Color(0xFF5F5E5A),
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String opt, int optIdx, String correctAnswer, Color accent) {
    final isCorrect = opt == correctAnswer;
    final isSelected = opt == _selectedAnswer;

    Color borderColor = const Color(0xFFE2E8F0);
    Color bgColor = const Color(0xFFF8FAFC);
    Color textColor = const Color(0xFF0F172A);
    Color labelBg = accent.withValues(alpha: 0.10);
    Color labelText = accent;
    Widget? trailingIcon;

    if (_showFeedback) {
      if (isCorrect) {
        borderColor = AppTheme.easy;
        bgColor = AppTheme.easy.withValues(alpha: 0.08);
        trailingIcon = const Icon(Icons.check_circle_rounded, size: 20, color: AppTheme.easy);
        labelBg = AppTheme.easy.withValues(alpha: 0.15);
        labelText = AppTheme.easy;
      } else if (isSelected && !isCorrect) {
        borderColor = AppTheme.hard;
        bgColor = AppTheme.hard.withValues(alpha: 0.08);
        trailingIcon = const Icon(Icons.cancel_rounded, size: 20, color: AppTheme.hard);
        textColor = AppTheme.hard;
        labelBg = AppTheme.hard.withValues(alpha: 0.12);
        labelText = AppTheme.hard;
      } else {
        bgColor = const Color(0xFFF8F8F8);
        borderColor = const Color(0xFFEEEEEE);
        textColor = const Color(0xFF999999);
        labelBg = const Color(0xFFEEEEEE);
        labelText = const Color(0xFF999999);
      }
    }

    final intervalStart = (optIdx * 0.15).clamp(0.0, 1.0);
    final intervalEnd   = (0.4 + optIdx * 0.15).clamp(0.0, 1.0);

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _optionEntranceCtrl, curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOut))),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
            CurvedAnimation(parent: _optionEntranceCtrl, curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOut))),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showFeedback ? null : () => _selectAnswer(opt),
              splashColor: accent.withValues(alpha: 0.08),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: (_showFeedback && isCorrect) ? 1.8 : 1.0),
                  boxShadow: _showFeedback && isCorrect ? [
                    BoxShadow(color: AppTheme.easy.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 3)),
                  ] : [],
                ),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: labelBg, borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(_optionLabels[optIdx], style: TextStyle(color: labelText, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(opt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor))),
                  if (trailingIcon != null) ...[const SizedBox(width: 8), trailingIcon],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
