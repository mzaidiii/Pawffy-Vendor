import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawffy/features/notification/providers/notification_controller.dart';
import 'data/models/notification_model.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'health':
        return Icons.medical_services_outlined;
      case 'booking':
        return Icons.calendar_today_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'alert':
        return Icons.warning_amber_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'health':
        return const Color(0xFF4CAF50);
      case 'booking':
        return const Color(0xFF2196F3);
      case 'payment':
        return const Color(0xFF9C27B0);
      case 'alert':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFFE85D04);
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          notifAsync.maybeWhen(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => ref
                    .read(notificationControllerProvider.notifier)
                    .markAllRead(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    'Mark all read',
                    style: GoogleFonts.barlow(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE85D04),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not load notifications',
                style: GoogleFonts.barlow(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    ref.read(notificationControllerProvider.notifier).refresh(),
                child: Text(
                  'Try again',
                  style: GoogleFonts.barlow(
                    color: const Color(0xFFE85D04),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: const Color(0xFFE85D04).withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You\'re all caught up!',
                    style: GoogleFonts.barlow(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No new notifications right now.',
                    style: GoogleFonts.barlow(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFE85D04),
            onRefresh: () =>
                ref.read(notificationControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(
                  notification: notif,
                  iconData: _iconForType(notif.type),
                  iconColor: _colorForType(notif.type),
                  timeAgo: _timeAgo(notif.createdAt),
                  onTap: () {
                    if (!notif.isRead) {
                      ref
                          .read(notificationControllerProvider.notifier)
                          .markAsRead(notif.id);
                    }
                  },
                  onDelete: () => ref
                      .read(notificationControllerProvider.notifier)
                      .deleteNotification(notif.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final IconData iconData;
  final Color iconColor;
  final String timeAgo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.iconData,
    required this.iconColor,
    required this.timeAgo,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? const Color(0xFFE85D04).withOpacity(0.06)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFFE85D04).withOpacity(0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.barlow(
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: GoogleFonts.barlow(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.barlow(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread dot
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE85D04),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
