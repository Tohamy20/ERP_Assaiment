import 'package:erpflutter/erp_core/folder_manager/models/folder_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderRepository {
  static const _storageKey = 'folders';

  Future<List<Folder>> getAllFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = prefs.getStringList(_storageKey) ?? [];
    return foldersJson.map(_fromJson).toList();
  }

  Future<void> saveFolders(List<Folder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      folders.map((f) => _toJson(f)).toList(),
    );
  }

  String _toJson(Folder folder) {
    return [
      folder.id,
      folder.name,
      folder.parentId ?? '',
      folder.children.join(','),
      folder.createdAt.toIso8601String(),
      folder.updatedAt.toIso8601String(),
    ].join('|');
  }

  Folder _fromJson(String json) {
    final parts = json.split('|');
    return Folder(
      id: parts[0],
      name: parts[1],
      parentId: parts[2].isEmpty ? null : parts[2],
      parentName: parts.length > 6 ? parts[6] : null,
      children: parts[3].split(',').where((c) => c.isNotEmpty).toList(),
      createdAt: DateTime.parse(parts[4]),
      updatedAt: DateTime.parse(parts[5]),
    );
  }
}