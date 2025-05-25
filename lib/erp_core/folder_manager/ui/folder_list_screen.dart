import 'package:erpflutter/erp_core/access_control/access_control_sdk.dart';
import 'package:erpflutter/erp_core/access_control/auth_service.dart';
import 'package:erpflutter/erp_core/access_control/permission_level.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../access_control/access_control_sdk.dart';
import '../sdk/folder_manager_sdk.dart';
import '../models/folder_model.dart';
// Add these imports for RBAC


class FolderListScreen extends StatefulWidget {
  final Folder? currentFolder;

  const FolderListScreen({super.key, this.currentFolder});

  @override
  _FolderListScreenState createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  late Future<List<Folder>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _foldersFuture = _loadFolders();
  }

  Future<List<Folder>> _loadFolders() async {
    final sdk = context.read<FolderManagerSDK>();
    return widget.currentFolder == null 
        ? sdk.getFolderTree(parentId: '')
        : sdk.getFolderTree(parentId: widget.currentFolder!.id);
  }

  Future<void> _refreshFolders() async {
    setState(() {
      _foldersFuture = _loadFolders();
    });
  }
  Future<void> _managePermissions(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPermissionScreen(
          documentId: widget.currentFolder?.id ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFolder = widget.currentFolder;
    final auth = context.watch<AuthService>();
  
  if (!auth.isLoggedIn) {
    return const Center(
      child: Text('Please login to access folders'),
    );
  }
    return Scaffold(
      appBar: AppBar(
        title: Text(currentFolder?.name ?? 'Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateFolderDialog,
          ),
          if (currentFolder != null)
            IconButton(
              icon: const Icon(Icons.lock),
              onPressed: () => _managePermissions(context),
            ),
            IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => context.read<AuthService>().logout(),
    ),
        ],
      ),
      body: FutureBuilder<List<Folder>>(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No folders found.'));
          }
          final folders = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshFolders,
            child: ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return _FolderListItem(
                  folder: folder,
                  onFolderSelected: _navigateToFolder,
                  onRefresh: _refreshFolders,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToFolder(Folder folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderListScreen(currentFolder: folder),
      ),
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final nameController = TextEditingController();
    PermissionLevel _selectedPermission = PermissionLevel.view; // New permission state

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: Column( // Changed to Column for permission selector
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Folder Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PermissionLevel>(
              value: _selectedPermission,
              items: PermissionLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) => _selectedPermission = value!,
              decoration: const InputDecoration(
                labelText: 'Initial Permission',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _createFolder(nameController.text, _selectedPermission);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  
  
  // Updated to accept permission parameter
  Future<void> _createFolder(String name, PermissionLevel permission) async {
    try {

      final auth = context.read<AuthService>();
      final currentUser = auth.currentUserId;
      if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in')),
      );
      return;
    }

      final sdk = context.read<FolderManagerSDK>();
      final accessSDK = context.read<AccessControlSDK>();
    //  final currentUser = 'current_user_id'; // Replace with real auth
      
      // Create folder
      final newFolder = await sdk.createFolder(
        name,
        parentId: widget.currentFolder?.id,
      );

      // Set initial permission
      await accessSDK.assignPermission(
        documentId: newFolder.id, // Assuming folders use same ID system
        userId: currentUser, // Replace with actual user ID
        permission: permission,
      );

      await _refreshFolders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create folder: ${e.toString()}')),
      );
    }
  }
}

class _FolderListItem extends StatelessWidget {
  final Folder folder;
  final Function(Folder) onFolderSelected;
  final Function() onRefresh;

  const _FolderListItem({
    required this.folder,
    required this.onFolderSelected,
    required this.onRefresh,
  });

  Future<void> _deleteFolder(BuildContext context) async {
    try {
      final accessSDK = context.read<AccessControlSDK>();
      final auth = context.read<AuthService>();
    
        final hasPermission = await accessSDK.checkPermission(
      documentId: folder.id,
      userId: auth.currentUserId!,
      requiredLevel: PermissionLevel.edit,
    );

  if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need edit permissions')),
      );
      return;
    }

      final sdk = context.read<FolderManagerSDK>();
      await sdk.deleteFolder(folder.id);
      onRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete folder: ${e.toString()}')),
      );
    }
  }

  Future<void> _editFolder(BuildContext context) async {
    final nameController = TextEditingController(text: folder.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Folder'),
        content: TextField(controller: nameController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final updated = folder.copyWith(name: nameController.text);
                await context.read<FolderManagerSDK>().updateFolder(updated);
                onRefresh();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // New permission management method
  Future<void> _managePermissions(BuildContext context) async {
    try {
      final accessSDK = context.read<AccessControlSDK>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentPermissionScreen(
            documentId: folder.id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(folder.name),
      subtitle: Text('${folder.children.length} items'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Added permissions icon
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () => _managePermissions(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editFolder(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteFolder(context),
          ),
        ],
      ),
      onTap: () => onFolderSelected(folder),
    );
  }
}

// Add this new widget (create in separate file)
class DocumentPermissionScreen extends StatelessWidget {
  final String documentId;

  const DocumentPermissionScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Permissions')),
      body: Center(child: Text('Permission management for $documentId')),
    );
  }
}