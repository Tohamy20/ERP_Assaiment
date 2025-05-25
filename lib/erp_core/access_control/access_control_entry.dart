import 'package:flutter/foundation.dart';
import 'permission_level.dart';

class AccessControlEntry {
  final String documentId;
  final String userId;
  final PermissionLevel permission;

  AccessControlEntry({
    required this.documentId,
    required this.userId,
    required this.permission,
  });

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'userId': userId,
        'permission': permission.index,
      };

  factory AccessControlEntry.fromJson(Map<String, dynamic> json) {
    return AccessControlEntry(
      documentId: json['documentId'],
      userId: json['userId'],
      permission: PermissionLevel.values[json['permission']],
    );
  }
}