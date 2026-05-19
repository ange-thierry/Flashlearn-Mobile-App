import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../services/firestore_service.dart';
import '../data/fields_data.dart';
import '../data/study_card_data.dart';
import '../data/assessment_data.dart';
import '../utils/icon_helper.dart';

// ── Palette: Light Green + White (matches user dashboard) ─────────────────────
const _bg     = Color(0xFFF0FDF4); // mint-green background (same as login screen)
const _surface= Color(0xFFFFFFFF); // white surface
const _card   = Color(0xFFFFFFFF); // white cards
const _cardHi = Color(0xFFDCFCE7); // light green highlight
const _border = Color(0xFFBBF7D0); // green border
const _green  = Color(0xFF16A34A); // primary dark green
// Color(0xFF22C55E) available as _greenLt if needed
const _ink    = Color(0xFF0F172A); // dark text
const _sub    = Color(0xFF64748B); // muted text
const _grey   = Color(0xFF64748B); // alias for sub
const _amber  = Color(0xFFF59E0B); // warning
const _red    = Color(0xFFEF4444); // danger
const _blue   = Color(0xFF3B82F6); // info
const _purple = Color(0xFF8B5CF6); // accent

// Keep white usable for text on colored/gradient backgrounds
const _white  = Color(0xFFFFFFFF);
const _indigo = _purple;
const _violet = Color(0xFF7B5CE0);

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  // ignore: unused_field — reserved for section-level filtering
  String _searchQuery = '';
  late AnimationController _bgCtrl;

  static const _navItems = [
    (Icons.dashboard_rounded,     Icons.dashboard_outlined,     'Overview'),
    (Icons.grid_view_rounded,     Icons.grid_view_outlined,     'Fields'),
    (Icons.library_books_rounded, Icons.library_books_outlined, 'Content'),
    (Icons.timeline_rounded,      Icons.timeline_outlined,      'Activity'),
    (Icons.manage_accounts_rounded, Icons.manage_accounts_outlined, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    if (!prov.isAdmin) return _AccessDeniedScreen();

    final sections = [
      _OverviewSection(prov: prov),
      _FieldsSection(prov: prov),
      _ContentSection(prov: prov),
      const _ActivitySection(),
      const _NotificationsSection(),
    ];

    final isDark = prov.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0D1117) : _bg;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: Stack(
        children: [
          Container(color: bgColor),
          // Subtle green glow top-right
          Positioned(
            top: -60, right: -60,
            child: _GlowOrb(color: _green.withValues(alpha: 0.12), size: 260),
          ),
          // Main content
          Column(
            children: [
              _AdminAppBar(
                navIndex: _navIndex,
                onSearchChanged: (q) => setState(() => _searchQuery = q),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_navIndex),
                    child: sections[_navIndex],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        items: _navItems,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT GLOW ORB
// ─────────────────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _AdminAppBar extends StatefulWidget {
  final int navIndex;
  final ValueChanged<String> onSearchChanged;
  const _AdminAppBar({required this.navIndex, required this.onSearchChanged});

  @override
  State<_AdminAppBar> createState() => _AdminAppBarState();
}

class _AdminAppBarState extends State<_AdminAppBar> {
  final _searchCtrl = TextEditingController();

  static const _subtitles = [
    'Platform at a glance',
    'Manage study subjects',
    'Cards & questions',
    'Learner accounts',
    'Live system feed',
    'Account & settings',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final isDark = prov.isDarkMode;
    final top = MediaQuery.of(context).viewPadding.top;

    final bgColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFF0F6FC) : _ink;
    final subColor = isDark ? const Color(0xFF8B949E) : _sub;
    final greenColor = isDark ? const Color(0xFF3FB950) : _green;
    final borderColor = isDark ? const Color(0xFF30363D) : _green.withValues(alpha: 0.20);
    final inputBg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0FDF4);
    final inputBorder = isDark ? const Color(0xFF30363D) : _border;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.97),
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            boxShadow: [
              BoxShadow(
                color: greenColor.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(16, top + 12, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row 1: Logo · Title · Notification · Profile ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AppLogo(greenColor: greenColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          _subtitles[widget.navIndex],
                          style: TextStyle(color: subColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _AdminAvatar(isDark: isDark, prov: prov),
                ],
              ),
              const SizedBox(height: 12),
              // ── Row 2: Search bar · Theme toggle ──
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: inputBorder, width: 1),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) {
                          setState(() {});
                          widget.onSearchChanged(v);
                        },
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search dashboard...',
                          hintStyle: TextStyle(color: subColor, fontSize: 13),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: subColor,
                            size: 18,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    widget.onSearchChanged('');
                                    setState(() {});
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: subColor,
                                    size: 16,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Dark / Light toggle
                  GestureDetector(
                    onTap: prov.toggleDarkMode,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 64,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? greenColor.withValues(alpha: 0.18)
                            : _green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? greenColor.withValues(alpha: 0.45)
                              : _green.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: isDark
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 26,
                              height: 26,
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isDark ? greenColor : _green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: greenColor.withValues(alpha: 0.40),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  final Color greenColor;
  const _AppLogo({required this.greenColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [greenColor, greenColor.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: greenColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
    );
  }
}

class _NotifBell extends StatelessWidget {
  final bool isDark;
  final Color greenColor;
  const _NotifBell({required this.isDark, required this.greenColor});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0xFF21262D)
        : _green.withValues(alpha: 0.08);
    final borderColor = isDark
        ? const Color(0xFF30363D)
        : _green.withValues(alpha: 0.25);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Icon(Icons.notifications_rounded, color: greenColor, size: 20),
        ),
        Positioned(
          top: -3,
          right: -3,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
            child: const Center(
              child: Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  final bool isDark;
  final AppProvider prov;
  const _AdminAvatar({required this.isDark, required this.prov});

  @override
  Widget build(BuildContext context) {
    final photoUrl = prov.auth.photoURL;
    final name = prov.auth.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    final borderColor = isDark ? const Color(0xFF3FB950) : _green;
    final bgColor = isDark
        ? _green.withValues(alpha: 0.20)
        : _green.withValues(alpha: 0.12);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _LetterAvatar(initial: initial, bgColor: bgColor),
              )
            : _LetterAvatar(initial: initial, bgColor: bgColor),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final String initial;
  final Color bgColor;
  const _LetterAvatar({required this.initial, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: _green,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// Pulsing dot for live indicators
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.6),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int index;
  final List<(IconData, IconData, String)> items;
  final void Function(int) onTap;
  const _BottomNav({required this.index, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _green.withValues(alpha: 0.20), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.only(bottom: bot),
      child: SizedBox(
        height: 60,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == index;
            final (aIcon, iIcon, label) = items[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34, height: 28,
                      decoration: BoxDecoration(
                        color: active ? _green.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: active ? Border.all(color: _green.withValues(alpha: 0.35), width: 1) : null,
                      ),
                      child: Icon(
                        active ? aIcon : iIcon,
                        size: 18,
                        color: active ? _green : _grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color: active ? _green : _grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. OVERVIEW SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewSection extends StatefulWidget {
  final AppProvider prov;
  const _OverviewSection({required this.prov});
  @override
  State<_OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<_OverviewSection> {
  @override
  Widget build(BuildContext context) {
    final prov = widget.prov;
    final totalCards = prov.fields.fold(0, (s, f) =>
        s + (studyCardData[f.id]?['easy']?.length ?? 0)
          + (studyCardData[f.id]?['normal']?.length ?? 0)
          + (studyCardData[f.id]?['hard']?.length ?? 0));
    final totalMCQ = prov.fields.fold(0, (s, f) =>
        s + (assessmentData[f.id]?['easy']?.length ?? 0)
          + (assessmentData[f.id]?['normal']?.length ?? 0)
          + (assessmentData[f.id]?['hard']?.length ?? 0));
    final bot = MediaQuery.of(context).viewPadding.bottom;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().usersStream,
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        final userCount = docs.length;
        final isLoading = snap.connectionState == ConnectionState.waiting;

        // Build 7-day activity data from users
        final now = DateTime.now();
        final dailyTotals = List<int>.filled(7, 0);
        for (final doc in docs) {
          final daily = doc.data()['dailyCards'] as Map<String, dynamic>? ?? {};
          for (int i = 0; i < 7; i++) {
            final d = now.subtract(Duration(days: 6 - i));
            final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
            dailyTotals[i] += (daily[key] as int? ?? 0);
          }
        }

        // Subject card distribution
        final subjectCounts = prov.fields.map((f) {
          return (studyCardData[f.id]?['easy']?.length ?? 0)
               + (studyCardData[f.id]?['normal']?.length ?? 0)
               + (studyCardData[f.id]?['hard']?.length ?? 0);
        }).toList();

        return ListView(
          padding: EdgeInsets.fromLTRB(14, 14, 14, bot + 80),
          children: [
            // ── Hero card ────────────────────────────────────────────────
            _OverviewHero(
              userCount: userCount,
              totalCards: totalCards,
              totalMCQ: totalMCQ,
              subjectCount: prov.fields.length,
              isLoading: isLoading,
            ),
            const SizedBox(height: 14),

            // ── KPI row ──────────────────────────────────────────────────
            Row(children: [
              Expanded(child: _KpiCard(icon: Icons.group_rounded,     label: 'Users',    color: _blue,   value: isLoading ? null : '$userCount')),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(icon: Icons.grid_view_rounded, label: 'Subjects', color: _green,  value: '${prov.fields.length}')),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(icon: Icons.style_rounded,     label: 'Cards',    color: _purple, value: '$totalCards')),
              const SizedBox(width: 10),
              Expanded(child: _KpiCard(icon: Icons.quiz_rounded,      label: 'MCQs',     color: _amber,  value: '$totalMCQ')),
            ]),
            const SizedBox(height: 16),

            // ── 7-Day Activity Bar Chart ─────────────────────────────────
            _SectionLabel('7-Day Activity'),
            const SizedBox(height: 8),
            _GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Cards studied per day', style: TextStyle(fontSize: 11, color: _grey)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _green.withValues(alpha: 0.30), width: 0.8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _PulsingDot(color: _green),
                        const SizedBox(width: 4),
                        const Text('Live', style: TextStyle(color: _green, fontSize: 9, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 120,
                    child: _ActivityBarChart(data: dailyTotals),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Subject Distribution Donut ───────────────────────────────
            Row(children: [
              Expanded(
                flex: 5,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionLabel('Subject Distribution'),
                  const SizedBox(height: 8),
                  _GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      height: 140,
                      child: _SubjectDonutChart(
                        fields: prov.fields,
                        counts: subjectCounts,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionLabel('System Status'),
                  const SizedBox(height: 8),
                  _StatusCard(),
                ]),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Recent learners ──────────────────────────────────────────
            _SectionLabel('Recently Active'),
            const SizedBox(height: 8),
            if (isLoading)
              ...List.generate(3, (_) => const _SkeletonRow())
            else if (docs.isEmpty)
              _EmptyState(icon: Icons.group_outlined,
                  message: 'No users yet.\nUsers appear here after login.')
            else
              ...docs.take(5).map((d) => _UserRowCompact(data: d.data(), docId: d.id)),
          ],
        );
      },
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink, letterSpacing: 0.2),
  );
}

// ── Overview Hero Card ────────────────────────────────────────────────────────
class _OverviewHero extends StatelessWidget {
  final int userCount, totalCards, totalMCQ, subjectCount;
  final bool isLoading;
  const _OverviewHero({
    required this.userCount, required this.totalCards,
    required this.totalMCQ, required this.subjectCount, required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 10),
                const Text('FlashLearn', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const Text('Platform Overview', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 14),
                Row(children: [
                  _HeroStat(isLoading ? '—' : '$userCount', 'Users'),
                  const SizedBox(width: 18),
                  _HeroStat('$subjectCount', 'Subjects'),
                  const SizedBox(width: 18),
                  _HeroStat('$totalCards', 'Cards'),
                ]),
              ],
            ),
          ),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.40), width: 1.5),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, size: 28, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── 7-Day Activity Bar Chart (CustomPainter) ─────────────────────────────────
class _ActivityBarChart extends StatefulWidget {
  final List<int> data;
  const _ActivityBarChart({required this.data});
  @override
  State<_ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends State<_ActivityBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxVal = widget.data.isEmpty ? 1 : (widget.data.reduce(math.max) == 0 ? 1 : widget.data.reduce(math.max));

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.data.length, (i) {
            final frac = widget.data[i] / maxVal;
            final isToday = i == 6;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.data[i] > 0)
                      Text('${widget.data[i]}', style: TextStyle(fontSize: 8, color: isToday ? _green : _grey, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      height: (88 * frac * _anim.value).clamp(4.0, 88.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [_green, _green.withValues(alpha: 0.50)]
                              : [_blue.withValues(alpha: 0.70), _blue.withValues(alpha: 0.30)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: isToday ? [BoxShadow(color: _green.withValues(alpha: 0.35), blurRadius: 8)] : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(days[i], style: TextStyle(fontSize: 9, color: isToday ? _green : _grey, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Subject Donut Chart (CustomPainter) ───────────────────────────────────────
class _SubjectDonutChart extends StatefulWidget {
  final List<dynamic> fields;
  final List<int> counts;
  const _SubjectDonutChart({required this.fields, required this.counts});
  @override
  State<_SubjectDonutChart> createState() => _SubjectDonutChartState();
}

class _SubjectDonutChartState extends State<_SubjectDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  static const _colors = [_green, _blue, _amber, _red, _purple, Color(0xFF00D4FF)];

  @override
  Widget build(BuildContext context) {
    final total = widget.counts.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('No data', style: TextStyle(color: _grey, fontSize: 12)));
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(
        children: [
          Expanded(
            flex: 5,
            child: CustomPaint(
              painter: _DonutPainter(
                counts: widget.counts,
                colors: _colors,
                progress: _anim.value,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(math.min(widget.fields.length, 6), (i) {
                final f = widget.fields[i];
                final c = widget.counts[i];
                final pct = total > 0 ? (c / total * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(f.name.split(' ').first, style: const TextStyle(fontSize: 9, color: _white), overflow: TextOverflow.ellipsis)),
                    Text('$pct%', style: TextStyle(fontSize: 9, color: _colors[i % _colors.length], fontWeight: FontWeight.w700)),
                  ]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<int> counts;
  final List<Color> colors;
  final double progress;
  const _DonutPainter({required this.counts, required this.colors, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = counts.fold(0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final strokeW = radius * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeW / 2);

    double startAngle = -math.pi / 2;
    for (int i = 0; i < counts.length; i++) {
      final sweep = (counts[i] / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }

    // Center label
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: '$total\n', style: TextStyle(color: Colors.white, fontSize: radius * 0.36, fontWeight: FontWeight.w900)),
          TextSpan(text: 'cards', style: TextStyle(color: _grey, fontSize: radius * 0.22)),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? value;
  const _KpiCard({required this.icon, required this.label, required this.color, this.value});

  @override
  Widget build(BuildContext context) {
    final val = int.tryParse(value ?? '') ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20), width: 1),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          value == null
              ? _ShimmerBox(width: 36, height: 20, radius: 4)
              : _AnimatedCounter(end: val, color: color, fontSize: 18),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(fontSize: 9, color: _sub), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.cloud_done_rounded,    'Firestore',   _green),
      (Icons.lock_rounded,          'Auth',        _green),
      (Icons.notifications_rounded, 'FCM',         _green),
      (Icons.storage_rounded,       'Storage',     _green),
    ];
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: items.map((item) {
          final (icon, name, color) = item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 11, color: _ink))),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _PulsingDot(color: color),
                  const SizedBox(width: 4),
                  Text('OK', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UserRowCompact extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _UserRowCompact({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final name   = data['displayName'] as String? ?? 'Unknown';
    final email  = data['email'] as String? ?? '';
    final streak = data['streak'] as int? ?? 0;
    final cards  = data['cardsThisWeek'] as int? ?? 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();

    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailSheet(context, data, docId),
          splashColor: _indigo.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_indigo.withValues(alpha: 0.50), _violet.withValues(alpha: 0.30)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: _indigo.withValues(alpha: 0.40), width: 1),
                  ),
                  child: Center(child: Text(initial,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                      Text(
                        lastSeen != null ? _timeAgo(lastSeen) : email,
                        style: const TextStyle(fontSize: 10, color: _sub),
                      ),
                    ],
                  ),
                ),
                _MiniStat(Icons.local_fire_department_rounded, '$streak'),
                const SizedBox(width: 10),
                _MiniStat(Icons.menu_book_rounded, '$cards'),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 16, color: _sub),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, Map<String, dynamic> data, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(data: data, uid: uid),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. FIELDS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _FieldsSection extends StatelessWidget {
  final AppProvider prov;
  const _FieldsSection({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${prov.fields.length} subjects',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                        Text('Tap a field to expand · Use icons to edit/delete',
                            style: TextStyle(fontSize: 10, color: _sub)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(context).viewPadding.bottom + 90),
                children: prov.fields.map((f) => _FieldCard(field: f, prov: prov)).toList(),
              ),
            ),
          ],
        ),
        // Floating action button
        Positioned(
          bottom: MediaQuery.of(context).viewPadding.bottom + 80,
          right: 16,
          child: _PremiumFab(
            onTap: () => _showFieldDialog(context, prov),
            icon: Icons.add_rounded,
            label: 'Add Field',
          ),
        ),
      ],
    );
  }

  void _showFieldDialog(BuildContext context, AppProvider prov, [FieldModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.desc ?? '');
    final iconCtrl = TextEditingController(text: existing?.icon ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Add New Field' : 'Edit Field',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(ctrl: iconCtrl, label: 'Emoji Icon', hint: 'e.g. 📚'),
            const SizedBox(height: 12),
            _DialogField(ctrl: nameCtrl, label: 'Subject Name', hint: 'e.g. Mathematics'),
            const SizedBox(height: 12),
            _DialogField(ctrl: descCtrl, label: 'Description', hint: 'Short description', maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _indigo, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final desc = descCtrl.text.trim();
              final icon = iconCtrl.text.trim();
              if (name.isEmpty) return;
              if (existing == null) {
                prov.addField(FieldModel(
                  id: name.toLowerCase().replaceAll(' ', '_'),
                  name: name,
                  icon: icon.isEmpty ? 'subject' : icon,
                  colorValue: 0xFF5B5FEF,
                  desc: desc,
                  gradientHex: const ['3730A3', '5B5FEF'],
                ));
              } else {
                prov.updateField(FieldModel(
                  id: existing.id,
                  name: name,
                  icon: icon.isEmpty ? existing.icon : icon,
                  colorValue: existing.colorValue,
                  desc: desc,
                  gradientHex: existing.gradientHex,
                ));
              }
              Navigator.pop(ctx);
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatefulWidget {
  final FieldModel field;
  final AppProvider prov;
  const _FieldCard({required this.field, required this.prov});
  @override
  State<_FieldCard> createState() => _FieldCardState();
}

class _FieldCardState extends State<_FieldCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final grad = fieldGradient(widget.field.id);
    final cardCount = (studyCardData[widget.field.id]?['easy']?.length ?? 0)
        + (studyCardData[widget.field.id]?['normal']?.length ?? 0)
        + (studyCardData[widget.field.id]?['hard']?.length ?? 0);
    final mcqCount = (assessmentData[widget.field.id]?['easy']?.length ?? 0)
        + (assessmentData[widget.field.id]?['normal']?.length ?? 0)
        + (assessmentData[widget.field.id]?['hard']?.length ?? 0);

    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _expanded = !_expanded),
              splashColor: _indigo.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: grad.first.withValues(alpha: 0.40),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(child: Icon(fieldIconData(widget.field.id), size: 26, color: Colors.white)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.field.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(widget.field.desc,
                              style: TextStyle(fontSize: 11, color: _sub)),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              _DarkChip('$cardCount cards', _indigo),
                              const SizedBox(width: 6),
                              _DarkChip('$mcqCount MCQ', _amber),
                              const SizedBox(width: 6),
                              _DarkChip('3 levels', _green),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _GlassIconBtn(Icons.edit_rounded, _indigo,
                            () => _showEditDialog(context)),
                        const SizedBox(height: 8),
                        _GlassIconBtn(Icons.delete_rounded, _red,
                            () => _showDeleteConfirm(context)),
                      ],
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _sub),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded ? _FieldExpandedDetail(field: widget.field) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: widget.field.name);
    final descCtrl = TextEditingController(text: widget.field.desc);
    final iconCtrl = TextEditingController(text: widget.field.icon);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Field', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(ctrl: iconCtrl, label: 'Emoji Icon', hint: 'e.g. 📐'),
            const SizedBox(height: 12),
            _DialogField(ctrl: nameCtrl, label: 'Subject Name', hint: ''),
            const SizedBox(height: 12),
            _DialogField(ctrl: descCtrl, label: 'Description', hint: '', maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _indigo, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              widget.prov.updateField(FieldModel(
                id: widget.field.id,
                name: nameCtrl.text.trim().isEmpty ? widget.field.name : nameCtrl.text.trim(),
                icon: iconCtrl.text.trim().isEmpty ? widget.field.icon : iconCtrl.text.trim(),
                colorValue: widget.field.colorValue,
                desc: descCtrl.text.trim().isEmpty ? widget.field.desc : descCtrl.text.trim(),
                gradientHex: widget.field.gradientHex,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Field?', style: TextStyle(fontWeight: FontWeight.w800, color: _red)),
        content: Text('This will remove "${widget.field.name}" from the subject list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { widget.prov.deleteField(widget.field.id); Navigator.pop(ctx); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FieldExpandedDetail extends StatelessWidget {
  final FieldModel field;
  const _FieldExpandedDetail({required this.field});

  @override
  Widget build(BuildContext context) {
    const levels = ['easy', 'normal', 'hard'];
    const levelNames = {'easy': 'Easy', 'normal': 'Normal', 'hard': 'Hard'};
    const levelColors = {'easy': _green, 'normal': _amber, 'hard': _red};

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _border, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content breakdown',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sub)),
          const SizedBox(height: 10),
          Row(
            children: levels.map((lvl) {
              final count = studyCardData[field.id]?[lvl]?.length ?? 0;
              final mcq   = assessmentData[field.id]?[lvl]?.length ?? 0;
              final color = levelColors[lvl]!;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Text(levelNames[lvl]!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                      const SizedBox(height: 5),
                      Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                      Text('cards', style: TextStyle(fontSize: 9, color: _sub)),
                      Text('$mcq MCQ', style: TextStyle(fontSize: 9, color: _sub)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CONTENT SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ContentSection extends StatefulWidget {
  final AppProvider prov;
  const _ContentSection({required this.prov});
  @override
  State<_ContentSection> createState() => _ContentSectionState();
}

class _ContentSectionState extends State<_ContentSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedField = 'math';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    if (widget.prov.fields.isNotEmpty) _selectedField = widget.prov.fields.first.id;
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Field selector
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.prov.fields.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = widget.prov.fields[i];
                final active = f.id == _selectedField;
                final grad = fieldGradient(f.id);
                return GestureDetector(
                  onTap: () => setState(() => _selectedField = f.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: active ? LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                      color: active ? null : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: active ? Colors.white.withValues(alpha: 0.20) : _border,
                        width: 0.8,
                      ),
                      boxShadow: active ? [
                        BoxShadow(color: grad.first.withValues(alpha: 0.40), blurRadius: 12),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(fieldIconData(f.id), size: 13, color: active ? Colors.white : _sub),
                        const SizedBox(width: 6),
                        Text(f.name.split(' ').first,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : _sub)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Tab bar
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 1),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(11)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFF060D18),
              unselectedLabelColor: _grey,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
              padding: EdgeInsets.zero,
              tabs: const [
                Tab(height: 36, text: 'Study Cards'),
                Tab(height: 36, text: 'MCQ Quiz'),
                Tab(height: 36, text: 'Final Exam'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _StudyCardsTab(fieldId: _selectedField, prov: widget.prov),
              _MCQTab(fieldId: _selectedField, prov: widget.prov),
              _FinalExamTab(fieldId: _selectedField),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Study Cards Tab ────────────────────────────────────────────────────────────

class _StudyCardsTab extends StatelessWidget {
  final String fieldId;
  final AppProvider prov;
  const _StudyCardsTab({required this.fieldId, required this.prov});

  @override
  Widget build(BuildContext context) {
    const levels = ['easy', 'normal', 'hard'];
    const levelNames = {'easy': 'Easy', 'normal': 'Normal', 'hard': 'Hard'};
    const levelColors = {'easy': _green, 'normal': _amber, 'hard': _red};
    const levelBgs = {
      'easy': Color(0xFFF0FDF4), 'normal': Color(0xFFFFFBEB), 'hard': Color(0xFFFEF2F2),
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(context).viewPadding.bottom + 80),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Built-in + Admin cards', style: TextStyle(fontSize: 12, color: _grey)),
          _PrimaryBtn(label: 'Add Card', icon: Icons.add_rounded,
              onTap: () => _showCardDialog(context, fieldId)),
        ]),
        const SizedBox(height: 10),
        ...levels.map((lvl) {
          final cards = studyCardData[fieldId]?[lvl] ?? [];
          final color = levelColors[lvl]!;
          final bg    = levelBgs[lvl]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LevelHeader(label: levelNames[lvl]!, color: color, count: cards.length),
              const SizedBox(height: 6),
              ...cards.map((c) => _StudyCardRow(
                q: '${c['q'] ?? ''}',
                a: '${c['a'] ?? ''}',
                bg: bg,
                onEdit: () => _showCardDialog(context, fieldId,
                    level: lvl, q: '${c['q'] ?? ''}', a: '${c['a'] ?? ''}'),
                onDelete: () => _showBuiltInMsg(context),
              )),
              const SizedBox(height: 8),
            ],
          );
        }),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().adminCardsStream(fieldId),
          builder: (_, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LevelHeader(label: 'Admin Added', color: _indigo, count: null),
                const SizedBox(height: 6),
                ...docs.map((d) => _StudyCardRow(
                  q: d.data()['q'] as String? ?? '',
                  a: d.data()['a'] as String? ?? '',
                  bg: const Color(0xFFEEF2FF),
                  isAdminCard: true,
                  onEdit: () => _showCardDialog(context, fieldId,
                      level: d.data()['level'] as String? ?? 'easy',
                      q: d.data()['q'] as String?, a: d.data()['a'] as String?, docId: d.id),
                  onDelete: () => FirestoreService().deleteAdminCard(d.id),
                )),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showCardDialog(BuildContext context, String fieldId,
      {String? level, String? q, String? a, String? docId}) {
    final qCtrl = TextEditingController(text: q ?? '');
    final aCtrl = TextEditingController(text: a ?? '');
    String sel = level ?? 'easy';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(docId == null ? 'Add Study Card' : 'Edit Study Card',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LevelPicker(selected: sel, onChanged: (v) => setS(() => sel = v)),
            const SizedBox(height: 14),
            _DialogField(ctrl: qCtrl, label: 'Question', hint: 'What is…?', maxLines: 3),
            const SizedBox(height: 12),
            _DialogField(ctrl: aCtrl, label: 'Answer', hint: 'Correct answer…', maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _indigo, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final q2 = qCtrl.text.trim(); final a2 = aCtrl.text.trim();
              if (q2.isEmpty || a2.isEmpty) return;
              await FirestoreService().saveAdminCard(fieldId: fieldId, level: sel, question: q2, answer: a2, docId: docId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      )),
    );
  }

  void _showBuiltInMsg(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Built-in cards cannot be deleted. Add admin cards instead.'),
        duration: Duration(seconds: 2)));
}

class _StudyCardRow extends StatelessWidget {
  final String q, a;
  final Color bg;
  final bool isAdminCard;
  final VoidCallback onEdit, onDelete;
  const _StudyCardRow({required this.q, required this.a, required this.bg,
      this.isAdminCard = false, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(q, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _ink))),
                  if (isAdminCard) _AdminBadge(),
                ]),
                const SizedBox(height: 3),
                Text(a.length > 60 ? '${a.substring(0, 60)}…' : a,
                    style: TextStyle(fontSize: 10, color: _sub, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(children: [
            _GlassIconBtn(Icons.edit_rounded, _indigo, onEdit),
            const SizedBox(width: 5),
            _GlassIconBtn(Icons.delete_rounded, _red, onDelete),
          ]),
        ],
      ),
    );
  }
}

// ── MCQ Quiz Tab ──────────────────────────────────────────────────────────────

class _MCQTab extends StatelessWidget {
  final String fieldId;
  final AppProvider prov;
  const _MCQTab({required this.fieldId, required this.prov});

  @override
  Widget build(BuildContext context) {
    const levels = ['easy', 'normal', 'hard'];
    const levelNames = {'easy': 'Easy', 'normal': 'Normal', 'hard': 'Hard'};
    const levelColors = {'easy': _green, 'normal': _amber, 'hard': _red};

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(context).viewPadding.bottom + 80),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Built-in + Admin questions', style: TextStyle(fontSize: 12, color: _grey)),
          _PrimaryBtn(label: 'Add Question', icon: Icons.add_rounded,
              onTap: () => _showQuestionDialog(context, fieldId)),
        ]),
        const SizedBox(height: 10),
        ...levels.map((lvl) {
          final questions = assessmentData[fieldId]?[lvl] ?? [];
          final color = levelColors[lvl]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LevelHeader(label: levelNames[lvl]!, color: color, count: questions.length),
              const SizedBox(height: 6),
              ...questions.map((q) => _MCQRow(
                question: q['q'] as String? ?? '',
                answer: q['a'] as String? ?? '',
                options: List<String>.from(q['opts'] as List? ?? []),
                onEdit: () => _showQuestionDialog(context, fieldId, level: lvl,
                    question: q['q'] as String?, correct: q['a'] as String?,
                    opts: List<String>.from(q['opts'] as List? ?? [])),
                onDelete: () => _showBuiltInMsg(context),
              )),
              const SizedBox(height: 8),
            ],
          );
        }),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().adminQuestionsStream(fieldId),
          builder: (_, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LevelHeader(label: 'Admin Added', color: _indigo, count: null),
                const SizedBox(height: 6),
                ...docs.map((d) {
                  final data = d.data();
                  return _MCQRow(
                    question: data['q'] as String? ?? '',
                    answer: data['a'] as String? ?? '',
                    options: List<String>.from(data['opts'] as List? ?? []),
                    isAdminCard: true,
                    onEdit: () => _showQuestionDialog(context, fieldId,
                        level: data['level'] as String? ?? 'easy',
                        question: data['q'] as String?, correct: data['a'] as String?,
                        opts: List<String>.from(data['opts'] as List? ?? []), docId: d.id),
                    onDelete: () => FirestoreService().deleteAdminQuestion(d.id),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showQuestionDialog(BuildContext context, String fieldId,
      {String? level, String? question, String? correct, List<String>? opts, String? docId}) {
    final qCtrl = TextEditingController(text: question ?? '');
    final cCtrl = TextEditingController(text: correct ?? '');
    final o1 = TextEditingController(text: opts != null && opts.length > 0 ? opts[0] : '');
    final o2 = TextEditingController(text: opts != null && opts.length > 1 ? opts[1] : '');
    final o3 = TextEditingController(text: opts != null && opts.length > 2 ? opts[2] : '');
    final o4 = TextEditingController(text: opts != null && opts.length > 3 ? opts[3] : '');
    String sel = level ?? 'easy';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(docId == null ? 'Add MCQ Question' : 'Edit MCQ Question',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LevelPicker(selected: sel, onChanged: (v) => setS(() => sel = v)),
              const SizedBox(height: 12),
              _DialogField(ctrl: qCtrl, label: 'Question', hint: 'What is…?', maxLines: 3),
              const SizedBox(height: 10),
              _DialogField(ctrl: cCtrl, label: 'Correct Answer', hint: 'The right answer'),
              const SizedBox(height: 10),
              _DialogField(ctrl: o1, label: 'Option 1', hint: ''),
              const SizedBox(height: 8),
              _DialogField(ctrl: o2, label: 'Option 2', hint: ''),
              const SizedBox(height: 8),
              _DialogField(ctrl: o3, label: 'Option 3', hint: ''),
              const SizedBox(height: 8),
              _DialogField(ctrl: o4, label: 'Option 4', hint: ''),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _indigo, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final q2 = qCtrl.text.trim(); final a2 = cCtrl.text.trim();
              if (q2.isEmpty || a2.isEmpty) return;
              final options = [o1.text.trim(), o2.text.trim(), o3.text.trim(), o4.text.trim()]
                  .where((o) => o.isNotEmpty).toList();
              if (!options.contains(a2)) options.insert(0, a2);
              await FirestoreService().saveAdminQuestion(
                  fieldId: fieldId, level: sel, question: q2, correctAnswer: a2, options: options, docId: docId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      )),
    );
  }

  void _showBuiltInMsg(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Built-in questions cannot be deleted. Add admin questions instead.'),
        duration: Duration(seconds: 2)));
}

class _MCQRow extends StatelessWidget {
  final String question, answer;
  final List<String> options;
  final bool isAdminCard;
  final VoidCallback onEdit, onDelete;
  const _MCQRow({required this.question, required this.answer, required this.options,
      this.isAdminCard = false, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _ink)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _green.withValues(alpha: 0.35), width: 0.8),
                    ),
                    child: Text('✓ $answer', style: const TextStyle(fontSize: 9, color: _green, fontWeight: FontWeight.w700)),
                  ),
                  if (isAdminCard) ...[const SizedBox(width: 5), _AdminBadge()],
                ]),
                if (options.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(options.take(4).join(' · '),
                      style: TextStyle(fontSize: 9, color: _sub), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(children: [
            _GlassIconBtn(Icons.edit_rounded, _indigo, onEdit),
            const SizedBox(width: 5),
            _GlassIconBtn(Icons.delete_rounded, _red, onDelete),
          ]),
        ],
      ),
    );
  }
}

// ── Final Exam Tab — Full CRUD ─────────────────────────────────────────────────

class _FinalExamTab extends StatelessWidget {
  final String fieldId;
  const _FinalExamTab({required this.fieldId});

  @override
  Widget build(BuildContext context) {
    final easy   = (assessmentData[fieldId]?['easy']   ?? []).take(4).toList();
    final normal = (assessmentData[fieldId]?['normal'] ?? []).take(3).toList();
    final hard   = (assessmentData[fieldId]?['hard']   ?? []).take(3).toList();
    final builtIn = [...easy, ...normal, ...hard];

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(context).viewPadding.bottom + 80),
      children: [
        // Info card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
            boxShadow: [
              BoxShadow(color: Color(0xFF4338CA).withValues(alpha: 0.40), blurRadius: 20, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.school_rounded, size: 36, color: Colors.white),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Final Exam',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    SizedBox(height: 3),
                    Text('10 built-in + admin-added questions · Pass: 60%',
                        style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),

        // Add admin question
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Admin final exam questions', style: TextStyle(fontSize: 12, color: _sub)),
          _PrimaryBtn(label: 'Add Question', icon: Icons.add_rounded,
              onTap: () => _showFinalDialog(context, fieldId)),
        ]),
        const SizedBox(height: 10),

        // Admin-added final exam questions
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().adminFinalQuestionsStream(fieldId),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const _LoadingCard();
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty)
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _indigo.withValues(alpha: 0.15), width: 0.8),
                ),
                child: const Text('No admin questions added yet.\nTap "Add Question" to add custom final exam questions.',
                    style: TextStyle(fontSize: 12, color: _sub, height: 1.5)),
              );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LevelHeader(label: 'Admin Final Questions', color: _indigo, count: docs.length),
                const SizedBox(height: 6),
                ...docs.map((d) {
                  final data = d.data();
                  return _MCQRow(
                    question: data['q'] as String? ?? '',
                    answer: data['a'] as String? ?? '',
                    options: List<String>.from(data['opts'] as List? ?? []),
                    isAdminCard: true,
                    onEdit: () => _showFinalDialog(context, fieldId,
                        question: data['q'] as String?, correct: data['a'] as String?,
                        opts: List<String>.from(data['opts'] as List? ?? []), docId: d.id),
                    onDelete: () => FirestoreService().deleteAdminFinalQuestion(d.id),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          },
        ),

        // Built-in questions (read-only)
        const _LevelHeader(label: 'Built-in Questions (read-only)', color: _sub, count: 10),
        const SizedBox(height: 6),
        ...builtIn.asMap().entries.map((e) {
          final i = e.key;
          final q = e.value;
          final label = i < 4 ? 'Easy' : i < 7 ? 'Normal' : 'Hard';
          final color = i < 4 ? _green : i < 7 ? _amber : _red;
          return _GlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 28,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.40), color.withValues(alpha: 0.20)]),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.40), width: 0.8),
                  ),
                  child: Center(child: Text('${i + 1}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['q'] as String? ?? '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _ink)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: _green.withValues(alpha: 0.35), width: 0.8),
                          ),
                          child: Text('✓ ${q['a']}',
                              style: const TextStyle(fontSize: 9, color: _green, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
                          ),
                          child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showFinalDialog(BuildContext context, String fieldId,
      {String? question, String? correct, List<String>? opts, String? docId}) {
    final qCtrl = TextEditingController(text: question ?? '');
    final cCtrl = TextEditingController(text: correct ?? '');
    final o1 = TextEditingController(text: opts != null && opts.length > 0 ? opts[0] : '');
    final o2 = TextEditingController(text: opts != null && opts.length > 1 ? opts[1] : '');
    final o3 = TextEditingController(text: opts != null && opts.length > 2 ? opts[2] : '');
    final o4 = TextEditingController(text: opts != null && opts.length > 3 ? opts[3] : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(docId == null ? 'Add Final Exam Question' : 'Edit Final Exam Question',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(ctrl: qCtrl, label: 'Question', hint: 'What is…?', maxLines: 3),
              const SizedBox(height: 10),
              _DialogField(ctrl: cCtrl, label: 'Correct Answer', hint: 'The right answer'),
              const SizedBox(height: 10),
              _DialogField(ctrl: o1, label: 'Option 1', hint: ''),
              const SizedBox(height: 8),
              _DialogField(ctrl: o2, label: 'Option 2', hint: ''),
              const SizedBox(height: 8),
              _DialogField(ctrl: o3, label: 'Option 3', hint: ''),
              const SizedBox(height: 8),
              _DialogField(ctrl: o4, label: 'Option 4', hint: ''),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _indigo, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final q2 = qCtrl.text.trim(); final a2 = cCtrl.text.trim();
              if (q2.isEmpty || a2.isEmpty) return;
              final options = [o1.text.trim(), o2.text.trim(), o3.text.trim(), o4.text.trim()]
                  .where((o) => o.isNotEmpty).toList();
              if (!options.contains(a2)) options.insert(0, a2);
              await FirestoreService().saveAdminFinalQuestion(
                  fieldId: fieldId, question: q2, correctAnswer: a2, options: options, docId: docId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. USERS SECTION — search + CRUD
// ─────────────────────────────────────────────────────────────────────────────

class _UsersSection extends StatefulWidget {
  const _UsersSection();
  @override
  State<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<_UsersSection> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().usersStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _indigo));
        }
        if (snap.hasError) {
          return _EmptyState(icon: Icons.error_outline_rounded,
              message: 'Failed to load users.\nCheck your internet connection.');
        }

        final all = snap.data?.docs ?? [];
        final docs = _query.isEmpty
            ? all
            : all.where((d) {
                final name  = (d.data()['displayName'] as String? ?? '').toLowerCase();
                final email = (d.data()['email'] as String? ?? '').toLowerCase();
                return name.contains(_query) || email.contains(_query);
              }).toList();

        if (all.isEmpty) {
          return _EmptyState(icon: Icons.group_outlined,
              message: 'No users yet.\nUsers appear here once they log in.');
        }

        return Column(
          children: [
            // ── Header with search ─────────────────────────────────────────
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('${all.length} registered users',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _green.withValues(alpha: 0.35), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PulsingDot(color: _green),
                            const SizedBox(width: 5),
                            const Text('Live sync', style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar (glass)
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
                      style: const TextStyle(fontSize: 13, color: _ink),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email…',
                        hintStyle: const TextStyle(color: _sub, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _sub),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: _sub),
                                onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('${docs.length} of ${all.length} results',
                        style: TextStyle(fontSize: 11, color: _sub)),
                  ],
                ],
              ),
            ),

            // ── User list ──────────────────────────────────────────────────
            Expanded(
              child: docs.isEmpty
                  ? _EmptyState(icon: Icons.search_off_rounded,
                      message: 'No users match "$_query"')
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(14, 4, 14, MediaQuery.of(ctx).viewPadding.bottom + 80),
                      itemCount: docs.length,
                      itemBuilder: (_, i) => _UserCard(doc: docs[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _UserCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data     = doc.data();
    final name     = data['displayName'] as String? ?? 'Unknown';
    final email    = data['email'] as String? ?? '';
    final streak   = data['streak'] as int? ?? 0;
    final cards    = data['cardsThisWeek'] as int? ?? 0;
    final quizzes  = data['quizzesPassedTotal'] as int? ?? 0;
    final badges   = data['badgesUnlocked'] as int? ?? 0;
    final certs    = data['certifications'] as int? ?? 0;
    final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
    final suspended = data['suspended'] as bool? ?? false;
    final initial  = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final daily = (data['dailyCards'] as Map<String, dynamic>? ?? {});
    final now   = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return daily[key] as int? ?? 0;
    });
    final maxVal = last7.isEmpty ? 0 : last7.reduce((a, b) => a > b ? a : b);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (suspended ? _red : Colors.white).withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: suspended ? _red.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 12)],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showDetailSheet(context, data, doc.id),
              splashColor: _indigo.withValues(alpha: 0.06),
          child: Column(
            children: [
              // ── Top row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_indigo.withValues(alpha: 0.60), _violet.withValues(alpha: 0.40)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: _indigo.withValues(alpha: 0.40), width: 1),
                          ),
                          child: Center(child: Text(initial,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white))),
                        ),
                        if (suspended)
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: BoxDecoration(
                                  color: _red, shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5)),
                              child: const Icon(Icons.block_rounded, size: 8, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                              ),
                              if (suspended)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _red.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _red.withValues(alpha: 0.40), width: 0.8),
                                  ),
                                  child: const Text('Suspended',
                                      style: TextStyle(fontSize: 9, color: _red, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          Text(email, style: TextStyle(fontSize: 10, color: _sub)),
                          if (lastSeen != null)
                            Text('Last active ${_timeAgo(lastSeen)}',
                                style: TextStyle(fontSize: 10, color: _sub)),
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      children: [
                        _GlassIconBtn(Icons.edit_rounded, _indigo,
                            () => _showEditDialog(context, doc.id, name)),
                        const SizedBox(width: 6),
                        _GlassIconBtn(
                          suspended ? Icons.lock_open_rounded : Icons.block_rounded,
                          suspended ? _green : _amber,
                          () => FirestoreService().setUserSuspended(doc.id, suspended: !suspended),
                        ),
                        const SizedBox(width: 6),
                        _GlassIconBtn(Icons.delete_rounded, _red,
                            () => _showRemoveDialog(context, doc.id, name)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Stats row ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Row(
                  children: [
                    _StatPill(Icons.local_fire_department_rounded, '$streak', 'streak'),
                    _StatPill(Icons.menu_book_rounded, '$cards', 'cards/wk'),
                    _StatPill(Icons.quiz_rounded, '$quizzes', 'quizzes'),
                    _StatPill(Icons.emoji_events_rounded, '$badges', 'badges'),
                    _StatPill(Icons.school_rounded, '$certs', 'certs'),
                  ],
                ),
              ),

              // ── Daily bar chart ──────────────────────────────────────────
              if (last7.any((v) => v > 0))
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily cards — last 7 days',
                          style: TextStyle(fontSize: 10, color: _sub, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 36,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: last7.asMap().entries.map((e) {
                            final val = e.value;
                            final frac = maxVal > 0 ? val / maxVal : 0.0;
                            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      height: 24 * frac + (val > 0 ? 4 : 2),
                                      decoration: BoxDecoration(
                                        color: val > 0 ? _green : Colors.white.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(days[e.key], style: const TextStyle(fontSize: 8, color: _sub)),
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
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  void _showDetailSheet(BuildContext context, Map<String, dynamic> data, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(data: data, uid: uid),
    );
  }

  void _showEditDialog(BuildContext context, String uid, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit User', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // UID info chip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User UID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _sub)),
                  const SizedBox(height: 4),
                  Text(uid, style: const TextStyle(fontSize: 10, color: _ink, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DialogField(ctrl: ctrl, label: 'Display Name', hint: 'Full name'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _indigo, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              await FirestoreService().updateUserDisplayName(uid, newName);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove User?', style: TextStyle(fontWeight: FontWeight.w800, color: _red)),
        content: Text('This removes "$name" from the admin user list.\nTheir Firebase Auth account is NOT deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirestoreService().removeUserRecord(uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ── User Detail Bottom Sheet ───────────────────────────────────────────────────

class _UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final String uid;
  const _UserDetailSheet({required this.data, required this.uid});
  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.data);
  }

  void _confirmDelete(BuildContext context) {
    final name = _data['displayName'] as String? ?? 'this user';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove User?',
            style: TextStyle(fontWeight: FontWeight.w800, color: _red, fontSize: 16)),
        content: Text(
          'This removes "$name" from the admin user list.\nTheir Firebase Auth account is NOT deleted.',
          style: const TextStyle(fontSize: 13, color: _sub, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirestoreService().removeUserRecord(widget.uid);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _editName() {
    final ctrl = TextEditingController(text: _data['displayName'] as String? ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Display Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bg, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border, width: 0.8),
              ),
              child: Text('UID: ${widget.uid}',
                  style: const TextStyle(fontSize: 9, color: _sub, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 12),
            _DialogField(ctrl: ctrl, label: 'Display Name', hint: 'Full name'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _indigo, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isEmpty) return;
              await FirestoreService().updateUserDisplayName(widget.uid, newName);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                setState(() => _data['displayName'] = newName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name      = _data['displayName'] as String? ?? 'Unknown';
    final email     = _data['email'] as String? ?? '';
    final streak    = _data['streak'] as int? ?? 0;
    final cards     = _data['cardsThisWeek'] as int? ?? 0;
    final quizzes   = _data['quizzesPassedTotal'] as int? ?? 0;
    final badges    = _data['badgesUnlocked'] as int? ?? 0;
    final certs     = _data['certifications'] as int? ?? 0;
    final lastSeen  = (_data['lastSeen'] as Timestamp?)?.toDate();
    final initial   = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final suspended = _data['suspended'] as bool? ?? false;

    final daily = (_data['dailyCards'] as Map<String, dynamic>? ?? {});
    final now   = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return daily[key] as int? ?? 0;
    });
    final maxVal = last7.isEmpty ? 0 : last7.reduce((a, b) => a > b ? a : b);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Subject activity data from Firestore
    final fieldFinalsPassed = List<String>.from(_data['fieldFinalsPassed'] as List? ?? []);
    final rawLevels = _data['fieldCompletedLevels'] as Map<String, dynamic>? ?? {};
    final fieldCompletedLevels = rawLevels.map(
      (k, v) => MapEntry(k, List<String>.from(v as List? ?? [])),
    );
    final recentQuizzes = List<Map<String, dynamic>>.from(
      (_data['recentQuizzes'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
    );

    // All subjects the user has ever interacted with
    final allActiveFields = <String>{
      ...fieldFinalsPassed,
      ...fieldCompletedLevels.keys,
    }.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      maxChildSize: 0.95,
      minChildSize: 0.50,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _green.withValues(alpha: 0.30), width: 1.5)),
        ),
        child: ListView(
          controller: sc,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom + 24),
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // ── Profile header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_indigo.withValues(alpha: 0.60), _violet.withValues(alpha: 0.40)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: _indigo.withValues(alpha: 0.50), width: 2),
                      boxShadow: [BoxShadow(color: _indigo.withValues(alpha: 0.40), blurRadius: 20)],
                    ),
                    child: Center(child: Text(initial,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white))),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 12, color: _sub)),
                  if (lastSeen != null) ...[
                    const SizedBox(height: 4),
                    Text('Last active: ${_timeAgo(lastSeen)}',
                        style: const TextStyle(fontSize: 11, color: _sub)),
                  ],
                  if (suspended) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _red.withValues(alpha: 0.25)),
                      ),
                      child: const Text('Account Suspended',
                          style: TextStyle(fontSize: 11, color: _red, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats grid ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STATS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _sub, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.05,
                    children: [
                      _DetailStat(Icons.local_fire_department_rounded, '$streak', 'Streak', const Color(0xFFF97316)),
                      _DetailStat(Icons.menu_book_rounded, '$cards', 'Cards/Week', _indigo),
                      _DetailStat(Icons.quiz_rounded, '$quizzes', 'Quizzes', _blue),
                      _DetailStat(Icons.emoji_events_rounded, '$badges', 'Badges', _amber),
                      _DetailStat(Icons.school_rounded, '$certs', 'Certs', _green),
                      _DetailStat(Icons.calendar_today_rounded,
                          '${last7.fold(0, (a, b) => a + b)}', 'Cards/7d', const Color(0xFF8B5CF6)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Daily activity chart ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DAILY ACTIVITY (LAST 7 DAYS)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _sub, letterSpacing: 0.8)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 80,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: last7.asMap().entries.map((e) {
                        final val = e.value;
                        final frac = maxVal > 0 ? val / maxVal : 0.0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (val > 0)
                                  Text('$val',
                                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _green)),
                                const SizedBox(height: 2),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: 56 * frac + (val > 0 ? 4 : 2),
                                  decoration: BoxDecoration(
                                    gradient: val > 0
                                        ? const LinearGradient(
                                            colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : null,
                                    color: val > 0 ? null : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(days[e.key].substring(0, 2),
                                    style: const TextStyle(fontSize: 9, color: _sub)),
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

            const SizedBox(height: 20),

            // ── Subject progress ─────────────────────────────────────────────
            if (allActiveFields.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SUBJECT PROGRESS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _sub, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    ...allActiveFields.map((fieldId) {
                      final doneLevels = fieldCompletedLevels[fieldId] ?? [];
                      final passed = fieldFinalsPassed.contains(fieldId);
                      final pct = doneLevels.length / 3.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: passed ? _green.withValues(alpha: 0.04) : _bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: passed ? _green.withValues(alpha: 0.25) : _border,
                            width: passed ? 1.0 : 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fieldId[0].toUpperCase() + fieldId.substring(1).replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink),
                                  ),
                                ),
                                if (passed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('✓ Certified',
                                        style: TextStyle(fontSize: 9, color: _green, fontWeight: FontWeight.w700)),
                                  )
                                else
                                  Text('${(pct * 100).round()}%',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sub)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: passed ? 1.0 : pct,
                                backgroundColor: const Color(0xFFF0EDE8),
                                valueColor: AlwaysStoppedAnimation(passed ? _green : _indigo),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: ['easy', 'normal', 'hard'].map((lvl) {
                                final done = doneLevels.contains(lvl) || passed;
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: done ? _green.withValues(alpha: 0.10) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '${done ? '✓ ' : ''}${lvl[0].toUpperCase()}${lvl.substring(1)}',
                                    style: TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.w600,
                                      color: done ? _green : _sub,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Recent quiz results ──────────────────────────────────────────
            if (recentQuizzes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RECENT QUIZ RESULTS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _sub, letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    ...recentQuizzes.take(8).map((q) {
                      final field  = q['field'] as String? ?? '';
                      final level  = q['level'] as String? ?? '';
                      final pct    = (q['pct'] as num?)?.toInt() ?? 0;
                      final passed = q['passed'] as bool? ?? false;
                      final date   = q['date'] as String? ?? '';
                      final dt     = DateTime.tryParse(date);
                      final fieldLabel = field.isNotEmpty ? field[0].toUpperCase() + field.substring(1) : 'Unknown';
                      final levelLabel = level.isNotEmpty ? level[0].toUpperCase() + level.substring(1) : 'Unknown';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border, width: 0.7),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: (passed ? _green : _red).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 18,
                                color: passed ? _green : _red,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$fieldLabel — $levelLabel',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink),
                                  ),
                                  if (dt != null)
                                    Text(_timeAgo(dt),
                                        style: const TextStyle(fontSize: 10, color: _sub)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (passed ? _green : _red).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$pct%',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800,
                                  color: passed ? _green : _red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── UID ──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('USER ID',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _sub, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _bg, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border, width: 0.8),
                    ),
                    child: Text(widget.uid,
                        style: const TextStyle(fontSize: 11, color: _ink, fontFamily: 'monospace')),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _editName,
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          label: const Text('Edit Name'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _indigo,
                            side: const BorderSide(color: _indigo, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FirestoreService().setUserSuspended(widget.uid, suspended: !suspended);
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: Icon(suspended ? Icons.lock_open_rounded : Icons.block_rounded, size: 14),
                          label: Text(suspended ? 'Restore' : 'Suspend'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: suspended ? _green : _amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded, size: 14),
                      label: const Text('Remove User Record'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: BorderSide(color: _red.withValues(alpha: 0.5), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _DetailStat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.08)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: _sub)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. ACTIVITY SECTION — real-time feed
// ─────────────────────────────────────────────────────────────────────────────

class _ActivitySection extends StatefulWidget {
  const _ActivitySection();
  @override
  State<_ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<_ActivitySection> {
  String _filter = 'all'; // 'all' | 'today' | 'week'

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().usersStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _indigo));
        }
        final all = snap.data?.docs ?? [];
        final now = DateTime.now();

        final filtered = all.where((d) {
          final lastSeen = (d.data()['lastSeen'] as Timestamp?)?.toDate();
          if (lastSeen == null) return _filter == 'all';
          final diff = now.difference(lastSeen);
          if (_filter == 'today') return diff.inHours < 24;
          if (_filter == 'week')  return diff.inDays < 7;
          return true;
        }).toList();

        return Column(
          children: [
            // Header
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('User Activity Feed',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                      const Spacer(),
                      _PulsingDot(color: _green),
                      const SizedBox(width: 5),
                      const Text('Live', style: TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Filter chips
                  Row(
                    children: [
                      _FilterChip(label: 'All Users', value: 'all', current: _filter,
                          onTap: () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Today', value: 'today', current: _filter,
                          onTap: () => setState(() => _filter = 'today')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'This Week', value: 'week', current: _filter,
                          onTap: () => setState(() => _filter = 'week')),
                      const Spacer(),
                      Text('${filtered.length} users',
                          style: TextStyle(fontSize: 11, color: _sub)),
                    ],
                  ),
                ],
              ),
            ),

            // Feed
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(icon: Icons.timeline_outlined,
                      message: 'No activity found\nfor the selected filter.')
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(14, 8, 14,
                          MediaQuery.of(ctx).viewPadding.bottom + 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _ActivityRow(doc: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, current;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: active ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.transparent : _border,
            width: 0.8,
          ),
          boxShadow: active ? [
            BoxShadow(color: _indigo.withValues(alpha: 0.35), blurRadius: 10),
          ] : null,
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : _sub,
            )),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ActivityRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data    = doc.data();
    final name    = data['displayName'] as String? ?? 'Unknown';
    final email   = data['email'] as String? ?? '';
    final quizzes = data['quizzesPassedTotal'] as int? ?? 0;
    final streak  = data['streak'] as int? ?? 0;
    final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final now = DateTime.now();

    // Recency color
    Color dotColor = const Color(0xFF9CA3AF);
    String timeLabel = 'Unknown';
    if (lastSeen != null) {
      final diff = now.difference(lastSeen);
      timeLabel = _timeAgo(lastSeen);
      if (diff.inHours < 1) dotColor = _green;
      else if (diff.inHours < 24) dotColor = _blue;
      else if (diff.inDays < 7) dotColor = _amber;
      else dotColor = const Color(0xFF9CA3AF);
    }

    // Activity summary
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayCards = (data['dailyCards'] as Map<String, dynamic>?)?[todayKey] as int? ?? 0;

    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar with live dot
          Stack(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_indigo.withValues(alpha: 0.50), _violet.withValues(alpha: 0.30)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: _indigo.withValues(alpha: 0.35), width: 1),
                ),
                child: Center(child: Text(initial,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: dotColor, shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 2),
                    boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.40), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                Text(email, style: const TextStyle(fontSize: 10, color: _sub)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    if (todayCards > 0)
                      _MiniChip('📖 $todayCards today', _indigo.withValues(alpha: 0.20), _indigo),
                    if (streak > 0)
                      _MiniChip('🔥 $streak streak', _amber.withValues(alpha: 0.20), _amber),
                    if (quizzes > 0)
                      _MiniChip('✓ $quizzes quizzes', _green.withValues(alpha: 0.20), _green),
                  ],
                ),
              ],
            ),
          ),
          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: dotColor, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.50), blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 4),
              Text(timeLabel, style: TextStyle(fontSize: 10, color: _sub)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color bg, fg;
  const _MiniChip(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _LevelPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _LevelPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['easy', 'normal', 'hard'].map((lvl) {
        final active = selected == lvl;
        const colors = {'easy': _green, 'normal': _amber, 'hard': _red};
        final color = colors[lvl]!;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(lvl),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? color : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                lvl[0].toUpperCase() + lvl.substring(1),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: active ? Colors.white : color),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int? count;
  const _LevelHeader({required this.label, required this.color, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Container(width: 4, height: 16,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text('($count)', style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.6))),
          ],
        ],
      ),
    );
  }
}

// _SectionTitle removed — use Text inline for cleaner headers.

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _green.withValues(alpha: 0.40), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _green),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}


class _AdminBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_indigo.withValues(alpha: 0.40), _violet.withValues(alpha: 0.25)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _indigo.withValues(alpha: 0.50), width: 0.8),
      ),
      child: const Text('Admin', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MiniStat(this.icon, this.value);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: _sub),
      const SizedBox(width: 3),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink)),
    ],
  );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatPill(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: _sub),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ink)),
            Text(label, style: TextStyle(fontSize: 8, color: _sub)),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final int maxLines;
  const _DialogField({required this.ctrl, required this.label, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sub)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: _ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            filled: true, fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border, width: 0.8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border, width: 0.8)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _indigo, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_indigo.withValues(alpha: 0.30), _violet.withValues(alpha: 0.15)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _indigo.withValues(alpha: 0.35), width: 1),
              ),
              child: Icon(icon, size: 34, color: _indigo),
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _sub, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _indigo)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Glassmorphism card — use as the base container for content cards.
class _GlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool highlighted;

  const _GlassCard({
    this.child,
    this.padding,
    this.margin,
    this.highlighted = false,
  }); // highlighted kept for potential future use

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted ? _cardHi : _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? _green.withValues(alpha: 0.45) : _border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

/// Animated count-up number for KPI cards.
class _AnimatedCounter extends StatefulWidget {
  final int end;
  final Color color;
  final double fontSize;
  const _AnimatedCounter({required this.end, required this.color, this.fontSize = 26});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.end.toDouble())
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.end != widget.end) {
      _anim = Tween<double>(begin: _anim.value, end: widget.end.toDouble())
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        '${_anim.value.round()}',
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w900,
          color: widget.color,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

/// Shimmer skeleton box for loading states.
class _ShimmerBox extends StatefulWidget {
  final double width, height, radius;
  const _ShimmerBox({required this.width, required this.height, required this.radius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + _anim.value, 0),
            end: Alignment(1.0 + _anim.value, 0),
            colors: [
              Colors.white.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton row for user list loading.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _ShimmerBox(width: 38, height: 38, radius: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: double.infinity, height: 13, radius: 6),
                const SizedBox(height: 6),
                _ShimmerBox(width: 120, height: 10, radius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium floating action button.
class _PremiumFab extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  const _PremiumFab({required this.onTap, required this.icon, required this.label});

  @override
  State<_PremiumFab> createState() => _PremiumFabState();
}

class _PremiumFabState extends State<_PremiumFab> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: _green.withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: const Color(0xFF060D18)),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: const TextStyle(
                    color: Color(0xFF060D18), fontSize: 14,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}


class _HeroStat extends StatelessWidget {
  final String value, label;
  const _HeroStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ],
  );
}

/// Dark chip for field cards.
class _DarkChip extends StatelessWidget {
  final String label;
  final Color color;
  const _DarkChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.40), width: 0.8),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

/// Glass icon button for dark theme.
class _GlassIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _GlassIconBtn(this.icon, this.color, this.onTap);

  @override
  State<_GlassIconBtn> createState() => _GlassIconBtnState();
}

class _GlassIconBtnState extends State<_GlassIconBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.color.withValues(alpha: 0.35), width: 0.8),
          ),
          child: Icon(widget.icon, size: 16, color: widget.color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. NOTIFICATIONS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();
  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  String _type = 'announcement';
  String _topic = 'all_users';
  bool _sending = false;
  String _status = '';

  static const List<(String, IconData, String, Color)> _types = [
    ('announcement', Icons.campaign_rounded,    'Announcement',  _blue),
    ('reminder',     Icons.alarm_rounded,        'Study Reminder',_green),
    ('new_content',  Icons.auto_awesome_rounded,'New Content',   _purple),
    ('alert',        Icons.warning_amber_rounded,'Alert',         _amber),
  ];

  static const _topics = [
    ('all_users',    'All Users'),
    ('active',       'Active Learners'),
    ('beginners',    'Beginners'),
    ('advanced',     'Advanced'),
  ];

  static const _templates = [
    ('🔥 Study streak!', 'Don\'t break your streak. Complete today\'s flashcards now!', 'reminder'),
    ('📚 New content added', 'Fresh study cards are available. Check out the latest additions!', 'new_content'),
    ('🏆 Weekly challenge', 'This week\'s quiz challenge is live. Test your knowledge now!', 'announcement'),
    ('⏰ Daily reminder', 'Your daily study session is waiting. 10 minutes a day keeps forgetting away!', 'reminder'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      setState(() => _status = '⚠️ Title and message are required.');
      return;
    }
    setState(() { _sending = true; _status = ''; });

    try {
      await FirestoreService().saveNotificationRecord(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        type: _type,
        topic: _topic,
      );
      if (mounted) {
        setState(() {
          _status = '✅ Notification saved & queued for delivery.';
          _sending = false;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _titleCtrl.clear();
            _bodyCtrl.clear();
            setState(() => _status = '');
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _sending = false; _status = '❌ Failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).viewPadding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 14, 14, bot + 80),
      children: [
        // ── Section title ────────────────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded, color: _blue, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Push Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
            Text('Send announcements to learners', style: TextStyle(fontSize: 11, color: _sub)),
          ]),
        ]),
        const SizedBox(height: 18),

        // ── Quick Templates ──────────────────────────────────────────────────
        const Text('Quick Templates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final (title, body, type) = _templates[i];
              final typeData = _types.firstWhere((t) => t.$1 == type, orElse: () => _types[0]);
              return GestureDetector(
                onTap: () => setState(() {
                  _titleCtrl.text = title;
                  _bodyCtrl.text  = body;
                  _type = type;
                }),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (typeData.$4).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: (typeData.$4).withValues(alpha: 0.25), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(typeData.$2, size: 16, color: typeData.$4),
                      const SizedBox(height: 6),
                      Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(body, style: TextStyle(fontSize: 9, color: _sub), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // ── Compose Form ─────────────────────────────────────────────────────
        _GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Compose Notification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 14),

            // Notification type selector
            const Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sub)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _types.map((t) {
                final active = _type == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _type = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? (t.$4).withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? t.$4 : _border,
                        width: active ? 1.5 : 0.8,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.$2, size: 13, color: active ? t.$4 : _sub),
                      const SizedBox(width: 5),
                      Text(t.$3, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? t.$4 : _sub)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Audience selector
            const Text('Audience', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sub)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _topics.map((t) {
                final active = _topic == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _topic = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? _green.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? _green : _border, width: active ? 1.5 : 0.8),
                    ),
                    child: Text(t.$2, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? _green : _sub)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Title field
            const Text('Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sub)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 13, color: _ink),
              decoration: InputDecoration(
                hintText: 'e.g. New flashcards available!',
                hintStyle: TextStyle(fontSize: 13, color: _sub.withValues(alpha: 0.6)),
                filled: true, fillColor: const Color(0xFFF8FFFE),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _green, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Body field
            const Text('Message', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sub)),
            const SizedBox(height: 6),
            TextField(
              controller: _bodyCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: _ink),
              decoration: InputDecoration(
                hintText: 'Write your notification message here…',
                hintStyle: TextStyle(fontSize: 13, color: _sub.withValues(alpha: 0.6)),
                filled: true, fillColor: const Color(0xFFF8FFFE),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _green, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            if (_status.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _status.startsWith('✅') ? _green.withValues(alpha: 0.08)
                      : _status.startsWith('❌') ? _red.withValues(alpha: 0.08)
                      : _amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _status.startsWith('✅') ? _green.withValues(alpha: 0.30)
                        : _status.startsWith('❌') ? _red.withValues(alpha: 0.30)
                        : _amber.withValues(alpha: 0.30),
                  ),
                ),
                child: Text(_status, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _status.startsWith('✅') ? _green : _status.startsWith('❌') ? _red : _amber,
                )),
              ),
              const SizedBox(height: 12),
            ],

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(_sending ? 'Sending…' : 'Send Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Notification History ──────────────────────────────────────────────
        const Text('Recent Notifications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService().notificationsHistoryStream,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _green)));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return _GlassCard(
                padding: const EdgeInsets.all(20),
                child: const Center(child: Text('No notifications sent yet.', style: TextStyle(fontSize: 13, color: _sub))),
              );
            }
            return Column(
              children: docs.take(10).map((doc) {
                final d = doc.data();
                final title   = d['title'] as String? ?? '';
                final body    = d['body'] as String? ?? '';
                final type    = d['type'] as String? ?? 'announcement';
                final topic   = d['topic'] as String? ?? 'all';
                final ts      = (d['sentAt'] as Timestamp?)?.toDate();
                final typeData = _types.firstWhere((t) => t.$1 == type, orElse: () => _types[0]);
                final timeStr = ts != null ? _timeAgo(ts) : 'Unknown';

                return _GlassCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (typeData.$4).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(typeData.$2, size: 16, color: typeData.$4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                            const SizedBox(height: 3),
                            Text(body, style: TextStyle(fontSize: 11, color: _sub), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 5),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _green.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(topic.replaceAll('_', ' '), style: const TextStyle(fontSize: 9, color: _green, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 6),
                              Text(timeStr, style: TextStyle(fontSize: 10, color: _sub)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────

class _AccessDeniedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _red.withValues(alpha: 0.35), width: 1),
                ),
                child: const Icon(Icons.lock_rounded, size: 36, color: _red),
              ),
              const SizedBox(height: 20),
              const Text('Admin Access Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _white)),
              const SizedBox(height: 8),
              const Text('Only authorized administrators\nhave access to this panel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _grey, height: 1.5)),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.40), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Text('Go Back',
                      style: TextStyle(color: Color(0xFF060D18), fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Global helper ──────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1)  return '${diff.inMinutes}m ago';
  if (diff.inDays < 1)   return '${diff.inHours}h ago';
  if (diff.inDays < 7)   return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}
