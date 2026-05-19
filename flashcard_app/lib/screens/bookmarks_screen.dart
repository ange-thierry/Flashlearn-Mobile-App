import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../data/study_card_data.dart';
import '../data/fields_data.dart';
import '../theme/app_theme.dart';
import '../widgets/notif_scaffold.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with TickerProviderStateMixin {
  // Entrance animation
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  List<_BookmarkEntry> _resolveCards(AppProvider prov) {
    return prov.bookmarkedCards
        .map((key) {
          final parts = key.split(':');
          if (parts.length < 3) return null;
          final fieldId = parts[0];
          final level   = parts[1];
          final idx     = int.tryParse(parts[2]);
          if (idx == null) return null;
          final card = studyCardData[fieldId]?[level];
          if (card == null || idx >= card.length) return null;
          return _BookmarkEntry(
            key_: key, fieldId: fieldId, level: level,
            cardIndex: idx,
            question: card[idx]['q'] ?? '',
            answer: card[idx]['a'] ?? '',
          );
        })
        .whereType<_BookmarkEntry>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov  = context.watch<AppProvider>();
    final cards = _resolveCards(prov);
    const top = 0.0;
    final bot = MediaQuery.of(context).viewPadding.bottom;

    return NotifScaffold(
      showBell: false,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(18, top + 10, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                      ),
                      child: const Icon(Icons.bookmark_rounded, size: 26, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saved Cards',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text(
                          '${cards.length} bookmark${cards.length == 1 ? '' : 's'} — tap to flip',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Cards ────────────────────────────────────────────────────────
          Expanded(
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: cards.isEmpty
                ? _EmptyBookmarks()
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(18, 20, 18, bot + 20),
                    itemCount: cards.length,
                    itemBuilder: (context, i) {
                      final delay = i * 0.08;
                      final end   = (delay + 0.40).clamp(0.0, 1.0);
                      final anim  = CurvedAnimation(
                        parent: _entranceCtrl,
                        curve: Interval(delay, end, curve: Curves.easeOut),
                      );
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.22),
                            end: Offset.zero,
                          ).animate(anim),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _FlipBookmarkCard(
                              entry: cards[i],
                              onRemove: () {
                                prov.removeBookmark(cards[i].key_);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Bookmark removed'),
                                    backgroundColor: const Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flip Card ──────────────────────────────────────────────────────────────────

class _FlipBookmarkCard extends StatefulWidget {
  final _BookmarkEntry entry;
  final VoidCallback onRemove;
  const _FlipBookmarkCard({required this.entry, required this.onRemove});
  @override
  State<_FlipBookmarkCard> createState() => _FlipBookmarkCardState();
}

class _FlipBookmarkCardState extends State<_FlipBookmarkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 440));
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip() {
    if (_isFlipped) { _ctrl.reverse(); } else { _ctrl.forward(); }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    final grad       = fieldGradient(widget.entry.fieldId);
    final levelColor = {
      'easy': AppTheme.easy, 'normal': AppTheme.normal, 'hard': AppTheme.hard,
    }[widget.entry.level] ?? AppTheme.easy;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final val      = _anim.value;
        final showBack = val >= 0.5;
        final face     = showBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: _buildBack(grad, levelColor),
              )
            : _buildFront(grad, levelColor);

        return GestureDetector(
          onTap: _flip,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(val * math.pi),
            child: face,
          ),
        );
      },
    );
  }

  Widget _buildFront(List<Color> grad, Color levelColor) {
    final fieldName = builtInFields
        .firstWhere((f) => f.id == widget.entry.fieldId, orElse: () => builtInFields.first)
        .name;

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [grad.first, grad.last],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: grad.last.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(top: -20, right: -20, child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
          )),
          Positioned(bottom: -14, left: -10, child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fieldName.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.entry.level.toUpperCase(),
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: levelColor),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${widget.entry.cardIndex + 1}',
                        style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Question
                Text(
                  widget.entry.question,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: Colors.white, height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Flip hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Flip for answer', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          SizedBox(width: 5),
                          Icon(Icons.flip_rounded, size: 13, color: Colors.white70),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(List<Color> grad, Color levelColor) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: grad.last.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: grad.last.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back face header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [grad.first.withValues(alpha: 0.12), grad.last.withValues(alpha: 0.06)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _flip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: grad.first.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: grad.first.withValues(alpha: 0.20), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_rounded, size: 11, color: grad.first),
                        const SizedBox(width: 3),
                        Text('Question', style: TextStyle(fontSize: 11, color: grad.first, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('ANSWER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF16A34A), letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          // Answer text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entry.answer,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E), height: 1.55),
                ),
                const SizedBox(height: 16),
                // Remove button
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.30), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_remove_rounded, size: 15, color: Color(0xFFEF4444)),
                        SizedBox(width: 6),
                        Text('Remove bookmark', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyBookmarks extends StatefulWidget {
  @override
  State<_EmptyBookmarks> createState() => _EmptyBookmarksState();
}

class _EmptyBookmarksState extends State<_EmptyBookmarks>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _bounce.value),
                child: child,
              ),
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_outline_rounded, size: 40, color: Color(0xFF16A34A)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('No bookmarks yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on any\nstudy card to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _BookmarkEntry {
  final String key_, fieldId, level, question, answer;
  final int cardIndex;
  _BookmarkEntry({
    required this.key_, required this.fieldId, required this.level,
    required this.cardIndex, required this.question, required this.answer,
  });
}
