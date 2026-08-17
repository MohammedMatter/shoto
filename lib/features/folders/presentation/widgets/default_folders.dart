import 'package:flutter/widgets.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';

/// The two folders every install starts with.
///
/// **Two, against a free tier of three, and the gap is the point.** It was
/// seven, chosen when folders were uncapped. Three — one per free slot — was
/// the obvious answer once [SubscriptionConstants.freeFolderLimit] came back,
/// and it was wrong in a way that only shows up from the user's side: a
/// starter set the exact size of the allowance means the first folder somebody
/// names *themselves* is the one that meets the paywall. Their own idea, the
/// moment they have it, priced. Shoto suggested the other two; charging for
/// the first one that was actually theirs is the worst possible place to put
/// a price.
///
/// So the set leaves a slot. Two folders to recognise, one to invent, and the
/// paywall arrives on the fourth — after somebody has filed something of their
/// own into something of their own, which is the only state in which paying
/// for more of them makes any sense.
///
/// **These two.** Of the seven, these are the two anybody recognises: a recipe
/// from a story and the thing the assistant said. Workouts was the third and
/// came out here — it is a real category and a narrower one, and a starter
/// folder that stays empty for somebody who does not train spends a slot on
/// nothing. Trips, medications, money and music are all things people keep
/// screenshots of in bursts, and a folder that is empty eleven months of the
/// year is a poor use of a slot that was never free to begin with.
///
/// **Why seven, and why those seven** — the reasoning that chose the original
/// set, kept because it is what the three left standing were chosen from.
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
/// Each keeps the colour and the glyph it had in the set of seven: somebody
/// upgrading meets the same three folders they would have met before, in the
/// same colours, rather than a set that looks reshuffled.
List<FolderSeed> defaultFolderSeeds(BuildContext context) => <FolderSeed>[
  FolderSeed(
    name: context.l10n.folderDefaultAiNotes,
    color: 0xFF8B7BF0, // violet
    iconKey: 'sparkle',
  ),
  FolderSeed(
    name: context.l10n.folderDefaultRecipes,
    color: 0xFFF5883C, // orange
    iconKey: 'food',
  ),
];
