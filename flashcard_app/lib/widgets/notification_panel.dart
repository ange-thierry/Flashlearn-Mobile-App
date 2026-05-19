import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/icon_helper.dart';

class NotificationPanel extends StatelessWidget {
  final List<AppNotification> notifications;
  final VoidCallback onClearAll;
  final Function(String) onDismiss;
  final VoidCallback onClose;

  const NotificationPanel({
    super.key,
    required this.notifications,
    required this.onClearAll,
    required this.onDismiss,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0DDD8), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClearAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                  ),
                ],
              ),
            ),
            // Body
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No notifications yet',
                  style: TextStyle(color: Color(0xFF888780), fontSize: 13),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 0, color: Color(0xFFF8F5F0)),
                  itemBuilder: (_, i) => _NotifItem(
                    notification: notifications[i],
                    onDismiss: () => onDismiss(notifications[i].id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;

  const _NotifItem({required this.notification, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = Color(notification.colorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(notifTypeIcon(notification.type), size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.body,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5F5E5A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close_rounded, color: Color(0xFFCCCCCC), size: 15),
            ),
          ),
        ],
      ),
    );
  }
}
