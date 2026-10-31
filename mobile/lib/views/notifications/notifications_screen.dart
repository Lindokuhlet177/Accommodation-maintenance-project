import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/app_notification.dart';
import '../../models/request_status.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../widgets/status_badge.dart';

/// Notifications: staff updates on the student's requests.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndMarkRead());
  }

  /// Load the list, then clear the bell badge (New stays highlighted).
  Future<void> _loadAndMarkRead() async {
    final vm = context.read<NotificationsViewModel>();
    await vm.load();
    await vm.markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsViewModel>();
    final hasItems = vm.newItems.isNotEmpty || vm.earlierItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        color: AppColors.navy,
        onRefresh: _loadAndMarkRead,
        child: _buildBody(vm, hasItems),
      ),
    );
  }

  Widget _buildBody(NotificationsViewModel vm, bool hasItems) {
    // First load
    if (vm.isLoading && !hasItems) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navy));
    }

    // Error or nothing yet: message that can still be pulled to refresh
    if (vm.errorMessage != null || vm.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          const Center(child: StatusBadge(icon: Icons.notifications_none)),
          const SizedBox(height: 16),
          Text(
            vm.errorMessage ?? "You're all caught up",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (vm.errorMessage == null) ...[
            const SizedBox(height: 6),
            const Text(
              "We'll let you know when the caretaker updates your requests.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.navy),
            ),
          ],
        ],
      );
    }

    // The list, in "New" and "Earlier" sections
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (vm.newItems.isNotEmpty) ...[
          _SectionTitle('New'),
          for (final n in vm.newItems) _NotificationCard(notification: n),
        ],
        if (vm.earlierItems.isNotEmpty) ...[
          _SectionTitle('Earlier'),
          for (final n in vm.earlierItems) _NotificationCard(notification: n),
        ],
      ],
    );
  }
}

/// "New" / "Earlier" heading.
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// One notification card. Unread: navy border and a navy dot.
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

    IconData get _icon => notification.isNote
      ? Icons.chat_bubble_outline
      : switch (notification.status) {
          RequestStatus.assigned => Icons.engineering,
          RequestStatus.inProgress => Icons.build,
          RequestStatus.completed => Icons.task_alt,
          _ => Icons.notifications,
        };

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 1.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.requestDetails,
            arguments: notification.requestId,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: unread ? AppColors.navy : const Color(0xFFE3E3E3),
                width: unread ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.navy,
                  child: Icon(_icon, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(notification.requestTitle,
                                style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.navy,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(notification.message,
                          style: const TextStyle(
                              color: AppColors.navy, fontSize: 13)),
                                                    if (notification.detail != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"${notification.detail}"',
                          style: const TextStyle(
                              color: AppColors.greyText,
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(DateFormatter.timeAgo(notification.createdAt),
                          style: const TextStyle(
                              color: AppColors.greyText, fontSize: 11)),
                    ],
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