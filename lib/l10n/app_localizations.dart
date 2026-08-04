import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ur'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get commonPro;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get navFolders;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your screenshots, organized'**
  String get tagline;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// No description provided for @homeInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved'**
  String get homeInboxEmpty;

  /// No description provided for @homeInboxEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a screenshot into SHOTO to start'**
  String get homeInboxEmptySubtitle;

  /// No description provided for @homeInboxClear.
  ///
  /// In en, this message translates to:
  /// **'All filed'**
  String get homeInboxClear;

  /// No description provided for @homeInboxClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting to be sorted'**
  String get homeInboxClearSubtitle;

  /// No description provided for @homeInboxCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshots you have not filed yet'**
  String get homeInboxCountSubtitle;

  /// No description provided for @homeStatScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get homeStatScreenshots;

  /// No description provided for @homeStatFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get homeStatFavorites;

  /// No description provided for @homeStatFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get homeStatFolders;

  /// No description provided for @homeToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'What SHOTO can do'**
  String get homeToolsTitle;

  /// No description provided for @homeToolSafeShare.
  ///
  /// In en, this message translates to:
  /// **'Safe share'**
  String get homeToolSafeShare;

  /// No description provided for @homeToolSafeShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide private details first'**
  String get homeToolSafeShareSubtitle;

  /// No description provided for @homeToolDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Find duplicates'**
  String get homeToolDuplicates;

  /// No description provided for @homeToolDuplicatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free up storage'**
  String get homeToolDuplicatesSubtitle;

  /// No description provided for @homeToolSearch.
  ///
  /// In en, this message translates to:
  /// **'Search inside'**
  String get homeToolSearch;

  /// No description provided for @homeToolSearchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find text in your images'**
  String get homeToolSearchSubtitle;

  /// No description provided for @homeToolStitch.
  ///
  /// In en, this message translates to:
  /// **'Merge long shots'**
  String get homeToolStitch;

  /// No description provided for @homeToolStitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join a scrolling capture'**
  String get homeToolStitchSubtitle;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// No description provided for @libraryPickForMerge.
  ///
  /// In en, this message translates to:
  /// **'Pick two or more shots of the same page'**
  String get libraryPickForMerge;

  /// No description provided for @libraryPickForProtect.
  ///
  /// In en, this message translates to:
  /// **'Pick the screenshot to protect'**
  String get libraryPickForProtect;

  /// No description provided for @libraryActionProtect.
  ///
  /// In en, this message translates to:
  /// **'Protect'**
  String get libraryActionProtect;

  /// No description provided for @homeToolsTitleShort.
  ///
  /// In en, this message translates to:
  /// **'Do something'**
  String get homeToolsTitleShort;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Share a screenshot to SHOTO, or add one with the + button. Your gallery is never read — only what you hand over is kept.'**
  String get libraryEmptyMessage;

  /// No description provided for @libraryNoFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get libraryNoFavoritesTitle;

  /// No description provided for @libraryNoFavoritesMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a screenshot to save it here.'**
  String get libraryNoFavoritesMessage;

  /// No description provided for @libraryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryFilterAll;

  /// No description provided for @libraryFilterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFilterFavorites;

  /// No description provided for @libraryTraitSensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get libraryTraitSensitive;

  /// No description provided for @libraryTraitLink.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get libraryTraitLink;

  /// No description provided for @libraryTraitContact.
  ///
  /// In en, this message translates to:
  /// **'Phone or email'**
  String get libraryTraitContact;

  /// No description provided for @libraryTraitCode.
  ///
  /// In en, this message translates to:
  /// **'Codes'**
  String get libraryTraitCode;

  /// No description provided for @libraryTraitEvent.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get libraryTraitEvent;

  /// No description provided for @libraryCertaintyVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified by checksum'**
  String get libraryCertaintyVerified;

  /// No description provided for @libraryCertaintyRead.
  ///
  /// In en, this message translates to:
  /// **'Read from the text in your screenshots'**
  String get libraryCertaintyRead;

  /// No description provided for @libraryLensNoteWithUnread.
  ///
  /// In en, this message translates to:
  /// **'{basis} · {count} not read yet'**
  String libraryLensNoteWithUnread(String basis, int count);

  /// No description provided for @libraryNoTraitTitle.
  ///
  /// In en, this message translates to:
  /// **'No screenshots with {trait}'**
  String libraryNoTraitTitle(String trait);

  /// No description provided for @libraryNoTraitMessage.
  ///
  /// In en, this message translates to:
  /// **'Every screenshot that has been read carries none of these.'**
  String get libraryNoTraitMessage;

  /// No description provided for @libraryNoTraitUnreadMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing found in what has been read. {count} screenshots have never been read, so they can\'t be matched yet.'**
  String libraryNoTraitUnreadMessage(int count);

  /// No description provided for @libraryShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get libraryShowAll;

  /// No description provided for @libraryFilterUnsorted.
  ///
  /// In en, this message translates to:
  /// **'Unsorted'**
  String get libraryFilterUnsorted;

  /// No description provided for @libraryNoUnsortedTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything is filed'**
  String get libraryNoUnsortedTitle;

  /// No description provided for @libraryNoUnsortedMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting on you. New screenshots land here until you file or star them.'**
  String get libraryNoUnsortedMessage;

  /// No description provided for @librarySelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String librarySelectedCount(int count);

  /// No description provided for @librarySelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get librarySelectAll;

  /// No description provided for @libraryActionMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get libraryActionMerge;

  /// No description provided for @libraryActionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get libraryActionMove;

  /// No description provided for @libraryActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get libraryActionDelete;

  /// No description provided for @libraryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete screenshots?'**
  String get libraryDeleteTitle;

  /// No description provided for @libraryDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will permanently delete 1 screenshot from your device.} other{This will permanently delete {count} screenshots from your device.}}'**
  String libraryDeleteMessage(int count);

  /// No description provided for @permissionNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo access needed'**
  String get permissionNeededTitle;

  /// No description provided for @permissionNeededMessage.
  ///
  /// In en, this message translates to:
  /// **'SHOTO keeps the screenshots you share into it in their own album. It needs photo access to write there and read them back — it never lists the rest of your gallery.'**
  String get permissionNeededMessage;

  /// No description provided for @permissionPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Full photo access needed'**
  String get permissionPartialTitle;

  /// No description provided for @permissionPartialMessage.
  ///
  /// In en, this message translates to:
  /// **'SHOTO can currently only see a few photos you picked manually, so it cannot reach its own album. Choose \"Allow all\" in the photo permission to continue.'**
  String get permissionPartialMessage;

  /// No description provided for @permissionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionOpenSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsGridDensity.
  ///
  /// In en, this message translates to:
  /// **'Grid density'**
  String get settingsGridDensity;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Match my phone'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Now showing {language}'**
  String settingsLanguageSystemHint(String language);

  /// No description provided for @settingsBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get settingsBehaviour;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsHint.
  ///
  /// In en, this message translates to:
  /// **'A small tap when you press things'**
  String get settingsHapticsHint;

  /// No description provided for @settingsConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Ask before deleting'**
  String get settingsConfirmDelete;

  /// No description provided for @settingsConfirmDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Deleting cannot be undone'**
  String get settingsConfirmDeleteHint;

  /// No description provided for @settingsFindDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Find duplicates'**
  String get settingsFindDuplicates;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get settingsClearCache;

  /// No description provided for @settingsShare.
  ///
  /// In en, this message translates to:
  /// **'Share SHOTO'**
  String get settingsShare;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutTitle;

  /// No description provided for @settingsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'SHOTO never reads your gallery. It only holds the screenshots you share into it, and everything it does with them — reading text, finding duplicates — happens on this device. Nothing is ever uploaded.'**
  String get settingsPrivacyNote;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get commonUnlock;

  /// No description provided for @foldersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get foldersEmptyTitle;

  /// No description provided for @foldersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Folders are how you find things later. Make one for receipts, one for recipes — whatever you actually go looking for.'**
  String get foldersEmptyMessage;

  /// No description provided for @foldersNew.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get foldersNew;

  /// No description provided for @foldersCreate.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get foldersCreate;

  /// No description provided for @foldersNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get foldersNameLabel;

  /// No description provided for @foldersNameHint.
  ///
  /// In en, this message translates to:
  /// **'Receipts, Recipes, Work…'**
  String get foldersNameHint;

  /// No description provided for @foldersPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private (face or fingerprint lock)'**
  String get foldersPrivate;

  /// No description provided for @foldersPrivateFace.
  ///
  /// In en, this message translates to:
  /// **'Private (face lock)'**
  String get foldersPrivateFace;

  /// No description provided for @foldersPrivateFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Private (fingerprint lock)'**
  String get foldersPrivateFingerprint;

  /// No description provided for @foldersPrivateGeneric.
  ///
  /// In en, this message translates to:
  /// **'Private (locked)'**
  String get foldersPrivateGeneric;

  /// No description provided for @foldersOptions.
  ///
  /// In en, this message translates to:
  /// **'Folder options'**
  String get foldersOptions;

  /// No description provided for @foldersDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get foldersDelete;

  /// No description provided for @foldersDeleteKept.
  ///
  /// In en, this message translates to:
  /// **'Screenshots inside are kept'**
  String get foldersDeleteKept;

  /// No description provided for @foldersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String foldersDeleteTitle(String name);

  /// No description provided for @foldersDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The folder is removed but the screenshots inside stay in your library.'**
  String get foldersDeleteMessage;

  /// No description provided for @foldersRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get foldersRenameTitle;

  /// No description provided for @foldersMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get foldersMoveTitle;

  /// No description provided for @foldersMoveRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from folder'**
  String get foldersMoveRemove;

  /// No description provided for @foldersMoveNone.
  ///
  /// In en, this message translates to:
  /// **'No folders yet. Create one from the Folders tab.'**
  String get foldersMoveNone;

  /// No description provided for @folderLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock \"{name}\"'**
  String folderLockedTitle(String name);

  /// No description provided for @folderLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This folder is protected. Authenticate to view it.'**
  String get folderLockedMessage;

  /// No description provided for @folderEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get folderEmptyTitle;

  /// No description provided for @folderEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Move screenshots into this folder from your library.'**
  String get folderEmptyMessage;

  /// No description provided for @detailFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get detailFavorite;

  /// No description provided for @detailUnfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get detailUnfavorite;

  /// No description provided for @detailAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get detailAddFavorite;

  /// No description provided for @detailActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get detailActions;

  /// No description provided for @detailSafeShare.
  ///
  /// In en, this message translates to:
  /// **'Safe share'**
  String get detailSafeShare;

  /// No description provided for @detailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete screenshot?'**
  String get detailDeleteTitle;

  /// No description provided for @detailDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete it from your device.'**
  String get detailDeleteMessage;

  /// No description provided for @quickSaveTitleOne.
  ///
  /// In en, this message translates to:
  /// **'Save to SHOTO'**
  String get quickSaveTitleOne;

  /// No description provided for @quickSaveTitleMany.
  ///
  /// In en, this message translates to:
  /// **'Save {count} screenshots'**
  String quickSaveTitleMany(int count);

  /// No description provided for @quickSaveFileOne.
  ///
  /// In en, this message translates to:
  /// **'File this screenshot'**
  String get quickSaveFileOne;

  /// No description provided for @quickSaveFileMany.
  ///
  /// In en, this message translates to:
  /// **'File {count} screenshots'**
  String quickSaveFileMany(int count);

  /// No description provided for @quickSavePickFolder.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder'**
  String get quickSavePickFolder;

  /// No description provided for @quickSaveNeedFolder.
  ///
  /// In en, this message translates to:
  /// **'Make a folder to put them in'**
  String get quickSaveNeedFolder;

  /// No description provided for @quickSaveFileIn.
  ///
  /// In en, this message translates to:
  /// **'File in {folder}'**
  String quickSaveFileIn(String folder);

  /// No description provided for @quickSaveCreateFirstFolder.
  ///
  /// In en, this message translates to:
  /// **'Create your first folder'**
  String get quickSaveCreateFirstFolder;

  /// No description provided for @quickSaveCreateFirstFolderWhy.
  ///
  /// In en, this message translates to:
  /// **'Folders are how you find things later'**
  String get quickSaveCreateFirstFolderWhy;

  /// No description provided for @quickSaveNewChip.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get quickSaveNewChip;

  /// No description provided for @quickSaveSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to SHOTO'**
  String get quickSaveSaved;

  /// No description provided for @quickSaveFiled.
  ///
  /// In en, this message translates to:
  /// **'Filed in {folder}.'**
  String quickSaveFiled(String folder);

  /// No description provided for @quickSaveFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not read that image'**
  String get quickSaveFailedTitle;

  /// No description provided for @quickSaveFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Try sharing it again.'**
  String get quickSaveFailedBody;

  /// No description provided for @quickSaveSignedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to SHOTO first'**
  String get quickSaveSignedOutTitle;

  /// No description provided for @quickSaveSignedOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your library belongs to your account. Open SHOTO, sign in, then share this again.'**
  String get quickSaveSignedOutBody;

  /// No description provided for @quickSaveSkipped.
  ///
  /// In en, this message translates to:
  /// **'Only the first {count} were taken'**
  String quickSaveSkipped(int count);

  /// No description provided for @dupTitle.
  ///
  /// In en, this message translates to:
  /// **'Find duplicates'**
  String get dupTitle;

  /// No description provided for @dupScanning.
  ///
  /// In en, this message translates to:
  /// **'Looking for duplicates'**
  String get dupScanning;

  /// No description provided for @dupReading.
  ///
  /// In en, this message translates to:
  /// **'Reading your library…'**
  String get dupReading;

  /// No description provided for @dupProgress.
  ///
  /// In en, this message translates to:
  /// **'Checked {done} of {total} screenshots'**
  String dupProgress(int done, int total);

  /// No description provided for @dupNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No duplicates found'**
  String get dupNoneTitle;

  /// No description provided for @dupNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your screenshot library is already clean.'**
  String get dupNoneBody;

  /// No description provided for @dupScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get dupScanAgain;

  /// No description provided for @dupReclaimable.
  ///
  /// In en, this message translates to:
  /// **'Up to {size} can be freed'**
  String dupReclaimable(String size);

  /// No description provided for @dupNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Nothing selected'**
  String get dupNothingSelected;

  /// No description provided for @dupDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} · free {size}'**
  String dupDeleteButton(int count, String size);

  /// No description provided for @dupDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} copies?'**
  String dupDeleteTitle(int count);

  /// No description provided for @dupDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes them from your device. The copies marked to keep are not affected.'**
  String get dupDeleteMessage;

  /// No description provided for @dupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} · freed {size}'**
  String dupDeleted(int count, String size);

  /// No description provided for @dupSets.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String dupSets(int count);

  /// No description provided for @dupBest.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get dupBest;

  /// No description provided for @dupKeepAll.
  ///
  /// In en, this message translates to:
  /// **'Keep all'**
  String get dupKeepAll;

  /// No description provided for @dupKeepingAll.
  ///
  /// In en, this message translates to:
  /// **'Keeping all — nothing will be deleted'**
  String get dupKeepingAll;

  /// No description provided for @dupUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get dupUndo;

  /// No description provided for @dupFrees.
  ///
  /// In en, this message translates to:
  /// **'Frees {size}'**
  String dupFrees(String size);

  /// No description provided for @safeShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe share'**
  String get safeShareTitle;

  /// No description provided for @safeShareScanning.
  ///
  /// In en, this message translates to:
  /// **'Checking for private details'**
  String get safeShareScanning;

  /// No description provided for @safeShareOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Reading happens on your phone.'**
  String get safeShareOnDevice;

  /// No description provided for @safeShareCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing private found'**
  String get safeShareCleanTitle;

  /// No description provided for @safeShareCleanBody.
  ///
  /// In en, this message translates to:
  /// **'No card numbers, account numbers, codes or contact details were spotted in this screenshot. You can share it as it is.'**
  String get safeShareCleanBody;

  /// No description provided for @safeShareUnreadableTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not read this screenshot'**
  String get safeShareUnreadableTitle;

  /// No description provided for @safeShareUnreadableBody.
  ///
  /// In en, this message translates to:
  /// **'The text in it could not be recognised.'**
  String get safeShareUnreadableBody;

  /// No description provided for @safeShareShareUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Share unchanged'**
  String get safeShareShareUnchanged;

  /// No description provided for @safeShareShareAnyway.
  ///
  /// In en, this message translates to:
  /// **'Share anyway'**
  String get safeShareShareAnyway;

  /// No description provided for @safeShareShareProtected.
  ///
  /// In en, this message translates to:
  /// **'Share protected copy'**
  String get safeShareShareProtected;

  /// No description provided for @safeShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not build the protected copy.'**
  String get safeShareFailed;

  /// No description provided for @safeShareFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 private detail found} other{{count} private details found}}'**
  String safeShareFoundTitle(int count);

  /// No description provided for @safeShareFreeScan.
  ///
  /// In en, this message translates to:
  /// **'Checking is always free.'**
  String get safeShareFreeScan;

  /// No description provided for @safeShareCleanAction.
  ///
  /// In en, this message translates to:
  /// **'Clean this screenshot'**
  String get safeShareCleanAction;

  /// No description provided for @safeShareShareAsIs.
  ///
  /// In en, this message translates to:
  /// **'Share without changes'**
  String get safeShareShareAsIs;

  /// No description provided for @safeShareHowTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked out, for good'**
  String get safeShareHowTitle;

  /// No description provided for @safeShareHowBody.
  ///
  /// In en, this message translates to:
  /// **'Every private detail is covered with a solid block before the copy leaves your phone. Nothing is blurred and nothing can be read back — the covered copy is the only version that exists.'**
  String get safeShareHowBody;

  /// No description provided for @safeShareTreatmentCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get safeShareTreatmentCover;

  /// No description provided for @safeShareTreatmentKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get safeShareTreatmentKeep;

  /// No description provided for @safeShareBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building your clean copy'**
  String get safeShareBuilding;

  /// No description provided for @safeShareNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Nothing will change'**
  String get safeShareNothingSelected;

  /// No description provided for @safeShareLockedPreview.
  ///
  /// In en, this message translates to:
  /// **'Unlock to see the clean version'**
  String get safeShareLockedPreview;

  /// No description provided for @safeShareReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check each one'**
  String get safeShareReviewTitle;

  /// No description provided for @safeShareFound.
  ///
  /// In en, this message translates to:
  /// **'{count} things covered'**
  String safeShareFound(int count);

  /// No description provided for @stitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge screenshots'**
  String get stitchTitle;

  /// No description provided for @stitchWorking.
  ///
  /// In en, this message translates to:
  /// **'Finding the overlap'**
  String get stitchWorking;

  /// No description provided for @stitchWorkingBody.
  ///
  /// In en, this message translates to:
  /// **'Matching where each screenshot continues from the last.'**
  String get stitchWorkingBody;

  /// No description provided for @stitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not merge'**
  String get stitchFailed;

  /// No description provided for @stitchSave.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get stitchSave;

  /// No description provided for @stitchSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your gallery'**
  String get stitchSaved;

  /// No description provided for @stitchDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get stitchDiscard;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your screenshots'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search words or what a picture shows'**
  String get searchHint;

  /// No description provided for @searchIntro.
  ///
  /// In en, this message translates to:
  /// **'Any word printed inside an image, or what the picture shows — try \"cat\", \"animal\", \"food\" or \"receipt\".'**
  String get searchIntro;

  /// No description provided for @searchNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoneTitle;

  /// No description provided for @searchNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing here reads or looks like \"{query}\".'**
  String searchNoneBody(String query);

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock SHOTO Pro'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything below, on one subscription.'**
  String get paywallSubtitle;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallYearly;

  /// No description provided for @paywallSave.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywallSave(int percent);

  /// No description provided for @paywallContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paywallContinue;

  /// No description provided for @paywallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get paywallUnavailable;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestore;

  /// No description provided for @paywallLegal.
  ///
  /// In en, this message translates to:
  /// **'Auto-renews until cancelled. Cancel anytime from your App Store or Google Play account settings. By continuing you agree to our Terms of Service and Privacy Policy.'**
  String get paywallLegal;

  /// No description provided for @subPremiumBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get subPremiumBadge;

  /// No description provided for @subPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'SHOTO Pro'**
  String get subPremiumTitle;

  /// No description provided for @subPremiumBody.
  ///
  /// In en, this message translates to:
  /// **'Every feature unlocked for you.'**
  String get subPremiumBody;

  /// No description provided for @subDevUnlock.
  ///
  /// In en, this message translates to:
  /// **'Tester access'**
  String get subDevUnlock;

  /// No description provided for @subDevUnlockBody.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on this device — not a real subscription'**
  String get subDevUnlockBody;

  /// No description provided for @subUnlockEverything.
  ///
  /// In en, this message translates to:
  /// **'Unlock everything'**
  String get subUnlockEverything;

  /// No description provided for @proWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'You are on Pro'**
  String get proWelcomeTitle;

  /// No description provided for @proWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Every feature is unlocked. There is nothing else to set up.'**
  String get proWelcomeBody;

  /// No description provided for @proWelcomeAction.
  ///
  /// In en, this message translates to:
  /// **'Start using it'**
  String get proWelcomeAction;

  /// No description provided for @featSearch.
  ///
  /// In en, this message translates to:
  /// **'Search inside your screenshots'**
  String get featSearch;

  /// No description provided for @featSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Find any screenshot by the words written in it, in Arabic or English. Nothing is uploaded — the reading happens on your phone.'**
  String get featSearchBody;

  /// No description provided for @featSafeShare.
  ///
  /// In en, this message translates to:
  /// **'Safe share'**
  String get featSafeShare;

  /// No description provided for @featSafeShareBody.
  ///
  /// In en, this message translates to:
  /// **'Swaps card numbers, addresses, names and contact details for realistic stand-ins — same length, same format, same place. The copy you send does not look edited.'**
  String get featSafeShareBody;

  /// No description provided for @featActions.
  ///
  /// In en, this message translates to:
  /// **'Turn screenshots into actions'**
  String get featActions;

  /// No description provided for @featActionsBody.
  ///
  /// In en, this message translates to:
  /// **'Call a number, open a link, copy a verification code or an IBAN — straight from the picture, without retyping anything.'**
  String get featActionsBody;

  /// No description provided for @featDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Find duplicates'**
  String get featDuplicates;

  /// No description provided for @featDuplicatesBody.
  ///
  /// In en, this message translates to:
  /// **'Spot near-identical shots you kept twice and clear them out — always with a review step first.'**
  String get featDuplicatesBody;

  /// No description provided for @featStitch.
  ///
  /// In en, this message translates to:
  /// **'Merge long screenshots'**
  String get featStitch;

  /// No description provided for @featStitchBody.
  ///
  /// In en, this message translates to:
  /// **'Join a scrolling capture back into one tall image, with the overlap found and removed automatically.'**
  String get featStitchBody;

  /// No description provided for @featUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited folders and screenshots'**
  String get featUnlimited;

  /// No description provided for @featUnlimitedBody.
  ///
  /// In en, this message translates to:
  /// **'The free tier stops at a few folders and screenshots. Pro removes both caps.'**
  String get featUnlimitedBody;

  /// No description provided for @featSearchHow.
  ///
  /// In en, this message translates to:
  /// **'SHOTO reads the text printed inside every screenshot and remembers it, so one word you remember seeing is enough to find the picture again — no file names, no folders, no scrolling.'**
  String get featSearchHow;

  /// No description provided for @featSearchPoint1.
  ///
  /// In en, this message translates to:
  /// **'Reads Arabic and English, and still matches when the spelling differs slightly.'**
  String get featSearchPoint1;

  /// No description provided for @featSearchPoint2.
  ///
  /// In en, this message translates to:
  /// **'Also finds by what the picture shows — try \"receipt\", \"cat\" or \"food\".'**
  String get featSearchPoint2;

  /// No description provided for @featSearchPoint3.
  ///
  /// In en, this message translates to:
  /// **'The reading happens on your phone. Nothing is uploaded, so it works offline too.'**
  String get featSearchPoint3;

  /// No description provided for @featSafeShareHow.
  ///
  /// In en, this message translates to:
  /// **'Finding what is private in a screenshot is free and unlimited. Paying is what turns those findings into a clean copy: each detail is redrawn in the screenshot\'s own colours as a different, equally ordinary value.'**
  String get featSafeShareHow;

  /// No description provided for @featSafeSharePoint1.
  ///
  /// In en, this message translates to:
  /// **'Card numbers are Luhn-checked and IBANs mod-97 checked — and the stand-ins pass the same checks, so nothing looks fabricated.'**
  String get featSafeSharePoint1;

  /// No description provided for @featSafeSharePoint2.
  ///
  /// In en, this message translates to:
  /// **'Also catches names, addresses, order numbers, verification codes, phone numbers and email addresses.'**
  String get featSafeSharePoint2;

  /// No description provided for @featSafeSharePoint3.
  ///
  /// In en, this message translates to:
  /// **'You see every change before you send, and can cover or keep any of them instead. The original screenshot is never touched.'**
  String get featSafeSharePoint3;

  /// No description provided for @featActionsHow.
  ///
  /// In en, this message translates to:
  /// **'Whatever is written inside a screenshot becomes something you can use. SHOTO picks out the useful parts and puts a button on each one.'**
  String get featActionsHow;

  /// No description provided for @featActionsPoint1.
  ///
  /// In en, this message translates to:
  /// **'Phone numbers, links, email addresses, IBANs and verification codes are found for you.'**
  String get featActionsPoint1;

  /// No description provided for @featActionsPoint2.
  ///
  /// In en, this message translates to:
  /// **'One tap to call, open or copy — no reading digits off a picture.'**
  String get featActionsPoint2;

  /// No description provided for @featActionsPoint3.
  ///
  /// In en, this message translates to:
  /// **'Works on the screenshots you already have, not only on new ones.'**
  String get featActionsPoint3;

  /// No description provided for @featStitchHow.
  ///
  /// In en, this message translates to:
  /// **'Take a few shots as you scroll through a long chat or page, and SHOTO works out where they overlap and joins them back into one tall image.'**
  String get featStitchHow;

  /// No description provided for @featStitchPoint1.
  ///
  /// In en, this message translates to:
  /// **'The repeated strip between two shots is found and removed automatically.'**
  String get featStitchPoint1;

  /// No description provided for @featStitchPoint2.
  ///
  /// In en, this message translates to:
  /// **'You see the join before anything is saved — automatic detection is good, but never certain.'**
  String get featStitchPoint2;

  /// No description provided for @featStitchPoint3.
  ///
  /// In en, this message translates to:
  /// **'The merged image saves to your gallery like any other picture.'**
  String get featStitchPoint3;

  /// No description provided for @featDuplicatesHow.
  ///
  /// In en, this message translates to:
  /// **'SHOTO compares screenshots by what they look like rather than by name or size, so it catches the near-identical ones too — a resend, a different crop, the same thing captured twice.'**
  String get featDuplicatesHow;

  /// No description provided for @featDuplicatesPoint1.
  ///
  /// In en, this message translates to:
  /// **'Groups whatever looks the same and suggests the copy worth keeping.'**
  String get featDuplicatesPoint1;

  /// No description provided for @featDuplicatesPoint2.
  ///
  /// In en, this message translates to:
  /// **'Shows how much space each group frees before you decide anything.'**
  String get featDuplicatesPoint2;

  /// No description provided for @featDuplicatesPoint3.
  ///
  /// In en, this message translates to:
  /// **'Nothing is deleted until you have reviewed the group and confirmed it.'**
  String get featDuplicatesPoint3;

  /// No description provided for @featUnlimitedHow.
  ///
  /// In en, this message translates to:
  /// **'The free tier is a real, usable app rather than a trial — it just has a ceiling. Pro takes the ceiling off, and everything you already organized stays exactly where it is.'**
  String get featUnlimitedHow;

  /// No description provided for @featUnlimitedPoint1.
  ///
  /// In en, this message translates to:
  /// **'As many folders as your library actually needs.'**
  String get featUnlimitedPoint1;

  /// No description provided for @featUnlimitedPoint2.
  ///
  /// In en, this message translates to:
  /// **'No cap on how many screenshots you file and favourite.'**
  String get featUnlimitedPoint2;

  /// No description provided for @featUnlimitedPoint3.
  ///
  /// In en, this message translates to:
  /// **'Saving, folders, favourites and search history stay yours either way.'**
  String get featUnlimitedPoint3;

  /// No description provided for @includedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every Pro feature, explained.'**
  String get includedSubtitle;

  /// No description provided for @includedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a feature to see how it works'**
  String get includedHint;

  /// No description provided for @includedHowLabel.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get includedHowLabel;

  /// No description provided for @includedActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan is active'**
  String get includedActiveTitle;

  /// No description provided for @includedActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Everything below is unlocked on this account.'**
  String get includedActiveBody;

  /// No description provided for @includedLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not unlocked yet'**
  String get includedLockedTitle;

  /// No description provided for @includedLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Read what each one actually does, then decide.'**
  String get includedLockedBody;

  /// No description provided for @includedFreeTitle.
  ///
  /// In en, this message translates to:
  /// **'What the free tier gives you'**
  String get includedFreeTitle;

  /// No description provided for @includedFreeBody.
  ///
  /// In en, this message translates to:
  /// **'{folders} folders and {count} organized screenshots — plus saving, favourites and the gallery, free for good.'**
  String includedFreeBody(int folders, int count);

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SHOTO'**
  String get authWelcome;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save, organize and find every screenshot in one place.'**
  String get authSubtitle;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogle;

  /// No description provided for @authApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authApple;

  /// No description provided for @authLegal.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy.'**
  String get authLegal;

  /// No description provided for @onboardingCta.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingCta;

  /// No description provided for @onboardingPromise.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your phone.'**
  String get onboardingPromise;

  /// No description provided for @actionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsTitle;

  /// No description provided for @actionsWorking.
  ///
  /// In en, this message translates to:
  /// **'Reading the screenshot'**
  String get actionsWorking;

  /// No description provided for @actionsWorkingBody.
  ///
  /// In en, this message translates to:
  /// **'Looking for numbers, links and codes.'**
  String get actionsWorkingBody;

  /// No description provided for @actionsNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to act on'**
  String get actionsNoneTitle;

  /// No description provided for @actionsNoneBody.
  ///
  /// In en, this message translates to:
  /// **'No phone numbers, links, codes or account numbers were found in this screenshot.'**
  String get actionsNoneBody;

  /// No description provided for @actionsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionsCopy;

  /// No description provided for @actionsCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get actionsCopied;

  /// No description provided for @actionsNoApp.
  ///
  /// In en, this message translates to:
  /// **'No app on this device can do that.'**
  String get actionsNoApp;

  /// No description provided for @devModeOn.
  ///
  /// In en, this message translates to:
  /// **'Developer mode on — every feature unlocked'**
  String get devModeOn;

  /// No description provided for @devModeBadge.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER MODE'**
  String get devModeBadge;

  /// No description provided for @devModeOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off developer mode?'**
  String get devModeOffTitle;

  /// No description provided for @devModeOffBody.
  ///
  /// In en, this message translates to:
  /// **'SHOTO will go back to the free tier on this device, so you can test the paywall and the limits again.'**
  String get devModeOffBody;

  /// No description provided for @devModeOffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get devModeOffConfirm;

  /// No description provided for @devAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer access'**
  String get devAccessTitle;

  /// No description provided for @devAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code to unlock every Pro feature on this device.'**
  String get devAccessBody;

  /// No description provided for @devWrongCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong code'**
  String get devWrongCode;

  /// No description provided for @devTapToDisable.
  ///
  /// In en, this message translates to:
  /// **'Tap {count}× to turn off'**
  String devTapToDisable(int count);

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @kindCard.
  ///
  /// In en, this message translates to:
  /// **'a card number'**
  String get kindCard;

  /// No description provided for @kindIban.
  ///
  /// In en, this message translates to:
  /// **'a bank account'**
  String get kindIban;

  /// No description provided for @kindCode.
  ///
  /// In en, this message translates to:
  /// **'a verification code'**
  String get kindCode;

  /// No description provided for @kindNationalId.
  ///
  /// In en, this message translates to:
  /// **'an ID number'**
  String get kindNationalId;

  /// No description provided for @kindEmail.
  ///
  /// In en, this message translates to:
  /// **'an email address'**
  String get kindEmail;

  /// No description provided for @kindPhone.
  ///
  /// In en, this message translates to:
  /// **'a phone number'**
  String get kindPhone;

  /// No description provided for @kindLink.
  ///
  /// In en, this message translates to:
  /// **'a link'**
  String get kindLink;

  /// No description provided for @actionCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get actionCall;

  /// No description provided for @actionWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get actionWhatsapp;

  /// No description provided for @actionSms.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get actionSms;

  /// No description provided for @actionEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get actionEmailAction;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @kindEvent.
  ///
  /// In en, this message translates to:
  /// **'an event'**
  String get kindEvent;

  /// No description provided for @kindPlace.
  ///
  /// In en, this message translates to:
  /// **'a place'**
  String get kindPlace;

  /// No description provided for @kindWifi.
  ///
  /// In en, this message translates to:
  /// **'a Wi-Fi network'**
  String get kindWifi;

  /// No description provided for @kindTracking.
  ///
  /// In en, this message translates to:
  /// **'a shipment'**
  String get kindTracking;

  /// No description provided for @actionAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get actionAddToCalendar;

  /// No description provided for @actionOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get actionOpenMaps;

  /// No description provided for @actionDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get actionDirections;

  /// No description provided for @actionCopyNetwork.
  ///
  /// In en, this message translates to:
  /// **'Copy name'**
  String get actionCopyNetwork;

  /// No description provided for @actionTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get actionTrack;

  /// No description provided for @actionEventUntitled.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get actionEventUntitled;

  /// No description provided for @countScreenshots.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No screenshots} =1{1 screenshot} other{{count} screenshots}}'**
  String countScreenshots(int count);

  /// No description provided for @countPosition.
  ///
  /// In en, this message translates to:
  /// **'{position} of {total}'**
  String countPosition(int position, int total);

  /// No description provided for @countChip.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count}'**
  String countChip(String label, int count);

  /// No description provided for @dupSetsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set of duplicates} other{{count} sets of duplicates}}'**
  String dupSetsFound(int count);

  /// No description provided for @dupSimilarCopies.
  ///
  /// In en, this message translates to:
  /// **'{count} similar copies'**
  String dupSimilarCopies(int count);

  /// No description provided for @safeShareFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing found} other{{count} things found}}'**
  String safeShareFoundCount(int count);

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsDuplicatesHint.
  ///
  /// In en, this message translates to:
  /// **'Spot screenshots you took twice'**
  String get settingsDuplicatesHint;

  /// No description provided for @settingsPremium.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get settingsPremium;

  /// No description provided for @settingsWhatsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What is included'**
  String get settingsWhatsIncluded;

  /// No description provided for @settingsFeatureCount.
  ///
  /// In en, this message translates to:
  /// **'{count} features, one plan'**
  String settingsFeatureCount(int count);

  /// No description provided for @settingsShareHint.
  ///
  /// In en, this message translates to:
  /// **'Tell someone who needs it'**
  String get settingsShareHint;

  /// No description provided for @settingsShareText.
  ///
  /// In en, this message translates to:
  /// **'SHOTO keeps my screenshots organized on their own — everything stays on the phone.'**
  String get settingsShareText;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSignOutHint.
  ///
  /// In en, this message translates to:
  /// **'Your screenshots stay on this device'**
  String get settingsSignOutHint;

  /// No description provided for @settingsCacheMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring…'**
  String get settingsCacheMeasuring;

  /// No description provided for @settingsCacheSize.
  ///
  /// In en, this message translates to:
  /// **'{size} of thumbnails'**
  String settingsCacheSize(String size);

  /// No description provided for @homeSafeShareHint.
  ///
  /// In en, this message translates to:
  /// **'Open a screenshot, then tap Safe share.'**
  String get homeSafeShareHint;

  /// No description provided for @homeStitchHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press two or more screenshots in your library, then tap Merge.'**
  String get homeStitchHint;

  /// No description provided for @stitchLimit.
  ///
  /// In en, this message translates to:
  /// **'Merge up to {count} screenshots at a time.'**
  String stitchLimit(int count);

  /// No description provided for @shareSavedPrompt.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Screenshot saved. Add it to a folder?} other{Screenshots saved. Add them to a folder?}}'**
  String shareSavedPrompt(int count);

  /// No description provided for @stitchResultMerged.
  ///
  /// In en, this message translates to:
  /// **'{count} screenshots merged'**
  String stitchResultMerged(int count);

  /// No description provided for @stitchResultTrimmed.
  ///
  /// In en, this message translates to:
  /// **'{count} px of repeated content removed'**
  String stitchResultTrimmed(int count);

  /// No description provided for @errorLoadScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Could not load your screenshots.'**
  String get errorLoadScreenshots;

  /// No description provided for @errorLoadFolders.
  ///
  /// In en, this message translates to:
  /// **'Could not load your folders.'**
  String get errorLoadFolders;

  /// No description provided for @errorScanDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Could not scan for duplicates.'**
  String get errorScanDuplicates;

  /// No description provided for @errorDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the selected screenshots.'**
  String get errorDeleteSelected;

  /// No description provided for @errorStitchFailed.
  ///
  /// In en, this message translates to:
  /// **'These screenshots could not be merged.'**
  String get errorStitchFailed;

  /// No description provided for @errorStitchSave.
  ///
  /// In en, this message translates to:
  /// **'The merged image could not be saved.'**
  String get errorStitchSave;

  /// No description provided for @errorOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Please reopen the app.'**
  String get errorOnboarding;

  /// No description provided for @errorSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get errorSignInCancelled;

  /// No description provided for @errorSignInInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was interrupted. Please try again.'**
  String get errorSignInInterrupted;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorPlans.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription plans.'**
  String get errorPlans;

  /// No description provided for @errorPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get errorPurchase;

  /// No description provided for @errorNoSubscription.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found for this account.'**
  String get errorNoSubscription;

  /// No description provided for @errorRestore.
  ///
  /// In en, this message translates to:
  /// **'Could not restore purchases.'**
  String get errorRestore;

  /// No description provided for @errorStitchTooFew.
  ///
  /// In en, this message translates to:
  /// **'Pick at least two screenshots to merge.'**
  String get errorStitchTooFew;

  /// No description provided for @errorStitchTooMany.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} screenshots can be merged at once.'**
  String errorStitchTooMany(int count);

  /// No description provided for @errorStitchUnreadable.
  ///
  /// In en, this message translates to:
  /// **'One of the screenshots could not be read.'**
  String get errorStitchUnreadable;

  /// No description provided for @errorStitchWidths.
  ///
  /// In en, this message translates to:
  /// **'These screenshots are different widths, so they cannot be part of the same scroll.'**
  String get errorStitchWidths;

  /// No description provided for @errorStitchNoOverlap.
  ///
  /// In en, this message translates to:
  /// **'These screenshots do not overlap. Merging only works on shots of the same page taken while scrolling.'**
  String get errorStitchNoOverlap;

  /// No description provided for @errorStitchOverlap.
  ///
  /// In en, this message translates to:
  /// **'The overlap between these screenshots could not be resolved.'**
  String get errorStitchOverlap;

  /// No description provided for @errorStitchTooTall.
  ///
  /// In en, this message translates to:
  /// **'The merged image would be too tall. Try merging fewer screenshots.'**
  String get errorStitchTooTall;

  /// No description provided for @errorStitchEncode.
  ///
  /// In en, this message translates to:
  /// **'The merged image could not be encoded.'**
  String get errorStitchEncode;

  /// No description provided for @errorRedactionSave.
  ///
  /// In en, this message translates to:
  /// **'The protected copy could not be saved.'**
  String get errorRedactionSave;

  /// No description provided for @shareSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Screenshot saved} other{{count} screenshots saved}}'**
  String shareSavedCount(int count);

  /// No description provided for @densityLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get densityLarge;

  /// No description provided for @densityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get densityMedium;

  /// No description provided for @densitySmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get densitySmall;

  /// No description provided for @sensitiveCard.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get sensitiveCard;

  /// No description provided for @sensitiveIban.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get sensitiveIban;

  /// No description provided for @sensitiveCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get sensitiveCode;

  /// No description provided for @sensitiveNationalId.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get sensitiveNationalId;

  /// No description provided for @sensitiveEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get sensitiveEmail;

  /// No description provided for @sensitivePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get sensitivePhone;

  /// No description provided for @sensitiveAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get sensitiveAddress;

  /// No description provided for @sensitiveName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sensitiveName;

  /// No description provided for @sensitiveOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get sensitiveOrderNumber;

  /// No description provided for @sensitiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get sensitiveNumber;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbPileTitle.
  ///
  /// In en, this message translates to:
  /// **'A thousand screenshots, one pile'**
  String get onbPileTitle;

  /// No description provided for @onbPileBody.
  ///
  /// In en, this message translates to:
  /// **'You screenshot to remember. A week later it is buried under four hundred others.'**
  String get onbPileBody;

  /// No description provided for @onbChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'SHOTO never reads your gallery'**
  String get onbChooseTitle;

  /// No description provided for @onbChooseBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing arrives on its own. You share a screenshot in — that is the whole rule.'**
  String get onbChooseBody;

  /// No description provided for @onbFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Filed the moment you send it'**
  String get onbFileTitle;

  /// No description provided for @onbFileBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a folder right in the share sheet. The app does not even open.'**
  String get onbFileBody;

  /// No description provided for @onbFindTitle.
  ///
  /// In en, this message translates to:
  /// **'Search what is inside them'**
  String get onbFindTitle;

  /// No description provided for @onbFindBody.
  ///
  /// In en, this message translates to:
  /// **'The words printed in a screenshot, and what the picture shows. Type “receipt”, or “dog”.'**
  String get onbFindBody;

  /// No description provided for @onbProTitle.
  ///
  /// In en, this message translates to:
  /// **'SHOTO Pro'**
  String get onbProTitle;

  /// No description provided for @onbProBody.
  ///
  /// In en, this message translates to:
  /// **'Rules file new screenshots for you, and everything below comes with them.'**
  String get onbProBody;

  /// No description provided for @onbProMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String onbProMore(int count);

  /// No description provided for @onbFolderExample.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get onbFolderExample;

  /// No description provided for @onbSearchExample.
  ///
  /// In en, this message translates to:
  /// **'receipt'**
  String get onbSearchExample;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Add screenshots'**
  String get importTitle;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 screenshot imported} other{{count} screenshots imported}}'**
  String importDone(int count);

  /// No description provided for @importPartial.
  ///
  /// In en, this message translates to:
  /// **'{imported} of {picked} imported'**
  String importPartial(int imported, int picked);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save those screenshots'**
  String get importFailed;

  /// No description provided for @homeToolImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick from your phone — your gallery is never read'**
  String get homeToolImportSubtitle;

  /// No description provided for @importPickerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The photo picker could not open'**
  String get importPickerUnavailable;

  /// No description provided for @searchWorking.
  ///
  /// In en, this message translates to:
  /// **'Reading your screenshots…'**
  String get searchWorking;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Back up & restore'**
  String get settingsBackup;

  /// No description provided for @settingsBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Keep a copy of your library in a file'**
  String get settingsBackupHint;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @backupIntro.
  ///
  /// In en, this message translates to:
  /// **'Your library lives on this phone and nowhere else. A backup is the copy that survives losing it.'**
  String get backupIntro;

  /// No description provided for @backupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a backup'**
  String get backupCreateTitle;

  /// No description provided for @backupCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Packs every screenshot, folder and label into one file, then lets you choose where to keep it.'**
  String get backupCreateBody;

  /// No description provided for @backupCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backupCreateAction;

  /// No description provided for @backupWorking.
  ///
  /// In en, this message translates to:
  /// **'Packing your library…'**
  String get backupWorking;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'{screenshots, plural, =1{Backed up 1 screenshot} other{Backed up {screenshots} screenshots}} and {folders, plural, =1{1 folder} other{{folders} folders}}'**
  String backupDone(int screenshots, int folders);

  /// No description provided for @backupDoneWithSkips.
  ///
  /// In en, this message translates to:
  /// **'Backed up {screenshots, plural, =1{1 screenshot} other{{screenshots} screenshots}}. {skipped, plural, =1{1 could not be read} other{{skipped} could not be read}}.'**
  String backupDoneWithSkips(int screenshots, int skipped);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup could not be finished'**
  String get backupFailed;

  /// No description provided for @backupPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'The file is built on this phone and goes only where you send it. Nothing is uploaded.'**
  String get backupPrivacyNote;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get restoreTitle;

  /// No description provided for @restoreBody.
  ///
  /// In en, this message translates to:
  /// **'Adds everything from a backup file to this library. Nothing already here is removed.'**
  String get restoreBody;

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @restoreWorking.
  ///
  /// In en, this message translates to:
  /// **'Putting your library back…'**
  String get restoreWorking;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Everything in the file is added to your library. Your current screenshots stay exactly as they are.'**
  String get restoreConfirmMessage;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'{screenshots, plural, =1{Restored 1 screenshot} other{Restored {screenshots} screenshots}} and {folders, plural, =1{1 folder} other{{folders} folders}}'**
  String restoreDone(int screenshots, int folders);

  /// No description provided for @restoreDoneWithSkips.
  ///
  /// In en, this message translates to:
  /// **'Restored {screenshots, plural, =1{1 screenshot} other{{screenshots} screenshots}}. {skipped, plural, =1{1 was skipped} other{{skipped} were skipped}}.'**
  String restoreDoneWithSkips(int screenshots, int skipped);

  /// No description provided for @restoreNotABackup.
  ///
  /// In en, this message translates to:
  /// **'That file is not a SHOTO backup'**
  String get restoreNotABackup;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'The restore could not be finished'**
  String get restoreFailed;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get settingsContactSupport;

  /// No description provided for @supportSubject.
  ///
  /// In en, this message translates to:
  /// **'SHOTO support'**
  String get supportSubject;

  /// No description provided for @supportNoMailApp.
  ///
  /// In en, this message translates to:
  /// **'No email app found. The address is copied instead.'**
  String get supportNoMailApp;

  /// No description provided for @supportGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi SHOTO team,'**
  String get supportGreeting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fr',
    'hi',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
