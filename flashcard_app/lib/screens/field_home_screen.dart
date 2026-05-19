import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../data/fields_data.dart';
import '../theme/app_theme.dart';
import '../widgets/notif_scaffold.dart';
import '../widgets/level_card.dart';

class FieldHomeScreen extends StatelessWidget {
  const FieldHomeScreen({super.key});

  static const _levels = ['easy', 'normal', 'hard'];

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


