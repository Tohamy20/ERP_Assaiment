import 'dart:typed_data';
import 'package:erpflutter/erp_core/access_control/access_control_sdk.dart';
import 'package:erpflutter/erp_core/access_control/permission_level.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../sdk/file_upload_sdk.dart';
import '../models/document_model.dart';

class UploadPage extends StatefulWidget {
  final String? currentFolderId;
  const UploadPage({super.key, this.currentFolderId});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;

  bool _isUploading = false;
  String? _uploadResult;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true, // important for web
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFile = result.files.single;
          _fileBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      setState(() {
        _uploadResult = 'Error picking file: $e';
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _fileBytes == null) {
      setState(() {
        _uploadResult = 'Please select a file first.';
      });
      return;
    }

    final sdk = context.read<FileUploadSDK>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final tags = _tagsController.text.split(',').map((e) => e.trim()).toList();

    setState(() {
      _isUploading = true;
      _uploadResult = null;
    });

    try {
      Document uploaded = await sdk.uploadDocument(
        bytes: _fileBytes!,
        fileName: _selectedFile!.name,
        title: title,
        description: description,
        tags: tags,
        folderId: widget.currentFolderId,
      );
      final accessSDK = context.read<AccessControlSDK>();
    await accessSDK.assignPermission(
      documentId: uploaded.id, // Use actual uploaded doc ID
      userId: 'current_user_id', // Get from auth system
      permission: PermissionLevel.edit,
    );

      setState(() {
        _uploadResult = 'Upload successful + permissions set: ${uploaded.filePath}';
        _selectedFile = null;
        _fileBytes = null;
        _titleController.clear();
        _descriptionController.clear();
        _tagsController.clear();
      });
    } catch (e) {
      setState(() {
        _uploadResult = 'Upload failed: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            TextField(controller: _tagsController, decoration: const InputDecoration(labelText: 'Tags (comma-separated)')),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Select File'),
            ),
            if (_selectedFile != null) Text('Selected: ${_selectedFile!.name} (${_selectedFile!.size} bytes)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              child: _isUploading ? const CircularProgressIndicator() : const Text('Upload'),
            ),
            if (_uploadResult != null) ...[
              const SizedBox(height: 20),
              Text(_uploadResult!, style: TextStyle(color: _uploadResult!.startsWith('Upload successful') ? Colors.green : Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
