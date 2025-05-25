import 'dart:io';

import 'package:erpflutter/erp_core/document_manager/validation/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../sdk/file_upload_sdk.dart';

class UploadPage extends StatefulWidget {
   final String? currentFolderId;
  const UploadPage({super.key, this.currentFolderId});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  File? _selectedFile;

  Future<void> _uploadDocument() async {
  if (_selectedFile == null) return;

  final uploadSDK = context.read<FileUploadSDK>();
  try {
    final fileBytes = await _selectedFile!.readAsBytes();
    final fileName = _selectedFile!.path.split('/').last;

    if (fileBytes.isEmpty) {
      throw Exception('File content unavailable - failed to read bytes');
    }

    final document = await uploadSDK.uploadDocument(
      bytes: fileBytes,
      fileName: fileName,
      title: _titleController.text,
      description: _descriptionController.text,
      tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      folderId: widget.currentFolderId, // Pass folder ID
    );

    // Handle success
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text('Uploaded: ${document.title}'),
      ),
    );
    
  } on Exception catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Upload failed: ${e.toString()}')),
    );
  }
}

  Future<void> _pickFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error picking file: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Upload'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => Navigator.pushNamed(context, '/folders'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title')),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description')),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Select File')),
            if (_selectedFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('Selected: ${_selectedFile!.path.split('/').last}'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadDocument,
              child: const Text('Upload Document')),
          ],
        ),
      ),
    ));
  }
}