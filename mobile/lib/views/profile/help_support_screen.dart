import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../widgets/status_badge.dart';

/// Profile > Help & Support.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  /// Questions and answers (shown as expandable cards).
  static const List<(String, String)> _faq = [
    (
      'How do I report a problem?',
      'On Home, tap "Report a problem". Add a title, choose the category, describe the '
          'problem and pick a priority. On the next step you can add up to 3 photos, then tap Submit. '
          'You get a reference number like MT 000123.'
    ),
    (
      'What do the statuses mean?',
      'Open: your request has been received.\n'
          'In Progress: maintenance is working on it.\n'
          'Closed: you confirmed the problem is fixed.\n\n'
          'When the repair is done you will be asked to confirm it. If it is not fixed, '
          'tap "No, it\'s still a problem" and the request opens again.'
    ),
    (
      'Which priority should I choose?',
      'Urgent: a danger or no basic service (burst pipe, no electricity, broken lock on '
          'the main door).\n'
          'High: something important is broken (no hot water, toilet not working).\n'
          'Medium: it affects daily life but can wait a few days (broken desk lamp).\n'
          'Low: small or cosmetic issues (loose cupboard handle).'
    ),
    (
      'Can I add photos after submitting?',
      'Photos are added when you report the problem (up to 3). If you need to share more, '
          'mention it in the confirmation comment or speak to your caretaker.'
    ),
    (
      'Why can\'t I report a problem?',
      'You can only report problems once your account is linked to your room. This happens '
          'automatically when your student number and surname match your accommodation contract. '
          'If Home says "We couldn\'t find your contract", check your details and tap "Try again", '
          'or contact your landlord.'
    ),
    (
      'How will I know when something changes?',
      'The bell on Home shows a red number when maintenance updates your request or adds a note. '
          'Tap it to see what changed.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final property = context.watch<HomeViewModel>().accommodationName;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Center(child: StatusBadge(icon: Icons.support_agent)),
            const SizedBox(height: 8),
            Text('How can we help?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
            const SizedBox(height: 20),

            // ---------- Emergency ----------
            Card(
              color: const Color(0xFFFFEBEE),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('In an emergency',
                            style: TextStyle(
                                color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'For fire, flooding, gas leaks or electrical danger, get to safety and call for '
                      'help first. Do not wait for a reply in the app.',
                      style: TextStyle(color: AppColors.navy, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _EmergencyRow(label: 'Fire & ambulance', number: '10177'),
                    _EmergencyRow(label: 'Police', number: '10111'),
                    _EmergencyRow(label: 'Emergency from a cellphone', number: '112'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------- FAQ ----------
            Text('Frequently asked questions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final (question, answer) in _faq)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Theme(
                    // Remove the lines ExpansionTile draws when open
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: AppColors.navy,
                      collapsedIconColor: AppColors.navy,
                      title: Text(question,
                          style: const TextStyle(
                              color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(answer,
                            style: const TextStyle(color: AppColors.greyText, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // ---------- Contact ----------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.apartment, color: AppColors.navy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Still need help?',
                              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Contact the landlord or caretaker of $property for questions about '
                            'your room, your contract or your account.',
                            style: const TextStyle(color: AppColors.greyText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('StudentStayFix · Report • Track • Fix',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.greyText, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// One emergency number. SelectableText lets the student copy it.
class _EmergencyRow extends StatelessWidget {
  final String label;
  final String number;

  const _EmergencyRow({required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.phone, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.navy, fontSize: 13))),
          SelectableText(number,
              style: const TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}