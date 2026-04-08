class OwnerAuthValidators {
  static String? validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Owner name is required.';
    }
    if (trimmed.length > 100) {
      return 'Owner name must be 100 characters or fewer.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? validateNepalPhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Phone number is required.';
    }
    if (!RegExp(r'^98\d{8}$').hasMatch(trimmed)) {
      return 'Use a valid Nepal phone number like 98XXXXXXXX.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (password.length > 64) {
      return 'Password must be 64 characters or fewer.';
    }
    return null;
  }

  static String? validateBusinessName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length > 150) {
      return 'Business name must be 150 characters or fewer.';
    }
    return null;
  }
}
