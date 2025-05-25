import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../sdk/folder_manager_sdk.dart';
import '../models/folder_model.dart';

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

@override
Widget build(BuildContext context) {
  final currentFolder = widget.currentFolder;
  return Scaffold(
    appBar: AppBar(
      title: Text(currentFolder?.name ?? 'Root Folders'),
      actions: [
        IconButton(
          icon: const Icon(Icons.upload),
          onPressed: () => Navigator.pushNamed(
            context,
            '/upload',
            arguments: {'folderId': currentFolder?.id},
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showCreateFolderDialog,
        ),
      ],
    ),
    body: FutureBuilder<List<Folder>>(
      future: _foldersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final folders = snapshot.data ?? [];
        return ListView.builder(
          itemCount: folders.length,
          itemBuilder: (context, index) => _FolderListItem(
            folder: folders[index],
            onFolderSelected: (folder) => _navigateToFolder(folder),
            onRefresh: _refreshFolders,
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
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Folder Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _createFolder(nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createFolder(String name) async {
    try {
      final sdk = context.read<FolderManagerSDK>();
      await sdk.createFolder(
        name,
        parentId: widget.currentFolder?.id,
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(folder.name),
      subtitle: Text('${folder.children.length} items'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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