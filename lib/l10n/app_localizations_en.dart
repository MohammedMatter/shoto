// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsYourName => 'Your name';

  @override
  String get settingsYourNameHint =>
      'So Safe Share can cover it when it appears';

  @override
  String get settingsYourNameNotSet => 'Not set';

  @override
  String get ownerNameTitle => 'Your name';

  @override
  String get ownerNameBody =>
      'Safe Share finds card numbers and codes by their own arithmetic. A name it can only find if it already knows yours. Typed once, kept on this phone, never sent anywhere.';

  @override
  String get ownerNameFieldHint => 'The name your bank prints';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navFolders => 'Folders';

  @override
  String get navSettings => 'Settings';

  @override
  String get tagline => 'Your screenshots, organized';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeInboxEmpty => 'Nothing saved yet';

  @override
  String get homeInboxEmptySubtitle =>
      'Pick a few from your phone now, or share a screenshot into SHOTO from any app.';

  @override
  String get homeEmptyImportCta => 'Choose from my phone';

  @override
  String get homeInboxClear => 'All filed';

  @override
  String get homeInboxClearSubtitle => 'Nothing waiting to be sorted';

  @override
  String get homeInboxCountSubtitle => 'Screenshots you have not filed yet';

  @override
  String get homeStatScreenshots => 'Screenshots';

  @override
  String get homeStatFavorites => 'Favorites';

  @override
  String get homeStatFolders => 'Folders';

  @override
  String get homeToolsTitle => 'Tools';

  @override
  String get homeToolsTitleEmpty => 'Start here';

  @override
  String get homeToolSafeShare => 'Safe share';

  @override
  String get homeToolSafeShareSubtitle => 'Hide private details first';

  @override
  String get homeToolDuplicates => 'Find duplicates';

  @override
  String get homeToolDuplicatesSubtitle => 'Free up storage';

  @override
  String get homeToolSearch => 'Search inside';

  @override
  String get homeToolSearchSubtitle => 'Find text in your images';

  @override
  String get homeToolStitch => 'Merge long shots';

  @override
  String get homeToolStitchSubtitle => 'Join a scrolling capture';

  @override
  String get homeRecent => 'Recent';

  @override
  String get libraryPickForMerge => 'Pick two or more shots of the same page';

  @override
  String get libraryPickForProtect => 'Pick the screenshot to protect';

  @override
  String get libraryActionProtect => 'Protect';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get libraryEmptyTitle => 'Nothing saved yet';

  @override
  String get libraryEmptyMessage =>
      'Share a screenshot to SHOTO, or add one with the + button. Your gallery is never read — only what you hand over is kept.';

  @override
  String get libraryNoFavoritesTitle => 'No favorites yet';

  @override
  String get libraryNoFavoritesMessage =>
      'Tap the heart on a screenshot to save it here.';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterFavorites => 'Favorites';

  @override
  String get libraryTraitSensitive => 'Sensitive';

  @override
  String get libraryTraitLink => 'Links';

  @override
  String get libraryTraitContact => 'Phone or email';

  @override
  String get libraryTraitCode => 'Codes';

  @override
  String get libraryTraitEvent => 'Dates';

  @override
  String get libraryCertaintyVerified => 'Verified by checksum';

  @override
  String get libraryCertaintyRead => 'Read from the text in your screenshots';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count not read yet';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return 'No screenshots with $trait';
  }

  @override
  String get libraryNoTraitMessage =>
      'Every screenshot that has been read carries none of these.';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'Nothing found in what has been read. $count screenshots have never been read, so they can\'t be matched yet.';
  }

  @override
  String get libraryShowAll => 'Show all';

  @override
  String get libraryFilterUnsorted => 'Unsorted';

  @override
  String get libraryNoUnsortedTitle => 'Everything is filed';

  @override
  String get libraryNoUnsortedMessage =>
      'Nothing is waiting on you. New screenshots land here until you file or star them.';

  @override
  String librarySelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get librarySelectAll => 'Select all';

  @override
  String get libraryActionMerge => 'Merge';

  @override
  String get libraryActionMove => 'Move';

  @override
  String get libraryActionDelete => 'Delete';

  @override
  String get libraryDeleteTitle => 'Delete screenshots?';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This will permanently delete $count screenshots from your device.',
      one: 'This will permanently delete 1 screenshot from your device.',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'Photo access needed';

  @override
  String get permissionNeededMessage =>
      'SHOTO keeps the screenshots you share into it in their own album. It needs photo access to write there and read them back — it never lists the rest of your gallery.';

  @override
  String get permissionPartialTitle => 'Full photo access needed';

  @override
  String get permissionPartialMessage =>
      'SHOTO can currently only see a few photos you picked manually, so it cannot reach its own album. Choose \"Allow all\" in the photo permission to continue.';

  @override
  String get permissionOpenSettings => 'Open Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsGridDensity => 'Grid density';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Match my phone';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Now showing $language';
  }

  @override
  String get settingsBehaviour => 'Behaviour';

  @override
  String get settingsHaptics => 'Haptic feedback';

  @override
  String get settingsHapticsHint => 'A small tap when you press things';

  @override
  String get settingsConfirmDelete => 'Ask before deleting';

  @override
  String get settingsConfirmDeleteHint => 'Deleting cannot be undone';

  @override
  String get settingsFindDuplicates => 'Find duplicates';

  @override
  String get settingsClearCache => 'Clear image cache';

  @override
  String get settingsShare => 'Share SHOTO';

  @override
  String get settingsPrivacyNote =>
      'SHOTO never reads your gallery. It only holds the screenshots you share into it, and everything it does with them — reading text, finding duplicates — happens on this device. Nothing is ever uploaded.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonShare => 'Share';

  @override
  String get commonUnlock => 'Unlock';

  @override
  String get foldersEmptyTitle => 'No folders yet';

  @override
  String get foldersEmptyMessage =>
      'Folders are how you find things later. Make one for receipts, one for recipes — whatever you actually go looking for.';

  @override
  String get foldersNew => 'New folder';

  @override
  String get foldersCreate => 'Create folder';

  @override
  String get foldersNameLabel => 'Folder name';

  @override
  String get foldersNameHint => 'Receipts, Recipes, Work…';

  @override
  String get foldersPrivate => 'Private (face or fingerprint lock)';

  @override
  String get foldersPrivateFace => 'Private (face lock)';

  @override
  String get foldersPrivateFingerprint => 'Private (fingerprint lock)';

  @override
  String get foldersPrivateGeneric => 'Private (locked)';

  @override
  String get foldersOptions => 'Folder options';

  @override
  String get foldersDelete => 'Delete folder';

  @override
  String get foldersDeleteKept => 'Screenshots inside are kept';

  @override
  String foldersDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get foldersDeleteMessage =>
      'The folder is removed but the screenshots inside stay in your library.';

  @override
  String get foldersRenameTitle => 'Rename folder';

  @override
  String get foldersMoveTitle => 'Move to folder';

  @override
  String get foldersMoveRemove => 'Remove from folder';

  @override
  String get foldersMoveNone =>
      'No folders yet. Create one from the Folders tab.';

  @override
  String folderLockedTitle(String name) {
    return 'Unlock \"$name\"';
  }

  @override
  String get folderLockedMessage =>
      'This folder is protected. Authenticate to view it.';

  @override
  String get folderEmptyTitle => 'Nothing here yet';

  @override
  String get folderEmptyMessage =>
      'Move screenshots into this folder from your library.';

  @override
  String get detailFavorite => 'Favorite';

  @override
  String get detailUnfavorite => 'Remove from favorites';

  @override
  String get detailAddFavorite => 'Add to favorites';

  @override
  String get detailActions => 'Actions';

  @override
  String get detailSafeShare => 'Safe share';

  @override
  String get detailDeleteTitle => 'Delete screenshot?';

  @override
  String get detailDeleteMessage =>
      'This will permanently delete it from your device.';

  @override
  String get quickSaveTitleOne => 'Save to SHOTO';

  @override
  String quickSaveTitleMany(int count) {
    return 'Save $count screenshots';
  }

  @override
  String get quickSaveFileOne => 'File this screenshot';

  @override
  String quickSaveFileMany(int count) {
    return 'File $count screenshots';
  }

  @override
  String get quickSavePickFolder => 'Pick a folder';

  @override
  String get quickSaveNeedFolder => 'Make a folder to put them in';

  @override
  String quickSaveFileIn(String folder) {
    return 'File in $folder';
  }

  @override
  String get quickSaveCreateFirstFolder => 'Create your first folder';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'Folders are how you find things later';

  @override
  String get quickSaveNewChip => 'New';

  @override
  String get quickSaveSaved => 'Saved to SHOTO';

  @override
  String quickSaveFiled(String folder) {
    return 'Filed in $folder.';
  }

  @override
  String get quickSaveFailedTitle => 'Could not read that image';

  @override
  String get quickSaveFailedBody => 'Try sharing it again.';

  @override
  String quickSaveSkipped(int count) {
    return 'Only the first $count were taken';
  }

  @override
  String get dupTitle => 'Find duplicates';

  @override
  String get dupScanning => 'Looking for duplicates';

  @override
  String get dupReading => 'Reading your library…';

  @override
  String dupProgress(int done, int total) {
    return 'Checked $done of $total screenshots';
  }

  @override
  String get dupNoneTitle => 'No duplicates found';

  @override
  String get dupNoneBody => 'Your screenshot library is already clean.';

  @override
  String get dupScanAgain => 'Scan again';

  @override
  String dupReclaimable(String size) {
    return 'Up to $size can be freed';
  }

  @override
  String get dupNothingSelected => 'Nothing selected';

  @override
  String dupDeleteButton(int count, String size) {
    return 'Delete $count · free $size';
  }

  @override
  String dupDeleteTitle(int count) {
    return 'Delete $count copies?';
  }

  @override
  String get dupDeleteMessage =>
      'This permanently deletes them from your device. The copies marked to keep are not affected.';

  @override
  String dupDeleted(int count, String size) {
    return 'Deleted $count · freed $size';
  }

  @override
  String dupSets(int count) {
    return '$count sets';
  }

  @override
  String get dupBest => 'BEST';

  @override
  String get dupKeepAll => 'Keep all';

  @override
  String get dupKeepingAll => 'Keeping all — nothing will be deleted';

  @override
  String get dupUndo => 'Undo';

  @override
  String dupFrees(String size) {
    return 'Frees $size';
  }

  @override
  String get safeShareTitle => 'Safe share';

  @override
  String get safeShareScanning => 'Checking for private details';

  @override
  String get safeShareOnDevice => 'Reading happens on your phone.';

  @override
  String get safeShareCleanTitle => 'Nothing private found';

  @override
  String get safeShareCleanBody =>
      'No card numbers, account numbers, codes or contact details were spotted in this screenshot. You can share it as it is.';

  @override
  String get safeShareUnreadableTitle => 'Could not read this screenshot';

  @override
  String get safeShareUnreadableBody =>
      'The text in it could not be recognised.';

  @override
  String get safeShareShareUnchanged => 'Share unchanged';

  @override
  String get safeShareShareAnyway => 'Share anyway';

  @override
  String get safeShareShareProtected => 'Share protected copy';

  @override
  String get safeShareFailed => 'Could not build the protected copy.';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count private details found',
      one: '1 private detail found',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'Checking is always free.';

  @override
  String get safeShareCleanAction => 'Clean this screenshot';

  @override
  String get safeShareShareAsIs => 'Share without changes';

  @override
  String get safeShareHowTitle => 'Blocked out, for good';

  @override
  String get safeShareHowBody =>
      'Every private detail is covered with a solid block before the copy leaves your phone. Nothing is blurred and nothing can be read back — the covered copy is the only version that exists.';

  @override
  String get safeShareTreatmentCover => 'Cover';

  @override
  String get safeShareTreatmentKeep => 'Keep';

  @override
  String get safeShareBuilding => 'Building your clean copy';

  @override
  String get safeShareNothingSelected => 'Nothing will change';

  @override
  String get safeShareLockedPreview => 'Unlock to see the clean version';

  @override
  String get safeShareReviewTitle => 'Check each one';

  @override
  String safeShareFound(int count) {
    return '$count things covered';
  }

  @override
  String get stitchTitle => 'Merge screenshots';

  @override
  String get stitchWorking => 'Finding the overlap';

  @override
  String get stitchWorkingBody =>
      'Matching where each screenshot continues from the last.';

  @override
  String get stitchFailed => 'Could not merge';

  @override
  String get stitchSave => 'Save to gallery';

  @override
  String get stitchSaved => 'Saved to your gallery';

  @override
  String get stitchDiscard => 'Discard';

  @override
  String get commonDone => 'Done';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get searchTitle => 'Search your screenshots';

  @override
  String get searchHint => 'Search words or what a picture shows';

  @override
  String get searchIntro =>
      'Any word printed inside an image, or what the picture shows — try \"cat\", \"animal\", \"food\" or \"receipt\".';

  @override
  String get searchNoneTitle => 'No matches';

  @override
  String searchNoneBody(String query) {
    return 'Nothing here reads or looks like \"$query\".';
  }

  @override
  String get paywallTitle => 'Unlock SHOTO Pro';

  @override
  String get paywallSubtitle => 'Everything below, on one subscription.';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String paywallSave(int percent) {
    return 'Save $percent%';
  }

  @override
  String get paywallContinue => 'Continue';

  @override
  String get paywallUnavailable => 'Not available yet';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallLegal =>
      'Auto-renews until cancelled. Cancel anytime from your App Store or Google Play account settings. By continuing you agree to our Terms of Service and Privacy Policy.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'SHOTO Pro';

  @override
  String get subPremiumBody => 'Every feature unlocked for you.';

  @override
  String get subDevUnlock => 'Tester access';

  @override
  String get subDevUnlockBody =>
      'Unlocked on this device — not a real subscription';

  @override
  String get subUnlockEverything => 'Unlock everything';

  @override
  String get proWelcomeTitle => 'You are on Pro';

  @override
  String get proWelcomeBody =>
      'Every feature is unlocked. There is nothing else to set up.';

  @override
  String get proWelcomeAction => 'Start using it';

  @override
  String get featSafeShare => 'Safe share';

  @override
  String get featSafeShareBody =>
      'Swaps card numbers, addresses, names and contact details for realistic stand-ins — same length, same format, same place. The copy you send does not look edited.';

  @override
  String get featActions => 'Turn screenshots into actions';

  @override
  String get featActionsBody =>
      'Call a number, open a link, copy a verification code or an IBAN — straight from the picture, without retyping anything.';

  @override
  String get featDuplicates => 'Find duplicates';

  @override
  String get featDuplicatesBody =>
      'Spot near-identical shots you kept twice and clear them out — always with a review step first.';

  @override
  String get featStitch => 'Merge long screenshots';

  @override
  String get featStitchBody =>
      'Join a scrolling capture back into one tall image, with the overlap found and removed automatically.';

  @override
  String get featUnlimited => 'No ceiling on your library';

  @override
  String featUnlimitedBody(Object count) {
    return 'The free tier organizes $count screenshots. Pro takes the number away.';
  }

  @override
  String get featSafeShareHow =>
      'Finding what is private in a screenshot is free and unlimited. Paying is what turns those findings into a clean copy: each detail is redrawn in the screenshot\'s own colours as a different, equally ordinary value.';

  @override
  String get featSafeSharePoint1 =>
      'Card numbers are Luhn-checked and IBANs mod-97 checked — and the stand-ins pass the same checks, so nothing looks fabricated.';

  @override
  String get featSafeSharePoint2 =>
      'Also catches names, addresses, order numbers, verification codes, phone numbers and email addresses.';

  @override
  String get featSafeSharePoint3 =>
      'You see every change before you send, and can cover or keep any of them instead. The original screenshot is never touched.';

  @override
  String get featActionsHow =>
      'Whatever is written inside a screenshot becomes something you can use. SHOTO picks out the useful parts and puts a button on each one.';

  @override
  String get featActionsPoint1 =>
      'Phone numbers, links, email addresses, IBANs and verification codes are found for you.';

  @override
  String get featActionsPoint2 =>
      'One tap to call, open or copy — no reading digits off a picture.';

  @override
  String get featActionsPoint3 =>
      'Works on the screenshots you already have, not only on new ones.';

  @override
  String get featStitchHow =>
      'Take a few shots as you scroll through a long chat or page, and SHOTO works out where they overlap and joins them back into one tall image.';

  @override
  String get featStitchPoint1 =>
      'The repeated strip between two shots is found and removed automatically.';

  @override
  String get featStitchPoint2 =>
      'You see the join before anything is saved — automatic detection is good, but never certain.';

  @override
  String get featStitchPoint3 =>
      'The merged image saves to your gallery like any other picture.';

  @override
  String get featDuplicatesHow =>
      'SHOTO compares screenshots by what they look like rather than by name or size, so it catches the near-identical ones too — a resend, a different crop, the same thing captured twice.';

  @override
  String get featDuplicatesPoint1 =>
      'Groups whatever looks the same and suggests the copy worth keeping.';

  @override
  String get featDuplicatesPoint2 =>
      'Shows how much space each group frees before you decide anything.';

  @override
  String get featDuplicatesPoint3 =>
      'Nothing is deleted until you have reviewed the group and confirmed it.';

  @override
  String get featUnlimitedHow =>
      'The free tier is a real, usable app: saving, folders, favourites and full search, with no account and nothing uploaded. It has exactly one ceiling — how many screenshots it organizes — and Pro removes it. Everything you already organized stays exactly where it is.';

  @override
  String get featUnlimitedPoint1 =>
      'Folders are unlimited on the free tier, and always were meant to be.';

  @override
  String get featUnlimitedPoint2 =>
      'Naming what a screenshot is for is free and uncapped too.';

  @override
  String get featUnlimitedPoint3 =>
      'Hitting the ceiling means SHOTO became where you keep things. Nothing is deleted when you do.';

  @override
  String get includedSubtitle => 'Every Pro feature, explained.';

  @override
  String get includedHint => 'Tap a feature to see how it works';

  @override
  String get includedHowLabel => 'How it works';

  @override
  String get includedActiveTitle => 'Your plan is active';

  @override
  String get includedActiveBody =>
      'Everything below is unlocked on this account.';

  @override
  String get includedLockedTitle => 'Not unlocked yet';

  @override
  String get includedLockedBody =>
      'Read what each one actually does, then decide.';

  @override
  String get includedFreeTitle => 'What the free tier gives you';

  @override
  String includedFreeBody(int count) {
    return '$count organized screenshots, unlimited folders, and full search — free for good.';
  }

  @override
  String get onboardingCta => 'Get started';

  @override
  String get onboardingPromise => 'Everything stays on your phone.';

  @override
  String get actionsTitle => 'Actions';

  @override
  String get actionsWorking => 'Reading the screenshot';

  @override
  String get actionsWorkingBody => 'Looking for numbers, links and codes.';

  @override
  String get actionsNoneTitle => 'Nothing to act on';

  @override
  String get actionsNoneBody =>
      'No phone numbers, links, codes or account numbers were found in this screenshot.';

  @override
  String get actionsCopy => 'Copy';

  @override
  String get actionsCopied => 'Copied';

  @override
  String get actionsNoApp => 'No app on this device can do that.';

  @override
  String get devModeOn => 'Developer mode on — every feature unlocked';

  @override
  String get devModeBadge => 'DEVELOPER MODE';

  @override
  String get devModeOffTitle => 'Turn off developer mode?';

  @override
  String get devModeOffBody =>
      'SHOTO will go back to the free tier on this device, so you can test the paywall and the limits again.';

  @override
  String get devModeOffConfirm => 'Turn off';

  @override
  String get devAccessTitle => 'Developer access';

  @override
  String get devAccessBody =>
      'Enter the 4-digit code to unlock every Pro feature on this device.';

  @override
  String get devWrongCode => 'Wrong code';

  @override
  String devTapToDisable(int count) {
    return 'Tap $count× to turn off';
  }

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get kindCard => 'a card number';

  @override
  String get kindIban => 'a bank account';

  @override
  String get kindCode => 'a verification code';

  @override
  String get kindNationalId => 'an ID number';

  @override
  String get kindEmail => 'an email address';

  @override
  String get kindPhone => 'a phone number';

  @override
  String get kindLink => 'a link';

  @override
  String get actionCall => 'Call';

  @override
  String get actionWhatsapp => 'WhatsApp';

  @override
  String get actionSms => 'Message';

  @override
  String get actionEmailAction => 'Write';

  @override
  String get actionOpen => 'Open';

  @override
  String get kindEvent => 'an event';

  @override
  String get kindPlace => 'a place';

  @override
  String get kindWifi => 'a Wi-Fi network';

  @override
  String get kindTracking => 'a shipment';

  @override
  String get actionAddToCalendar => 'Add to calendar';

  @override
  String get actionOpenMaps => 'Open in Maps';

  @override
  String get actionDirections => 'Directions';

  @override
  String get actionCopyNetwork => 'Copy name';

  @override
  String get actionTrack => 'Track';

  @override
  String get actionEventUntitled => 'Event';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshots',
      one: '1 screenshot',
      zero: 'No screenshots',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$position of $total';
  }

  @override
  String countChip(String label, int count) {
    return '$label · $count';
  }

  @override
  String dupSetsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets of duplicates',
      one: '1 set of duplicates',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count similar copies';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things found',
      one: '1 thing found',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsDuplicatesHint => 'Spot screenshots you took twice';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'What is included';

  @override
  String settingsFeatureCount(int count) {
    return '$count features, one plan';
  }

  @override
  String get settingsShareHint => 'Tell someone who needs it';

  @override
  String get settingsShareText =>
      'SHOTO keeps my screenshots organized on their own — everything stays on the phone.';

  @override
  String get settingsCacheMeasuring => 'Measuring…';

  @override
  String settingsCacheSize(String size) {
    return '$size of thumbnails';
  }

  @override
  String get homeSafeShareHint => 'Open a screenshot, then tap Safe share.';

  @override
  String get homeStitchHint =>
      'Long-press two or more screenshots in your library, then tap Merge.';

  @override
  String stitchLimit(int count) {
    return 'Merge up to $count screenshots at a time.';
  }

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Screenshots saved. Add them to a folder?',
      one: 'Screenshot saved. Add it to a folder?',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count screenshots merged';
  }

  @override
  String stitchResultTrimmed(int count) {
    return '$count px of repeated content removed';
  }

  @override
  String get errorLoadScreenshots => 'Could not load your screenshots.';

  @override
  String get errorLoadFolders => 'Could not load your folders.';

  @override
  String get errorScanDuplicates => 'Could not scan for duplicates.';

  @override
  String get errorDeleteSelected =>
      'Could not delete the selected screenshots.';

  @override
  String get errorStitchFailed => 'These screenshots could not be merged.';

  @override
  String get errorStitchSave => 'The merged image could not be saved.';

  @override
  String get errorOnboarding => 'Could not load. Please reopen the app.';

  @override
  String get errorSignInCancelled => 'Sign-in was cancelled.';

  @override
  String get errorSignInInterrupted =>
      'Sign-in was interrupted. Please try again.';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorPlans => 'Could not load subscription plans.';

  @override
  String get errorPurchase => 'Purchase failed. Please try again.';

  @override
  String get errorNoSubscription =>
      'No active subscription found for this account.';

  @override
  String get errorRestore => 'Could not restore purchases.';

  @override
  String get errorStitchTooFew => 'Pick at least two screenshots to merge.';

  @override
  String errorStitchTooMany(int count) {
    return 'Up to $count screenshots can be merged at once.';
  }

  @override
  String get errorStitchUnreadable =>
      'One of the screenshots could not be read.';

  @override
  String get errorStitchWidths =>
      'These screenshots are different widths, so they cannot be part of the same scroll.';

  @override
  String get errorStitchNoOverlap =>
      'These screenshots do not overlap. Merging only works on shots of the same page taken while scrolling.';

  @override
  String get errorStitchOverlap =>
      'The overlap between these screenshots could not be resolved.';

  @override
  String get errorStitchTooTall =>
      'The merged image would be too tall. Try merging fewer screenshots.';

  @override
  String get errorStitchEncode => 'The merged image could not be encoded.';

  @override
  String get errorRedactionSave => 'The protected copy could not be saved.';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshots saved',
      one: 'Screenshot saved',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'Large';

  @override
  String get densityMedium => 'Medium';

  @override
  String get densitySmall => 'Small';

  @override
  String get sensitiveCard => 'Card number';

  @override
  String get sensitiveIban => 'Bank account';

  @override
  String get sensitiveCode => 'Verification code';

  @override
  String get sensitiveNationalId => 'ID number';

  @override
  String get sensitiveEmail => 'Email address';

  @override
  String get sensitivePhone => 'Phone number';

  @override
  String get sensitiveAddress => 'Address';

  @override
  String get sensitiveName => 'Name';

  @override
  String get sensitiveOrderNumber => 'Order number';

  @override
  String get sensitiveNumber => 'Number';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbPileTitle => 'A thousand screenshots, one pile';

  @override
  String get onbPileBody =>
      'You screenshot to remember. A week later it is buried under four hundred others.';

  @override
  String get onbChooseTitle => 'SHOTO never reads your gallery';

  @override
  String get onbChooseBody =>
      'Nothing arrives on its own. You share a screenshot in — that is the whole rule.';

  @override
  String get onbFileTitle => 'Filed the moment you send it';

  @override
  String get onbFileBody =>
      'Pick a folder right in the share sheet. The app does not even open.';

  @override
  String get onbFindTitle => 'Search what is inside them';

  @override
  String get onbFindBody =>
      'The words printed in a screenshot, and what the picture shows. Type “receipt”, or “dog”.';

  @override
  String get onbSafeShareTitle => 'The screenshot you can actually send';

  @override
  String get onbSafeShareBody =>
      'A card number becomes a different card number — same length, same place, still valid. Nobody can tell it was edited.';

  @override
  String get onbFolderExample => 'Receipts';

  @override
  String get onbSearchExample => 'receipt';

  @override
  String get importTitle => 'Add screenshots';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshots imported',
      one: '1 screenshot imported',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return '$imported of $picked imported';
  }

  @override
  String get importFailed => 'Could not save those screenshots';

  @override
  String get homeToolImportSubtitle =>
      'Pick from your phone — your gallery is never read';

  @override
  String get importPickerUnavailable => 'The photo picker could not open';

  @override
  String get searchWorking => 'Reading your screenshots…';

  @override
  String get settingsBackup => 'Back up & restore';

  @override
  String get settingsBackupHint => 'Keep a copy of your library in a file';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupIntro =>
      'Your library lives on this phone and nowhere else. A backup is the copy that survives losing it.';

  @override
  String get backupCreateTitle => 'Create a backup';

  @override
  String get backupCreateBody =>
      'Packs every screenshot, folder and label into one file, then lets you choose where to keep it.';

  @override
  String get backupCreateAction => 'Create backup';

  @override
  String get backupWorking => 'Packing your library…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Backed up $screenshots screenshots',
      one: 'Backed up 1 screenshot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders folders',
      one: '1 folder',
    );
    return '$_temp0 and $_temp1';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots screenshots',
      one: '1 screenshot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped could not be read',
      one: '1 could not be read',
    );
    return 'Backed up $_temp0. $_temp1.';
  }

  @override
  String get backupFailed => 'The backup could not be finished';

  @override
  String get backupPrivacyNote =>
      'The file is built on this phone and goes only where you send it. Nothing is uploaded.';

  @override
  String get restoreTitle => 'Restore a backup';

  @override
  String get restoreBody =>
      'Adds everything from a backup file to this library. Nothing already here is removed.';

  @override
  String get restoreAction => 'Restore';

  @override
  String get restoreWorking => 'Putting your library back…';

  @override
  String get restoreConfirmTitle => 'Restore this backup?';

  @override
  String get restoreConfirmMessage =>
      'Everything in the file is added to your library. Your current screenshots stay exactly as they are.';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Restored $screenshots screenshots',
      one: 'Restored 1 screenshot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders folders',
      one: '1 folder',
    );
    return '$_temp0 and $_temp1';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots screenshots',
      one: '1 screenshot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped were skipped',
      one: '1 was skipped',
    );
    return 'Restored $_temp0. $_temp1.';
  }

  @override
  String get restoreNotABackup => 'That file is not a SHOTO backup';

  @override
  String get restoreFailed => 'The restore could not be finished';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get supportSubject => 'SHOTO support';

  @override
  String get supportNoMailApp =>
      'No email app found. The address is copied instead.';

  @override
  String get supportGreeting => 'Hi SHOTO team,';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get dateThisWeek => 'Earlier this week';

  @override
  String get dateThisMonth => 'Earlier this month';

  @override
  String get librarySortNewest => 'Newest first';

  @override
  String get librarySortOldest => 'Oldest first';

  @override
  String get librarySortLabel => 'Order';

  @override
  String get libraryShowOnly => 'Show only';

  @override
  String get libraryShowEverything => 'Everything';

  @override
  String libraryScanPrompt(int count) {
    return 'Read $count screenshots';
  }

  @override
  String get libraryScanning => 'Reading…';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders already exist here',
      one: '1 folder already exists here',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'These names are in your library and in the backup. Same name does not always mean same folder, so this one is yours to decide.';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more',
      one: 'and 1 more',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'Put them together';

  @override
  String get restoreClashMergeBody =>
      'Screenshots go into the folders you already have.';

  @override
  String get restoreClashSeparate => 'Keep them apart';

  @override
  String get restoreClashSeparateBody =>
      'Makes a second folder with the same name. Nothing existing is touched.';

  @override
  String get intentBuy => 'Buy';

  @override
  String get intentRead => 'Read';

  @override
  String get intentReply => 'Reply';

  @override
  String get intentTry => 'Try';

  @override
  String get intentVisit => 'Visit';

  @override
  String get intentBuyWaiting => 'To buy';

  @override
  String get intentReadWaiting => 'To read';

  @override
  String get intentReplyWaiting => 'To reply';

  @override
  String get intentTryWaiting => 'To try';

  @override
  String get intentVisitWaiting => 'To visit';

  @override
  String get intentWatch => 'Watch';

  @override
  String get intentListen => 'Listen';

  @override
  String get intentCook => 'Cook';

  @override
  String get intentBook => 'Book';

  @override
  String get intentPay => 'Pay';

  @override
  String get intentSend => 'Send';

  @override
  String get intentDownload => 'Download';

  @override
  String get intentApply => 'Apply';

  @override
  String get intentCompare => 'Compare';

  @override
  String get intentFix => 'Fix';

  @override
  String get intentWatchWaiting => 'To watch';

  @override
  String get intentListenWaiting => 'To listen to';

  @override
  String get intentCookWaiting => 'To cook';

  @override
  String get intentBookWaiting => 'To book';

  @override
  String get intentPayWaiting => 'To pay';

  @override
  String get intentSendWaiting => 'To send';

  @override
  String get intentDownloadWaiting => 'To download';

  @override
  String get intentApplyWaiting => 'To apply for';

  @override
  String get intentCompareWaiting => 'To compare';

  @override
  String get intentFixWaiting => 'To fix';

  @override
  String get intentMore => 'More';

  @override
  String get intentSectionCommon => 'Ready-made';

  @override
  String get intentSectionYours => 'Yours';

  @override
  String get intentYoursEmpty =>
      'A verb you write yourself works exactly like the ones above.';

  @override
  String get intentNewAction => 'Write your own';

  @override
  String get intentNewTitle => 'Name it yourself';

  @override
  String get intentEditTitle => 'Edit this one';

  @override
  String get intentNameLabel => 'The verb';

  @override
  String get intentNameHint => 'Return it, cancel it, call them…';

  @override
  String get intentIconLabel => 'Icon';

  @override
  String intentDeleteTitle(String label) {
    return 'Delete \"$label\"?';
  }

  @override
  String get intentDeleteMessage =>
      'The screenshots stay where they are. They just stop waiting for anything.';

  @override
  String get intentSelectionAction => 'Mark as';

  @override
  String intentSelectionApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshots marked',
      one: '1 screenshot marked',
    );
    return '$_temp0';
  }

  @override
  String get intentPrompt => 'What will you do with it?';

  @override
  String get intentSkip => 'Nothing in particular';

  @override
  String get intentWaitingTitle => 'Waiting on you';

  @override
  String get intentNothingWaiting => 'Nothing waiting on you';

  @override
  String get intentAllDone =>
      'You have finished everything you saved for later.';

  @override
  String get intentMarkDone => 'Done';

  @override
  String get intentUndo => 'Put it back';

  @override
  String get intentDoneToast => 'Ticked off';

  @override
  String get intentChange => 'Change what this is for';

  @override
  String get intentClear => 'Not for anything';

  @override
  String intentEmptyOne(String verb) {
    return 'Nothing here to $verb';
  }

  @override
  String get intentEmptyBody =>
      'Screenshots you mark land here until you tick them off.';

  @override
  String intentDoneCount(int count) {
    return '$count finished';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }
}
