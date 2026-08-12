import 'package:flutter/material.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_icons.dart';

/// A folder, small — its plate colour and its glyph, and nothing else.
///
/// **The card, shrunk to a badge.** Everywhere a folder is named outside the
/// grid — the header of its own page, the sheet asking whether to delete it —
/// something has to say *which* folder, and until now each place invented its
/// own answer: the detail page drew `Icons.folder_rounded` on an 18% wash of
/// the colour, the actions sheet drew the bare glyph with no plate. Neither
/// looked like the thing the user had just tapped.
///
/// So this is built from the same two functions the card is: [folderPlateColor]
/// for the fill and [onFolderColor] for the glyph on it. A folder is then
/// recognisably itself at 98dp on a grid and at 32dp in a header, because both
/// are the same object at two sizes rather than two drawings of one idea.
///
/// **No tab and no pocket at this size.** The folder silhouette is what makes
/// the card read as a folder, and below about 40dp the tab is three pixels of
/// notch that reads as a rendering artefact. What survives shrinking is the
/// colour and the glyph, so those are what it keeps.
class FolderMark extends StatelessWidget {
  final FolderEntity folder;

  /// The badge's edge length. The glyph is sized from it.
  final double size;

  const FolderMark({super.key, required this.folder, required this.size});

  @override
  Widget build(BuildContext context) {
    final Color foreground = onFolderColor(folder.color);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: folderPlateColor(folder.color),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      // Full strength, unlike the watermark on the card. There it sits behind
      // the name and must not compete with it; here it *is* the identification,
      // with no name written across it.
      child: folder.isPrivate
          ? Icon(Icons.lock_rounded, size: size * 0.52, color: foreground)
          : FolderGlyph(
              iconKey: folder.iconKey,
              size: size * 0.52,
              color: foreground,
            ),
    );
  }
}
