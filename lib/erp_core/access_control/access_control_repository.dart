import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'access_control_entry.dart';

class AccessControlRepository {
  static const _storageKey = 'access_control_entries';

  Future<List<AccessControlEntry>> getAcl(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_storageKey) ?? [];
    return entriesJson
        .map((json) => AccessControlEntry.fromJson(jsonDecode(json)))
        .where((entry) => entry.documentId == documentId)
        .toList();
  }

  Future<void> assignPermission(AccessControlEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_storageKey) ?? [];

    // Remove existing entry for the same user and document
    entriesJson.removeWhere((e) {
      final existing = AccessControlEntry.fromJson(jsonDecode(e));
      return existing.documentId == entry.documentId &&
          existing.userId == entry.userId;
    });

    // Add new entry
    entriesJson.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_storageKey, entriesJson);
  }

  Future<void> removePermission(String documentId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_storageKey) ?? [];
    entriesJson.removeWhere((e) {
      final existing = AccessControlEntry.fromJson(jsonDecode(e));
      return existing.documentId == documentId && existing.userId == userId;
    });
    await prefs.setStringList(_storageKey, entriesJson);
  }
}