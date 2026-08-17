import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
    Locale('pt'),
  ];

  /// No description provided for @settingsCrashReports.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get settingsCrashReports;

  /// No description provided for @settingsCrashReportsHint.
  ///
  /// In en, this message translates to:
  /// **'Send technical details when something goes wrong'**
  String get settingsCrashReportsHint;

  /// No description provided for @settingsOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Replay the introduction'**
  String get settingsOnboarding;

  /// No description provided for @settingsOnboardingHint.
  ///
  /// In en, this message translates to:
  /// **'Watch the opening sequence again'**
  String get settingsOnboardingHint;

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

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Shoto'**
  String get authWelcome;

  /// No description provided for @authWhy.
  ///
  /// In en, this message translates to:
  /// **'Not everything you save deserves the same shelf. Shoto gives the screenshots you actually care about a place of their own.'**
  String get authWhy;

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

  /// No description provided for @settingsSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get settingsSignIn;

  /// No description provided for @settingsSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Only needed to move a purchase to another phone.'**
  String get settingsSignInHint;

  /// No description provided for @paywallTrialCta.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Start 1 day free} other{Start {days} days free}}'**
  String paywallTrialCta(int days);

  /// No description provided for @paywallTrialNote.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Free for a day, then {price}. Cancel any time before it ends.} other{Free for {days} days, then {price}. Cancel any time before it ends.}}'**
  String paywallTrialNote(int days, String price);

  /// No description provided for @triageTitle.
  ///
  /// In en, this message translates to:
  /// **'Since you last looked'**
  String get triageTitle;

  /// No description provided for @triageBody.
  ///
  /// In en, this message translates to:
  /// **'Keep what belongs in Shoto. Everything else stays exactly where it is.'**
  String get triageBody;

  /// No description provided for @triageKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get triageKeep;

  /// No description provided for @triageSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get triageSkip;

  /// No description provided for @triageFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get triageFinish;

  /// No description provided for @triageProgress.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String triageProgress(int index, int total);

  /// No description provided for @triageNewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new screenshot} other{{count} new screenshots}}'**
  String triageNewCount(int count);

  /// No description provided for @triageKept.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing kept} =1{1 kept} other{{count} kept}}'**
  String triageKept(int count);

  /// No description provided for @triageReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get triageReview;

  /// No description provided for @triageInviteDecline.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get triageInviteDecline;

  /// No description provided for @triageInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Show new screenshots here?'**
  String get triageInviteTitle;

  /// No description provided for @triageInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Shoto can list what you capture from now on, so you can keep the few that matter. Nothing joins your library until you say so.'**
  String get triageInviteBody;

  /// No description provided for @triageInviteAccept.
  ///
  /// In en, this message translates to:
  /// **'Show them'**
  String get triageInviteAccept;

  /// No description provided for @triageInviteDismiss.
  ///
  /// In en, this message translates to:
  /// **'No thanks'**
  String get triageInviteDismiss;

  /// No description provided for @settingsTriage.
  ///
  /// In en, this message translates to:
  /// **'Offer new screenshots'**
  String get settingsTriage;

  /// No description provided for @settingsTriageHint.
  ///
  /// In en, this message translates to:
  /// **'Shows what you capture; keeps nothing on its own'**
  String get settingsTriageHint;

  /// No description provided for @settingsCaptureAlerts.
  ///
  /// In en, this message translates to:
  /// **'Notify me right away'**
  String get settingsCaptureAlerts;

  /// No description provided for @settingsCaptureAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'A quiet notification right after you take one'**
  String get settingsCaptureAlertsHint;

  /// No description provided for @settingsCaptureAlertsMuted.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Shoto — turn them on in your phone\'s settings'**
  String get settingsCaptureAlertsMuted;

  /// No description provided for @settingsCaptureAlertsStopped.
  ///
  /// In en, this message translates to:
  /// **'Android stopped the checks. Open Shoto once to start them again'**
  String get settingsCaptureAlertsStopped;

  /// No description provided for @settingsCaptureAlertsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Watching. Nothing captured yet'**
  String get settingsCaptureAlertsWaiting;

  /// No description provided for @settingsCaptureAlertsLastRun.
  ///
  /// In en, this message translates to:
  /// **'Last checked {when}'**
  String settingsCaptureAlertsLastRun(String when);

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String timeAgoDays(int count);

  /// No description provided for @settingsQuickTile.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings tile'**
  String get settingsQuickTile;

  /// No description provided for @settingsQuickTileHint.
  ///
  /// In en, this message translates to:
  /// **'Save your last screenshot without opening the share sheet'**
  String get settingsQuickTileHint;

  /// No description provided for @settingsQuickTileAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to Quick Settings'**
  String get settingsQuickTileAdded;

  /// No description provided for @settingsQuickTileManual.
  ///
  /// In en, this message translates to:
  /// **'Add it by hand: pull down Quick Settings, tap edit, then drag the Shoto tile in.'**
  String get settingsQuickTileManual;

  /// No description provided for @settingsQuickTileSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Two swipes, from any app'**
  String get settingsQuickTileSheetTitle;

  /// No description provided for @settingsQuickTileSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Shoto can sit in your phone\'s Quick Settings, beside the torch. One tap files the screenshot you just took — no app to open, no share sheet to scroll.'**
  String get settingsQuickTileSheetBody;

  /// No description provided for @settingsQuickTileStepPull.
  ///
  /// In en, this message translates to:
  /// **'Swipe down from the top of any screen'**
  String get settingsQuickTileStepPull;

  /// No description provided for @settingsQuickTileStepTap.
  ///
  /// In en, this message translates to:
  /// **'Tap the Shoto tile — your last screenshot is filed'**
  String get settingsQuickTileStepTap;

  /// No description provided for @settingsQuickTileStepStays.
  ///
  /// In en, this message translates to:
  /// **'It stays in the same square, unlike the share sheet'**
  String get settingsQuickTileStepStays;

  /// No description provided for @settingsQuickTileAdd.
  ///
  /// In en, this message translates to:
  /// **'Add the tile'**
  String get settingsQuickTileAdd;

  /// No description provided for @settingsQuickTileNote.
  ///
  /// In en, this message translates to:
  /// **'Reads only the screenshot you just took. Nothing leaves your phone.'**
  String get settingsQuickTileNote;

  /// No description provided for @folderIconsBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get folderIconsBasics;

  /// No description provided for @folderIconsWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get folderIconsWork;

  /// No description provided for @folderIconsMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get folderIconsMoney;

  /// No description provided for @folderIconsTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get folderIconsTravel;

  /// No description provided for @folderIconsHome.
  ///
  /// In en, this message translates to:
  /// **'Home & health'**
  String get folderIconsHome;

  /// No description provided for @folderIconsMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get folderIconsMedia;

  /// No description provided for @folderIconsPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get folderIconsPeople;

  /// No description provided for @folderIconsSymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get folderIconsSymbols;

  /// No description provided for @folderIconsSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get folderIconsSocial;

  /// No description provided for @folderIconsApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get folderIconsApps;

  /// No description provided for @quickTileOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Save without the share sheet'**
  String get quickTileOfferTitle;

  /// No description provided for @quickTileOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Add a Quick Settings shortcut for your last screenshot'**
  String get quickTileOfferBody;

  /// No description provided for @triageNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to review'**
  String get triageNothingNew;

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
  /// **'Nothing saved yet'**
  String get homeInboxEmpty;

  /// No description provided for @homeInboxEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a few from your phone now, or share a screenshot into Shoto from any app.'**
  String get homeInboxEmptySubtitle;

  /// No description provided for @homeEmptyImportCta.
  ///
  /// In en, this message translates to:
  /// **'Choose from my phone'**
  String get homeEmptyImportCta;

  /// No description provided for @homeNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get homeNeedsYou;

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
  /// **'Tools'**
  String get homeToolsTitle;

  /// No description provided for @homeToolsTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get homeToolsTitleEmpty;

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
  /// **'Share a screenshot to Shoto, or add one with the + button. Your gallery is never read — only what you hand over is kept.'**
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

  /// No description provided for @librarySelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get librarySelect;

  /// No description provided for @librarySelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select screenshots'**
  String get librarySelectPrompt;

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
  /// **'Shoto keeps the screenshots you share into it in their own album. It needs photo access to write there and read them back — it never lists the rest of your gallery.'**
  String get permissionNeededMessage;

  /// No description provided for @permissionAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Shoto needs to see its Screenshots album'**
  String get permissionAskTitle;

  /// No description provided for @permissionAskMessage.
  ///
  /// In en, this message translates to:
  /// **'Only that album, and only to list what is in it. Nothing is uploaded, and nothing joins your library until you pick it.'**
  String get permissionAskMessage;

  /// No description provided for @permissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get permissionAllow;

  /// No description provided for @permissionPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Full photo access needed'**
  String get permissionPartialTitle;

  /// No description provided for @permissionPartialMessage.
  ///
  /// In en, this message translates to:
  /// **'Shoto can currently only see a few photos you picked manually, so it cannot reach its own album. Choose \"Allow all\" in the photo permission to continue.'**
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

  /// No description provided for @settingsAppearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Theme, accent colour and grid size'**
  String get settingsAppearanceHint;

  /// No description provided for @appearanceTint.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get appearanceTint;

  /// No description provided for @appearanceTintHint.
  ///
  /// In en, this message translates to:
  /// **'Buttons, switches and anything selected.'**
  String get appearanceTintHint;

  /// No description provided for @appearancePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get appearancePreview;

  /// No description provided for @tintTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get tintTeal;

  /// No description provided for @tintSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get tintSlate;

  /// No description provided for @tintIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get tintIndigo;

  /// No description provided for @tintPlum.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get tintPlum;

  /// No description provided for @tintRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get tintRose;

  /// No description provided for @tintEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get tintEmber;

  /// No description provided for @tintAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get tintAmber;

  /// No description provided for @tintMoss.
  ///
  /// In en, this message translates to:
  /// **'Moss'**
  String get tintMoss;

  /// No description provided for @tintGarnet.
  ///
  /// In en, this message translates to:
  /// **'Garnet'**
  String get tintGarnet;

  /// No description provided for @tintBrass.
  ///
  /// In en, this message translates to:
  /// **'Brass'**
  String get tintBrass;

  /// No description provided for @tintFern.
  ///
  /// In en, this message translates to:
  /// **'Fern'**
  String get tintFern;

  /// No description provided for @tintJade.
  ///
  /// In en, this message translates to:
  /// **'Jade'**
  String get tintJade;

  /// No description provided for @tintOlive.
  ///
  /// In en, this message translates to:
  /// **'Olive'**
  String get tintOlive;

  /// No description provided for @tintCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get tintCyan;

  /// No description provided for @tintDenim.
  ///
  /// In en, this message translates to:
  /// **'Denim'**
  String get tintDenim;

  /// No description provided for @tintViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get tintViolet;

  /// No description provided for @tintSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get tintSky;

  /// No description provided for @tintOrchid.
  ///
  /// In en, this message translates to:
  /// **'Orchid'**
  String get tintOrchid;

  /// No description provided for @tintFuchsia.
  ///
  /// In en, this message translates to:
  /// **'Fuchsia'**
  String get tintFuchsia;

  /// No description provided for @tintClay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get tintClay;

  /// No description provided for @tintGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get tintGraphite;

  /// No description provided for @appearanceMoreColors.
  ///
  /// In en, this message translates to:
  /// **'More colours'**
  String get appearanceMoreColors;

  /// No description provided for @appearanceSelectTint.
  ///
  /// In en, this message translates to:
  /// **'Select accent colour'**
  String get appearanceSelectTint;

  /// No description provided for @appearanceFolders.
  ///
  /// In en, this message translates to:
  /// **'Folder cards'**
  String get appearanceFolders;

  /// No description provided for @appearanceFolderCount.
  ///
  /// In en, this message translates to:
  /// **'Screenshot count'**
  String get appearanceFolderCount;

  /// No description provided for @appearanceFolderDate.
  ///
  /// In en, this message translates to:
  /// **'Date created'**
  String get appearanceFolderDate;

  /// No description provided for @appearanceFolderSize.
  ///
  /// In en, this message translates to:
  /// **'Cards per row'**
  String get appearanceFolderSize;

  /// No description provided for @appearanceLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library grid'**
  String get appearanceLibrary;

  /// No description provided for @appIcon.
  ///
  /// In en, this message translates to:
  /// **'App icon'**
  String get appIcon;

  /// No description provided for @appIconDefault.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get appIconDefault;

  /// No description provided for @appIconHint.
  ///
  /// In en, this message translates to:
  /// **'Changing this closes Shoto for a moment while Android swaps the icon.'**
  String get appIconHint;

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
  /// **'Share Shoto'**
  String get settingsShare;

  /// No description provided for @settingsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Shoto holds only the screenshots you hand it, and everything it does with them — reading text, finding duplicates — happens on this device. Your pictures are never uploaded. Three things are yours to switch on: offering new screenshots reads your Screenshots album so it can ask about them, an account sends only your email address so a subscription survives a change of phone, and crash reports send what broke — the code, never a picture.'**
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

  /// No description provided for @foldersEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit folder'**
  String get foldersEditTitle;

  /// No description provided for @foldersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search folders'**
  String get foldersSearchHint;

  /// No description provided for @foldersSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort folders'**
  String get foldersSortLabel;

  /// No description provided for @foldersSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get foldersSortRecent;

  /// No description provided for @foldersSortName.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get foldersSortName;

  /// No description provided for @foldersSortFullest.
  ///
  /// In en, this message translates to:
  /// **'Most screenshots'**
  String get foldersSortFullest;

  /// No description provided for @foldersNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No folder matches'**
  String get foldersNoMatchTitle;

  /// No description provided for @foldersNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing here is called \"{query}\". Try part of the name.'**
  String foldersNoMatchMessage(String query);

  /// No description provided for @folderDefaultTrips.
  ///
  /// In en, this message translates to:
  /// **'Trip plans'**
  String get folderDefaultTrips;

  /// No description provided for @folderDefaultRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get folderDefaultRecipes;

  /// No description provided for @folderDefaultMedications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get folderDefaultMedications;

  /// No description provided for @folderDefaultAiNotes.
  ///
  /// In en, this message translates to:
  /// **'AI notes'**
  String get folderDefaultAiNotes;

  /// No description provided for @folderDefaultMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get folderDefaultMoney;

  /// No description provided for @folderDefaultWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get folderDefaultWorkouts;

  /// No description provided for @folderDefaultMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get folderDefaultMusic;

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

  /// No description provided for @a11yScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot from {date}'**
  String a11yScreenshot(String date);

  /// No description provided for @a11yScreenshotFavorite.
  ///
  /// In en, this message translates to:
  /// **'Screenshot from {date}, favorite'**
  String a11yScreenshotFavorite(String date);

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

  /// No description provided for @detailMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get detailMore;

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
  /// **'Save to Shoto'**
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
  /// **'Saved to Shoto'**
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

  /// No description provided for @quickSaveNoCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'No screenshot yet'**
  String get quickSaveNoCaptureTitle;

  /// No description provided for @quickSaveNoCaptureBody.
  ///
  /// In en, this message translates to:
  /// **'Take a screenshot, then tap the tile again.'**
  String get quickSaveNoCaptureBody;

  /// No description provided for @quickSaveNoAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Shoto can\'t see your screenshots'**
  String get quickSaveNoAccessTitle;

  /// No description provided for @quickSaveNoAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Open Shoto and allow photo access, then try the tile again.'**
  String get quickSaveNoAccessBody;

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

  /// No description provided for @safeShareKeepCopy.
  ///
  /// In en, this message translates to:
  /// **'Keep the copy in Shoto'**
  String get safeShareKeepCopy;

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
  /// **'Unlock Shoto Pro'**
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

  /// No description provided for @paywallPerYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get paywallPerYear;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get paywallPerMonth;

  /// No description provided for @paywallPreviewPricing.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions aren\'t live yet — pricing shown for preview.'**
  String get paywallPreviewPricing;

  /// No description provided for @paywallNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions aren\'t set up yet — check back soon.'**
  String get paywallNotSetUp;

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

  /// No description provided for @settingsRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Already paid? Bring your subscription back.'**
  String get settingsRestoreHint;

  /// No description provided for @settingsRestoreDone.
  ///
  /// In en, this message translates to:
  /// **'Your subscription is back.'**
  String get settingsRestoreDone;

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
  /// **'Shoto Pro'**
  String get subPremiumTitle;

  /// No description provided for @subPremiumBody.
  ///
  /// In en, this message translates to:
  /// **'Every feature unlocked for you.'**
  String get subPremiumBody;

  /// No description provided for @subPremiumRenews.
  ///
  /// In en, this message translates to:
  /// **'Renews {date}'**
  String subPremiumRenews(String date);

  /// No description provided for @quotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get quotaTitle;

  /// No description provided for @quotaUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit}'**
  String quotaUsed(int used, int limit);

  /// No description provided for @quotaLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No room left — Pro removes the limit} =1{1 screenshot left on the free tier} other{{count} screenshots left on the free tier}}'**
  String quotaLeft(int count);

  /// No description provided for @quotaUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get quotaUnlimited;

  /// No description provided for @quotaUnlimitedNote.
  ///
  /// In en, this message translates to:
  /// **'No ceiling on what you keep.'**
  String get quotaUnlimitedNote;

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

  /// No description provided for @trialUsed.
  ///
  /// In en, this message translates to:
  /// **'That one was on us — your free try'**
  String get trialUsed;

  /// No description provided for @trialFree.
  ///
  /// In en, this message translates to:
  /// **'Free try'**
  String get trialFree;

  /// No description provided for @proOnly.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proOnly;

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

  /// No description provided for @featSafeShare.
  ///
  /// In en, this message translates to:
  /// **'Safe share'**
  String get featSafeShare;

  /// No description provided for @featSafeShareBody.
  ///
  /// In en, this message translates to:
  /// **'Finds card numbers, addresses, names and contact details and covers each with a solid block. The words around them stay, so the picture still reads — and the copy you send has no layer to peel back.'**
  String get featSafeShareBody;

  /// No description provided for @featActions.
  ///
  /// In en, this message translates to:
  /// **'Turn screenshots into actions'**
  String get featActions;

  /// No description provided for @featActionsBody.
  ///
  /// In en, this message translates to:
  /// **'Open a link, write to an address, copy a verification code or an IBAN — straight from the picture, without retyping anything.'**
  String get featActionsBody;

  /// No description provided for @featTraits.
  ///
  /// In en, this message translates to:
  /// **'Filter by what\'s inside'**
  String get featTraits;

  /// No description provided for @featTraitsBody.
  ///
  /// In en, this message translates to:
  /// **'Show only the screenshots with a link, a phone number, a code, a date or a card number in them — matched on the words inside the picture.'**
  String get featTraitsBody;

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
  /// **'Unlimited screenshots'**
  String get featUnlimited;

  /// No description provided for @featUnlimitedBody.
  ///
  /// In en, this message translates to:
  /// **'The free tier organizes {count} screenshots and keeps {folders} folders. Pro takes both numbers away.'**
  String featUnlimitedBody(Object count, Object folders);

  /// No description provided for @featUnlimitedBodyPro.
  ///
  /// In en, this message translates to:
  /// **'Your library has no ceiling — keep as much as you like.'**
  String get featUnlimitedBodyPro;

  /// No description provided for @featSafeShareHow.
  ///
  /// In en, this message translates to:
  /// **'Finding what is private in a screenshot is free and unlimited. Paying is what turns those findings into a clean copy: each detail you leave selected is covered in the exported image, which is flat — no layer to undo.'**
  String get featSafeShareHow;

  /// No description provided for @featSafeSharePoint1.
  ///
  /// In en, this message translates to:
  /// **'Card numbers are Luhn-checked and IBANs mod-97 checked, so those two are found by proof rather than by pattern — no guessing on the detail that matters most.'**
  String get featSafeSharePoint1;

  /// No description provided for @featSafeSharePoint2.
  ///
  /// In en, this message translates to:
  /// **'Also catches names, addresses, order numbers, verification codes, phone numbers and email addresses.'**
  String get featSafeSharePoint2;

  /// No description provided for @featSafeSharePoint3.
  ///
  /// In en, this message translates to:
  /// **'You see everything found before you send, and can leave any of it showing if the app got it wrong. The original screenshot is never touched.'**
  String get featSafeSharePoint3;

  /// No description provided for @featActionsHow.
  ///
  /// In en, this message translates to:
  /// **'Whatever is written inside a screenshot becomes something you can use. Shoto picks out the useful parts and puts a button on each one.'**
  String get featActionsHow;

  /// No description provided for @featActionsPoint1.
  ///
  /// In en, this message translates to:
  /// **'Links, email addresses, IBANs, verification codes, dates and parcel numbers are found for you.'**
  String get featActionsPoint1;

  /// No description provided for @featActionsPoint2.
  ///
  /// In en, this message translates to:
  /// **'One tap to open or copy — no reading characters off a picture.'**
  String get featActionsPoint2;

  /// No description provided for @featActionsPoint3.
  ///
  /// In en, this message translates to:
  /// **'Works on the screenshots you already have, not only on new ones.'**
  String get featActionsPoint3;

  /// No description provided for @featTraitsHow.
  ///
  /// In en, this message translates to:
  /// **'Filtering is free on whatever Shoto has already read: search, smart actions and Safe share each leave recognised text behind, and every filter is derived from that. Paying is what reads the rest of the library in one pass, so a filter can also see the screenshots no other feature has opened yet.'**
  String get featTraitsHow;

  /// No description provided for @featTraitsPoint1.
  ///
  /// In en, this message translates to:
  /// **'Five filters — card numbers and IBANs, links, phone numbers and email addresses, verification codes, and dates you are expected to turn up for.'**
  String get featTraitsPoint1;

  /// No description provided for @featTraitsPoint2.
  ///
  /// In en, this message translates to:
  /// **'Card numbers and IBANs are proven by checksum. The rest are read from the picture, so they under-report rather than over-claim.'**
  String get featTraitsPoint2;

  /// No description provided for @featTraitsPoint3.
  ///
  /// In en, this message translates to:
  /// **'The library always says how many screenshots have never been read, so an empty result is never passed off as an absence. Reading happens on the phone; nothing is uploaded.'**
  String get featTraitsPoint3;

  /// No description provided for @featTint.
  ///
  /// In en, this message translates to:
  /// **'Choose your accent'**
  String get featTint;

  /// No description provided for @featTintBody.
  ///
  /// In en, this message translates to:
  /// **'{count} accents for the buttons, switches and selections — each one tuned to stay readable in both light and dark.'**
  String featTintBody(int count);

  /// No description provided for @featTintHow.
  ///
  /// In en, this message translates to:
  /// **'Most apps hand you a row of raw colours and let the contrast fall where it may, which is why a yellow accent usually arrives carrying white text nobody can read. Shoto stores your choice as a position on the colour wheel rather than as a fixed colour, then works out the exact shade for light mode and for dark mode — so whichever you pick carries text at the same strength the app\'s own colour does.'**
  String get featTintHow;

  /// No description provided for @featTintPoint1.
  ///
  /// In en, this message translates to:
  /// **'{count} accents, from teal and moss through amber and ember to plum, indigo and slate.'**
  String featTintPoint1(int count);

  /// No description provided for @featTintPoint2.
  ///
  /// In en, this message translates to:
  /// **'Each one is worked out twice, once for light mode and once for dark, against the same contrast target — so no accent glows on a dark screen or disappears on a pale one.'**
  String get featTintPoint2;

  /// No description provided for @featTintPoint3.
  ///
  /// In en, this message translates to:
  /// **'Red for delete, green for done and amber for warnings never change, so a colour that means something never becomes decoration.'**
  String get featTintPoint3;

  /// No description provided for @featStitchHow.
  ///
  /// In en, this message translates to:
  /// **'Scrolling capture, on a phone that has it, has to be started while you are still on the page. Shoto works afterwards: pick two or more shots already in your library — including ones somebody sent you — and it finds where they overlap and joins them into one tall image.'**
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
  /// **'Sharing shots in one at a time rarely makes duplicates. Keeping a batch from \"Since you last looked\" does — you move fast, and two captures of the same thing both get kept. Shoto compares by what a shot looks like, not its name or size, so it catches those, along with a resend or a different crop.'**
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
  /// **'The free tier is a real, usable app: saving, folders, favourites and full search, with no account and nothing uploaded. It has two ceilings — how many screenshots it organizes, and how many folders it keeps — and Pro removes both. Everything you already organized stays exactly where it is.'**
  String get featUnlimitedHow;

  /// No description provided for @featUnlimitedPoint1.
  ///
  /// In en, this message translates to:
  /// **'The free tier keeps {count} folders, which is exactly the starter set Shoto gives you. Pro takes that number away too.'**
  String featUnlimitedPoint1(Object count);

  /// No description provided for @featUnlimitedPoint2.
  ///
  /// In en, this message translates to:
  /// **'Naming what a screenshot is for is free and uncapped too.'**
  String get featUnlimitedPoint2;

  /// No description provided for @featUnlimitedPoint3.
  ///
  /// In en, this message translates to:
  /// **'Hitting the ceiling means Shoto became where you keep things. Nothing is deleted when you do.'**
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
  /// **'{count} organized screenshots, unlimited folders, and full search — free for good.'**
  String includedFreeBody(int count);

  /// No description provided for @onboardingCta.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingCta;

  /// No description provided for @onboardingPromise.
  ///
  /// In en, this message translates to:
  /// **'Your screenshots stay on your phone.'**
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
  /// **'Shoto will go back to the free tier on this device, so you can test the paywall and the limits again.'**
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

  /// No description provided for @kindLink.
  ///
  /// In en, this message translates to:
  /// **'a link'**
  String get kindLink;

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
  /// **'Shoto keeps my screenshots organized on their own — everything stays on the phone.'**
  String get settingsShareText;

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

  /// No description provided for @shareChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'What should Shoto do with it?'**
  String get shareChoiceTitle;

  /// No description provided for @shareChoiceProtect.
  ///
  /// In en, this message translates to:
  /// **'Cover private details'**
  String get shareChoiceProtect;

  /// No description provided for @shareChoiceProtectHint.
  ///
  /// In en, this message translates to:
  /// **'Hide what is private and send it on. It is not saved here.'**
  String get shareChoiceProtectHint;

  /// No description provided for @quickSaveCoverAction.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get quickSaveCoverAction;

  /// No description provided for @quickSaveCoverWhy.
  ///
  /// In en, this message translates to:
  /// **'Has private details?'**
  String get quickSaveCoverWhy;

  /// No description provided for @shareChoiceSave.
  ///
  /// In en, this message translates to:
  /// **'Save to Shoto'**
  String get shareChoiceSave;

  /// No description provided for @shareChoiceSaveHint.
  ///
  /// In en, this message translates to:
  /// **'Add it to your library and file it.'**
  String get shareChoiceSaveHint;

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

  /// No description provided for @errorSaveFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not save that folder.'**
  String get errorSaveFolder;

  /// No description provided for @errorDeleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not delete that folder.'**
  String get errorDeleteFolder;

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

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A home for the screenshots worth keeping. Filed, searchable, and safe to send.'**
  String get onbWelcomeBody;

  /// No description provided for @onbSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save it the second you take it'**
  String get onbSaveTitle;

  /// No description provided for @onbSaveBody.
  ///
  /// In en, this message translates to:
  /// **'Tap share in any app and pick Shoto. That is the only way anything gets in.'**
  String get onbSaveBody;

  /// No description provided for @onbChipAnyApp.
  ///
  /// In en, this message translates to:
  /// **'Any app'**
  String get onbChipAnyApp;

  /// No description provided for @onbChipOneTap.
  ///
  /// In en, this message translates to:
  /// **'One tap'**
  String get onbChipOneTap;

  /// No description provided for @onbChipToFolder.
  ///
  /// In en, this message translates to:
  /// **'Straight to a folder'**
  String get onbChipToFolder;

  /// No description provided for @onbFileTitle.
  ///
  /// In en, this message translates to:
  /// **'A library, not a camera roll'**
  String get onbFileTitle;

  /// No description provided for @onbFileBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you send lands filed, and stays exactly where you put it.'**
  String get onbFileBody;

  /// No description provided for @onbChipFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get onbChipFolders;

  /// No description provided for @onbChipFavourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get onbChipFavourites;

  /// No description provided for @onbChipDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Duplicate finder'**
  String get onbChipDuplicates;

  /// No description provided for @onbFindTitle.
  ///
  /// In en, this message translates to:
  /// **'Find the words inside a picture'**
  String get onbFindTitle;

  /// No description provided for @onbFindBody.
  ///
  /// In en, this message translates to:
  /// **'Shoto reads your screenshots, so one word you remember is enough.'**
  String get onbFindBody;

  /// No description provided for @onbChipInsideText.
  ///
  /// In en, this message translates to:
  /// **'Text in images'**
  String get onbChipInsideText;

  /// No description provided for @onbChipOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get onbChipOffline;

  /// No description provided for @onbChipCards.
  ///
  /// In en, this message translates to:
  /// **'Card numbers'**
  String get onbChipCards;

  /// No description provided for @onbChipCodes.
  ///
  /// In en, this message translates to:
  /// **'Codes and IDs'**
  String get onbChipCodes;

  /// No description provided for @onbChipPreview.
  ///
  /// In en, this message translates to:
  /// **'You see every cover'**
  String get onbChipPreview;

  /// No description provided for @onbChipGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery never opened'**
  String get onbChipGallery;

  /// No description provided for @onbChipOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Stays on your phone'**
  String get onbChipOnDevice;

  /// No description provided for @onbSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send them anyway'**
  String get onbSendTitle;

  /// No description provided for @onbSendBody.
  ///
  /// In en, this message translates to:
  /// **'Shoto hides the private parts first, and shows you every cover before it goes.'**
  String get onbSendBody;

  /// No description provided for @onbYoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing moves without you'**
  String get onbYoursTitle;

  /// No description provided for @onbYoursBody.
  ///
  /// In en, this message translates to:
  /// **'Your gallery is never opened. Only what you hand over is kept.'**
  String get onbYoursBody;

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
  /// **'That file is not a Shoto backup'**
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
  /// **'Shoto support'**
  String get supportSubject;

  /// No description provided for @supportNoMailApp.
  ///
  /// In en, this message translates to:
  /// **'No email app found. The address is copied instead.'**
  String get supportNoMailApp;

  /// No description provided for @supportGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi Shoto team,'**
  String get supportGreeting;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Earlier this week'**
  String get dateThisWeek;

  /// No description provided for @dateThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Earlier this month'**
  String get dateThisMonth;

  /// No description provided for @librarySortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get librarySortNewest;

  /// No description provided for @librarySortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get librarySortOldest;

  /// No description provided for @librarySortLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get librarySortLabel;

  /// No description provided for @libraryShowOnly.
  ///
  /// In en, this message translates to:
  /// **'Show only'**
  String get libraryShowOnly;

  /// No description provided for @libraryShowEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get libraryShowEverything;

  /// No description provided for @libraryScanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Read {count} screenshots'**
  String libraryScanPrompt(int count);

  /// No description provided for @libraryScanning.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get libraryScanning;

  /// No description provided for @restoreClashTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder already exists here} other{{count} folders already exist here}}'**
  String restoreClashTitle(int count);

  /// No description provided for @restoreClashBody.
  ///
  /// In en, this message translates to:
  /// **'These names are in your library and in the backup. Same name does not always mean same folder, so this one is yours to decide.'**
  String get restoreClashBody;

  /// No description provided for @restoreClashMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{and 1 more} other{and {count} more}}'**
  String restoreClashMore(int count);

  /// No description provided for @restoreClashMerge.
  ///
  /// In en, this message translates to:
  /// **'Put them together'**
  String get restoreClashMerge;

  /// No description provided for @restoreClashMergeBody.
  ///
  /// In en, this message translates to:
  /// **'Screenshots go into the folders you already have.'**
  String get restoreClashMergeBody;

  /// No description provided for @restoreClashSeparate.
  ///
  /// In en, this message translates to:
  /// **'Keep them apart'**
  String get restoreClashSeparate;

  /// No description provided for @restoreClashSeparateBody.
  ///
  /// In en, this message translates to:
  /// **'Makes a second folder with the same name. Nothing existing is touched.'**
  String get restoreClashSeparateBody;

  /// No description provided for @intentBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get intentBuy;

  /// No description provided for @intentRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get intentRead;

  /// No description provided for @intentReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get intentReply;

  /// No description provided for @intentTry.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get intentTry;

  /// No description provided for @intentVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get intentVisit;

  /// No description provided for @intentBuyWaiting.
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get intentBuyWaiting;

  /// No description provided for @intentReadWaiting.
  ///
  /// In en, this message translates to:
  /// **'To read'**
  String get intentReadWaiting;

  /// No description provided for @intentReplyWaiting.
  ///
  /// In en, this message translates to:
  /// **'To reply'**
  String get intentReplyWaiting;

  /// No description provided for @intentTryWaiting.
  ///
  /// In en, this message translates to:
  /// **'To try'**
  String get intentTryWaiting;

  /// No description provided for @intentVisitWaiting.
  ///
  /// In en, this message translates to:
  /// **'To visit'**
  String get intentVisitWaiting;

  /// No description provided for @intentWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get intentWatch;

  /// No description provided for @intentListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get intentListen;

  /// No description provided for @intentCook.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get intentCook;

  /// No description provided for @intentBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get intentBook;

  /// No description provided for @intentPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get intentPay;

  /// No description provided for @intentSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get intentSend;

  /// No description provided for @intentDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get intentDownload;

  /// No description provided for @intentApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get intentApply;

  /// No description provided for @intentCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get intentCompare;

  /// No description provided for @intentFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get intentFix;

  /// No description provided for @intentWatchWaiting.
  ///
  /// In en, this message translates to:
  /// **'To watch'**
  String get intentWatchWaiting;

  /// No description provided for @intentListenWaiting.
  ///
  /// In en, this message translates to:
  /// **'To listen to'**
  String get intentListenWaiting;

  /// No description provided for @intentCookWaiting.
  ///
  /// In en, this message translates to:
  /// **'To cook'**
  String get intentCookWaiting;

  /// No description provided for @intentBookWaiting.
  ///
  /// In en, this message translates to:
  /// **'To book'**
  String get intentBookWaiting;

  /// No description provided for @intentPayWaiting.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get intentPayWaiting;

  /// No description provided for @intentSendWaiting.
  ///
  /// In en, this message translates to:
  /// **'To send'**
  String get intentSendWaiting;

  /// No description provided for @intentDownloadWaiting.
  ///
  /// In en, this message translates to:
  /// **'To download'**
  String get intentDownloadWaiting;

  /// No description provided for @intentApplyWaiting.
  ///
  /// In en, this message translates to:
  /// **'To apply for'**
  String get intentApplyWaiting;

  /// No description provided for @intentCompareWaiting.
  ///
  /// In en, this message translates to:
  /// **'To compare'**
  String get intentCompareWaiting;

  /// No description provided for @intentFixWaiting.
  ///
  /// In en, this message translates to:
  /// **'To fix'**
  String get intentFixWaiting;

  /// No description provided for @intentMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get intentMore;

  /// No description provided for @intentSectionCommon.
  ///
  /// In en, this message translates to:
  /// **'Ready-made'**
  String get intentSectionCommon;

  /// No description provided for @intentSectionYours.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get intentSectionYours;

  /// No description provided for @intentYoursEmpty.
  ///
  /// In en, this message translates to:
  /// **'A verb you write yourself works exactly like the ones above.'**
  String get intentYoursEmpty;

  /// No description provided for @intentNewAction.
  ///
  /// In en, this message translates to:
  /// **'Write your own'**
  String get intentNewAction;

  /// No description provided for @intentNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Name it yourself'**
  String get intentNewTitle;

  /// No description provided for @intentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit this one'**
  String get intentEditTitle;

  /// No description provided for @intentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'The verb'**
  String get intentNameLabel;

  /// No description provided for @intentNameHint.
  ///
  /// In en, this message translates to:
  /// **'Return it, cancel it, call them…'**
  String get intentNameHint;

  /// No description provided for @intentIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get intentIconLabel;

  /// No description provided for @intentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{label}\"?'**
  String intentDeleteTitle(String label);

  /// No description provided for @intentDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'The screenshots stay where they are. They just stop waiting for anything.'**
  String get intentDeleteMessage;

  /// No description provided for @intentSelectionAction.
  ///
  /// In en, this message translates to:
  /// **'Mark as'**
  String get intentSelectionAction;

  /// No description provided for @intentSelectionApplied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 screenshot marked} other{{count} screenshots marked}}'**
  String intentSelectionApplied(int count);

  /// No description provided for @intentPrompt.
  ///
  /// In en, this message translates to:
  /// **'What it\'s for, if you like'**
  String get intentPrompt;

  /// No description provided for @intentSkip.
  ///
  /// In en, this message translates to:
  /// **'Nothing in particular'**
  String get intentSkip;

  /// No description provided for @intentWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting on you'**
  String get intentWaitingTitle;

  /// No description provided for @intentNothingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting on you'**
  String get intentNothingWaiting;

  /// No description provided for @intentAllDone.
  ///
  /// In en, this message translates to:
  /// **'You have finished everything you saved for later.'**
  String get intentAllDone;

  /// No description provided for @intentMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get intentMarkDone;

  /// No description provided for @intentUndo.
  ///
  /// In en, this message translates to:
  /// **'Put it back'**
  String get intentUndo;

  /// No description provided for @intentDoneToast.
  ///
  /// In en, this message translates to:
  /// **'Ticked off'**
  String get intentDoneToast;

  /// No description provided for @intentListEnd.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{That is the only one waiting} other{That is all {count} of them}}'**
  String intentListEnd(int count);

  /// No description provided for @intentChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get intentChange;

  /// No description provided for @intentClear.
  ///
  /// In en, this message translates to:
  /// **'Not for anything'**
  String get intentClear;

  /// No description provided for @intentEmptyOne.
  ///
  /// In en, this message translates to:
  /// **'Nothing here to {verb}'**
  String intentEmptyOne(String verb);

  /// No description provided for @intentEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Screenshots you mark land here until you tick them off.'**
  String get intentEmptyBody;

  /// No description provided for @intentProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String intentProgress(int done, int total);

  /// No description provided for @intentDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} finished'**
  String intentDoneCount(int count);

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String dateDaysAgo(int count);

  /// No description provided for @dateWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String dateWeeksAgo(int count);

  /// No description provided for @dateMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String dateMonthsAgo(int count);

  /// No description provided for @copyTextSelect.
  ///
  /// In en, this message translates to:
  /// **'Select text'**
  String get copyTextSelect;

  /// No description provided for @copyTextSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get copyTextSelectAll;

  /// No description provided for @copyTextHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold any text to copy it'**
  String get copyTextHint;

  /// No description provided for @copyTextPrompt.
  ///
  /// In en, this message translates to:
  /// **'Drag to select'**
  String get copyTextPrompt;

  /// No description provided for @copyTextNone.
  ///
  /// In en, this message translates to:
  /// **'No text Shoto can read in this screenshot'**
  String get copyTextNone;
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
    'de',
    'en',
    'es',
    'fr',
    'it',
    'nl',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
