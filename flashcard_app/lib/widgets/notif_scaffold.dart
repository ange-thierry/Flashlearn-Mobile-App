import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_provider.dart';
import '../theme/app_theme.dart';
import 'notification_bell.dart';
import 'notification_panel.dart';
import 'achievement_banner.dart';

/// Wraps every screen — adds the notification bell, achievement banner, and slide-down
/// notification panel.
class NotifScaffold extends StatefulWidget {
  final Widget body;
  final bool showBell;

  const NotifScaffold({super.key, required this.body, this.showBell = true});

  @override
  State<NotifScaffold> createState() => _NotifScaffoldState();
}

class _NotifScaffoldState extends State<NotifScaffold> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final notif = prov.notifService;
    // Use viewPadding so the bell stays anchored to the raw screen edge,
    // even when SafeArea below has already consumed the top inset.
    final top = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // SafeArea handles the top (status-bar) inset only.
          // Bottom inset is managed per-screen via viewPadding so that custom
          // bottom-nav bars and scroll views can each add the exact padding they
          // need without double-counting (which would cause fractional overflow).
          SafeArea(bottom: false, child: widget.body),

          // Achievement banner (auto-shows on unlock)
          const AchievementBanner(),

          // Bell (only when showBell — admin panel is accessed via profile sheet)
          if (widget.showBell)
            Positioned(
              top: top + 8,
              right: 12,
              child: StreamBuilder<List<AppNotification>>(
                stream: notif.notificationsStream,
                builder: (_, __) => NotificationBell(
                  unreadCount: notif.unreadCount,
                  onTap: () {
                    notif.markAllRead();
                    setState(() => _panelOpen = !_panelOpen);
                  },
                ),
              ),
            ),

          // Notification panel (persistent list)
          if (_panelOpen)
            Positioned(
              top: top + 54,
              right: 10,
              child: SizedBox(
                width: 304,
                child: StreamBuilder<List<AppNotification>>(
                  stream: notif.notificationsStream,
                  builder: (_, __) => NotificationPanel(
                    notifications: notif.notifications,
                    onClearAll: () {
                      notif.clearAll();
                      setState(() => _panelOpen = false);
                    },
                    onDismiss: notif.dismiss,
                    onClose: () => setState(() => _panelOpen = false),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
