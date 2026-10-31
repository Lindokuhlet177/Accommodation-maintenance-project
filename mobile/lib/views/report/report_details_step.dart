import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/maintenance_request.dart';
import '../../models/request_status.dart';
import '../../viewmodels/report_request_viewmodel.dart';

/// Frame 12: Title, Issue Category, Description, Priority, Next.
class ReportDetailsStep extends StatefulWidget {
  const ReportDetailsStep({super.key});

  @override
  State<ReportDetailsStep> createState() => _ReportDetailsStepState();
}

class _ReportDetailsStepState extends State<ReportDetailsStep> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // Start with what's already in the ViewModel, so text survives
    // going to the Photo step and back
    final vm = context.read<ReportRequestViewModel>();
    _titleController = TextEditingController(text: vm.title);
    _descriptionController = TextEditingController(text: vm.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Navy-outlined box style used by every field on this step.
  InputDecoration _outlined({String? hint, bool showCounter = true}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.greyText),
      filled: false,
      contentPadding: const EdgeInsets.all(14),
      counterText: showCounter ? null : '', // '' hides the counter
      counterStyle: const TextStyle(color: AppColors.navy),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.navy, width: 2.5),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportRequestViewModel>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- Title ----------
          _label('Title'),
          TextField(
            controller: _titleController,
            onChanged: vm.setTitle,
            maxLength: ReportRequestViewModel.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.navy),
            decoration: _outlined(hint: 'Enter title here', showCounter: false),
          ),
          const SizedBox(height: 16),

          // ---------- Issue Category ----------
          _label('Issue Category'),
          DropdownButtonFormField<String>(
            initialValue: vm.category,
            hint: const Text('Select a category',
                style: TextStyle(color: AppColors.greyText)),
            items: MaintenanceRequest.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: vm.setCategory,
            decoration: _outlined(),
            dropdownColor: AppColors.white,
            iconEnabledColor: AppColors.navy,
            style: const TextStyle(color: AppColors.navy, fontSize: 15),
          ),
          const SizedBox(height: 24),

          // ---------- Description (with 0/500 counter) ----------
          _label('Description'),
          TextField(
            controller: _descriptionController,
            onChanged: vm.setDescription,
            maxLines: 6,
            maxLength: ReportRequestViewModel.maxDescriptionLength,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: AppColors.navy),
            decoration: _outlined(hint: 'Describe the problem in detail'),
          ),
          const SizedBox(height: 12),

          // ---------- Priority: 2 rows of radio buttons ----------
          _label('Priority'),
          Row(
            children: [
              Expanded(child: _priorityOption(vm, RequestPriority.low)),
              Expanded(child: _priorityOption(vm, RequestPriority.medium)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _priorityOption(vm, RequestPriority.high)),
              Expanded(child: _priorityOption(vm, RequestPriority.urgent)),
            ],
          ),

          // ---------- Error from the ViewModel ----------
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 32),

          // ---------- Next ----------
          Center(
            child: SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  vm.goToPhotoStep(); // validates, then moves to step 2
                },
                child: const Text('Next'),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _priorityOption(ReportRequestViewModel vm, RequestPriority value) {
    return _PriorityRadio(
      label: value.dbValue, // "Low", "Medium", "High", "Urgent"
      isSelected: vm.priority == value,
      onTap: () => vm.setPriority(value),
    );
  }
}

/// One radio option: circle + label. Tapping anywhere on it selects it.
class _PriorityRadio extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityRadio({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: AppColors.navy,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}