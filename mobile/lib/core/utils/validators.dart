// Form rules shared by Login, Sign up and Edit Profile.
// Each returns an error message, or null if the value is fine.
class Validators {
  Validators._();

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
    static String? studentNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Student number is required';
    }
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value.trim())) {
      return 'Letters and numbers only';
    }
    if (value.trim().length > 20) {
      return 'Student number is too long';
    }
    return null;
  }
    /// Optional phone number: 10 to 15 digits, spaces/+/()/- allowed.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^[0-9+ ()\-]+$').hasMatch(value.trim())) {
      return 'Numbers, spaces, + ( ) and - only';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
