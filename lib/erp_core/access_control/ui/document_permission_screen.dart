import 'package:erpflutter/erp_core/access_control/access_control_sdk.dart';
import 'package:erpflutter/erp_core/access_control/permission_level.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class DocumentPermissionScreen extends StatefulWidget {
  final String documentId;

  const DocumentPermissionScreen({super.key, required this.documentId});

  @override
  State<DocumentPermissionScreen> createState() => _DocumentPermissionScreenState();
}

class _DocumentPermissionScreenState extends State<DocumentPermissionScreen> {
  final _userIdController = TextEditingController();
  PermissionLevel _selectedLevel = PermissionLevel.view;

  @override
  Widget build(BuildContext context) {
    final accessSDK = context.read<AccessControlSDK>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Permissions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            DropdownButtonFormField<PermissionLevel>(
              value: _selectedLevel,
              items: PermissionLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedLevel = value!),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_userIdController.text.isNotEmpty) {
                  await accessSDK.assignPermission(
                    documentId: widget.documentId,
                    userId: _userIdController.text,
                    permission: _selectedLevel,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permission updated')),
                  );
                }
              },
              child: const Text('Assign Permission'),
            ),
          ],
        ),
      ),
    );
  }
}