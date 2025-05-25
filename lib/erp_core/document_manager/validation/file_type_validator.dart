import 'package:erpflutter/erp_core/document_manager/validation/validation_error.dart';

class FileTypeValidator {
  final Set<String> allowedTypes;
  final int maxFileSizeBytes;

  const FileTypeValidator({
    this.allowedTypes = const {'pdf', 'doc', 'docx', 'xls', 'xlsx'},
    this.maxFileSizeBytes = 10485760, // 10MB
  });

  void validate(String fileName, int fileSize) {
    final extension = _getFileExtension(fileName);
    _validateExtension(extension);
    _validateSize(fileSize);
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) throw ValidationError('NO_EXTENSION', 'File has no extension');
    return parts.last.toLowerCase();
  }

  void _validateExtension(String extension) {
    if (!allowedTypes.contains(extension)) {
      throw ValidationErrors.invalidType;
    }
  }

  void _validateSize(int fileSize) {
    if (fileSize > maxFileSizeBytes) {
      throw ValidationErrors.sizeExceeded;
    }
  }
}