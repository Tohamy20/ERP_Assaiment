import 'package:logging/logging.dart';
import '../models/folder_model.dart';
import '../repositories/folder_repository.dart';

class FolderManagerSDK {
  final FolderRepository repository;
  final Logger _logger = Logger('FolderManagerSDK');

  FolderManagerSDK({required this.repository});

  Future<Folder> createFolder(String name, {String? parentId}) async {
    try {
      _logger.info('Creating folder: $name');
      
      final folders = await repository.getAllFolders();
      final newFolder = Folder(name: name, parentId: parentId);
      
      if (parentId != null) {
        final parent = folders.firstWhere((f) => f.id == parentId);
        final updatedParent = parent.copyWith(
          children: [...parent.children, newFolder.id]
        );
        final folderIndex = folders.indexWhere((f) => f.id == parentId);
        folders[folderIndex] = updatedParent;
      }
      
      await repository.saveFolders([...folders, newFolder]);
      return newFolder;
    } catch (e, stackTrace) {
      _logger.severe('Folder creation failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      _logger.info('Deleting folder: $folderId');
      
      final folders = await repository.getAllFolders();
      final remaining = folders.where((f) => f.id != folderId).toList();
      await repository.saveFolders(remaining);
    } catch (e, stackTrace) {
      _logger.severe('Folder deletion failed', e, stackTrace);
      rethrow;
    }
  }

  Future<Folder> updateFolder(Folder folder) async {
    try {
      _logger.info('Updating folder: ${folder.id}');
      
      final folders = await repository.getAllFolders();
      final index = folders.indexWhere((f) => f.id == folder.id);
      folders[index] = folder;
      await repository.saveFolders(folders);
      return folder;
    } catch (e, stackTrace) {
      _logger.severe('Folder update failed', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Folder>> getFolderTree({required String parentId}) async {
    final folders = await repository.getAllFolders();
    return _buildTree(folders);
  }

  List<Folder> _buildTree(List<Folder> folders, {String? parentId}) {
    return folders
        .where((f) => f.parentId == parentId)
        .map((f) => f.copyWith(
              children: folders
                  .where((child) => child.parentId == f.id)
                  .map((child) => child.id)
                  .toList(),
            ))
        .toList();
  }
}