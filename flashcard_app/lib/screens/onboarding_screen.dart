import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      gradientColors: [Color(0xFF1A0A4E), Color(0xFF5C4E8A)],
      accentColor: Color(0xFF8B7FD4),
      icon: Icons.layers_rounded,
      title: 'Learn Smarter,\nNot Harder',
      body:
          'Adaptive flashcards built around spaced repetition — the science-backed method to retain knowledge longer and study more efficiently.',
      chips: [
        (Icons.school_rounded, '6 Subject Fields'),
        (Icons.style_rounded, '30 Cards / Field'),
        (Icons.repeat_rounded, 'Spaced Repetition'),
      ],
    ),
    _PageData(
      gradientColors: [Color(0xFF0D2847), Color(0xFF1A5EA3)],
      accentColor: Color(0xFF3A88D4),
      icon: Icons.insights_rounded,
      title: 'Track Every\nMilestone',
      body:
          'Level up through chapter exams, monitor your weekly progress, and stay on track with smart study reminders.',
      chips: [
        (Icons.military_tech_rounded, 'Level Exams'),
        (Icons.bar_chart_rounded, 'Weekly Reports'),
        (Icons.notifications_active_rounded, 'Reminders'),
      ],
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: p.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.fromLTRB(0, 8, 20, 0),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _PageContent(data: _pages[i]),
                ),
              ),
              // Bottom nav
              _BottomNav(
                pageCount: _pages.length,
                currentPage: _page,
                accentColor: p.accentColor,
                isLast: _page == _pages.length - 1,
                onNext: _next,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page content ──────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _PageData data;
  const _PageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Illustration(data: data),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: data.chips
                        .map((c) => _Chip(icon: c.$1, label: c.$2))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Illustration ──────────────────────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  final _PageData data;
  const _Illustration({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative floating dots
          Positioned(
            top: 14,
            right: 20,
            child: _dot(14, 0.18),
          ),
          Positioned(
            bottom: 24,
            left: 14,
            child: _dot(9, 0.22),
          ),
          Positioned(
            top: 44,
            left: 10,
            child: _dot(6, 0.14),
          ),
          Positioned(
            bottom: 60,
            right: 10,
            child: _dot(5, 0.16),
          ),
          // Outer ring
          Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          // Middle ring
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Inner glow circle
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.accentColor,
              boxShadow: [
                BoxShadow(
                  color: data.accentColor.withValues(alpha: 0.55),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(data.icon, size: 50, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _dot(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

// ── Feature chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final Color accentColor;
  final bool isLast;
  final VoidCallback onNext;

  const _BottomNav({
    required this.pageCount,
    required this.currentPage,
    required this.accentColor,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
      child: Row(
        children: [
          // Dot indicators
          Row(
            children: List.generate(pageCount, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white30,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          // Next / Get Started pill
          GestureDetector(
            onTap: onNext,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast ? 'Get Started' : 'Next',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLast
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    size: 15,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page data ─────────────────────────────────────────────────────────────────

class _PageData {
  final List<Color> gradientColors;
  final Color accentColor;
  final IconData icon;
  final String title;
  final String body;
  final List<(IconData, String)> chips;

  const _PageData({
    required this.gradientColors,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.body,
    required this.chips,
  });
}
