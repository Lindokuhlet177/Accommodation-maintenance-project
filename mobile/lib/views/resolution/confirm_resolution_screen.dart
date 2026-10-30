import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/confirm_resolution_viewmodel.dart';
import '../widgets/status_badge.dart';

/// Frame 15: Confirm Resolution.
/// Closes with true (fixed), false (still a problem) or null (Back pressed).
class ConfirmResolutionScreen extends StatelessWidget {
  final int requestId;

  const ConfirmResolutionScreen({super.key, required this.requestId});

  Future<void> _answer(
      BuildContext context, ConfirmResolutionViewModel vm, bool isFixed) async {
    FocusScope.of(context).unfocus(); // hide the keyboard

    final success = await vm.submit(requestId: requestId, isFixed: isFixed);

    if (success && context.mounted) {
      Navigator.pop(context, isFixed); // tell Request Details the answer
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConfirmResolutionViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Resolution'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: StatusBadge(icon: Icons.question_mark)),
              const SizedBox(height: 16),

              Text('Is the problem fixed?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              const Text(
                'Please confirm if the maintenance issue has been resolved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.navy),
              ),
              const SizedBox(height: 28),

              // ---------- Optional comment ----------
              Text('Additional comment (optional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                onChanged: vm.setComment,
                maxLines: 4,
                maxLength: ConfirmResolutionViewModel.maxCommentLength,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.navy),
                decoration: InputDecoration(
                  hintText: 'E.g. still leaking, needs further attention...',
                  hintStyle: const TextStyle(color: AppColors.greyText),
                  filled: false,
                  contentPadding: const EdgeInsets.all(14),
                  counterStyle: const TextStyle(color: AppColors.navy),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.navy, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.navy, width: 2.5),
                  ),
                ),
              ),

              // ---------- Error from the ViewModel ----------
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(vm.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.danger, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 28),

              // ---------- Yes / No ----------
              _AnswerButton(
                label: "Yes, it's fixed",
                color: AppColors.success,
                isLoading: vm.isSendingYes,
                onPressed: () => _answer(context, vm, true),
              ),
              const SizedBox(height: 12),
              _AnswerButton(
                label: "No, it's still a problem",
                color: AppColors.danger,
                isLoading: vm.isSendingNo,
                onPressed: () => _answer(context, vm, false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width coloured button that shows a spinner while sending.
class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // Only the colour changes; size and shape come from the theme
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.white),
            )
          : Text(label),
    );
  }
}