import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/maintenance_request.dart';
import 'status_chip.dart';

/// One row in "Recent Requests" on Home.
class RecentRequestTile extends StatelessWidget {
  final MaintenanceRequest request;
  final VoidCallback onTap;

  const RecentRequestTile({
    super.key,
    required this.request,
    required this.onTap,
  });

  /// An icon per category, like the tap, bulb and toilet icons in the design.
  static IconData iconFor(String category) {
    switch (category) {
      case 'Plumbing':
        return Icons.water_drop;
      case 'Electrical':
        return Icons.lightbulb;
      case 'Furniture':
        return Icons.chair;
      case 'Appliances':
        return Icons.kitchen;
      case 'Doors & Windows':
        return Icons.door_front_door;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // keeps the tap ripple inside the corners
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(iconFor(request.category), color: AppColors.navy, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.short(request.dateSubmitted),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip(status: request.status),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}