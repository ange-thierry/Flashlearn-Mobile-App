import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../models/models.dart';
import '../services/app_provider.dart';
import '../services/firestore_service.dart';
import '../data/fields_data.dart';
import '../theme/app_theme.dart';
import '../widgets/notif_scaffold.dart';
import '../widgets/notification_panel.dart';
import '../utils/icon_helper.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  String _selectedCategory = 'all';

  // Search state
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Bottom nav: 0=Home 1=Saved 2=Awards 3=Alerts 4=About Us
  static const _navItems = [
    (Icons.home_rounded,          Icons.home_outlined,              'Home'),
    (Icons.bookmark_rounded,      Icons.bookmark_outline_rounded,   'Saved'),
    (Icons.emoji_events_rounded,  Icons.emoji_events_outlined,      'Awards'),
    (Icons.notifications_rounded, Icons.notifications_none_rounded, 'Alerts'),
    (Icons.info_rounded,          Icons.info_outline_rounded,       'About Us'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FieldModel> _filteredFields(AppProvider prov) {
    if (_searchQuery.isEmpty) return prov.fields;
    final q = _searchQuery.toLowerCase();
    return prov.fields.where((f) {
      return f.name.toLowerCase().contains(q) ||
          f.desc.toLowerCase().contains(q) ||
          (_kFieldTitles[f.id] ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return NotifScaffold(
      showBell: false,
      body: LayoutBuilder(
        builder: (ctx, constraints) => constraints.maxWidth >= 700
            ? _wideLayout(ctx, prov)
            : _mobileLayout(ctx, prov),
      ),
    );
  }

  void _onNavTap(BuildContext context, AppProvider prov, int index) {
    if (index == 1) Navigator.pushNamed(context, '/bookmarks');
    else if (index == 2) Navigator.pushNamed(context, '/achievements');
    else if (index == 3) _openNotifSheet(context, prov);
    else if (index == 4) _openAboutUsSheet(context);
  }

  // ── Notification bottom sheet ─────────────────────────────────────────────
  void _openNotifSheet(BuildContext context, AppProvider prov) {
    final notif = prov.notifService;
    notif.markAllRead();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.60,
          maxChildSize: 0.92,
          minChildSize: 0.35,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_rounded, size: 18, color: Color(0xFF1A1A2E)),
                      const SizedBox(width: 8),
                      const Text('Alerts',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                      const Spacer(),
                      StreamBuilder<List<AppNotification>>(
                        stream: notif.notificationsStream,
                        builder: (_, __) => notif.notifications.isNotEmpty
                            ? TextButton(
                                onPressed: () { notif.clearAll(); Navigator.pop(ctx); },
                                child: const Text('Clear all',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF9A9895))),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // ── Admin Alerts from Firestore ──────────────────────
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirestoreService().notificationsHistoryStream,
                        builder: (_, snap) {
                          final adminDocs = snap.data?.docs ?? [];
                          if (adminDocs.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.30), width: 0.8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.campaign_rounded, size: 11, color: Color(0xFF16A34A)),
                                        SizedBox(width: 4),
                                        Text('From Admin', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                              ...adminDocs.take(10).map((doc) {
                                final d = doc.data();
                                final title = d['title'] as String? ?? '';
                                final body  = d['body']  as String? ?? '';
                                final type  = d['type']  as String? ?? 'announcement';
                                final ts    = (d['sentAt'] as Timestamp?)?.toDate();
                                final (icon, color) = switch (type) {
                                  'reminder'    => (Icons.alarm_rounded,         const Color(0xFF16A34A)),
                                  'new_content' => (Icons.auto_awesome_rounded,  const Color(0xFF8B5CF6)),
                                  'alert'       => (Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
                                  _ => (Icons.campaign_rounded, const Color(0xFF3B82F6)),
                                };
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: color.withValues(alpha: 0.20), width: 0.8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Icon(icon, size: 15, color: color),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(title,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                                            if (body.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(body,
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                                                  maxLines: 3, overflow: TextOverflow.ellipsis),
                                            ],
                                            if (ts != null) ...[
                                              const SizedBox(height: 5),
                                              Text(_fmtTime(ts),
                                                  style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(height: 24),
                            ],
                          );
                        },
                      ),
                      // ── Local app notifications ──────────────────────────
                      StreamBuilder<List<AppNotification>>(
                        stream: notif.notificationsStream,
                        builder: (_, __) {
                          final items = notif.notifications;
                          if (items.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.notifications_outlined, size: 40, color: Color(0xFF9A9895)),
                                    SizedBox(height: 10),
                                    Text('No app notifications yet',
                                        style: TextStyle(fontSize: 13, color: Color(0xFF9A9895))),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('App Notifications',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade500)),
                              ),
                              NotificationPanel(
                                notifications: items,
                                onClearAll: () { notif.clearAll(); Navigator.pop(ctx); },
                                onDismiss: notif.dismiss,
                                onClose: () => Navigator.pop(ctx),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Profile bottom sheet ──────────────────────────────────────────────────
  void _openProfileSheet(BuildContext context, AppProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final name       = prov.auth.displayName;
        final email      = prov.auth.userEmail ?? '';
        final cards      = prov.totalCardsThisWeek;
        final streak     = prov.streak;
        final badges     = prov.achievements.where((a) => a.isUnlocked).length;
        final certs      = prov.fieldFinalsPassed.length;

        final isDark = prov.isDarkMode;
        final sheetBg = isDark ? const Color(0xFF161B22) : Colors.white;
        final textColor = isDark ? const Color(0xFFF0F6FC) : const Color(0xFF1A1A2E);
        final subColor  = isDark ? const Color(0xFF8B949E) : const Color(0xFF9A9895);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF30363D) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 22),
                // Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.18),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                if (email.isNotEmpty)
                  Text(email, style: TextStyle(fontSize: 13, color: subColor)),
                const SizedBox(height: 20),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _profileStatTile(Icons.menu_book_rounded, '$cards',  'Cards/Week'),
                    _profileStatTile(Icons.local_fire_department_rounded, '$streak', 'Streak'),
                    _profileStatTile(Icons.emoji_events_rounded, '$badges', 'Badges'),
                    _profileStatTile(Icons.school_rounded, '$certs',  'Certs'),
                  ],
                ),
                const SizedBox(height: 22),
                // Admin panel button — only visible to the admin account
                if (prov.isAdmin) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, '/admin');
                      },
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                      label: const Text('Admin Panel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Dark mode toggle row
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0D1117)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF30363D)
                          : const Color(0xFFBBF7D0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF3FB950) : AppTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: isDark,
                        onChanged: (_) {
                          prov.toggleDarkMode();
                          Navigator.pop(ctx);
                        },
                        activeTrackColor: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, '/weekly-report');
                        },
                        icon: const Icon(Icons.bar_chart_rounded, size: 16),
                        label: const Text('Weekly Report'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.35)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          prov.resetForSignOut();
                          await prov.auth.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE24B4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Profile avatar helper (Gravatar via UI Avatars, or Google photo) ─────────
  Widget _buildProfileAvatar(AppProvider prov, {double radius = 20}) {
    final photoUrl = prov.auth.photoURL;
    final name     = prov.auth.displayName;
    final email    = prov.auth.userEmail ?? '';
    final seed     = name.isNotEmpty ? name : email;

    // Gravatar / UI-Avatars fallback URL (no MD5 required)
    final avatarUrl = photoUrl != null && photoUrl.isNotEmpty
        ? photoUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(seed)}'
          '&background=15803D&color=fff&bold=true&size=200&rounded=true';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.22),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.white.withValues(alpha: 0.22),
            child: Center(
              child: Text(
                seed.isNotEmpty ? seed[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.85,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppTheme.accent.withValues(alpha: 0.18),
            child: Center(
              child: Text(
                seed.isNotEmpty ? seed[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: radius * 0.85,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── About Us bottom sheet ─────────────────────────────────────────────────────
  void _openAboutUsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bot = MediaQuery.of(ctx).viewPadding.bottom;
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          maxChildSize: 0.94,
          minChildSize: 0.45,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: sc,
              padding: EdgeInsets.zero,
              children: [
                // ── Gradient header ──────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1),
                            ),
                            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FlashLearn',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                              Text('Smart Flashcard Learning App',
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Body ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vision
                      _aboutSection(
                        icon: Icons.visibility_rounded,
                        color: const Color(0xFF16A34A),
                        title: 'Our Vision',
                        content:
                          'To become the leading mobile learning platform that empowers '
                          'students and professionals to master any subject through '
                          'intelligent, gamified flashcard learning.',
                      ),
                      const SizedBox(height: 14),

                      // Mission
                      _aboutSection(
                        icon: Icons.rocket_launch_rounded,
                        color: const Color(0xFF2563EB),
                        title: 'Our Mission',
                        content:
                          'To make quality education accessible to everyone by providing '
                          'structured learning paths, adaptive assessments, and '
                          'achievement-driven motivation — anytime, anywhere.',
                      ),
                      const SizedBox(height: 24),

                      // Contact section
                      const Text('Contact Us',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 12),
                      _contactTile(
                        icon: Icons.email_rounded,
                        color: const Color(0xFFEA4335),
                        text: 'angethierry250@gmail.com',
                      ),
                      const SizedBox(height: 8),
                      _contactTile(
                        icon: Icons.email_outlined,
                        color: const Color(0xFF4285F4),
                        text: 'lucpas15nov@gmail.com',
                      ),
                      const SizedBox(height: 8),
                      _contactTile(
                        icon: Icons.phone_rounded,
                        color: const Color(0xFF16A34A),
                        text: '+250 782 451 980',
                      ),
                      const SizedBox(height: 28),

                      // Version / credits
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
                              ),
                              child: const Text('Version 1.0.0',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 8),
                            const Text('© 2025 FlashLearn. All rights reserved.',
                                style: TextStyle(fontSize: 10, color: Color(0xFF9A9895))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: bot + 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _aboutSection({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 5),
                Text(content,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          ),
        ],
      ),
    );
  }

  Widget _profileStatTile(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9A9895))),
      ],
    );
  }

  // ── MOBILE ────────────────────────────────────────────────────────────────────
  Widget _mobileLayout(BuildContext context, AppProvider prov) {
    final searching = _searchQuery.isNotEmpty;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _heroHeader(context, prov, wide: false)),
                  SliverToBoxAdapter(child: _quickStatsChips(context, prov)),
                  if (searching) ...[
                    SliverToBoxAdapter(child: _searchResultsSection(context, prov)),
                  ] else ...[
                    SliverToBoxAdapter(child: _dailyGoalsCard(context, prov)),
                    SliverToBoxAdapter(child: _quickActionsRow(context, prov)),
                    SliverToBoxAdapter(child: _continueSection(context, prov)),
                    SliverToBoxAdapter(child: _categoryPills(context, prov)),
                    SliverToBoxAdapter(child: _upcomingSection(context, prov)),
                    SliverToBoxAdapter(child: _inProgressSection(context, prov)),
                    SliverToBoxAdapter(child: _mobileDashboard(context, prov)),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
            _bottomNav(context, prov, unreadCount: prov.notifService.unreadCount),
          ],
        ),
        // Create Deck FAB
        Positioned(
          bottom: MediaQuery.of(context).viewPadding.bottom + 68,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (prov.isSuspended) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.block_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your account is suspended. You cannot create new decks.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }
              _showCreateDeckDialog(context, prov);
            },
            backgroundColor: prov.isSuspended
                ? const Color(0xFF94A3B8)
                : const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: Icon(
              prov.isSuspended ? Icons.block_rounded : Icons.add_rounded,
              size: 20,
            ),
            label: const Text(
              'Create Deck',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateDeckDialog(BuildContext context, AppProvider prov) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final iconCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final name = nameCtrl.text.trim();
        final desc = descCtrl.text.trim();
        final icon = iconCtrl.text.trim();
        final isValid = name.isNotEmpty;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_box_rounded, color: Color(0xFF16A34A), size: 22),
              SizedBox(width: 8),
              Text('Create New Deck', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your deck will be visible to all users on the dashboard.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 16),
                _DeckDialogField(ctrl: iconCtrl, label: 'Emoji Icon', hint: 'e.g. 📚', onChanged: (_) => setS(() {})),
                const SizedBox(height: 12),
                _DeckDialogField(ctrl: nameCtrl, label: 'Deck Name *', hint: 'e.g. Spanish Vocabulary', onChanged: (_) => setS(() {})),
                const SizedBox(height: 12),
                _DeckDialogField(ctrl: descCtrl, label: 'Description', hint: 'What is this deck about?', maxLines: 2, onChanged: (_) => setS(() {})),
                const SizedBox(height: 14),
                // Color preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF1E3A5F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            icon.isNotEmpty ? icon : '📦',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : 'Deck Name',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              desc.isNotEmpty ? desc : 'Description',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 10),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isValid ? () async {
                final uid = prov.auth.currentUser?.uid ?? '';
                final deckId = 'ud_${uid.substring(0, uid.length > 6 ? 6 : uid.length)}_${DateTime.now().millisecondsSinceEpoch}';
                await prov.addUserDeck(FieldModel(
                  id: deckId,
                  name: name,
                  icon: icon.isEmpty ? '📦' : icon,
                  colorValue: 0xFF16A34A,
                  desc: desc,
                  gradientHex: const ['16A34A', '1E3A5F'],
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deck "$name" created and shared with all users!'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } : null,
              child: const Text('Create Deck'),
            ),
          ],
        );
      }),
    );
  }

  // ── WIDE ──────────────────────────────────────────────────────────────────────
  Widget _wideLayout(BuildContext context, AppProvider prov) {
    final searching = _searchQuery.isNotEmpty;
    return Row(
        children: [
          _sidebar(context, prov),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _heroHeader(context, prov, wide: true)),
                SliverToBoxAdapter(child: _quickStatsChips(context, prov)),
                if (searching) ...[
                  SliverToBoxAdapter(child: _searchResultsSection(context, prov)),
                ] else ...[
                  SliverToBoxAdapter(child: _continueSection(context, prov)),
                  SliverToBoxAdapter(child: _categoryPills(context, prov)),
                  SliverToBoxAdapter(child: _upcomingSection(context, prov)),
                  SliverToBoxAdapter(child: _inProgressSection(context, prov)),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          _rightPanel(context, prov),
        ],
    );
  }

  // â"€â"€ LEFT SIDEBAR â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
  Widget _sidebar(BuildContext context, AppProvider prov) {
    final name = prov.auth.displayName;
    final isDark = prov.isDarkMode;
    return Container(
      width: 72,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: const Color(0xFF30363D), width: 0.8) : null,
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22)),
          ),
          const SizedBox(height: 28),
          for (int i = 0; i < _navItems.length; i++) _sidebarIcon(context, prov, i),
          const Spacer(),
          GestureDetector(
            onTap: () => _openProfileSheet(context, prov),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.accent.withValues(alpha: 0.18),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _sidebarIcon(BuildContext context, AppProvider prov, int index) {
    final isActive = index == 0;
    final (activeIcon, inactiveIcon, _) = _navItems[index];
    return GestureDetector(
      onTap: () => _onNavTap(context, prov, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 44,
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          isActive ? activeIcon : inactiveIcon,
          size: 20,
          color: isActive ? Colors.white : const Color(0xFFB0AEB8),
        ),
      ),
    );
  }

  // â"€â"€ BOTTOM NAV â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
  Widget _bottomNav(BuildContext context, AppProvider prov, {required int unreadCount}) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final isDark = prov.isDarkMode;
    final navBg = isDark ? const Color(0xFF161B22) : Colors.white;
    final navBorder = isDark ? const Color(0xFF30363D) : Colors.black.withValues(alpha: 0.06);
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder, width: isDark ? 0.8 : 0)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 60,
        child: Row(
          children: List.generate(_navItems.length, (i) {
            final isHome  = i == 0;
            final isNotif = i == 3;
            final (activeIcon, inactiveIcon, label) = _navItems[i];
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onNavTap(context, prov, i),
                  splashColor: AppTheme.primary.withValues(alpha: 0.06),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: 40,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: isHome
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF16A34A),
                                        Color(0xFF22C55E),
                                      ],
                                    )
                                  : null,
                              color: isHome ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              isHome ? activeIcon : inactiveIcon,
                              size: 21,
                              color: isHome
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF8B949E) : const Color(0xFFB0AEB8)),
                            ),
                          ),
                          if (isNotif && unreadCount > 0)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    fontSize: 7,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isHome ? FontWeight.w700 : FontWeight.w500,
                          color: isHome
                              ? AppTheme.primary
                              : (isDark ? const Color(0xFF8B949E) : const Color(0xFFB0AEB8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── HERO HEADER ───────────────────────────────────────────────────────────────
  Widget _heroHeader(BuildContext context, AppProvider prov, {required bool wide}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App name row ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App logo icon
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.8),
                ),
                child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              // App name
              const Expanded(
                child: Text(
                  'FlashLearn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              // Profile avatar at top right — taps open Profile sheet
              GestureDetector(
                onTap: () => _openProfileSheet(context, prov),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.70), width: 2),
                  ),
                  child: _buildProfileAvatar(prov, radius: 19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Search bar ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search subjects, topics…',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                    ),
                  )
                else
                  const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK STATS CHIPS ─────────────────────────────────────────────────────────
  Widget _quickStatsChips(BuildContext context, AppProvider prov) {
    final streak = prov.streak;
    final totalCards = prov.totalCardsThisWeek;
    final unlocked = prov.achievements.where((a) => a.isUnlocked).length;
    final finalsPassed = prov.fieldFinalsPassed.length;
    final chips = [
      (icon: Icons.local_fire_department_rounded, val: '$streak',      lbl: 'Streak',    color: const Color(0xFFF97316), bg: const Color(0xFFFFF7ED)),
      (icon: Icons.style_rounded,                 val: '$totalCards',  lbl: 'Cards/Week', color: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7)),
      (icon: Icons.emoji_events_rounded,           val: '$unlocked',   lbl: 'Badges',     color: const Color(0xFF22C55E), bg: const Color(0xFFDCFCE7)),
      (icon: Icons.school_rounded,                 val: '$finalsPassed', lbl: 'Certs',   color: const Color(0xFF06B6D4), bg: const Color(0xFFE0F9FF)),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 82,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final c = chips[i];
            return Container(
              width: 118,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Icon(c.icon, size: 14, color: c.color)),
                      ),
                      const Spacer(),
                      Text(c.val, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.color)),
                    ],
                  ),
                  const Spacer(),
                  Text(c.lbl, style: const TextStyle(fontSize: 10, color: Color(0xFF9A9895), fontWeight: FontWeight.w500)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── CONTINUE LEARNING ─────────────────────────────────────────────────────────
  Widget _continueSection(BuildContext context, AppProvider prov) {
    final inProgress = prov.fields.where((f) {
      final done = prov.completedLevelsForField(f.id);
      return done.isNotEmpty && !prov.fieldFinalsPassed.contains(f.id);
    }).toList();
    if (inProgress.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
          child: Row(
            children: [
              const Text('Continue Learning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text('See all', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        ...inProgress.map((f) => _continueCard(context, prov, f)),
      ],
    );
  }

  Widget _continueCard(BuildContext context, AppProvider prov, FieldModel field) {
    final grad = fieldGradient(field.id);
    final doneLevels = prov.completedLevelsForField(field.id);
    final levelsDone = doneLevels.length;
    final pct = levelsDone / 3.0;
    final nextLevel = ['Easy', 'Normal', 'Hard'].firstWhere(
      (l) => !doneLevels.contains(l.toLowerCase()),
      orElse: () => 'Final Exam',
    );

    return GestureDetector(
      onTap: () { prov.selectField(field); Navigator.pushNamed(context, '/field-home'); },
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            // Left gradient panel
            Container(
              width: 66, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18), bottomLeft: Radius.circular(18),
                ),
              ),
              child: Center(child: Icon(fieldIconData(field.id), size: 28, color: Colors.white)),
            ),
            // Right content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(field.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBBF7D0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Next: $nextLevel',
                              style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: const Color(0xFFF0EDE8),
                        valueColor: AlwaysStoppedAnimation(grad.last),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text('$levelsDone / 3 levels complete',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF9A9895))),
                        const Spacer(),
                        Text('${(pct * 100).round()}%',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: grad.last)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH RESULTS ────────────────────────────────────────────────────────────
  Widget _searchResultsSection(BuildContext context, AppProvider prov) {
    final results = _filteredFields(prov);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 18),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 14),
              Text('No results for "$_searchQuery"',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3A3A4A))),
              const SizedBox(height: 6),
              const Text('Try a different subject name or topic',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9A9895))),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'} for "$_searchQuery"',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9A9895), fontWeight: FontWeight.w500),
          ),
        ),
        ...results.map((f) => _searchResultCard(context, prov, f)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _searchResultCard(BuildContext context, AppProvider prov, FieldModel field) {
    final grad = fieldGradient(field.id);
    final isComplete = prov.fieldFinalsPassed.contains(field.id);
    final doneLevels = prov.completedLevelsForField(field.id);
    final lvlData = [
      ('easy', 'E', AppTheme.easy),
      ('normal', 'N', AppTheme.normal),
      ('hard', 'H', AppTheme.hard),
    ];

    return GestureDetector(
      onTap: () { prov.selectField(field); Navigator.pushNamed(context, '/field-home'); },
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            // Gradient left panel
            Container(
              width: 68, height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
              ),
              child: Center(child: Icon(fieldIconData(field.id), size: 30, color: Colors.white)),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(field.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                        ),
                        if (isComplete)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFDCF5EB), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Complete ✓',
                                style: TextStyle(fontSize: 9, color: Color(0xFF2A9B65), fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(field.desc, style: const TextStyle(fontSize: 11, color: Color(0xFF9A9895))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Level badges
                        ...lvlData.map((t) {
                          final (id, lbl, col) = t;
                          final done = doneLevels.contains(id);
                          return Container(
                            width: 22, height: 22,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: done ? col.withValues(alpha: 0.12) : const Color(0xFFF0EDE8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: done ? col : const Color(0xFFDDDDDD),
                                  width: done ? 1.5 : 0.5),
                            ),
                            child: Center(child: Text(
                              done ? '✓' : lbl,
                              style: TextStyle(
                                  fontSize: 8, fontWeight: FontWeight.w800,
                                  color: done ? col : const Color(0xFFBBBBBB)),
                            )),
                          );
                        }),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: isComplete ? const Color(0xFF2A9B65) : AppTheme.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            isComplete ? 'Retake' : 'Open',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
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

  // ── CATEGORY PILLS ────────────────────────────────────────────────────────────
  static const Map<String, Color> _pillBg = {
    'all': Color(0xFFDCFCE7),
    'math': Color(0xFFDCFCE7),
    'science': Color(0xFFDCF5EB),
    'history': Color(0xFFFFF0E0),
    'geography': Color(0xFFDEEBFF),
    'literature': Color(0xFFFFE5F0),
    'cs': Color(0xFFE2F5DF),
  };
  static const Map<String, Color> _pillActive = {
    'all': Color(0xFF16A34A),
    'math': Color(0xFF16A34A),
    'science': Color(0xFF2A9B65),
    'history': Color(0xFFCC8822),
    'geography': Color(0xFF2E6DBB),
    'literature': Color(0xFFBB3366),
    'cs': Color(0xFF3A7A2A),
  };

  Widget _categoryPills(BuildContext context, AppProvider prov) {
    final cats = <(String, String, IconData)>[
      ('all', 'All', Icons.apps_rounded),
      ...prov.fields.map((f) => (f.id, f.name.split(' ').first, fieldIconData(f.id))),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (id, label, icon) = cats[i];
            final isActive = _selectedCategory == id;
            final activeColor = _pillActive[id] ?? const Color(0xFF16A34A);
            final bgColor = isActive ? activeColor : (_pillBg[id] ?? const Color(0xFFDCFCE7));
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: isActive ? Colors.white : activeColor),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF3A3A4A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // UPCOMING CLASSES 
  Widget _upcomingSection(BuildContext context, AppProvider prov) {
    final fields = _selectedCategory == 'all'
        ? prov.fields
        : prov.fields.where((f) => f.id == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
          child: Row(
            children: [
              const Text('Flash Mind', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              const Spacer(),
              Text('See all', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: fields.isEmpty
              ? Center(child: Text('No subjects', style: TextStyle(color: Colors.grey.shade400)))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: fields.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => _FlipFieldCard(field: fields[i]),
                ),
        ),
      ],
    );
  }

  Widget _inProgressSection(BuildContext context, AppProvider prov) {
    final totalCards = prov.totalCardsThisWeek;
    final streak = prov.streak;
    final unlocked = prov.achievements.where((a) => a.isUnlocked).length;
    final totalA = prov.achievements.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
          child: Row(
            children: [
              const Text('In Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/achievements'),
                child: Text('View all', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        _progressRow(
          icon: Icons.style_rounded, bg: const Color(0xFFDCFCE7), accent: const Color(0xFF16A34A),
          title: 'Cards Studied', subtitle: 'This week',
          value: totalCards, max: 50,
          onTap: () => Navigator.pushNamed(context, '/weekly-report'),
        ),
        _progressRow(
          icon: Icons.local_fire_department_rounded, bg: const Color(0xFFFFF7ED), accent: const Color(0xFFF97316),
          title: 'Day Streak', subtitle: 'Keep it going!',
          value: streak, max: math.max(30, streak),
          onTap: () {},
        ),
        _progressRow(
          icon: Icons.emoji_events_rounded, bg: const Color(0xFFDCFCE7), accent: const Color(0xFF22C55E),
          title: 'Achievements', subtitle: 'Earned badges',
          value: unlocked, max: totalA,
          onTap: () => Navigator.pushNamed(context, '/achievements'),
        ),
      ],
    );
  }

  Widget _progressRow({
    required IconData icon, required Color bg, required Color accent,
    required String title, required String subtitle,
    required int value, required int max, required VoidCallback onTap,
  }) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      const Spacer(),
                      Text('$value / $max', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9A9895))),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: const Color(0xFFF0EDE8),
                      valueColor: AlwaysStoppedAnimation(accent),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
            ),
          ],
        ),
      ),
    );
  }

  // â"€â"€ MOBILE DASHBOARD (bottom of mobile scroll) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
  Widget _mobileDashboard(BuildContext context, AppProvider prov) {
    final unlocked = prov.achievements.where((a) => a.isUnlocked).length;
    final totalA = prov.achievements.length;
    final progressPct = totalA > 0 ? unlocked / totalA : 0.0;
    final totalCards = prov.totalCardsThisWeek;
    final finalsPassed = prov.fieldFinalsPassed.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 90, height: 90,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            segments: [
                              (color: const Color(0xFF16A34A), value: progressPct),
                              (color: const Color(0xFFDCFCE7), value: 1.0 - progressPct),
                            ],
                            strokeWidth: 13,
                          ),
                          child: Center(
                            child: Text(
                              '${(progressPct * 100).round()}%',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Achievement\nProgress', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xFF9A9895), height: 1.3)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _miniStat(Icons.emoji_events_rounded, '$unlocked', 'Badges', const Color(0xFFFFF0E0), const Color(0xFFCC8822)),
                    const SizedBox(height: 8),
                    _miniStat(Icons.style_rounded, '$totalCards', 'Cards/Week', const Color(0xFFBBF7D0), const Color(0xFF16A34A)),
                    const SizedBox(height: 8),
                    _miniStat(Icons.school_rounded, '$finalsPassed', 'Certified', const Color(0xFFDCF5EB), const Color(0xFF2A9B65)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
                Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9A9895))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â"€â"€ RIGHT PANEL (wide) â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€
  Widget _rightPanel(BuildContext context, AppProvider prov) {
    return SizedBox(
      width: 240,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 12, bottom: 12),
        child: Column(
          children: [
            const SizedBox(height: 56),
            _profileCard(context, prov),
            const SizedBox(height: 12),
            _activityCard(context, prov),
            const SizedBox(height: 12),
            _donutCard(context, prov),
            const SizedBox(height: 12),
            _summaryRow(context, prov),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context, AppProvider prov) {
    final name = prov.auth.displayName;
    final totalCards = prov.totalCardsThisWeek;
    final unlocked = prov.achievements.where((a) => a.isUnlocked).length;
    final finalsPassed = prov.fieldFinalsPassed.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.18),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              _profileStat(Icons.style_rounded, '$totalCards', 'Cards'),
              _profileStat(Icons.emoji_events_rounded, '$unlocked', 'Badges'),
              _profileStat(Icons.school_rounded, '$finalsPassed', 'Certs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileStat(IconData icon, String value, String label) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 19, color: AppTheme.primary),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9A9895))),
      ],
    ),
  );

  Widget _activityCard(BuildContext context, AppProvider prov) {
    final streak = prov.streak;
    final quizPassed = prov.totalQuizzesPassed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFFF0E0), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.local_fire_department_rounded, size: 22, color: Color(0xFFF97316)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$streak day streak', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                    Text('$quizPassed quizzes passed', style: const TextStyle(fontSize: 10, color: Color(0xFF9A9895))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _donutCard(BuildContext context, AppProvider prov) {
    final unlocked = prov.achievements.where((a) => a.isUnlocked).length;
    final totalA = prov.achievements.length;
    final cardVal = prov.totalCardsThisWeek.toDouble();
    final achieveVal = unlocked.toDouble();
    final quizVal = prov.totalQuizzesPassed.toDouble();
    final total = cardVal + achieveVal + quizVal;
    final overallPct = math.min(1.0, total / math.max(1.0, (50 + totalA + 10).toDouble()));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress Overview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 110, height: 110,
              child: CustomPaint(
                painter: _DonutPainter(
                  segments: total > 0
                      ? [
                          (color: const Color(0xFF16A34A), value: cardVal),
                          (color: const Color(0xFF2A9B65), value: achieveVal),
                          (color: const Color(0xFFCC8822), value: math.max(0, quizVal)),
                        ]
                      : [(color: const Color(0xFFEEECE8), value: 1.0)],
                  strokeWidth: 15,
                ),
                child: Center(
                  child: Text(
                    '${(overallPct * 100).round()}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legend(const Color(0xFF16A34A), 'Cards'),
              _legend(const Color(0xFF2A9B65), 'Badges'),
              _legend(const Color(0xFFCC8822), 'Quizzes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9A9895))),
    ],
  );

  Widget _summaryRow(BuildContext context, AppProvider prov) {
    return Row(
      children: [
        Expanded(child: _summaryCard(Icons.style_rounded, '${prov.fields.length * 30}', 'Total Cards', const Color(0xFFBBF7D0), const Color(0xFF16A34A))),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard(Icons.quiz_rounded, '${prov.quizzesTakenThisWeek}', 'Quizzes', const Color(0xFFDCF5EB), const Color(0xFF2A9B65))),
      ],
    );
  }

  Widget _summaryCard(IconData icon, String value, String label, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9A9895))),
        ],
      ),
    );
  }

  // ── DAILY GOALS CARD ──────────────────────────────────────────────────────────
  Widget _dailyGoalsCard(BuildContext context, AppProvider prov) {
    final done       = prov.todayCardCount;
    final goal       = prov.dayGoal;
    final pct        = goal > 0 ? (done / goal).clamp(0.0, 1.0) : 0.0;
    final isComplete = prov.dayGoalReached;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF16A34A), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text("Today's Goal",
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$done / $goal cards',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isComplete
                ? '🎉 Goal complete! Excellent work today!'
                : '${goal - done} more card${goal - done == 1 ? '' : 's'} to reach your daily goal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── ALL FIELDS SHEET ──────────────────────────────────────────────────────────
  void _showAllFieldsSheet(BuildContext context, AppProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.90,
          minChildSize: 0.40,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      const Text('All Subjects',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                      const Spacer(),
                      const Text('Tap to study',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9A9895))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: sc,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: prov.fields.length,
                    itemBuilder: (_, i) {
                      final f = prov.fields[i];
                      final grad = fieldGradient(f.id);
                      final isComplete = prov.fieldFinalsPassed.contains(f.id);
                      final doneLevels = prov.completedLevelsForField(f.id);
                      final pct = doneLevels.length / 3.0;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          prov.selectField(f);
                          Navigator.pushNamed(context, '/field-home');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60, height: 70,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                ),
                                child: Center(child: Icon(fieldIconData(f.id), size: 26, color: Colors.white)),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(f.name,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                                          ),
                                          if (isComplete)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCF5EB),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('✓',
                                                  style: TextStyle(fontSize: 10, color: Color(0xFF2A9B65), fontWeight: FontWeight.w700)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          backgroundColor: const Color(0xFFF0EDE8),
                                          valueColor: AlwaysStoppedAnimation(grad.last),
                                          minHeight: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${doneLevels.length}/3 levels',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF9A9895))),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey.shade300),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────────────────────────
  Widget _quickActionsRow(BuildContext context, AppProvider prov) {
    void studyNow() {
      _showAllFieldsSheet(context, prov);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F0E17))),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuickActionBtn(
                icon: Icons.play_circle_rounded,
                label: 'Study Now',
                color: AppTheme.primary,
                onTap: studyNow,
              ),
              const SizedBox(width: 10),
              _QuickActionBtn(
                icon: Icons.track_changes_rounded,
                label: 'Day Goal',
                color: const Color(0xFFF97316),
                onTap: () => _showDayGoalSheet(context, prov),
              ),
              const SizedBox(width: 10),
              _QuickActionBtn(
                icon: Icons.bar_chart_rounded,
                label: 'View Stats',
                color: AppTheme.easy,
                onTap: () => Navigator.pushNamed(context, '/stats'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDayGoalSheet(BuildContext context, AppProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayGoalSheet(prov: prov),
    );
  }


}

// ── QUICK ACTION BUTTON ────────────────────────────────────────────────────────

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.08),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.20), width: 0.8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 19, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(label,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F0E17))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── NEW DECK SHEET ─────────────────────────────────────────────────────────────

class _NewDeckSheet extends StatefulWidget {
  final AppProvider prov;
  const _NewDeckSheet({required this.prov});

  @override
  State<_NewDeckSheet> createState() => _NewDeckSheetState();
}

class _NewDeckSheetState extends State<_NewDeckSheet> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _step = 0;
  bool _saving = false;

  late final TabController _cardTabCtrl;
  late final TabController _examTabCtrl;

  final Map<String, List<Map<String, String>>> _cards = {
    'easy': [], 'normal': [], 'hard': [],
  };
  final Map<String, List<Map<String, dynamic>>> _assessments = {
    'easy': [], 'normal': [], 'hard': [],
  };

  @override
  void initState() {
    super.initState();
    _cardTabCtrl = TabController(length: 3, vsync: this);
    _examTabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _cardTabCtrl.dispose();
    _examTabCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _saveDeck();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _saveDeck() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    final fieldId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    // Persist the new field to Firestore so all users see it immediately.
    await widget.prov.addField(FieldModel(
      id: fieldId,
      name: name,
      icon: 'subject',
      colorValue: 0xFF5B5FEF,
      desc: _descCtrl.text.trim().isEmpty ? '$name study deck' : _descCtrl.text.trim(),
      gradientHex: const ['3730A3', '5B5FEF'],
    ));

    for (final entry in _cards.entries) {
      for (final card in entry.value) {
        await FirestoreService().saveAdminCard(
          fieldId: fieldId,
          level: entry.key,
          question: card['q']!,
          answer: card['a']!,
        );
      }
    }

    for (final entry in _assessments.entries) {
      for (final q in entry.value) {
        await FirestoreService().saveAdminQuestion(
          fieldId: fieldId,
          level: entry.key,
          question: q['q'] as String,
          correctAnswer: q['a'] as String,
          options: List<String>.from(q['opts'] as List),
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deck "$name" created successfully!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                if (_step > 0)
                  GestureDetector(
                    onTap: _back,
                    child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: Color(0xFF1A1A2E)),
                  ),
                if (_step > 0) const SizedBox(width: 8),
                const Text('New Deck',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                const Spacer(),
                Row(
                  children: List.generate(3, (i) => Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(
                      color: _step >= i ? AppTheme.primary : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  )),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ['Subject Info', 'Study Cards', 'Assessment / Exam'][_step],
                style: const TextStyle(fontSize: 12, color: Color(0xFF9A9895)),
              ),
            ),
          ),
          // Content
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep0(), _buildStep1(), _buildStep2()],
            ),
          ),
          // Bottom button
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bot + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_step == 0 && _nameCtrl.text.trim().isEmpty) || _saving ? null : _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_step == 2 ? 'Create Deck' : 'Next',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3730A3), Color(0xFF5B5FEF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: const Color(0xFF5B5FEF).withValues(alpha: 0.35),
                    blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.library_books_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _nameCtrl,
                    builder: (_, __) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameCtrl.text.trim().isEmpty ? 'Your Deck Name' : _nameCtrl.text.trim(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const Text('New study deck',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _DeckTextField(ctrl: _nameCtrl, label: 'Subject Name',
              hint: 'e.g. Biology, Physics…', onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          _DeckTextField(ctrl: _descCtrl, label: 'Description (optional)',
              hint: 'Brief description of this deck', maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    const levels = ['easy', 'normal', 'hard'];
    const levelNames = ['Easy', 'Normal', 'Hard'];
    const levelColors = [Color(0xFF16A34A), Color(0xFFF59E0B), Color(0xFFEF4444)];

    return Column(
      children: [
        _LevelTabBar(controller: _cardTabCtrl),
        Expanded(
          child: TabBarView(
            controller: _cardTabCtrl,
            children: List.generate(3, (i) {
              final level = levels[i];
              final color = levelColors[i];
              final cards = _cards[level]!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  ...cards.asMap().entries.map((e) => _DeckCardTile(
                    index: e.key + 1,
                    q: e.value['q']!,
                    a: e.value['a']!,
                    color: color,
                    onDelete: () => setState(() => cards.removeAt(e.key)),
                  )),
                  OutlinedButton.icon(
                    onPressed: () => _addCard(level, color, levelNames[i]),
                    icon: Icon(Icons.add_rounded, size: 16, color: color),
                    label: Text('Add ${levelNames[i]} Card',
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (cards.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('No ${levelNames[i].toLowerCase()} cards yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9A9895))),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    const levels = ['easy', 'normal', 'hard'];
    const levelNames = ['Easy', 'Normal', 'Hard'];
    const levelColors = [Color(0xFF16A34A), Color(0xFFF59E0B), Color(0xFFEF4444)];

    return Column(
      children: [
        _LevelTabBar(controller: _examTabCtrl),
        Expanded(
          child: TabBarView(
            controller: _examTabCtrl,
            children: List.generate(3, (i) {
              final level = levels[i];
              final color = levelColors[i];
              final questions = _assessments[level]!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  ...questions.asMap().entries.map((e) => _DeckQuestionTile(
                    index: e.key + 1,
                    q: e.value['q'] as String,
                    a: e.value['a'] as String,
                    opts: List<String>.from(e.value['opts'] as List),
                    color: color,
                    onDelete: () => setState(() => questions.removeAt(e.key)),
                  )),
                  OutlinedButton.icon(
                    onPressed: () => _addQuestion(level, color, levelNames[i]),
                    icon: Icon(Icons.add_rounded, size: 16, color: color),
                    label: Text('Add ${levelNames[i]} Question',
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color.withValues(alpha: 0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (questions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('No ${levelNames[i].toLowerCase()} questions yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9A9895))),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _addCard(String level, Color color, String levelName) {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final valid = qCtrl.text.trim().isNotEmpty && aCtrl.text.trim().isNotEmpty;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add $levelName Study Card',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DeckTextField(ctrl: qCtrl, label: 'Question', hint: 'What is…?',
                  maxLines: 3, onChanged: (_) => setS(() {})),
              const SizedBox(height: 12),
              _DeckTextField(ctrl: aCtrl, label: 'Answer', hint: 'Correct answer…',
                  maxLines: 2, onChanged: (_) => setS(() {})),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: valid ? AppTheme.primary : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: valid ? () {
                setState(() => _cards[level]!.add({'q': qCtrl.text.trim(), 'a': aCtrl.text.trim()}));
                Navigator.pop(ctx);
              } : null,
              child: const Text('Add'),
            ),
          ],
        );
      }),
    );
  }

  void _addQuestion(String level, Color color, String levelName) {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final o1 = TextEditingController();
    final o2 = TextEditingController();
    final o3 = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final opts = [o1.text.trim(), o2.text.trim(), o3.text.trim()].where((o) => o.isNotEmpty).toList();
        final valid = qCtrl.text.trim().isNotEmpty && aCtrl.text.trim().isNotEmpty && opts.isNotEmpty;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add $levelName Question',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DeckTextField(ctrl: qCtrl, label: 'Question', hint: 'What is…?',
                    maxLines: 3, onChanged: (_) => setS(() {})),
                const SizedBox(height: 10),
                _DeckTextField(ctrl: aCtrl, label: 'Correct Answer', hint: 'The right answer',
                    onChanged: (_) => setS(() {})),
                const SizedBox(height: 10),
                _DeckTextField(ctrl: o1, label: 'Wrong Option 1', hint: 'Incorrect choice',
                    onChanged: (_) => setS(() {})),
                const SizedBox(height: 8),
                _DeckTextField(ctrl: o2, label: 'Wrong Option 2', hint: 'Incorrect choice',
                    onChanged: (_) => setS(() {})),
                const SizedBox(height: 8),
                _DeckTextField(ctrl: o3, label: 'Wrong Option 3 (optional)', hint: 'Incorrect choice',
                    onChanged: (_) => setS(() {})),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: valid ? AppTheme.primary : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: valid ? () {
                final allOpts = [aCtrl.text.trim(), ...opts];
                setState(() => _assessments[level]!.add({
                  'q': qCtrl.text.trim(),
                  'a': aCtrl.text.trim(),
                  'opts': allOpts,
                }));
                Navigator.pop(ctx);
              } : null,
              child: const Text('Add'),
            ),
          ],
        );
      }),
    );
  }
}

// ── Shared level tab bar ───────────────────────────────────────────────────────
class _LevelTabBar extends StatelessWidget {
  final TabController controller;
  const _LevelTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(9)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF9A9895),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          padding: EdgeInsets.zero,
          tabs: const [
            Tab(height: 34, text: 'Easy'),
            Tab(height: 34, text: 'Normal'),
            Tab(height: 34, text: 'Hard'),
          ],
        ),
      ),
    );
  }
}

// ── New deck tile widgets ──────────────────────────────────────────────────────
class _DeckCardTile extends StatelessWidget {
  final int index;
  final String q, a;
  final Color color;
  final VoidCallback onDelete;
  const _DeckCardTile({required this.index, required this.q, required this.a,
      required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(child: Text('$index',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(a, style: const TextStyle(fontSize: 11, color: Color(0xFF9A9895))),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, size: 17, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _DeckQuestionTile extends StatelessWidget {
  final int index;
  final String q, a;
  final List<String> opts;
  final Color color;
  final VoidCallback onDelete;
  const _DeckQuestionTile({required this.index, required this.q, required this.a,
      required this.opts, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(child: Text('$index',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('✓ $a', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                ),
                if (opts.length > 1) ...[
                  const SizedBox(height: 3),
                  Text(opts.skip(1).join(' · '),
                      style: const TextStyle(fontSize: 9, color: Color(0xFF9A9895)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, size: 17, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _DeckTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const _DeckTextField({required this.ctrl, required this.label, required this.hint,
      this.maxLines = 1, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9A9895)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ── DONUT PAINTER ─────────────────────────────────────────────────────────────
typedef _Seg = ({Color color, double value});

class _DonutPainter extends CustomPainter {
  final List<_Seg> segments;
  final double strokeWidth;

  const _DonutPainter({required this.segments, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = segments.fold(0.0, (s, e) => s + e.value);

    if (total <= 0) {
      canvas.drawCircle(
        center, radius,
        Paint()
          ..color = const Color(0xFFEEECE8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    double start = -math.pi / 2;
    const gap = 0.06;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2 * math.pi;
      if (sweep < gap * 2) continue;
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep - gap,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments || old.strokeWidth != strokeWidth;
}

// ── FLIP FIELD CARD ───────────────────────────────────────────────────────────
const Map<String, String> _kFieldTitles = {
  'math': 'Algebra, Calculus\n& Geometry',
  'science': 'Physics, Chemistry\n& Biology',
  'history': 'World Events\n& Civilizations',
  'geography': 'Countries, Capitals\n& Landscapes',
  'literature': 'Authors, Genres\n& Literary Terms',
  'cs': 'Algorithms &\nData Structures',
};

class _FlipFieldCard extends StatefulWidget {
  final dynamic field;
  const _FlipFieldCard({required this.field});

  @override
  State<_FlipFieldCard> createState() => _FlipFieldCardState();
}

class _FlipFieldCardState extends State<_FlipFieldCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _retakeDialog(BuildContext context, AppProvider prov) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retake Course?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'This will reset all progress for ${widget.field.name} — '
          'study sessions, assessments, and the final exam. '
          'Your achievements will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              prov.retakeField(widget.field.id as String);
              prov.selectField(widget.field);
              Navigator.pushNamed(context, '/field-home');
            },
            child: const Text('Retake',
                style: TextStyle(
                    color: Color(0xFF2A9B65), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final fieldId = widget.field.id as String;
    final grad = fieldGradient(fieldId);
    final isComplete = prov.fieldFinalsPassed.contains(fieldId);
    final doneLevels = prov.completedLevelsForField(fieldId);

    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) {
        final val = _anim.value;
        final showBack = val >= 0.5;

        final face = showBack
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: _buildBack(ctx, prov, grad, isComplete, doneLevels),
              )
            : _buildFront(ctx, grad, isComplete);

        return SizedBox(
          width: 200,
          height: 210,
          child: GestureDetector(
            onTap: _flip,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(val * math.pi),
              child: face,
            ),
          ),
        );
      },
    );
  }

  // ── FRONT FACE ───────────────────────────────────────────────────────────────
  Widget _buildFront(BuildContext context, List<Color> grad, bool isComplete) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: grad.last.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -18, right: -18,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: -12, left: -8,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle),
            ),
          ),
          // Field icon (top-right)
          Positioned(
            right: 14, top: 14,
            child: Icon(fieldIconData(widget.field.id as String), size: 36, color: Colors.white.withValues(alpha: 0.85)),
          ),
          // Complete badge
          if (isComplete)
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A9B65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 11),
                    SizedBox(width: 3),
                    Text('Complete',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(16, isComplete ? 34 : 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field name label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    (widget.field.name as String).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                // Subject subtitle
                Text(
                  _kFieldTitles[widget.field.id] ??
                      (widget.field.desc as String),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                // Bottom row: level dots + flip hint
                Row(
                  children: [
                    ...['E', 'N', 'H'].map((l) => Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: isComplete
                                ? const Color(0xFF2A9B65)
                                    .withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isComplete ? '✓' : l,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        )),
                    const Spacer(),
                    // Flip hint button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Flip',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(width: 3),
                          const Icon(Icons.flip_rounded, size: 13, color: Colors.white70),
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

  // ── BACK FACE ────────────────────────────────────────────────────────────────
  Widget _buildBack(
    BuildContext context,
    AppProvider prov,
    List<Color> grad,
    bool isComplete,
    List<String> doneLevels,
  ) {
    const levels = [
      ('easy', 'Easy'),
      ('normal', 'Normal'),
      ('hard', 'Hard'),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: grad,
            begin: Alignment.bottomRight,
            end: Alignment.topLeft),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: grad.last.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Container(
        // Dark overlay to visually distinguish the back
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: back button + emoji
            Row(
              children: [
                GestureDetector(
                  onTap: _flip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_rounded, size: 11, color: Colors.white),
                        SizedBox(width: 3),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Icon(fieldIconData(widget.field.id as String), size: 22, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 10),
            // Level rows: Easy / Normal / Hard
            ...levels.map((t) {
              final (id, label) = t;
              final done = doneLevels.contains(id);
              return _levelRow(label, done);
            }),
            // Final Exam row
            _levelRow('Final Exam', isComplete, isFinal: true),
            const Spacer(),
            // CTA button
            GestureDetector(
              onTap: isComplete
                  ? () => _retakeDialog(context, prov)
                  : () {
                      prov.selectField(widget.field);
                      Navigator.pushNamed(context, '/field-home');
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color:
                      isComplete ? const Color(0xFF2A9B65) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  isComplete ? 'Retake Course' : 'Start Learning',
                  style: TextStyle(
                    color: isComplete ? Colors.white : grad.first,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelRow(String label, bool done, {bool isFinal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: done
                  ? const Color(0xFF2A9B65).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                done ? Icons.check_rounded : (isFinal ? Icons.school_rounded : Icons.circle_outlined),
                size: 10,
                color: done ? const Color(0xFF6DDC9A) : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: done ? Colors.white : Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: done ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            done ? (isFinal ? 'Passed' : 'Done') : 'Pending',
            style: TextStyle(
              color: done
                  ? const Color(0xFF6DDC9A)
                  : Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1)  return '${diff.inMinutes}m ago';
  if (diff.inDays < 1)   return '${diff.inHours}h ago';
  if (diff.inDays < 7)   return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

// ── DAY GOAL SHEET ────────────────────────────────────────────────────────────

class _DayGoalSheet extends StatefulWidget {
  final AppProvider prov;
  const _DayGoalSheet({required this.prov});

  @override
  State<_DayGoalSheet> createState() => _DayGoalSheetState();
}

class _DayGoalSheetState extends State<_DayGoalSheet> {
  late double _goalValue;

  static const _orange  = Color(0xFFF97316);
  static const _ink     = Color(0xFF0F172A);
  static const _sub     = Color(0xFF64748B);
  static const _green   = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    final g = widget.prov.dayGoal.clamp(5, 50);
    _goalValue = (g % 5 == 0 ? g : ((g / 5).round() * 5)).toDouble().clamp(5, 50);
  }

  @override
  Widget build(BuildContext context) {
    final done        = widget.prov.todayCardCount;
    final goal        = _goalValue.round();
    final pct         = goal > 0 ? (done / goal).clamp(0.0, 1.0) : 0.0;
    final isComplete  = done >= goal;
    final bot         = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, bot + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_orange, _orange.withValues(alpha: 0.70)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: _orange.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Study Goal',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
                    Text('Set how many cards you\'ll study today',
                        style: TextStyle(fontSize: 11, color: _sub)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Congratulations banner (shown only when goal is already reached)
          if (isComplete) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: _green.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  const Text('Goal Achieved!',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    'Amazing work! You studied $done card${done == 1 ? '' : 's'} today.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep the momentum going — set a new goal!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Progress ring / bar
          if (!isComplete) ...[
            // Progress bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s Progress',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sub)),
                    Text('$done / $goal cards',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: done > 0 ? _orange : _sub,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: _orange.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(_orange),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  goal - done > 0
                      ? '${goal - done} more card${goal - done == 1 ? '' : 's'} to reach your goal'
                      : 'Goal reached!',
                  style: TextStyle(fontSize: 11, color: _sub),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Goal setter
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _orange.withValues(alpha: 0.20), width: 0.8),
            ),
            child: Column(
              children: [
                Text(
                  '$goal cards / day',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _orange,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _goalLabel(goal),
                  style: TextStyle(fontSize: 11, color: _orange.withValues(alpha: 0.65), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _orange,
                    inactiveTrackColor: _orange.withValues(alpha: 0.18),
                    thumbColor: _orange,
                    overlayColor: _orange.withValues(alpha: 0.12),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _goalValue,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    onChanged: (v) => setState(() => _goalValue = v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('5', style: TextStyle(fontSize: 10, color: _sub)),
                    Text('25', style: TextStyle(fontSize: 10, color: _sub)),
                    Text('50', style: TextStyle(fontSize: 10, color: _sub)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await widget.prov.setDayGoal(_goalValue.round());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Daily goal set to ${_goalValue.round()} cards. You\'ve got this! 💪'),
                      backgroundColor: _orange,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Set Goal',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _goalLabel(int goal) {
    if (goal <= 5)  return 'Light warm-up — great for busy days';
    if (goal <= 10) return 'Steady pace — builds a strong habit';
    if (goal <= 20) return 'Active learner — solid daily session';
    if (goal <= 35) return 'High achiever — serious study mode';
    return 'Champion mode — maximum retention!';
  }
}

// ── Dialog input field reused by Create Deck dialog ──────────────────────────
class _DeckDialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _DeckDialogField({
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
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
        const SizedBox(height: 5),
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




