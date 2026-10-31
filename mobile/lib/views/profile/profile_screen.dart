import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../viewmodels/profile_viewmodel.dart';

import '../widgets/logout_helper.dart';

/// Frame 9: Profile tab.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().load();
    });
  }

 Future<void> _onLogout() async {
    await confirmAndLogout(context);
  }
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.navy,
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text('Profile',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontSize: 20)),
            const SizedBox(height: 20),

            if (vm.isLoading && vm.student == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.navy)),
              )
            else if (vm.errorMessage != null && vm.student == null)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Text(vm.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.navy)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                        onPressed: vm.load, child: const Text('Try again')),
                  ],
                ),
              )
            else ...[
              // ---------- Avatar, name, student number ----------
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.navy,
                  child: Text(vm.initials,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              Text(vm.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(vm.studentNumberLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),

              // ---------- Accommodation + room ----------
              _Panel(children: [
                _PanelRow(icon: Icons.apartment, label: vm.accommodationName),
                _PanelRow(icon: Icons.meeting_room, label: vm.roomLabel),
              ]),
              const SizedBox(height: 16),

              // ---------- Menu ----------
              _Panel(children: [
                _PanelRow(
                  icon: Icons.person,
                  label: 'Edit Profile',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                _PanelRow(
                  icon: Icons.help,
                  label: 'Help & Support',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
                _PanelRow(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                ),
                _PanelRow(
                  icon: Icons.logout,
                  label: 'Log Out',
                  onTap: _onLogout,
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Light-grey rounded panel holding several rows.
class _Panel extends StatelessWidget {
  final List<Widget> children;

  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFDADDE2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

/// One row inside a panel. With onTap it shows a › arrow.
class _PanelRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PanelRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBDBDBD)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.navy, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: AppColors.navy),
              ],
            ),
          ),
        ),
      ),
    );
  }
}