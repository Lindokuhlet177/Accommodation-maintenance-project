import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../widgets/app_logo.dart';
import '../widgets/recent_request_tile.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import 'contract_match_card.dart';

/// Frame 7: Home tab.
class HomeScreen extends StatefulWidget {
  final VoidCallback onSeeAll;       // switches to the My Requests tab
  

  const HomeScreen({
    super.key,
    required this.onSeeAll,
   
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load once the screen is on screen (context is ready)
        WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().load();
      context.read<NotificationsViewModel>().load(); // for the bell badge
    });
    
  }

  void _onReportPressed(HomeViewModel vm) {
    if (!vm.canReportProblem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Your room has not been assigned yet. Please contact your landlord.'),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.report);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final notifications = context.watch<NotificationsViewModel>();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.navy,
        onRefresh: () => Future.wait([vm.refresh(), notifications.load()]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // ---------- Top bar: menu, logo, bell ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.navy, size: 28),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                const AppLogo(height: 44),
                             IconButton(
                  icon: Badge(
                    isLabelVisible: notifications.unreadCount > 0,
                    label: Text('${notifications.unreadCount}'),
                    backgroundColor: AppColors.danger,
                    child: const Icon(Icons.notifications_none,
                        color: AppColors.navy, size: 28),
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ---------- Loading / error / content ----------
            if (vm.isLoading && vm.student == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.navy),
                ),
              )
            else if (vm.errorMessage != null && vm.student == null)
              _ErrorMessage(message: vm.errorMessage!, onRetry: vm.load)
            else ...[
              // Greeting
              Text('Hi, ${vm.fullName}!',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),

              // Accommodation and room
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.apartment, color: AppColors.navy),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vm.accommodationName,
                          style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text(vm.roomLabel,
                          style: const TextStyle(
                              color: AppColors.navy, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Report a problem
                           // No room yet: "Try again" card instead of Report a problem
              if (vm.student != null && !vm.student!.hasRoom)
                ContractMatchCard(
                  // A new key after each attempt keeps the fields in sync
                  key: ValueKey('match-${vm.student!.matchAttempts}'),
                  student: vm.student!,
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _onReportPressed(vm),
                  icon: const Icon(Icons.add, size: 28),
                  label: const Text('Report a problem'),
                ),

              // Active Requests card
              _ActiveRequestsCard(count: vm.activeCount, onSeeAll: widget.onSeeAll),
              const SizedBox(height: 24),

              // Recent Requests
              Text('Recent Requests',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (vm.recentRequests.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("You haven't reported any problems yet.",
                      style: TextStyle(color: AppColors.navy)),
                )
              else
                ...vm.recentRequests.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RecentRequestTile(
                      request: r,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.requestDetails,
                        arguments: r.id, // which request to open
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// White card with the number of active requests.
class _ActiveRequestsCard extends StatelessWidget {
  final int count;
  final VoidCallback onSeeAll;

  const _ActiveRequestsCard({required this.count, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.assignment, color: AppColors.navy, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Requests',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('$count',
                      style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            TextButton(
              onPressed: onSeeAll,
              child: Text('See All',
                  style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown if loading fails, with a retry button.
class _ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorMessage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.navy),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.navy)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}