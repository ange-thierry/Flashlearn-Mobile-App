import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../widgets/notif_scaffold.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final achievements = prov.achievements;
    final unlocked = achievements.where((a) => a.isUnlocked).length;

    return NotifScaffold(
      showBell: false,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1202), Color(0xFF3D2A04)],
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
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_ios_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        const Text('Back', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(Icons.emoji_events_rounded, size: 44, color: Color(0xFFBA7517)),
                const SizedBox(height: 8),
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: achievements.isEmpty
                              ? 0
                              : unlocked / achievements.length,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFFBA7517)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$unlocked / ${achievements.length} unlocked',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Achievement grid ──────────────────────────────────────────────
          Expanded(
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: achievements.isEmpty
                  ? const Center(child: Text('No achievements yet.'))
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        18, 20, 18,
                        24 + MediaQuery.of(context).viewPadding.bottom,
                      ),
                      itemCount: achievements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = achievements[i];
                        return _AchievementTile(achievement: a);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final unlocked = a.isUnlocked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFF8F7F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFBA7517).withValues(alpha: 0.4)
              : const Color(0xFFE0DDD8),
          width: unlocked ? 1.5 : 0.5,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: const Color(0xFFBA7517).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: unlocked
                      ? const LinearGradient(
                          colors: [Color(0xFFBA7517), Color(0xFF7A4D0A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: unlocked ? null : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  unlocked ? a.icon : '🔒',
                  style: TextStyle(fontSize: unlocked ? 26 : 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: unlocked
                            ? const Color(0xFF1A1A2E)
                            : const Color(0xFF888780),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      a.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: unlocked
                            ? const Color(0xFF5F5E5A)
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                    if (unlocked && a.unlockedAt != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA7517).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Unlocked ${_formatDate(a.unlockedAt!)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFBA7517),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (unlocked)
                const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFBA7517)),
            ],
          ),
          if (unlocked) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF0E8CC), height: 1),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/award-certificate',
                arguments: achievement,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBA7517), Color(0xFF7A4D0A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'View Award Certificate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
