import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../models/status_history.dart';
import '../widgets/status_badge.dart';
import '../widgets/status_timeline.dart';

/// Frame 16: shown after the student confirms the problem is fixed.
class CompletedScreen extends StatelessWidget {
  final List<StatusHistory> timeline;

  const CompletedScreen({super.key, required this.timeline});

  /// Back to Home, closing Details and this screen on the way.
  void _goHome(BuildContext context) {
    Navigator.popUntil(
      context,
      (route) => route.settings.name == AppRoutes.home || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Center(
                        child: StatusBadge(
                            icon: Icons.sentiment_very_satisfied),
                      ),
                      const SizedBox(height: 24),
                      Text('Status Updates',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      // Every circle ticked: the request is finished
                      StatusTimeline(entries: timeline, isFinished: true),
                    ],
                  ),
                ),
              ),

              // "Completed" button, as in the design: returns to Home
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: OutlinedButton(
                  onPressed: () => _goHome(context),
                  child: const Text('Completed'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}