class FolderEntity {
  final int id;
  final String name;
  final int color;
  final DateTime createdAt;
  final int screenshotCount;

  const FolderEntity({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.screenshotCount = 0,
  });
}
