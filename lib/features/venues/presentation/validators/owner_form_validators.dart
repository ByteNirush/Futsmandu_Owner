class OwnerFormValidators {
  const OwnerFormValidators._();

  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? doubleInRange(
    String? value, {
    required String label,
    required double min,
    required double max,
  }) {
    final requiredError = requiredText(value, label);
    if (requiredError != null) {
      return requiredError;
    }

    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < min || parsed > max) {
      return '$label must be between $min and $max';
    }
    return null;
  }

  static String? intInRange(
    String? value, {
    required String label,
    required int min,
    required int max,
  }) {
    final requiredError = requiredText(value, label);
    if (requiredError != null) {
      return requiredError;
    }

    final parsed = int.tryParse(value!.trim());
    if (parsed == null || parsed < min || parsed > max) {
      return '$label must be between $min and $max';
    }
    return null;
  }

  static String? hhmm(String? value, {required String label}) {
    final requiredError = requiredText(value, label);
    if (requiredError != null) {
      return requiredError;
    }

    final text = value!.trim();
    final parts = text.split(':');
    if (parts.length != 2) {
      return '$label must be in HH:MM format';
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return '$label must be in HH:MM format';
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return '$label must be a valid time';
    }

    return null;
  }
}
