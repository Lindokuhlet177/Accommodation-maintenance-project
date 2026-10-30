import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../widgets/logout_helper.dart';

/// Slide-out menu opened from the menu icon on Home.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Same student data as the Profile tab (already loaded)
    final vm = context.watch<ProfileViewModel>();

    return Drawer(
      width: 280,
      backgroundColor: const Color(0xFFDDDDDD),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // ---------- Faded logo in the background ----------
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 260,
                  fit: BoxFit.contain,
                  // Until the logo is added, a large icon stands in
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.home_repair_service,
                      size: 200,
                      color: AppColors.navy),
                ),
              ),
            ),

            // ---------- Content ----------
            Column(
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.navy,
                  child: Text(vm.initials,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(vm.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _DrawerInfoRow(
                          icon: Icons.apartment, label: vm.accommodationName),
                      const SizedBox(height: 8),
                      _DrawerInfoRow(
                          icon: Icons.meeting_room, label: vm.roomLabel),
                    ],
                  ),
                ),

                const Spacer(), // pushes Log Out to the bottom

                // ---------- Log Out ----------
                InkWell(
                  onTap: () => confirmAndLogout(context),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, color: AppColors.navy, size: 26),
                        SizedBox(width: 14),
                        Text('Log Out',
                            style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded row with an icon and text (accommodation, room).
class _DrawerInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DrawerInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBDBDBD)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}