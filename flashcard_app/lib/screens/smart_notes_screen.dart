import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── SMART NOTES SCREEN ────────────────────────────────────────────────────────

class SmartNotesScreen extends StatefulWidget {
  const SmartNotesScreen({super.key});

  @override
  State<SmartNotesScreen> createState() => _SmartNotesScreenState();
}

class _SmartNotesScreenState extends State<SmartNotesScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<_GeneratedCard> _cards = [];
  bool _generating = false;
  bool _generated = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showSnack('Paste or type your notes first.');
      return;
    }
    if (text.split(' ').length < 5) {
      _showSnack('Add more content for better results.');
      return;
    }
    setState(() {
      _generating = true;
      _generated = false;
      _cards = [];
    });
    // Simulate processing delay for AI feel
    await Future.delayed(const Duration(milliseconds: 1400));
    final cards = _SmartNotesEngine.generate(text);
    if (!mounted) return;
    setState(() {
      _generating = false;
      _generated = true;
      _cards = cards;
    });
    if (_cards.isEmpty) {
      _showSnack('No flashcards detected. Try adding definition sentences.');
    } else {
      await Future.delayed(const Duration(milliseconds: 200));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _cards = [];
      _generated = false;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppTheme.primary),
            ),
            const SizedBox(width: 8),
            const Text('Smart Notes',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          if (_controller.text.isNotEmpty || _generated)
            TextButton(
              onPressed: _clear,
              child: Text('Clear',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderBanner(isDark: isDark),
            const SizedBox(height: 18),
            _InputSection(
              controller: _controller,
              isDark: isDark,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _GenerateButton(
              generating: _generating,
              pulseCtrl: _pulseCtrl,
              onTap: _generate,
              hasText: _controller.text.trim().isNotEmpty,
            ),
            if (_generating) ...[
              const SizedBox(height: 24),
              const _ProcessingIndicator(),
            ],
            if (_generated && _cards.isNotEmpty) ...[
              const SizedBox(height: 28),
              _ResultsHeader(count: _cards.length),
              const SizedBox(height: 12),
              ..._cards.asMap().entries.map(
                (e) => _CardTile(card: e.value, index: e.key),
              ),
              const SizedBox(height: 16),
              _TipBanner(isDark: isDark),
            ],
            if (_generated && _cards.isEmpty) ...[
              const SizedBox(height: 24),
              const _EmptyResult(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── HEADER BANNER ─────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  final bool isDark;
  const _HeaderBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.12),
            AppTheme.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.18), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description_rounded,
                size: 22, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Flashcard Generator',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  'Paste your notes — flashcards are auto-generated instantly.',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? Colors.white60
                          : const Color(0xFF374151)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── INPUT SECTION ─────────────────────────────────────────────────────────────

class _InputSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  const _InputSection(
      {required this.controller,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Notes',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 10,
            minLines: 6,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: isDark ? Colors.white : const Color(0xFF0F0E17),
            ),
            decoration: InputDecoration(
              hintText:
                  'Paste your lecture notes, textbook passages, or study material here...\n\nExample:\nPhotosynthesis is the process by which plants make food using sunlight.\nThe mitochondria is the powerhouse of the cell.',
              hintStyle: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark
                    ? Colors.white30
                    : const Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${controller.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

// ── GENERATE BUTTON ───────────────────────────────────────────────────────────

class _GenerateButton extends StatelessWidget {
  final bool generating;
  final bool hasText;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;
  const _GenerateButton({
    required this.generating,
    required this.hasText,
    required this.pulseCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) {
        final scale = generating
            ? 1.0 + pulseCtrl.value * 0.015
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: generating ? null : onTap,
              icon: generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                generating ? 'Generating…' : 'Generate Flashcards',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasText && !generating ? AppTheme.primary : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── PROCESSING INDICATOR ──────────────────────────────────────────────────────

class _ProcessingIndicator extends StatelessWidget {
  const _ProcessingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(
            'Analysing your notes…',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'Extracting key concepts and definitions',
            style: TextStyle(
                fontSize: 11.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── RESULTS HEADER ────────────────────────────────────────────────────────────

class _ResultsHeader extends StatelessWidget {
  final int count;
  const _ResultsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded,
            size: 18, color: AppTheme.primary),
        const SizedBox(width: 7),
        Text(
          '$count flashcard${count == 1 ? '' : 's'} generated',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary),
        ),
      ],
    );
  }
}

// ── CARD TILE ─────────────────────────────────────────────────────────────────

class _CardTile extends StatefulWidget {
  final _GeneratedCard card;
  final int index;
  const _CardTile({required this.card, required this.index});

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _expanded ? _ctrl.forward() : _ctrl.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _tagColor(widget.card.tag);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _toggle,
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: accent.withValues(alpha: 0.25), width: 0.8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6)
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Q${widget.index + 1}',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TagChip(label: widget.card.tag, color: accent),
                      const Spacer(),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.card.question,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  SizeTransition(
                    sizeFactor: _expandAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Divider(
                            height: 1,
                            color: accent.withValues(alpha: 0.2)),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              margin: const EdgeInsets.only(top: 2, right: 8),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.card.answer,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
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

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Definition':
        return AppTheme.primary;
      case 'Concept':
        return const Color(0xFF6366F1);
      case 'Process':
        return const Color(0xFFF97316);
      case 'Fact':
        return const Color(0xFF06B6D4);
      default:
        return AppTheme.primary;
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── TIP BANNER ────────────────────────────────────────────────────────────────

class _TipBanner extends StatelessWidget {
  final bool isDark;
  const _TipBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              size: 16,
              color: isDark ? Colors.amber.shade300 : Colors.amber.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap any card to reveal the answer. Add these to your study set for a full flashcard session.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── EMPTY RESULT ──────────────────────────────────────────────────────────────

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No flashcards detected',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Try sentences like:\n"Osmosis is the movement of water across a membrane."',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── DATA MODEL ────────────────────────────────────────────────────────────────

class _GeneratedCard {
  final String question;
  final String answer;
  final String tag;
  const _GeneratedCard(
      {required this.question, required this.answer, required this.tag});
}

// ── PROCESSING ENGINE ─────────────────────────────────────────────────────────

class _SmartNotesEngine {
  static List<_GeneratedCard> generate(String text) {
    final sentences = _splitSentences(text);
    final cards = <_GeneratedCard>[];
    final seen = <String>{};

    for (final sentence in sentences) {
      final s = sentence.trim();
      if (s.length < 15) continue;

      _GeneratedCard? card =
          _tryDefinitionPattern(s) ??
          _tryProcessPattern(s) ??
          _tryCompositionPattern(s) ??
          _tryHistoricalPattern(s) ??
          _tryFormulaPattern(s) ??
          _tryExamplePattern(s);

      if (card != null) {
        final key = card.question.toLowerCase();
        if (!seen.contains(key)) {
          seen.add(key);
          cards.add(card);
        }
      }
    }
    return cards;
  }

  // ── Sentence splitting ──────────────────────────────────────────────────────

  static List<String> _splitSentences(String text) {
    // Split on period/exclamation/question mark followed by space or end,
    // but preserve abbreviations heuristically (single capital letter before dot).
    final raw = text
        .replaceAll('\n\n', '. ')
        .replaceAll('\n', ' ')
        .trim();
    final parts = <String>[];
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final ch = raw[i];
      buf.write(ch);
      if ((ch == '.' || ch == '!' || ch == '?') && i + 1 < raw.length) {
        final next = raw[i + 1];
        if (next == ' ' || next == '\n') {
          final part = buf.toString().trim();
          if (part.isNotEmpty) parts.add(part);
          buf.clear();
          i++; // skip space
        }
      }
    }
    if (buf.isNotEmpty) parts.add(buf.toString().trim());
    return parts.where((p) => p.length > 8).toList();
  }

  // ── Pattern matchers ────────────────────────────────────────────────────────

  // "[Term] is/are [definition]"
  static _GeneratedCard? _tryDefinitionPattern(String s) {
    final re = RegExp(
        r'^([A-Z][^.?!]{2,60}?)\s+(?:is|are|was|were)\s+(?:defined as\s+|described as\s+)?(.+)',
        caseSensitive: true);
    final m = re.firstMatch(s);
    if (m == null) return null;
    final term = m.group(1)!.trim();
    final defn = _stripTrailingPunct(m.group(2)!.trim());
    if (term.split(' ').length > 8) return null; // too long to be a term
    final q = term.split(' ').length == 1
        ? 'What is ${term.toLowerCase()}?'
        : 'What ${_isPlural(term) ? 'are' : 'is'} ${term.toLowerCase()}?';
    return _GeneratedCard(question: q, answer: _capitalize(defn), tag: 'Definition');
  }

  // "[X] refers to / means / describes [Y]"
  static _GeneratedCard? _tryProcessPattern(String s) {
    final re = RegExp(
        r'^([A-Z][^.?!]{2,60}?)\s+(?:refers to|means|describes|involves|requires)\s+(.+)',
        caseSensitive: true);
    final m = re.firstMatch(s);
    if (m == null) return null;
    final term = m.group(1)!.trim();
    final defn = _stripTrailingPunct(m.group(2)!.trim());
    if (term.split(' ').length > 8) return null;
    return _GeneratedCard(
      question: 'What does ${term.toLowerCase()} involve/mean?',
      answer: _capitalize(defn),
      tag: 'Process',
    );
  }

  // "[X] consists of / contains / includes [Y]"
  static _GeneratedCard? _tryCompositionPattern(String s) {
    final re = RegExp(
        r'^([A-Z][^.?!]{2,60}?)\s+(?:consists of|contains|is made of|is made up of|is composed of|includes)\s+(.+)',
        caseSensitive: true);
    final m = re.firstMatch(s);
    if (m == null) return null;
    final term = m.group(1)!.trim();
    final defn = _stripTrailingPunct(m.group(2)!.trim());
    if (term.split(' ').length > 8) return null;
    return _GeneratedCard(
      question: 'What does ${term.toLowerCase()} consist of?',
      answer: _capitalize(defn),
      tag: 'Concept',
    );
  }

  // "[X] was/were born/invented/discovered in/by [Y]" or "[Name] [verb] [fact]"
  static _GeneratedCard? _tryHistoricalPattern(String s) {
    final re = RegExp(
        r'^([A-Z][a-zA-Z ]{1,40}?)\s+(?:was|were)\s+(born|invented|discovered|founded|created|established|introduced)\s+(.+)',
        caseSensitive: true);
    final m = re.firstMatch(s);
    if (m == null) return null;
    final subject = m.group(1)!.trim();
    final verb = m.group(2)!.trim();
    final detail = _stripTrailingPunct(m.group(3)!.trim());
    if (subject.split(' ').length > 5) return null;
    return _GeneratedCard(
      question: 'When/where was ${subject.toLowerCase()} $verb?',
      answer: _capitalize('${subject.capitalize()} was $verb $detail'),
      tag: 'Fact',
    );
  }

  // Sentences containing "formula", "equation", "symbol"
  static _GeneratedCard? _tryFormulaPattern(String s) {
    final re = RegExp(
        r'^([A-Z][^.?!]{2,60}?)\s+(?:formula|equation|symbol)\s+(?:is|are|for)\s+(.+)',
        caseSensitive: true);
    final m = re.firstMatch(s);
    if (m == null) return null;
    final term = m.group(1)!.trim();
    final value = _stripTrailingPunct(m.group(2)!.trim());
    return _GeneratedCard(
      question: 'What is the formula for ${term.toLowerCase()}?',
      answer: _capitalize(value),
      tag: 'Fact',
    );
  }

  // "[X] is an example of [Y]"  /  "An example of [X] is [Y]"
  static _GeneratedCard? _tryExamplePattern(String s) {
    final re = RegExp(
        r'[Aa]n?\s+example of\s+([^,\.]{3,60}?)\s+is\s+(.+)',
        caseSensitive: false);
    final m = re.firstMatch(s);
    if (m == null) return null;
    final concept = m.group(1)!.trim();
    final example = _stripTrailingPunct(m.group(2)!.trim());
    return _GeneratedCard(
      question: 'Give an example of ${concept.toLowerCase()}.',
      answer: _capitalize(example),
      tag: 'Concept',
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _stripTrailingPunct(String s) =>
      s.replaceAll(RegExp(r'[.!?]+$'), '').trim();

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static bool _isPlural(String term) {
    final lower = term.toLowerCase();
    return lower.endsWith('s') && !lower.endsWith('ss');
  }
}

extension on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
