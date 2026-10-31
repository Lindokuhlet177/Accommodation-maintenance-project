import 'package:flutter/material.dart';
import '../../models/request_status.dart';

/// The Low / Medium / High / Urgent label next to the status chip.
class PriorityChip extends StatelessWidget {
  final RequestPriority priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    // Calm colours for low priority, stronger ones as it gets more urgent
    final (Color background, Color text) = switch (priority) {
      RequestPriority.low => (const Color(0xFFDDE6F5), const Color(0xFF0B1D51)),
      RequestPriority.medium => (const Color(0xFFFFF1C2), const Color(0xFF7A5600)),
      RequestPriority.high => (const Color(0xFFFFD9B3), const Color(0xFF9A4100)),
      RequestPriority.urgent => (const Color(0xFFF8C6C6), const Color(0xFFC62828)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.dbValue,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}