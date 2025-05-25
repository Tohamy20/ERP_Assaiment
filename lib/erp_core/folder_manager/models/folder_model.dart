
import 'package:equatable/equatable.dart';
import 'package:erpflutter/erp_core/access_control/permission_level.dart';
import 'package:uuid/uuid.dart';

class Folder extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> children;
  final String? parentName;
  final Map<String, PermissionLevel> permissions;

  Folder({
    String? id,
    required this.name,
    this.parentId,
    List<String>? children,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.parentName,
    this.permissions = const {},
  })  : id = id ?? Uuid().v4(),
        children = children ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

   Folder copyWith({
    String? name,
    String? parentId,
    List<String>? children,
    String? parentName,
    Map<String, PermissionLevel>? permissions,
  }) {
    return Folder(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      parentName: parentName ?? this.parentName,
      permissions: permissions ?? this.permissions,
    );
  }

 @override
  List<Object?> get props => [id, name, parentId, createdAt, updatedAt, children, permissions];
}