/// How long a folder name may be, in characters.
///
/// **The limit exists for the places the name is quoted, not for the database.**
/// A folder name is never shown alone: it is embedded in the Quick Save
/// button ("File in {folder}"), printed inside a chip in a horizontal strip,
/// and read back in the confirmation line. Every one of those has a width the
/// name does not control, and the button was the one that failed loudly —
/// a long enough name ran past its edge and painted overflow stripes.
///
/// Those surfaces now ellipsize rather than overflow, and they have to:
/// names also arrive from a restored backup, which passes through no text
/// field at all. This cap is the other half — it keeps the ellipsis rare
/// instead of merely survivable.
///
/// 32 rather than the 24 used for intent labels
/// (`CustomIntentEditorSheet._maxLabelLength`): an intent is one verb and has
/// to stay readable at a glance mid-save, while a folder name is a filing
/// label somebody may reasonably want to be specific with — "Recipes to try
/// this winter" is 27 and is not an abuse of the field.
///
/// Applied on the three fields that can set a name: the Quick Save naming
/// stage, the create-folder sheet, and rename.
const int kMaxFolderNameLength = 32;
