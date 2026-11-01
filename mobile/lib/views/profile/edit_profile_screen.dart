import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../widgets/labeled_text_field.dart';

/// Profile > Edit Profile: name, surname and phone.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Start with the student's current details
    final student = context.read<ProfileViewModel>().student;
    _nameController = TextEditingController(text: student?.name ?? '');
    _surnameController = TextEditingController(text: student?.surname ?? '');
    _phoneController = TextEditingController(text: student?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final vm = context.read<ProfileViewModel>();
    if (vm.isSaving) return;

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Grab before the await (the screen may close afterwards)
    final home = context.read<HomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final saved = await vm.updateProfile(
      name: _nameController.text,
      surname: _surnameController.text,
      phone: _phoneController.text,
    );

    if (saved) {
      home.refresh(); // "Hi, …!" on Home shows the new name
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final student = vm.student;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: student == null
            ? const Center(
                child: Text('Could not load your profile.',
                    style: TextStyle(color: AppColors.navy)))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar with initials
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.navy,
                          child: Text(vm.initials,
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      LabeledTextField(
                        label: 'Name',
                        controller: _nameController,
                        validator: (v) => Validators.required(v, 'Name'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      LabeledTextField(
                        label: 'Surname',
                        controller: _surnameController,
                        validator: (v) => Validators.required(v, 'Surname'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      LabeledTextField(
                        label: 'Phone (optional)',
                        controller: _phoneController,
                        validator: Validators.phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 20),

                      // Locked details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LockedRow(label: 'Email', value: student.email),
                              const SizedBox(height: 10),
                              _LockedRow(
                                  label: 'Student number',
                                  value: student.studentNumber ?? '-'),
                              const SizedBox(height: 10),
                              const Text(
                                'These are linked to your login and your accommodation '
                                'contract. Contact your landlord to change them.',
                                style: TextStyle(color: AppColors.greyText, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (vm.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(vm.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.danger, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: _onSave,
                        child: vm.isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: AppColors.white),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// A read-only detail with a lock icon.
class _LockedRow extends StatelessWidget {
  final String label;
  final String value;

  const _LockedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lock_outline, size: 18, color: AppColors.greyText),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.greyText, fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.navy, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
