import 'package:flutter/widgets.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';

/// The seven folders every install starts with.
///
/// **Why seven, and why these seven.**
///
/// The Folders tab used to open on an empty state: a glyph, two sentences and
/// a button that asked the user to invent a filing system from nothing. That
/// is the hardest question in the app asked at the worst possible moment — on
/// a screen they have opened once, before they have filed anything, with no
/// example of what a good folder looks like. Almost nobody answers it.
///
/// These are the answer instead. Each one is a category people already keep
/// screenshots of and already know they keep screenshots of: the flight
/// confirmation, the recipe from a story, the dosage on a box, the thing the
/// assistant said, the price, the workout, the song. Nobody has to invent
/// anything; the first act on the tab is recognising something rather than
/// composing something.
///
/// They are ordinary folders the moment they exist — renameable, deletable,
/// re-colourable, and never restored once removed. Shoto suggested them; it
/// does not own them.
///
/// **Seven distinct colours on purpose.** The whole argument for colour in
/// this feature is that it is a filing mark rather than decoration, and a
/// starter set that arrived in three shades of blue would teach the opposite —
/// that the colour is something the app picked and therefore means nothing.
/// One hue each, from [kFolderColors], is what makes the grid legible from
/// across a room on day one.
///
/// The names are resolved here, against the device's language, and become
/// plain text in the database from that point on. See [FolderSeed].
List<FolderSeed> defaultFolderSeeds(BuildContext context) => <FolderSeed>[
  FolderSeed(
    name: context.l10n.folderDefaultTrips,
    color: 0xFF5B8DEF, // blue
    iconKey: 'map',
  ),
  FolderSeed(
    name: context.l10n.folderDefaultRecipes,
    color: 0xFFF5883C, // orange
    iconKey: 'food',
  ),
  FolderSeed(
    name: context.l10n.folderDefaultMedications,
    color: 0xFFFF8A65, // coral
    iconKey: 'pill',
  ),
  FolderSeed(
    name: context.l10n.folderDefaultAiNotes,
    color: 0xFF8B7BF0, // violet
    iconKey: 'sparkle',
  ),
  FolderSeed(
    name: context.l10n.folderDefaultMoney,
    color: 0xFFFFC857, // amber
    iconKey: 'money',
  ),
  FolderSeed(
    name: context.l10n.folderDefaultWorkouts,
    color: 0xFF33E0C2, // teal
    iconKey: 'fitness',
  ),
  FolderSeed(
    name: context.l10n.folderDefaultMusic,
    color: 0xFFEF5DA8, // pink
    iconKey: 'music',
  ),
];
