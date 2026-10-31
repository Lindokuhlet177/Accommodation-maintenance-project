import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/request_status.dart';

/// The coloured Open / In Progress / Closed label.
class StatusChip extends StatelessWidget {
  final RequestStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Colours are a View decision, so they live here, not in the model
    final (Color background, Color text) = switch (status.chipLabel) {
      'Open' => (AppColors.openBg, AppColors.openText),
      'In Progress' => (AppColors.inProgressBg, AppColors.inProgressText),
      _ => (AppColors.closedBg, AppColors.closedText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.chipLabel,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}