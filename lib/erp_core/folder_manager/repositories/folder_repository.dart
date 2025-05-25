import 'package:erpflutter/erp_core/access_control/permission_level.dart';
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
      _encodePermissions(folder.permissions),
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
      permissions: parts.length > 6 ? _decodePermissions(parts[6]) : {},
    );
  }

String _encodePermissions(Map<String, PermissionLevel> permissions) {
    return permissions.entries
        .map((e) => '${e.key}:${e.value.index}')
        .join(',');
  }

  Map<String, PermissionLevel> _decodePermissions(String input) {
    if (input.isEmpty) return {};
    return Map.fromEntries(input.split(',').map((entry) {
      final parts = entry.split(':');
      return MapEntry(
        parts[0],
        PermissionLevel.values[int.parse(parts[1])],
      );
    }));
  }
}  