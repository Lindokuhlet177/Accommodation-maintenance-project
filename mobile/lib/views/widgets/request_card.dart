import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/maintenance_request.dart';
import 'status_chip.dart';

/// One card in the My Requests list.
class RequestCard extends StatelessWidget {
  final MaintenanceRequest request;
  final VoidCallback onTap;

  const RequestCard({super.key, required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE3E3E3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.title,
                        style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('#${request.reference}',
                        style: const TextStyle(
                            color: AppColors.greyText, fontSize: 11)),
                    const SizedBox(height: 6),
                    Text(DateFormatter.short(request.dateSubmitted),
                        style: const TextStyle(
                            color: AppColors.navy, fontSize: 11)),
                  ],
                ),
              ),
              StatusChip(status: request.status),
            ],
          ),
        ),
      ),
    );
  }
}