class ValidationError implements Exception {
  final String code;
  final String message;

  const ValidationError(this.code, this.message);

  @override
  String toString() => 'ValidationError($code): $message';
}

// Common error types
class ValidationErrors {
  static const invalidType = ValidationError('INVALID_TYPE', 'Unsupported file type');
  static const sizeExceeded = ValidationError('SIZE_EXCEEDED', 'File size exceeds limit');
}