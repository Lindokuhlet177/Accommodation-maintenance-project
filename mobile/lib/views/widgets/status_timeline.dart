import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/status_history.dart';

/// The "Status Updates" list: a circle per entry joined by a line.
class StatusTimeline extends StatelessWidget {
  final List<StatusHistory> entries;

  /// true = every circle ticked (request closed).
  /// false = the newest entry is still in progress (hollow circle).
  final bool isFinished;

  const StatusTimeline({
    super.key,
    required this.entries,
    this.isFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('No updates yet.',
          style: TextStyle(color: AppColors.navy));
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineRow(
            entry: entries[i],
            isLast: i == entries.length - 1,
            isDone: isFinished || i < entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final StatusHistory entry;
  final bool isLast;
  final bool isDone;

  const _TimelineRow({
    required this.entry,
    required this.isLast,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight lets the line stretch to the height of the text
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle + connecting line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                                Icon(
                  entry.isNote
                      ? Icons.chat_bubble        // staff note, not a status step
                      : isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                  color: AppColors.navy,
                  size: 20,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.navy),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Date + what happened
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormatter.withTime(entry.changedAt),
                      style: const TextStyle(
                          color: AppColors.navy, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(entry.note ?? entry.status.dbValue,
                      style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}