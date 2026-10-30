import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/report_request_viewmodel.dart';
import 'report_details_step.dart';
import 'report_photo_step.dart';
import 'request_submitted_view.dart';

/// Frames 12–14: Report a Problem (stepper + current step, then Submitted).
class ReportRequestScreen extends StatelessWidget {
  const ReportRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportRequestViewModel>();

        // After a successful submit, show the Submitted screen
    if (vm.submittedRequest != null) {
      return RequestSubmittedView(
        request: vm.submittedRequest!,
        photoWarning: vm.photoWarning,
      );
    }

    final onPhotoStep = vm.currentStep == 1;

    // Back on the Photo step goes to Details instead of leaving the form
    return PopScope(
      canPop: !onPhotoStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.backToDetails();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.navy),
                      onPressed: () => onPhotoStep
                          ? vm.backToDetails()
                          : Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: _ReportStepper(
                        currentStep: vm.currentStep,
                        onTapDetails: vm.backToDetails,
                      ),
                    ),
                    const SizedBox(width: 48), // balances the back arrow
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: onPhotoStep
                      ? const ReportPhotoStep()
                      : const ReportDetailsStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "1 Details —— 2 Photo" indicator.
class _ReportStepper extends StatelessWidget {
  final int currentStep;
  final VoidCallback onTapDetails;

  const _ReportStepper({required this.currentStep, required this.onTapDetails});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepCircle(
          number: 1,
          label: 'Details',
          isActive: currentStep == 0,
          onTap: onTapDetails,
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(top: 20, left: 8, right: 8),
            color: AppColors.navy,
          ),
        ),
        _StepCircle(number: 2, label: 'Photo', isActive: currentStep == 1),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _StepCircle({
    required this.number,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isActive ? AppColors.navy : AppColors.inactive,
            child: Text('$number',
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}