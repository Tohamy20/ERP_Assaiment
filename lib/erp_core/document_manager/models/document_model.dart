class Document {
  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String filePath;
  final String fileType;
  final int fileSize;
  final DateTime uploadDate;

  Document({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadDate, required String originalFileName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'tags': tags,
    'filePath': filePath,
    'fileType': fileType,
    'fileSize': fileSize,
    'uploadDate': uploadDate.toIso8601String(),
  };
}