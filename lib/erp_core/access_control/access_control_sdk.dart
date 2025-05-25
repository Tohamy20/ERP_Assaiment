import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'access_control_entry.dart';
import 'access_control_repository.dart';
import 'permission_level.dart';

class AccessControlSDK {
  final AccessControlRepository repository;

  AccessControlSDK({required this.repository});

  Future<void> assignPermission({
    required String documentId,
    required String userId,
    required PermissionLevel permission,
  }) async {
    final entry = AccessControlEntry(
      documentId: documentId,
      userId: userId,
      permission: permission,
    );
    await repository.assignPermission(entry);
  }
  static const _storageKey = 'access_control_entries';
  Future<List<AccessControlEntry>> getAcl(String documentId) async {

    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_storageKey) ?? [];
    return entriesJson
        .map((json) => AccessControlEntry.fromJson(jsonDecode(json)))
        .where((entry) => entry.documentId == documentId)
        .toList();
  }
  Future<void> removePermission(String documentId, String userId) async {
    await repository.removePermission(documentId, userId);
  }

  Future<bool> checkPermission({
    required String documentId,
    required String userId,
    required PermissionLevel requiredLevel,
  }) async {
    final acl = await repository.getAcl(documentId);
    final userEntry = acl.firstWhere(
      (entry) => entry.userId == userId,
      orElse: () => AccessControlEntry(
        documentId: documentId,
        userId: '',
        permission: PermissionLevel.view,
      ),
    );
    return userEntry.permission.index >= requiredLevel.index;
  }
}

// Custom Exceptions
class PermissionAssignmentException implements Exception {
  final String message;
  PermissionAssignmentException(this.message);
  @override
  String toString() => 'PermissionAssignmentException: $message';
}