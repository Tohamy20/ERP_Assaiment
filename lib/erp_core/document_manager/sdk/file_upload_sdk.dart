import 'dart:io';
import 'dart:typed_data';

import 'package:erpflutter/erp_core/document_manager/models/document_model.dart';
import 'package:erpflutter/erp_core/document_manager/repositories/document_repository.dart';
import 'package:erpflutter/erp_core/document_manager/validation/file_type_validator.dart';
import 'package:erpflutter/erp_core/document_manager/validation/validation_error.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart'; 

class FileUploadSDK {
  final DocumentRepository repository;
  final FileTypeValidator validator;
  final Uuid uuid;
  final Logger _logger = Logger('FileUploadSDK');

  FileUploadSDK({
    required this.repository,
    this.validator = const FileTypeValidator(),
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  /// Uploads a document with full metadata handling
  /// 
  /// [bytes] - Raw file content in bytes
  /// [fileName] - Original filename with extension
  /// [title] - Document title (required)
  /// [description] - Document description
  /// [tags] - List of document tags
  /// 
  /// Returns: [Document] object with stored details
  /// 
  /// Throws: [DocumentUploadException] on failure
  Future<Document> uploadDocument({
    required Uint8List bytes,
    required String fileName,
    required String title,
    String description = '',
    required List<String> tags, String? folderId,
  }) async {
    try {
      _logger.info('Starting document upload: $fileName');
      
      // Validate inputs
      _validateMetadata(title, tags);
      
      // Clean inputs
      final cleanedTitle = title.trim();
      final cleanedDescription = description.trim();
      final cleanedTags = _cleanTags(tags);
      final fileExtension = _getFileExtension(fileName);

      // Perform validation
      validator.validate(fileName, bytes.length);
      
      // Store file
      final storagePath = await _storeFile(bytes, fileName);
      
      // Create document object
      return _createDocument(
        fileName: fileName,
        fileExtension: fileExtension,
        bytes: bytes,
        storagePath: storagePath,
        title: cleanedTitle,
        description: cleanedDescription,
        tags: cleanedTags,
      );
      
    } on ValidationError catch (e) {
      _logger.severe('Validation failed: ${e.message}');
      throw DocumentUploadException('Validation error: ${e.message}');
    } on RepositoryException catch (e) {
      _logger.severe('Storage failed: ${e.message}');
      throw DocumentUploadException('Storage error: ${e.message}');
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error', e, stackTrace);
      throw DocumentUploadException('Unexpected error: ${e.toString()}');
    }
  }

  String _getFileExtension(String fileName) {
    final extension = fileName.split('.').lastOrNull;
    if (extension == null || extension.isEmpty) {
      throw ValidationError('Invalid filename', 'File has no extension');
    }
    return extension.toLowerCase();
  }

  Future<String> _storeFile(Uint8List bytes, String fileName) async {
  
  if (kIsWeb) {
    // Simulate storage in-memory or remote storage via HTTP POST
    final simulatedPath = 'web_storage/$fileName';
    // You could also use a map or cache to store it
    return simulatedPath;
  }
  else{
     // Mobile/Desktop: use path_provider
  final directory = await getApplicationDocumentsDirectory(); // this is the line that crashes on web
  final path = '${directory.path}/erp_document';
  final file = File('$path/$fileName');

  await Directory(path).create(recursive: true);
  await file.writeAsBytes(bytes);

  return file.path;
  }
  
  
  
  try {



    // Get app document directory
    final appDocDir = await getApplicationDocumentsDirectory();

    // Define subdirectory path
    final folderPath = Directory('${appDocDir.path}/erp_document');

    // Ensure the folder exists
    if (!await folderPath.exists()) {
      await folderPath.create(recursive: true);
    }

    // Define full file path
    final filePath = '${folderPath.path}/$fileName';

    // Write the bytes to file
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return file.path;
  } catch (e) {
    throw RepositoryException('File storage failed: ${e.toString()}');
  }
}


  Document _createDocument({
    required String fileName,
    required String fileExtension,
    required Uint8List bytes,
    required String storagePath,
    required String title,
    required String description,
    required List<String> tags,
  }) {
    return Document(
      id: uuid.v4(),
      title: title,
      description: description,
      tags: tags,
      filePath: storagePath,
      fileType: fileExtension,
      fileSize: bytes.length,
      uploadDate: DateTime.now().toUtc(),
      originalFileName: fileName,
    );
  }

  void _validateMetadata(String title, List<String> tags) {
    if (title.trim().isEmpty) {
      throw ValidationError('Invalid title', 'Title cannot be empty');
    }
    
    if (tags.any((tag) => tag.trim().isEmpty)) {
      throw ValidationError('Invalid tags', 'Tags cannot contain empty values');
    }
  }

  List<String> _cleanTags(List<String> tags) {
    return tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
}

// Custom Exceptions
class DocumentUploadException implements Exception {
  final String message;
  DocumentUploadException(this.message);
  
  @override
  String toString() => 'DocumentUploadException: $message';
}

class RepositoryException implements Exception {
  final String message;
  RepositoryException(this.message);
  
  @override
  String toString() => 'RepositoryException: $message';
}