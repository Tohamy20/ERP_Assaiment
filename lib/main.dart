import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:universal_html/html.dart';
import 'package:uuid/uuid.dart';

// Core components
import 'erp_core/document_manager/sdk/file_upload_sdk.dart';
import 'erp_core/document_manager/repositories/document_repository.dart';
import 'erp_core/document_manager/ui/upload_page.dart';
import 'erp_core/folder_manager/ui/folder_list_screen.dart';
import 'erp_core/folder_manager/repositories/folder_repository.dart';
import 'erp_core/folder_manager/sdk/folder_manager_sdk.dart';

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
    
    if (record.error != null) print('Error: ${record.error}');
    if (record.stackTrace != null) print('StackTrace: ${record.stackTrace}');
  });
}

void main() {
  _setupLogging();
  final uuid = Uuid();
  
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => DocumentRepository()),
        Provider(create: (_) => FolderRepository()),
        Provider(
          create: (context) => FileUploadSDK(
            repository: context.read<DocumentRepository>(),
            uuid: uuid,
          ),
        ),
        Provider(
          create: (context) => FolderManagerSDK(
            repository: context.read<FolderRepository>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP Document Manager',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/folders',
      routes: {
        '/folders': (context) => const FolderListScreen(),
        '/upload': (context) => const UploadPage(),
      },
      onGenerateRoute: (settings) {
        // Handle folder-specific uploads
        if (settings.name == '/upload') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => UploadPage(
              currentFolderId: args?['folderId'],
            ),
          );
        }
        return null;
      },
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blueGrey,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}