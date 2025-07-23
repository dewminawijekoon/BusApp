import '../config/constants.dart';

class Validators {
  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    if (!hasValidPasswordStrength(value)) {
      return 'Password must contain at least one letter and one number';
    }

    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    final name = value.trim();
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (name.length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters';
    }

    if (!isValidName(name)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim().replaceAll(RegExp(r'[^\d]'), '');
    
    if (phone.length < 10) {
      return 'Please enter a valid phone number';
    }

    if (!isValidPhoneNumber(phone)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }

    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numericError = validateNumeric(value, fieldName);
    if (numericError != null) return numericError;

    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  /// Check if email format is valid
  static bool isValidEmail(String email) {
    return RegExp(AppConstants.emailPattern).hasMatch(email);
  }

  /// Check if password has valid strength
  static bool hasValidPasswordStrength(String password) {
    // Must contain at least one letter and one number
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
  }

  /// Check if name is valid (only letters and spaces)
  static bool isValidName(String name) {
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  /// Check if phone number format is valid
  static bool isValidPhoneNumber(String phone) {
    // Basic phone validation - adjust pattern based on your requirements
    return RegExp(r'^\d{10,15}$').hasMatch(phone);
  }

  /// Validate bus route code
  static String? validateRouteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Route code is required';
    }

    final code = value.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9\-]{2,10}$').hasMatch(code)) {
      return 'Route code must be 2-10 characters (letters, numbers, hyphens only)';
    }

    return null;
  }

  /// Validate bus plate number
  static String? validatePlateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Plate number is required';
    }

    final plate = value.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9\-\s]{3,15}$').hasMatch(plate)) {
      return 'Please enter a valid plate number';
    }

    return null;
  }

  /// Validate rating (1-5)
  static String? validateRating(String? value) {
    final numericError = validateNumeric(value, 'Rating');
    if (numericError != null) return numericError;

    final rating = double.parse(value!);
    if (rating < 1 || rating > 5) {
      return 'Rating must be between 1 and 5';
    }

    return null;
  }

  /// Validate crowd level (1-5)
  static String? validateCrowdLevel(int? value) {
    if (value == null) {
      return 'Please select crowd level';
    }

    if (value < AppConstants.emptyCrowdLevel || value > AppConstants.fullCrowdLevel) {
      return 'Invalid crowd level';
    }

    return null;
  }

  /// Validate time format (HH:MM)
  static String? validateTimeFormat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Time is required';
    }

    if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)) {
      return 'Please enter time in HH:MM format';
    }

    return null;
  }

  /// Validate date is not in the past
  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }

    if (date.isBefore(DateTime.now())) {
      return 'Date cannot be in the past';
    }

    return null;
  }

  /// Validate coordinates (latitude/longitude)
  static String? validateLatitude(String? value) {
    final numericError = validateNumeric(value, 'Latitude');
    if (numericError != null) return numericError;

    final lat = double.parse(value!);
    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }

    return null;
  }

  static String? validateLongitude(String? value) {
    final numericError = validateNumeric(value, 'Longitude');
    if (numericError != null) return numericError;

    final lng = double.parse(value!);
    if (lng < -180 || lng > 180) {
      return 'Longitude must be between -180 and 180';
    }

    return null;
  }

  /// Validate comment/feedback text
  static String? validateComment(String? value, {int maxLength = 500}) {
    if (value != null && value.trim().length > maxLength) {
      return 'Comment must be less than $maxLength characters';
    }
    return null;
  }

  /// Validate search query
  static String? validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a search term';
    }

    if (value.trim().length < 2) {
      return 'Search term must be at least 2 characters';
    }

    return null;
  }
}