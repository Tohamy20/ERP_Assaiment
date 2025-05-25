import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart';

class DocumentRepository {
  // In-memory map for web file simulation
  final Map<String, Uint8List> _webStorage = {};

  /// Stores a file and returns its path (real on mobile/desktop, simulated on web)
  Future<String> storeFile(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      final id = 'doc_${DateTime.now().millisecondsSinceEpoch}';
      _webStorage[id] = bytes;

      final simulatedPath = 'web_memory_storage/$id/$fileName';
      print('📁 Simulated saving file to: $simulatedPath');  // <-- add this line
      return simulatedPath;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/erp_document';
      final file = io.File('$path/$fileName');
      
        print('📁 Saving file to: $path');
       // <-- This logs where it's being saved

      await io.Directory(path).create(recursive: true);
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      throw Exception('Failed to store file: $e');
    }
  }

  /// Fetch a file from web storage by simulated path
  Uint8List? getFileFromWebStorage(String simulatedPath) {
    if (!kIsWeb) return null;

    // Extract ID from simulated path
    final parts = simulatedPath.split('/');
    if (parts.length >= 3) {
      final id = parts[1];
      return _webStorage[id];
    }
    return null;
  }
}
