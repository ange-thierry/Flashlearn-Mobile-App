import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_provider.dart';
import '../services/firestore_service.dart';
import '../data/fields_data.dart';
import '../theme/app_theme.dart';
import '../widgets/notif_scaffold.dart';
import '../widgets/level_card.dart';

class FieldHomeScreen extends StatelessWidget {
  const FieldHomeScreen({super.key});

  static const _levels = ['easy', 'normal', 'hard'];

  void _showDeckContentSheet(BuildContext context, AppProvider prov, String fieldId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeckContentSheet(fieldId: fieldId),
    );
  }

  void _confirmRetake(BuildContext context, AppProvider prov, field) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retake Course?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'This will reset all progress for ${field.name}   -  study sessions, assessments, and the final exam. Your achievements will be kept.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              prov.retakeField(field.id as String);
              prov.selectField(field);
            },
            child: const Text('Retake', style: TextStyle(color: Color(0xFF2A9B65), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final field = prov.selectedField;
    if (field == null) {
      return const Scaffold(
          body: Center(child: Text('No field selected')));
    }

    final grad = fieldGradient(field.id);
    final allDone = prov.allLevelsComplete;
    final courseComplete = prov.fieldFinalsPassed.contains(field.id);
    final hasCertificate = courseComplete && !prov.isAdminField(field.id) && !prov.isUserDeck(field.id);
    final currentUid = prov.auth.currentUser?.uid ?? '';
    final isOwnDeck = prov.isUserDeck(field.id) &&
        (prov.deckCreatorUid(field.id) == currentUid || prov.isAdmin);

    return NotifScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          children: [
            // -- Gradient header -------------------------------------------
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Fields', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      if (isOwnDeck) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showDeckContentSheet(context, prov, field.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_note_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Manage', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(field.icon,
                      style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 6),
                  Text(
                    field.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '30 study cards . 3 levels . Assessments & Exam',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  // -- Course-complete banner ----------------------------
                  if (courseComplete) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('🏅', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Course Complete!',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                                    Text('You passed all levels and the final exam.',
                                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _confirmRetake(context, prov, field),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.8),
                                  ),
                                  child: const Text('Retake',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                          if (hasCertificate) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              prov.loadCertificateFor(field.id);
                              Navigator.pushNamed(context, '/certificate');
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDFB84A).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFDFB84A).withValues(alpha: 0.55), width: 1),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.workspace_premium_rounded, size: 15, color: Color(0xFFDFB84A)),
                                  SizedBox(width: 7),
                                  Text('View Certificate',
                                      style: TextStyle(
                                        color: Color(0xFFDFB84A),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      )),
                                ],
                              ),
                            ),
                          ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // Streak card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAEEDA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFAC775), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Text('',
                            style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${prov.streak}-Day Study Streak',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF633806)),
                              ),
                              Text(
                                'Next reward at ${prov.streak + 3} days!',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF854F0B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA7517),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${prov.streak} ',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Level cards
                  for (int i = 0; i < _levels.length; i++)
                    LevelCard(
                      level: _levels[i],
                      levelIndex: i,
                      isLocked: i > 0 &&
                          !prov.completedLevels
                              .contains(_levels[i - 1]),
                      isDone: prov.completedLevels
                          .contains(_levels[i]),
                      studiedCount: _levels[i] == prov.currentLevel
                          ? prov.cardAnswers.length
                          : 0,
                      onStudy: () {
                        prov.setLevel(_levels[i]);
                        Navigator.pushNamed(context, '/study');
                      },
                      onAssess: () {
                        prov.startAssessment(_levels[i]);
                        Navigator.pushNamed(context, '/quiz');
                      },
                    ),

                  // Final exam card
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: allDone || courseComplete ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: courseComplete
                            ? const Color(0xFF0E3D28)
                            : allDone
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFFF0EDE8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: courseComplete
                              ? const Color(0xFF2A9B65)
                              : allDone
                                  ? AppTheme.primary
                                  : const Color(0xFFDDDDDD),
                          width: courseComplete ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(courseComplete ? '' : '',
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            courseComplete ? 'Final Exam  -  Passed!' : 'Final Examination',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: courseComplete || allDone
                                  ? Colors.white
                                  : const Color(0xFF5F5E5A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            courseComplete
                                ? 'You have completed this course '
                                : '10 MCQ questions across all 3 levels',
                            style: TextStyle(
                              fontSize: 11,
                              color: courseComplete
                                  ? const Color(0xFF6DDC9A)
                                  : allDone
                                      ? const Color(0xFF9B8FD4)
                                      : const Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (courseComplete)
                            GestureDetector(
                              onTap: () => _confirmRetake(context, prov, field),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A9B65),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Retake Course',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            )
                          else if (allDone)
                            GestureDetector(
                              onTap: () {
                                prov.startFinalExam();
                                Navigator.pushNamed(context, '/quiz');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5B5FEF), Color(0xFF7C4DFF)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  color: null,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Start Final Exam',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            const Text(
                              'Pass all 3 assessments to unlock',
                              style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DECK CONTENT MANAGEMENT SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _DeckContentSheet extends StatefulWidget {
  final String fieldId;
  const _DeckContentSheet({required this.fieldId});

  @override
  State<_DeckContentSheet> createState() => _DeckContentSheetState();
}

class _DeckContentSheetState extends State<_DeckContentSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _green  = Color(0xFF16A34A);
  static const _ink    = Color(0xFF0F172A);
  static const _sub    = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).viewPadding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.55,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF1E3A5F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manage Deck Content',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                        Text('Add study cards, MCQ & exam questions',
                            style: TextStyle(fontSize: 11, color: _sub)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: _sub,
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  padding: EdgeInsets.zero,
                  tabs: const [
                    Tab(height: 34, text: 'Study Cards'),
                    Tab(height: 34, text: 'MCQ Quiz'),
                    Tab(height: 34, text: 'Final Exam'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _DeckStudyCardsTab(fieldId: widget.fieldId),
                  _DeckMCQTab(fieldId: widget.fieldId),
                  _DeckFinalTab(fieldId: widget.fieldId),
                ],
              ),
            ),
            SizedBox(height: bot),
          ],
        ),
      ),
    );
  }
}

// ── Uniform Card Row Widget (same design for all card types) ──────────────────

class _UniformCardRow extends StatelessWidget {
  final String question;
  final String answer;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UniformCardRow({
    required this.question,
    required this.answer,
    this.badge,
    this.badgeColor = const Color(0xFF16A34A),
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.30), width: 0.8),
                    ),
                    child: Text(badge!, style: TextStyle(fontSize: 9, color: badgeColor, fontWeight: FontWeight.w700)),
                  ),
                ],
                Text(question,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(answer.length > 60 ? '${answer.substring(0, 60)}…' : answer,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(children: [
            _SmallIconBtn(Icons.edit_rounded, const Color(0xFF8B5CF6), onEdit),
            const SizedBox(width: 4),
            _SmallIconBtn(Icons.delete_rounded, const Color(0xFFEF4444), onDelete),
          ]),
        ],
      ),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallIconBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Icon(icon, size: 14, color: color),
    ),
  );
}

// ── Study Cards Tab ────────────────────────────────────────────────────────────

class _DeckStudyCardsTab extends StatelessWidget {
  final String fieldId;
  const _DeckStudyCardsTab({required this.fieldId});

  @override
  Widget build(BuildContext context) {
    const levelColors = {
      'easy': Color(0xFF16A34A),
      'normal': Color(0xFFF59E0B),
      'hard': Color(0xFFEF4444),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Study Cards', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            TextButton.icon(
              onPressed: () => _showCardDialog(context, fieldId),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Card'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().adminCardsStream(fieldId),
          builder: (_, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.style_outlined, size: 40, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 10),
                      Text('No study cards yet', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      Text('Tap "Add Card" to create your first card', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: docs.map((d) {
                final data = d.data();
                final level = data['level'] as String? ?? 'easy';
                final color = levelColors[level] ?? const Color(0xFF16A34A);
                return _UniformCardRow(
                  question: data['q'] as String? ?? '',
                  answer: data['a'] as String? ?? '',
                  badge: level.toUpperCase(),
                  badgeColor: color,
                  onEdit: () => _showCardDialog(context, fieldId,
                      level: level,
                      q: data['q'] as String?,
                      a: data['a'] as String?,
                      docId: d.id),
                  onDelete: () => FirestoreService().deleteAdminCard(d.id),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showCardDialog(BuildContext ctx, String fieldId,
      {String? level, String? q, String? a, String? docId}) {
    final qCtrl = TextEditingController(text: q ?? '');
    final aCtrl = TextEditingController(text: a ?? '');
    String sel = level ?? 'easy';

    showDialog(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(builder: (dlgCtx, setS) {
        final isValid = qCtrl.text.trim().isNotEmpty && aCtrl.text.trim().isNotEmpty;
        return _UniformCardDialog(
          title: docId == null ? 'Add Study Card' : 'Edit Study Card',
          levelPicker: _LevelSelector(selected: sel, onChanged: (v) => setS(() => sel = v)),
          fields: [
            _CardField(ctrl: qCtrl, label: 'Question', hint: 'What is…?', maxLines: 3, onChanged: (_) => setS(() {})),
            const SizedBox(height: 12),
            _CardField(ctrl: aCtrl, label: 'Answer', hint: 'Correct answer…', maxLines: 3, onChanged: (_) => setS(() {})),
          ],
          isValid: isValid,
          onSave: () async {
            await FirestoreService().saveAdminCard(
              fieldId: fieldId,
              level: sel,
              question: qCtrl.text.trim(),
              answer: aCtrl.text.trim(),
              docId: docId,
            );
            if (dlgCtx.mounted) Navigator.pop(dlgCtx);
          },
          onCancel: () => Navigator.pop(dlgCtx),
        );
      }),
    );
  }
}

// ── MCQ Tab ────────────────────────────────────────────────────────────────────

class _DeckMCQTab extends StatelessWidget {
  final String fieldId;
  const _DeckMCQTab({required this.fieldId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('MCQ Questions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            TextButton.icon(
              onPressed: () => _showMCQDialog(context, fieldId),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Question'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().adminQuestionsStream(fieldId),
          builder: (_, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 40, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 10),
                      Text('No MCQ questions yet', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      Text('Tap "Add Question" to create questions', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: docs.map((d) {
                final data = d.data();
                return _UniformCardRow(
                  question: data['q'] as String? ?? '',
                  answer: '✓ ${data['a'] ?? ''}',
                  badge: (data['level'] as String? ?? 'easy').toUpperCase(),
                  badgeColor: const Color(0xFF3B82F6),
                  onEdit: () => _showMCQDialog(context, fieldId,
                      level: data['level'] as String?,
                      question: data['q'] as String?,
                      correct: data['a'] as String?,
                      opts: List<String>.from(data['opts'] as List? ?? []),
                      docId: d.id),
                  onDelete: () => FirestoreService().deleteAdminQuestion(d.id),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showMCQDialog(BuildContext ctx, String fieldId,
      {String? level, String? question, String? correct, List<String>? opts, String? docId}) {
    final qCtrl = TextEditingController(text: question ?? '');
    final cCtrl = TextEditingController(text: correct ?? '');
    final o1 = TextEditingController(text: opts != null && opts.length > 0 ? opts[0] : '');
    final o2 = TextEditingController(text: opts != null && opts.length > 1 ? opts[1] : '');
    final o3 = TextEditingController(text: opts != null && opts.length > 2 ? opts[2] : '');
    final o4 = TextEditingController(text: opts != null && opts.length > 3 ? opts[3] : '');
    String sel = level ?? 'easy';

    showDialog(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(builder: (dlgCtx, setS) {
        final curOpts = [o1.text.trim(), o2.text.trim(), o3.text.trim(), o4.text.trim()].where((o) => o.isNotEmpty).toList();
        final isValid = qCtrl.text.trim().isNotEmpty && cCtrl.text.trim().isNotEmpty && curOpts.length >= 2;
        return _UniformCardDialog(
          title: docId == null ? 'Add MCQ Question' : 'Edit MCQ Question',
          levelPicker: _LevelSelector(selected: sel, onChanged: (v) => setS(() => sel = v)),
          fields: [
            _CardField(ctrl: qCtrl, label: 'Question', hint: 'What is…?', maxLines: 3, onChanged: (_) => setS(() {})),
            const SizedBox(height: 10),
            _CardField(ctrl: cCtrl, label: 'Correct Answer', hint: 'The right answer', onChanged: (_) => setS(() {})),
            const SizedBox(height: 10),
            _CardField(ctrl: o1, label: 'Option 1', hint: '', onChanged: (_) => setS(() {})),
            const SizedBox(height: 8),
            _CardField(ctrl: o2, label: 'Option 2', hint: '', onChanged: (_) => setS(() {})),
            const SizedBox(height: 8),
            _CardField(ctrl: o3, label: 'Option 3 (optional)', hint: '', onChanged: (_) => setS(() {})),
            const SizedBox(height: 8),
            _CardField(ctrl: o4, label: 'Option 4 (optional)', hint: '', onChanged: (_) => setS(() {})),
          ],
          isValid: isValid,
          onSave: () async {
            final options = [o1.text.trim(), o2.text.trim(), o3.text.trim(), o4.text.trim()].where((o) => o.isNotEmpty).toList();
            final a = cCtrl.text.trim();
            if (!options.contains(a)) options.insert(0, a);
            await FirestoreService().saveAdminQuestion(
              fieldId: fieldId,
              level: sel,
              question: qCtrl.text.trim(),
              correctAnswer: a,
              options: options,
              docId: docId,
            );
            if (dlgCtx.mounted) Navigator.pop(dlgCtx);
          },
          onCancel: () => Navigator.pop(dlgCtx),
        );
      }),
    );
  }
}

// ── Final Exam Tab ─────────────────────────────────────────────────────────────

class _DeckFinalTab extends StatelessWidget {
  final String fieldId;
  const _DeckFinalTab({required this.fieldId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Final Exam Questions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            TextButton.icon(
              onPressed: () => _showFinalDialog(context, fieldId),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Question'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().adminFinalQuestionsStream(fieldId),
          builder: (_, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 40, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 10),
                      Text('No final exam questions yet', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      Text('Tap "Add Question" to create exam questions', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: docs.map((d) {
                final data = d.data();
                return _UniformCardRow(
                  question: data['q'] as String? ?? '',
                  answer: '✓ ${data['a'] ?? ''}',
                  badge: 'FINAL',
                  badgeColor: const Color(0xFF8B5CF6),
                  onEdit: () => _showFinalDialog(context, fieldId,
                      question: data['q'] as String?,
                      correct: data['a'] as String?,
                      opts: List<String>.from(data['opts'] as List? ?? []),
                      docId: d.id),
                  onDelete: () => FirestoreService().deleteAdminFinalQuestion(d.id),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showFinalDialog(BuildContext ctx, String fieldId,
      {String? question, String? correct, List<String>? opts, String? docId}) {
    final qCtrl = TextEditingController(text: question ?? '');
    final cCtrl = TextEditingController(text: correct ?? '');
    final o1 = TextEditingController(text: opts != null && opts.length > 0 ? opts[0] : '');
    final o2 = TextEditingController(text: opts != null && opts.length > 1 ? opts[1] : '');
    final o3 = TextEditingController(text: opts != null && opts.length > 2 ? opts[2] : '');
    final o4 = TextEditingController(text: opts != null && opts.length > 3 ? opts[3] : '');

    showDialog(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(builder: (dlgCtx, setS) {
        final curOpts = [o1.text.trim(), o2.text.trim(), o3.text.trim(), o4.text.trim()].where((o) => o.isNotEmpty).toList();
        final isValid = qCtrl.text.trim().isNotEmpty && cCtrl.text.trim().isNotEmpty && curOpts.length >= 2;
        return _UniformCardDialog(
          title: docId == null ? 'Add Final Exam Question' : 'Edit Final Exam Question',
          levelPicker: null,
          fields: [
            _CardField(ctrl: qCtrl, label: 'Question', hint: 'What is…?', maxLines: 3, onChanged: (_) => setS(() {})),
            const SizedBox(height: 10),
            _CardField(ctrl: cCtrl, label: 'Correct Answer', hint: 'The right answer', onChanged: (_) => setS(() {})),
            const SizedBox(height: 10),
            _CardField(ctrl: o1, label: 'Option 1', hint: '', onChanged: (_) => setS(() {})),
            const SizedBox(height: 8),
            _CardField(ctrl: o2, label: 'Option 2', hint: '', onChanged: (_) => setS(() {})),
            const SizedBox(height: 8),
            _CardField(ctrl: o3, label: 'Option 3 (optional)', hint: '', onChanged: (_) => setS(() {})),
            const SizedBox(height: 8),
            _CardField(ctrl: o4, label: 'Option 4 (optional)', hint: '', onChanged: (_) => setS(() {})),
          ],
          isValid: isValid,
          onSave: () async {
            final options = [o1.text.trim(), o2.text.trim(), o3.text.trim(), o4.text.trim()].where((o) => o.isNotEmpty).toList();
            final a = cCtrl.text.trim();
            if (!options.contains(a)) options.insert(0, a);
            await FirestoreService().saveAdminFinalQuestion(
              fieldId: fieldId,
              question: qCtrl.text.trim(),
              correctAnswer: a,
              options: options,
              docId: docId,
            );
            if (dlgCtx.mounted) Navigator.pop(dlgCtx);
          },
          onCancel: () => Navigator.pop(dlgCtx),
        );
      }),
    );
  }
}

// ── Uniform Card Dialog (same design for study / MCQ / exam cards) ─────────────

class _UniformCardDialog extends StatelessWidget {
  final String title;
  final Widget? levelPicker;
  final List<Widget> fields;
  final bool isValid;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _UniformCardDialog({
    required this.title,
    required this.levelPicker,
    required this.fields,
    required this.isValid,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.style_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (levelPicker != null) ...[
              const SizedBox(height: 12),
              levelPicker!,
              const SizedBox(height: 4),
            ],
            ...fields,
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: isValid ? onSave : null,
          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _LevelSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _LevelSelector({required this.selected, required this.onChanged});

  static const _levels = [
    ('easy',   'Easy',   Color(0xFF16A34A)),
    ('normal', 'Normal', Color(0xFFF59E0B)),
    ('hard',   'Hard',   Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _levels.map((l) {
        final (id, label, color) = l;
        final active = id == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? color : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active ? color : color.withValues(alpha: 0.25),
                  width: active ? 1.5 : 0.8,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : color,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CardField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _CardField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
