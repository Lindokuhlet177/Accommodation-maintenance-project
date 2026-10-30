import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/maintenance_request.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/requests_viewmodel.dart';
import '../widgets/status_badge.dart';

/// Frame 14: Request Submitted.
class RequestSubmittedView extends StatelessWidget {
  final MaintenanceRequest request;
  final String? photoWarning;

  const RequestSubmittedView({
    super.key,
    required this.request,
    this.photoWarning,
  });

  /// Home and My Requests should show the new request straight away.
  static void _refreshLists(BuildContext context) {
    context.read<HomeViewModel>().refresh();
    context.read<RequestsViewModel>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    // Phone/browser Back behaves like "Back to Home" and refreshes Home
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _refreshLists(context);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        const StatusBadge(icon: Icons.check),
                        const SizedBox(height: 16),
                        Text('Request Submitted!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontSize: 22)),
                        const SizedBox(height: 8),
                        const Text(
                          'Your maintenance request has been successfully submitted.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.navy),
                        ),

                        // Shown only if the photos failed to upload
                        if (photoWarning != null) ...[
                          const SizedBox(height: 12),
                          Text(photoWarning!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 24),
                        _ReferenceCard(request: request),
                      ],
                    ),
                  ),
                ),

                // Buttons pinned to the bottom
                SizedBox(
                  width: 260,
                  child: ElevatedButton(
                    onPressed: () {
                      _refreshLists(context);
                      // Replace this screen, so Back from Details goes Home
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.requestDetails,
                        arguments: request.id,
                      );
                    },
                    child: const Text('View Request'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 260,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context), // PopScope refreshes
                    child: const Text('Back to Home'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The card with the reference, category, priority and date.
class _ReferenceCard extends StatelessWidget {
  final MaintenanceRequest request;

  const _ReferenceCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.navy, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Light-blue header with the reference number
          Container(
            width: double.infinity,
            color: AppColors.normalPriority,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                const Text('Request Reference',
                    style: TextStyle(color: AppColors.navy, fontSize: 12)),
                const SizedBox(height: 4),
                Text('# ${request.reference}',
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1.5, color: AppColors.navy),
          const SizedBox(height: 6),
          _InfoRow(label: 'Category', value: request.category),
          _InfoRow(label: 'Priority', value: request.priority.dbValue),
          _InfoRow(label: 'Date', value: DateFormatter.short(request.dateSubmitted)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.navy, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}