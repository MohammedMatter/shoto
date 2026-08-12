class FolderEntity {
  final int id;
  final String name;
  final int color;
  final DateTime createdAt;
  final int screenshotCount;
  final bool isPrivate;

  /// Which glyph the folder wears, as a key into `FolderIcons`.
  ///
  /// **Nullable, and it will stay nullable.** Every folder made before the
  /// column existed has no key, and that is a real answer rather than missing
  /// data: those folders were drawn with a plain folder glyph and they still
  /// are. Resolving happens in the presentation layer, where an unknown or
  /// absent key falls back to the same picture.
  final String? iconKey;

  const FolderEntity({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.screenshotCount = 0,
    this.isPrivate = false,
    this.iconKey,
  });

  FolderEntity copyWith({
    String? name,
    int? color,
    int? screenshotCount,
    bool? isPrivate,
    String? iconKey,
  }) {
    return FolderEntity(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
      screenshotCount: screenshotCount ?? this.screenshotCount,
      isPrivate: isPrivate ?? this.isPrivate,
      iconKey: iconKey ?? this.iconKey,
    );
  }
}
