import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/requests_viewmodel.dart';
import '../../viewmodels/notifications_viewmodel.dart';

/// Shared Log Out: used by the slide-out menu and the Profile tab.
/// Asks for confirmation, signs out, clears old data, goes to Login.
Future<void> confirmAndLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log Out',
              style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  // Grab everything needed before the await (context may change after)
  final profileVm = context.read<ProfileViewModel>();
  final homeVm = context.read<HomeViewModel>();
  final requestsVm = context.read<RequestsViewModel>();
  final notificationsVm = context.read<NotificationsViewModel>();
  final navigator = Navigator.of(context);

  await profileVm.logout();
  homeVm.clear();
  requestsVm.clear();
  notificationsVm.clear();

  // Clear every screen from history, so Back can't return to the app
  navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
}