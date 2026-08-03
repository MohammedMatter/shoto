class FolderEntity {
  final int id;
  final String name;
  final int color;
  final DateTime createdAt;
  final int screenshotCount;
  final bool isPrivate;

  const FolderEntity({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.screenshotCount = 0,
    this.isPrivate = false,
  });

  FolderEntity copyWith({
    String? name,
    int? color,
    int? screenshotCount,
    bool? isPrivate,
  }) {
    return FolderEntity(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
      screenshotCount: screenshotCount ?? this.screenshotCount,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
