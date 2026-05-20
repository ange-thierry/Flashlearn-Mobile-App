import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../data/fields_data.dart';
import '../widgets/notif_scaffold.dart';
import '../widgets/study_card_widget.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final field = prov.selectedField;
    final card = prov.currentCard;

    if (field == null || card == null) {
      return const Scaffold(body: Center(child: Text('No card available')));
    }

    final grad = fieldGradient(field.id);
    final color = fieldColor(field.id);
    final total = prov.currentStudyCards.length;
    final idx = prov.cardIndex;
    final correctCount =
        prov.cardAnswers.values.where((v) => v == 'correct').length;
    final canProceed = prov.hasAnsweredCurrentCard;

    return NotifScaffold(
      showBell: false,
      body: GestureDetector(
        // Swipe left = next card (only if answered)
        // Swipe right = previous card
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -300) {
            // Swipe left  next
            if (canProceed) {
              if (idx < total - 1) {
                prov.nextCard();
              } else {
                prov.completeStudy();
                Navigator.pop(context);
              }
            } else {
              _showMustAnswerSnack(context);
            }
          } else if (velocity > 300) {
            // Swipe right  prev
            prov.prevCard();
          }
        },
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                18,
                MediaQuery.of(context).padding.top + 8,
                18,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top action row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_ios_rounded,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              const Text('Back',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Card progress pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${idx + 1} / $total',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bookmark shortcut
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/bookmarks'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(Icons.bookmark_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    prov.currentLevel.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  field.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Study Cards',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Correct counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.40),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '$correctCount mastered',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (idx + 1) / total,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content with rounded top corners ──────────────────────────
            Expanded(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Must-answer warning
                    if (!canProceed && idx < total - 1)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFFBEB),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFFDE68A), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.info_outline_rounded,
                                  size: 13, color: Color(0xFFD97706)),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Flip the card and mark your answer before moving on.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Card ────────────────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: StudyCardWidget(
                  card: card,
                  gradient: grad,
                  fieldColor: color,
                  level: prov.currentLevel,
                  cardNum: idx + 1,
                  total: total,
                  onCorrect: prov.markCardCorrect,
                  onWrong: prov.markCardWrong,
                  isBookmarked: prov.isCurrentCardBookmarked,
                  onToggleBookmark: prov.toggleCurrentCardBookmark,
                ),
              ),
            ),

            // ── Navigation buttons ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                18, 0, 18, 20 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: [
                  // ── Prev ───────────────────────────────────────────────
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: idx > 0 ? prov.prevCard : null,
                        splashColor: const Color(0xFF5B5FEF).withValues(alpha: 0.08),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: idx > 0
                                ? Colors.white
                                : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: idx > 0
                                  ? const Color(0xFFE0DFFF)
                                  : const Color(0xFFDDDDDD),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_rounded,
                                  size: 13,
                                  color: idx > 0
                                      ? const Color(0xFF1A1A2E)
                                      : const Color(0xFFBBBBBB),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Previous',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: idx > 0
                                        ? const Color(0xFF1A1A2E)
                                        : const Color(0xFFBBBBBB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Next / Finish ───────────────────────────────────────
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (!canProceed) {
                            _showMustAnswerSnack(context);
                            return;
                          }
                          if (idx < total - 1) {
                            prov.nextCard();
                          } else {
                            prov.completeStudy();
                            Navigator.pop(context);
                          }
                        },
                        splashColor: Colors.white.withValues(alpha: 0.20),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: canProceed
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF5B5FEF),
                                      Color(0xFF7C4DFF),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: canProceed ? null : const Color(0xFFCCCCCC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  idx < total - 1 ? 'Next' : 'Finish',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: canProceed
                                        ? Colors.white
                                        : const Color(0xFF888888),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  idx < total - 1
                                      ? Icons.arrow_forward_ios_rounded
                                      : Icons.check_rounded,
                                  size: 13,
                                  color: canProceed
                                      ? Colors.white
                                      : const Color(0xFF888888),
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
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMustAnswerSnack(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 16)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Flip the card and mark yourself first!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
