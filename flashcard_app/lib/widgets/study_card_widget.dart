import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class StudyCardWidget extends StatefulWidget {
  final Map<String, String> card;
  final List<Color> gradient;
  final Color fieldColor;
  final String level;
  final int cardNum;
  final int total;
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;

  const StudyCardWidget({
    super.key,
    required this.card,
    required this.gradient,
    required this.fieldColor,
    required this.level,
    required this.cardNum,
    required this.total,
    required this.onCorrect,
    required this.onWrong,
    required this.isBookmarked,
    required this.onToggleBookmark,
  });

  @override
  State<StudyCardWidget> createState() => _StudyCardWidgetState();
}

class _StudyCardWidgetState extends State<StudyCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _entranceScale;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  bool _isFlipped = false;
  String? _answered;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _entranceScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack),
    );
    _entranceCtrl.forward();

    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant StudyCardWidget old) {
    super.didUpdateWidget(old);
    if (old.cardNum != widget.cardNum) {
      _flipCtrl.reset();
      setState(() {
        _isFlipped = false;
        _answered = null;
      });
      _entranceCtrl.reset();
      _entranceCtrl.forward();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (!_isFlipped) {
      SoundService.playFlip();
      _flipCtrl.forward();
      setState(() => _isFlipped = true);
    } else if (_answered == null) {
      SoundService.playFlip();
      _flipCtrl.reverse();
      setState(() => _isFlipped = false);
    }
  }

  String get _levelEmoji => {
        'easy': '🟢',
        'normal': '🟡',
        'hard': '🔴',
      }[widget.level]!;

  String get _levelLabel => {
        'easy': 'Easy',
        'normal': 'Normal',
        'hard': 'Hard',
      }[widget.level]!;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _entranceScale,
      child: Column(
        children: [
          GestureDetector(
            onTap: _flip,
            child: AnimatedBuilder(
              animation: _flipAnim,
              builder: (context, child) {
                final val = _flipAnim.value;
                final angle = val * math.pi;
                final isShowingBack = val >= 0.5;

                Widget face;
                if (isShowingBack) {
                  face = Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _buildBack(),
                  );
                } else {
                  face = _buildFront();
                }

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: face,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoChip(),
        ],
      ),
    );
  }

  // ── Front Face (Question) ─────────────────────────────────────────────────
  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: widget.fieldColor.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative shapes
          Positioned(
            top: -14,
            right: -14,
            child: Container(
              width: 90,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_levelEmoji,
                                  style: const TextStyle(fontSize: 11)),
                              const SizedBox(width: 5),
                              Text(
                                _levelLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Bookmark button
                        GestureDetector(
                          onTap: () {
                            widget.onToggleBookmark();
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              key: ValueKey(widget.isBookmarked),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: widget.isBookmarked
                                    ? const Color(0xFFBA7517).withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.isBookmarked ? 'Saved' : 'Save',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.cardNum} / ${widget.total}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: widget.cardNum / widget.total,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
              // Question
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STUDY QUESTION',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.card['q'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
              // Flip hint
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25), width: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tap to flip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
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
    );
  }

  // ── Back Face (Answer) ────────────────────────────────────────────────────
  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: widget.fieldColor.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -14,
            right: -14,
            child: Container(
              width: 90,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (back)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '💡 Answer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _answered == null ? _flip : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          ' Question',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Answer text
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANSWER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                      ),
                      child: Text(
                        widget.card['a'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _buildActions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_answered != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: _answered == 'correct'
              ? const Color(0xFF1D9E75).withValues(alpha: 0.2)
              : const Color(0xFFE24B4A).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _answered == 'correct'
                ? const Color(0xFF1D9E75).withValues(alpha: 0.5)
                : const Color(0xFFE24B4A).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _answered == 'correct' ? '  Mastered' : '😕  Not Mastered',
          style: TextStyle(
            color: _answered == 'correct'
                ? const Color(0xFFAAFFCC)
                : const Color(0xFFFFAAAA),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return Row(
      children: [
        // ── Wrong ───────────────────────────────────────────────────────
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() => _answered = 'wrong');
                widget.onWrong();
              },
              splashColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.50),
                    width: 1.5,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('😕', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text(
                        'Unmastered',
                        style: TextStyle(
                          color: Color(0xFFFFCCCC),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ── Correct ─────────────────────────────────────────────────────
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() => _answered = 'correct');
                widget.onCorrect();
              },
              splashColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.50),
                    width: 1.5,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✓', style: TextStyle(fontSize: 16, color: Color(0xFFAAFFCC))),
                      SizedBox(width: 6),
                      Text(
                        'Mastered',
                        style: TextStyle(
                          color: Color(0xFFAAFFCC),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip() {
    final answered = _answered;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF333355), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: widget.fieldColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.style_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answered == null
                      ? _isFlipped
                          ? 'Mark yourself after reading the answer'
                          : 'Tap the card to reveal the answer'
                      : answered == 'correct'
                          ? ' Mastered — great job!'
                          : '😕 Not mastered yet — review it!',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _dot(AppTheme.easy),
                    const SizedBox(width: 5),
                    _dot(AppTheme.normal),
                    const SizedBox(width: 5),
                    _dot(AppTheme.hard),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
