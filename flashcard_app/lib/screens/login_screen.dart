import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';

// ── Palette ─────────────────────────────────────────────────────────────────
const _green700 = Color(0xFF15803D);
const _green500 = Color(0xFF16A34A);
const _green100 = Color(0xFFDCFCE7);
const _greenGlow = Color(0xFF22C55E);
const _bg       = Color(0xFFF0FDF4);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Entrance animations ────────────────────────────────────────────────────
  late AnimationController _entranceCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _statsFade;
  late Animation<double> _featuresFade;
  late Animation<double> _ctaFade;

  // ── Logo pulse ─────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // ── Form state ─────────────────────────────────────────────────────────────
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _loading = false;
  String _error = '';
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass     = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.0, 0.42, curve: Curves.easeOutBack)));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.0, 0.32)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.26, 0.58, curve: Curves.easeOut)));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.26, 0.56)));
    _statsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.42, 0.64)));
    _featuresFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.56, 0.78)));
    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entranceCtrl,
            curve: const Interval(0.70, 1.0)));

    _entranceCtrl.forward();

    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
        reverseDuration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.45, end: 0.80).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Auth handlers ──────────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = ''; });
    final result = await AuthService().signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == AuthResult.success) {
      final auth = AuthService();
      await context.read<AppProvider>().reloadForCurrentUser();
      if (auth.isAdmin) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        await _showWelcomeOverlay();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/fields');
      }
    } else if (result != AuthResult.cancelled) {
      setState(() => _error = 'Google sign-in failed. Check your connection.');
    }
  }

  Future<void> _showWelcomeOverlay() async {
    final auth = AuthService();
    final completer = Completer<void>();
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => _WelcomeDialog(
        name: auth.displayName,
        firstName: auth.firstName,
        photoUrl: auth.photoURL,
        onDone: () { Navigator.of(ctx).pop(); completer.complete(); },
      ),
    );
    return completer.future;
  }

  Future<void> _emailSubmit() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (_isSignUp) {
      final confirm = _confirmCtrl.text.trim();
      if (confirm != pass) {
        setState(() => _error = 'Passwords do not match.');
        return;
      }
      if (pass.length < 6) {
        setState(() => _error = 'Password must be at least 6 characters.');
        return;
      }
    }
    setState(() { _loading = true; _error = ''; });
    final auth = AuthService();
    final result = _isSignUp
        ? await auth.signUp(email, pass)
        : await auth.signIn(email, pass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == AuthResult.success) {
      final auth = AuthService();
      await context.read<AppProvider>().reloadForCurrentUser();
      if (auth.isAdmin) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (_isSignUp) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/fields');
      } else {
        await _showWelcomeOverlay();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/fields');
      }
    } else {
      setState(() => _error = _errorMsg(result));
    }
  }

  String _errorMsg(AuthResult r) => switch (r) {
    AuthResult.wrongPassword => 'Incorrect password.',
    AuthResult.invalidEmail  => 'Invalid email address.',
    AuthResult.emailInUse    => 'Email already in use — try signing in.',
    AuthResult.weakPassword  => 'Password must be at least 6 characters.',
    _                        => 'Authentication failed. Please try again.',
  };

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _Background(size: size),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                26, 0, 26, MediaQuery.of(context).viewPadding.bottom + 16,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, __) => _AppLogo(glowOpacity: _pulse.value),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: const _TitleBlock(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  FadeTransition(
                    opacity: _statsFade,
                    child: const _StatsStrip(),
                  ),

                  const SizedBox(height: 26),

                  FadeTransition(
                    opacity: _featuresFade,
                    child: const _FeatureRow(),
                  ),

                  const SizedBox(height: 10),

                  FadeTransition(
                    opacity: _featuresFade,
                    child: const _TrustRow(),
                  ),

                  const SizedBox(height: 30),

                  FadeTransition(
                    opacity: _ctaFade,
                    child: _buildCTA(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CTA section ────────────────────────────────────────────────────────────
  Widget _buildCTA() {
    return Column(
      children: [
        // Error banner
        if (_error.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppTheme.hard.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.hard.withValues(alpha: 0.30), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.hard),
                const SizedBox(width: 8),
                Expanded(child: Text(_error,
                    style: const TextStyle(fontSize: 12, color: AppTheme.hard))),
              ],
            ),
          ),

        // Prompt text
        Text(
          'Choose how you\'d like to continue',
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 14),

        // PRIMARY: Continue with Google
        _GoogleButton(loading: _loading, onTap: _googleSignIn),

        const SizedBox(height: 14),

        // Sign In / Sign Up toggle tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25), width: 1),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _AuthModeTab(
                label: 'Sign In',
                icon: Icons.login_rounded,
                active: !_isSignUp,
                onTap: () => setState(() { _isSignUp = false; _error = ''; }),
              ),
              _AuthModeTab(
                label: 'Sign Up',
                icon: Icons.person_add_rounded,
                active: _isSignUp,
                onTap: () => setState(() { _isSignUp = true; _error = ''; }),
              ),
            ],
          ),
        ),

        // Email form
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _showEmailForm
              ? _EmailForm(
                  loading: _loading,
                  showPass: _showPass,
                  isSignUp: _isSignUp,
                  emailCtrl: _emailCtrl,
                  passCtrl: _passCtrl,
                  confirmCtrl: _confirmCtrl,
                  onTogglePass: () => setState(() => _showPass = !_showPass),
                  onSubmit: _emailSubmit,
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 10),

        // Show/hide email form toggle
        GestureDetector(
          onTap: () => setState(() { _showEmailForm = !_showEmailForm; _error = ''; }),
          child: Text(
            _showEmailForm ? 'Hide form' : 'Continue with Email',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF16A34A).withValues(alpha: 0.80),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF16A34A).withValues(alpha: 0.40),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Free forever · No credit card needed',
          style: TextStyle(
            fontSize: 11,
            color: _green700.withValues(alpha: 0.50),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  final Size size;
  const _Background({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base white-indigo gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F5FD), Color(0xFFECEBFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Purple glow — top right
        Positioned(
          top: -size.height * 0.08,
          right: -size.width * 0.18,
          child: Container(
            width: size.width * 0.75,
            height: size.width * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _greenGlow.withValues(alpha: 0.16),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        // Soft indigo glow — bottom left
        Positioned(
          bottom: -size.height * 0.08,
          left: -size.width * 0.12,
          child: Container(
            width: size.width * 0.65,
            height: size.width * 0.65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _green500.withValues(alpha: 0.10),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        // Dot grid overlay
        Opacity(
          opacity: 0.045,
          child: CustomPaint(
            painter: _DotGridPainter(),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _green500.withValues(alpha: 0.40)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    const spacing = 26.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// APP LOGO
// ─────────────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  final double glowOpacity;
  const _AppLogo({required this.glowOpacity});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120, height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _greenGlow.withValues(alpha: glowOpacity * 0.40),
                _green500.withValues(alpha: glowOpacity * 0.14),
                Colors.transparent,
              ], stops: const [0.0, 0.5, 1.0]),
            ),
          ),
          // Logo box
          Container(
            width: 86, height: 86,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF15803D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _green500.withValues(alpha: glowOpacity * 0.65),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            ),
            child: const Icon(Icons.auto_stories_rounded, size: 44, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TITLE BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'FlashLearn',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.2,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Master any subject, one card at a time.\nStudy smarter with adaptive flashcards.',
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.55),
            height: 1.5,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _green500.withValues(alpha: 0.20), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _green500.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_rounded, size: 16, color: _green700),
          const SizedBox(width: 8),
          Text(
            'Sharpen your mind',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F5233),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 3, height: 3,
            decoration: BoxDecoration(
              color: _green500.withValues(alpha: 0.40),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.auto_stories_rounded, size: 14, color: _green700),
          const SizedBox(width: 5),
          Text(
            'Learn smarter',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.50),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE ROW
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  static const _features = [
    (Icons.local_fire_department_rounded, 'Streaks',      'Build habits',  Color(0xFFCC6600), Color(0xFFFFF0DC)),
    (Icons.emoji_events_rounded, 'Achievements', 'Earn rewards',  Color(0xFF3730A3), Color(0xFFEEEEFF)),
    (Icons.bolt_rounded, 'Smart Quiz',   'Test yourself', Color(0xFF1565C0), Color(0xFFDCEEFF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _features.map((f) {
        final (icon, title, sub, accent, bg) = f;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.18), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Center(child: Icon(icon, size: 22, color: accent)),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1B3A2A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: TextStyle(fontSize: 10, color: const Color(0xFF1A1A2E).withValues(alpha: 0.42)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRUST ROW
// ─────────────────────────────────────────────────────────────────────────────

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _avatarColors = [
    Color(0xFF2EA86B), Color(0xFF1565C0), Color(0xFFCC6600),
    Color(0xFF7B1FA2), Color(0xFF1B7C4A),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 74, height: 24,
          child: Stack(
            children: List.generate(5, (i) => Positioned(
              left: i * 13.0,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: _avatarColors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 2),
                ),
                child: Center(child: Text(
                  ['A', 'B', 'C', 'D', 'E'][i],
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                )),
              ),
            )),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Joined by students worldwide',
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : onTap,
        splashColor: _green100,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _green500.withValues(alpha: 0.30), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _green500.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4285F4)),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GoogleLogo(),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22, height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    final colors = [
      (const Color(0xFF4285F4), 0.0, 0.25),
      (const Color(0xFFEA4335), 0.25, 0.50),
      (const Color(0xFFFBBC05), 0.50, 0.70),
      (const Color(0xFF34A853), 0.70, 1.0),
    ];

    for (final (color, start, end) in colors) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      final startAngle = (start * 2 - 0.5) * 3.14159;
      final sweepAngle = (end - start) * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 1.5),
        startAngle, sweepAngle - 0.05, false, paint,
      );
    }

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(size.width - 1, cy), barPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH MODE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _AuthModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _AuthModeTab({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF16A34A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : const Color(0xFF16A34A).withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF16A34A).withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMAIL FORM
// ─────────────────────────────────────────────────────────────────────────────

class _EmailForm extends StatelessWidget {
  final bool loading;
  final bool showPass;
  final bool isSignUp;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final VoidCallback onTogglePass;
  final VoidCallback onSubmit;

  const _EmailForm({
    required this.loading,
    required this.showPass,
    required this.isSignUp,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.onTogglePass,
    required this.onSubmit,
  });

  static const _green500 = Color(0xFF16A34A);
  static const _green700 = Color(0xFF15803D);
  static const _bg = Color(0xFFF0FDF4);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green500.withValues(alpha: 0.18), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _green500.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email field
          _field(
            controller: emailCtrl,
            hint: 'you@example.com',
            icon: Icons.alternate_email_rounded,
            type: TextInputType.emailAddress,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          // Password field
          TextField(
            controller: passCtrl,
            obscureText: !showPass,
            textInputAction: isSignUp ? TextInputAction.next : TextInputAction.done,
            onSubmitted: isSignUp ? null : (_) => onSubmit(),
            style: const TextStyle(color: Color(0xFF1B3A2A), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: const Color(0xFF1A1A2E).withValues(alpha: 0.30), fontSize: 14),
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20,
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.35)),
              suffixIcon: IconButton(
                icon: Icon(
                  showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: const Color(0xFF1A1A2E).withValues(alpha: 0.35),
                ),
                onPressed: onTogglePass,
              ),
              filled: true, fillColor: _bg,
              border: _inputBorder(),
              enabledBorder: _inputBorder(),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _green500, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          // Confirm password (sign up only)
          if (isSignUp) ...[
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: !showPass,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              style: const TextStyle(color: Color(0xFF1B3A2A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Confirm password',
                hintStyle: TextStyle(color: const Color(0xFF1A1A2E).withValues(alpha: 0.30), fontSize: 14),
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 20,
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.35)),
                filled: true, fillColor: _bg,
                border: _inputBorder(),
                enabledBorder: _inputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _green500, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: Icon(isSignUp ? Icons.person_add_rounded : Icons.login_rounded, size: 18),
              label: loading
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      isSignUp ? 'Create Account' : 'Sign In',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
          if (isSignUp) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Already have an account? Switch to Sign In above.',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.40),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? type,
    TextInputAction? action,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textInputAction: action,
      style: const TextStyle(color: Color(0xFF1B3A2A), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF1A1A2E).withValues(alpha: 0.30), fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A1A2E).withValues(alpha: 0.35)),
        filled: true,
        fillColor: _bg,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _green500, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  static OutlineInputBorder _inputBorder() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide(color: _green500.withValues(alpha: 0.18), width: 0.8),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeDialog extends StatefulWidget {
  final String name;
  final String firstName;
  final String? photoUrl;
  final VoidCallback onDone;

  const _WelcomeDialog({
    required this.name,
    required this.firstName,
    required this.photoUrl,
    required this.onDone,
  });

  @override
  State<_WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _photoScale;
  late Animation<double> _textFade;
  late Animation<double> _progressVal;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

    _photoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack)));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.65)));
    _progressVal = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)));

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _green500.withValues(alpha: 0.40), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _green500.withValues(alpha: 0.25),
                blurRadius: 50,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _photoScale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          _green500.withValues(alpha: 0.30),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: _green500.withValues(alpha: 0.55), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _green500.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.photoUrl != null
                            ? Image.network(
                                widget.photoUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) =>
                                    progress == null ? child : _initials(widget.name),
                                errorBuilder: (_, __, ___) => _initials(widget.name),
                              )
                            : _initials(widget.name),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.50),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.firstName,
                      style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3A2A), letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.name != widget.firstName ? widget.name : 'Ready to learn?',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1A1A2E).withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              FadeTransition(
                opacity: _textFade,
                child: AnimatedBuilder(
                  animation: _progressVal,
                  builder: (_, __) => Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressVal.value,
                          minHeight: 4,
                          color: _green500,
                          backgroundColor: _green100,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Taking you to your dashboard…',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF1A1A2E).withValues(alpha: 0.30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initials(String name) {
    final parts = name.trim().split(' ');
    final text = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(text,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}
