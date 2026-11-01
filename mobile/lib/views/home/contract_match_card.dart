import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/student.dart';
import '../../viewmodels/home_viewmodel.dart';

/// Shown on Home when the student isn't linked to a room yet.
class ContractMatchCard extends StatefulWidget {
  final Student student;

  const ContractMatchCard({super.key, required this.student});

  @override
  State<ContractMatchCard> createState() => _ContractMatchCardState();
}

class _ContractMatchCardState extends State<ContractMatchCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _surnameController;

  @override
  void initState() {
    super.initState();
    // Start with what they typed at sign-up, so they only fix the typo
    _numberController = TextEditingController(text: widget.student.studentNumber ?? '');
    _surnameController = TextEditingController(text: widget.student.surname);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _onTryAgain(HomeViewModel vm) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final linked = await vm.retryContractMatch(
      studentNumber: _numberController.text,
      surname: _surnameController.text,
    );

    if (linked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Found your contract. Your room is now linked!')),
      );
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF2F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final student = widget.student;

    // Declined or tenancy ended: nothing to retry
    if (student.isBlocked) {
      return _InfoCard(
        icon: Icons.block,
        title: student.registrationStatus == 'ended'
            ? 'Your tenancy has ended'
            : 'Your registration was declined',
        text: 'Please contact your landlord if you think this is a mistake.',
      );
    }

    final noAttemptsLeft = student.attemptsLeft == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.search_off, color: AppColors.navy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("We couldn't find your contract",
                        style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Check that your student number and surname are exactly as on your '
                'accommodation contract, then try again.',
                style: TextStyle(color: AppColors.greyText, fontSize: 13),
              ),
              const SizedBox(height: 14),

              if (noAttemptsLeft)
                const Text(
                  'No attempts left. Please contact your landlord to link your room.',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                )
              else ...[
                TextFormField(
                  controller: _numberController,
                  decoration: _decoration('Student number'),
                  textCapitalization: TextCapitalization.characters,
                  validator: Validators.studentNumber,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _surnameController,
                  decoration: _decoration('Surname'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'Surname'),
                ),

                if (vm.retryMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(vm.retryMessage!,
                      style: const TextStyle(
                          color: AppColors.danger, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 14),

                ElevatedButton(
                  onPressed: vm.isRetrying ? null : () => _onTryAgain(vm),
                  child: vm.isRetrying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.white),
                        )
                      : const Text('Try again'),
                ),
                const SizedBox(height: 6),
                Text(
                  '${student.attemptsLeft} attempt${student.attemptsLeft == 1 ? '' : 's'} left',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple card with an icon, a title and a sentence.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.navy, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(text,
                      style: const TextStyle(color: AppColors.greyText, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
