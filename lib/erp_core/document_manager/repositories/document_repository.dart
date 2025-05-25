import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:universal_html/html.dart' as html;  // Add this import

class DocumentRepository {

  Future<String> _getStoragePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/erp_documents';
  }

 Future<String> storeFile(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      // Web-specific handling (e.g., upload to server)
      return _handleWebStorage(bytes, fileName);
    } else {
      // Mobile/Desktop storage
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/erp_documents/$fileName';
      await File(path).writeAsBytes(bytes);
      return path;
    }
  }
   Future<String> _handleWebStorage(Uint8List bytes, String fileName) async {
    // Example: Trigger file download for web
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
    
    return 'web_storage/$fileName'; // Return a reference
  }
}