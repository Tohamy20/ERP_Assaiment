class FileValidator {
  static const List<String> allowedTypes = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];
  static const int maxSizeMB = 10;
  static const int maxSizeBytes = maxSizeMB * 1024 * 1024;

  static String? validate(String fileType, int fileSize) {
    if (!allowedTypes.contains(fileType.toLowerCase())) {
      return 'Unsupported file type: $fileType';
    }
    
    if (fileSize > maxSizeBytes) {
      return 'File size exceeds $maxSizeMB MB limit';
    }
    
    return null;
  }
}