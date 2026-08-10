// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsCrashReports => 'Absturzberichte';

  @override
  String get settingsCrashReportsHint =>
      'Technische Details senden, wenn etwas schiefgeht';

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsSignOutTitle => 'Abmelden?';

  @override
  String get authWelcome => 'Willkommen bei Shoto';

  @override
  String get authSubtitle =>
      'Mit einer Anmeldung bleibt dein Abo dir erhalten, wenn du das Handy wechselst. Deine Screenshots bleiben so oder so auf diesem Gerät – ein Konto nimmt sie nie mit.';

  @override
  String get authGoogle => 'Weiter mit Google';

  @override
  String get authApple => 'Weiter mit Apple';

  @override
  String get authLegal =>
      'Wenn du fortfährst, stimmst du unseren Nutzungsbedingungen und der Datenschutzerklärung zu.';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsSignOutHint =>
      'Deine Screenshots bleiben auf diesem Gerät';

  @override
  String get settingsSignIn => 'Anmelden';

  @override
  String get settingsSignInHint =>
      'Optional. Nur nötig, um einen Kauf auf ein anderes Handy zu übertragen.';

  @override
  String paywallTrialCta(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage gratis starten',
      one: '1 Tag gratis starten',
    );
    return '$_temp0';
  }

  @override
  String paywallTrialNote(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage gratis, danach $price. Jederzeit vorher kündbar.',
      one: 'Einen Tag gratis, danach $price. Jederzeit vorher kündbar.',
    );
    return '$_temp0';
  }

  @override
  String get triageTitle => 'Seit deinem letzten Blick';

  @override
  String get triageBody =>
      'Behalte, was zu Shoto gehört. Alles andere bleibt genau dort, wo es ist.';

  @override
  String get triageKeep => 'Behalten';

  @override
  String get triageSkip => 'Überspringen';

  @override
  String get triageFinish => 'Fertig';

  @override
  String triageProgress(int index, int total) {
    return '$index von $total';
  }

  @override
  String triageNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Screenshots',
      one: '1 neuer Screenshot',
    );
    return '$_temp0';
  }

  @override
  String triageKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count behalten',
      one: '1 behalten',
      zero: 'Nichts behalten',
    );
    return '$_temp0';
  }

  @override
  String get triageReview => 'Ansehen';

  @override
  String get triageInviteDecline => 'Jetzt nicht';

  @override
  String get triageInviteTitle => 'Neue Screenshots hier anzeigen?';

  @override
  String get triageInviteBody =>
      'Shoto kann ab jetzt auflisten, was du aufnimmst, damit du die wenigen behältst, auf die es ankommt. Nichts landet in deiner Bibliothek, bevor du es sagst.';

  @override
  String get triageInviteAccept => 'Anzeigen';

  @override
  String get triageInviteDismiss => 'Nein danke';

  @override
  String get settingsTriage => 'Neue Screenshots anbieten';

  @override
  String get settingsTriageHint =>
      'Zeigt, was du aufnimmst; behält von allein nichts';

  @override
  String get triageNothingNew => 'Nichts Neues zum Ansehen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonSomethingWentWrong => 'Etwas ist schiefgegangen';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'Start';

  @override
  String get navLibrary => 'Mediathek';

  @override
  String get navFolders => 'Ordner';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get tagline => 'Deine Screenshots, geordnet';

  @override
  String get homeGreetingMorning => 'Guten Morgen';

  @override
  String get homeGreetingAfternoon => 'Guten Tag';

  @override
  String get homeGreetingEvening => 'Guten Abend';

  @override
  String get homeInboxEmpty => 'Noch nichts gespeichert';

  @override
  String get homeInboxEmptySubtitle =>
      'Wähle jetzt ein paar von deinem Handy oder teile aus jeder App einen Screenshot in Shoto.';

  @override
  String get homeEmptyImportCta => 'Von meinem Handy wählen';

  @override
  String get homeInboxClear => 'Alles abgelegt';

  @override
  String get homeInboxClearSubtitle => 'Nichts wartet aufs Sortieren';

  @override
  String get homeInboxCountSubtitle =>
      'Screenshots, die du noch nicht abgelegt hast';

  @override
  String get homeStatScreenshots => 'Screenshots';

  @override
  String get homeStatFavorites => 'Favoriten';

  @override
  String get homeStatFolders => 'Ordner';

  @override
  String get homeToolsTitle => 'Werkzeuge';

  @override
  String get homeToolsTitleEmpty => 'Hier anfangen';

  @override
  String get homeToolSafeShare => 'Safe Share';

  @override
  String get homeToolSafeShareSubtitle => 'Erst Privates verbergen';

  @override
  String get homeToolDuplicates => 'Duplikate finden';

  @override
  String get homeToolDuplicatesSubtitle => 'Speicher freimachen';

  @override
  String get homeToolSearch => 'Darin suchen';

  @override
  String get homeToolSearchSubtitle => 'Text in deinen Bildern finden';

  @override
  String get homeToolStitch => 'Lange Shots verbinden';

  @override
  String get homeToolStitchSubtitle => 'Eine Scroll-Aufnahme zusammenfügen';

  @override
  String get homeRecent => 'Zuletzt';

  @override
  String get libraryPickForMerge =>
      'Wähle zwei oder mehr Aufnahmen derselben Seite';

  @override
  String get libraryPickForProtect => 'Wähle den Screenshot zum Schützen';

  @override
  String get libraryActionProtect => 'Schützen';

  @override
  String get homeSeeAll => 'Alle ansehen';

  @override
  String get libraryEmptyTitle => 'Noch nichts gespeichert';

  @override
  String get libraryEmptyMessage =>
      'Teile einen Screenshot mit Shoto oder füge einen über + hinzu. Deine Galerie wird nie gelesen – behalten wird nur, was du übergibst.';

  @override
  String get libraryNoFavoritesTitle => 'Noch keine Favoriten';

  @override
  String get libraryNoFavoritesMessage =>
      'Tippe das Herz auf einem Screenshot, um ihn hier abzulegen.';

  @override
  String get libraryFilterAll => 'Alle';

  @override
  String get libraryFilterFavorites => 'Favoriten';

  @override
  String get libraryTraitSensitive => 'Sensibel';

  @override
  String get libraryTraitLink => 'Links';

  @override
  String get libraryTraitContact => 'Telefon oder E-Mail';

  @override
  String get libraryTraitCode => 'Codes';

  @override
  String get libraryTraitEvent => 'Termine';

  @override
  String get libraryCertaintyVerified => 'Per Prüfsumme bestätigt';

  @override
  String get libraryCertaintyRead =>
      'Aus dem Text in deinen Screenshots gelesen';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count noch nicht gelesen';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return 'Keine Screenshots mit $trait';
  }

  @override
  String get libraryNoTraitMessage =>
      'Kein gelesener Screenshot enthält davon etwas.';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'Im Gelesenen nichts gefunden. $count Screenshots wurden nie gelesen und lassen sich daher noch nicht zuordnen.';
  }

  @override
  String get libraryShowAll => 'Alle anzeigen';

  @override
  String get libraryFilterUnsorted => 'Unsortiert';

  @override
  String get libraryNoUnsortedTitle => 'Alles ist abgelegt';

  @override
  String get libraryNoUnsortedMessage =>
      'Nichts wartet auf dich. Neue Screenshots landen hier, bis du sie ablegst oder markierst.';

  @override
  String librarySelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get librarySelectAll => 'Alle auswählen';

  @override
  String get libraryActionMerge => 'Verbinden';

  @override
  String get libraryActionMove => 'Verschieben';

  @override
  String get libraryActionDelete => 'Löschen';

  @override
  String get libraryDeleteTitle => 'Screenshots löschen?';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dies löscht $count Screenshots endgültig von deinem Gerät.',
      one: 'Dies löscht 1 Screenshot endgültig von deinem Gerät.',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'Fotozugriff nötig';

  @override
  String get permissionNeededMessage =>
      'Shoto bewahrt die Screenshots, die du hineinteilst, in einem eigenen Album auf. Für das Schreiben und Zurücklesen braucht es Fotozugriff – den Rest deiner Galerie listet es nie auf.';

  @override
  String get permissionAskTitle =>
      'Shoto braucht Zugriff auf sein Screenshots-Album';

  @override
  String get permissionAskMessage =>
      'Nur dieses Album, und nur um aufzulisten, was darin ist. Nichts wird hochgeladen, und nichts landet in deiner Bibliothek, bevor du es auswählst.';

  @override
  String get permissionAllow => 'Zugriff erlauben';

  @override
  String get permissionPartialTitle => 'Voller Fotozugriff nötig';

  @override
  String get permissionPartialMessage =>
      'Shoto sieht derzeit nur ein paar von dir ausgewählte Fotos und kommt so nicht an sein eigenes Album. Wähle in der Fotoberechtigung „Alle zulassen“, um fortzufahren.';

  @override
  String get permissionOpenSettings => 'Einstellungen öffnen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsGridDensity => 'Rasterdichte';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Wie mein Handy';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Zeigt gerade $language';
  }

  @override
  String get settingsBehaviour => 'Verhalten';

  @override
  String get settingsHaptics => 'Haptisches Feedback';

  @override
  String get settingsHapticsHint => 'Ein kurzer Impuls beim Drücken';

  @override
  String get settingsConfirmDelete => 'Vor dem Löschen fragen';

  @override
  String get settingsConfirmDeleteHint =>
      'Löschen lässt sich nicht rückgängig machen';

  @override
  String get settingsFindDuplicates => 'Duplikate finden';

  @override
  String get settingsClearCache => 'Bild-Cache leeren';

  @override
  String get settingsShare => 'Shoto teilen';

  @override
  String get settingsPrivacyNote =>
      'Shoto behält nur die Screenshots, die du ihm gibst, und alles, was damit geschieht – Text lesen, Duplikate finden – passiert auf diesem Gerät. Deine Bilder werden nie hochgeladen. Drei Dinge schaltest du selbst ein: das Anbieten neuer Screenshots liest dein Screenshots-Album, um danach zu fragen; ein Konto sendet nur deine E-Mail-Adresse, damit ein Abo einen Handywechsel übersteht; und Absturzberichte senden, was kaputtging – den Code, nie ein Bild.';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonConfirm => 'Bestätigen';

  @override
  String get commonRename => 'Umbenennen';

  @override
  String get commonShare => 'Teilen';

  @override
  String get commonUnlock => 'Freischalten';

  @override
  String get foldersEmptyTitle => 'Noch keine Ordner';

  @override
  String get foldersEmptyMessage =>
      'Ordner sind, wie du später etwas wiederfindest. Mach einen für Belege, einen für Rezepte – was auch immer du wirklich suchst.';

  @override
  String get foldersNew => 'Neuer Ordner';

  @override
  String get foldersCreate => 'Ordner erstellen';

  @override
  String get foldersNameLabel => 'Ordnername';

  @override
  String get foldersNameHint => 'Belege, Rezepte, Arbeit …';

  @override
  String get foldersPrivate => 'Privat (Gesichts- oder Fingerabdrucksperre)';

  @override
  String get foldersPrivateFace => 'Privat (Gesichtssperre)';

  @override
  String get foldersPrivateFingerprint => 'Privat (Fingerabdrucksperre)';

  @override
  String get foldersPrivateGeneric => 'Privat (gesperrt)';

  @override
  String get foldersOptions => 'Ordneroptionen';

  @override
  String get foldersDelete => 'Ordner löschen';

  @override
  String get foldersDeleteKept => 'Screenshots darin bleiben erhalten';

  @override
  String foldersDeleteTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get foldersDeleteMessage =>
      'Der Ordner verschwindet, aber die Screenshots darin bleiben in deiner Mediathek.';

  @override
  String get foldersRenameTitle => 'Ordner umbenennen';

  @override
  String get foldersMoveTitle => 'In Ordner verschieben';

  @override
  String get foldersMoveRemove => 'Aus dem Ordner nehmen';

  @override
  String get foldersMoveNone =>
      'Noch keine Ordner. Erstelle einen im Tab „Ordner“.';

  @override
  String folderLockedTitle(String name) {
    return '„$name“ entsperren';
  }

  @override
  String get folderLockedMessage =>
      'Dieser Ordner ist geschützt. Authentifiziere dich, um ihn zu sehen.';

  @override
  String get folderEmptyTitle => 'Hier ist noch nichts';

  @override
  String get folderEmptyMessage =>
      'Verschiebe Screenshots aus deiner Mediathek in diesen Ordner.';

  @override
  String get detailFavorite => 'Favorit';

  @override
  String get detailUnfavorite => 'Aus Favoriten entfernen';

  @override
  String get detailAddFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get detailActions => 'Aktionen';

  @override
  String get detailSafeShare => 'Safe Share';

  @override
  String get detailMore => 'Mehr';

  @override
  String get detailDeleteTitle => 'Screenshot löschen?';

  @override
  String get detailDeleteMessage =>
      'Dies löscht ihn endgültig von deinem Gerät.';

  @override
  String get quickSaveTitleOne => 'In Shoto sichern';

  @override
  String quickSaveTitleMany(int count) {
    return '$count Screenshots sichern';
  }

  @override
  String get quickSaveFileOne => 'Diesen Screenshot ablegen';

  @override
  String quickSaveFileMany(int count) {
    return '$count Screenshots ablegen';
  }

  @override
  String get quickSavePickFolder => 'Ordner wählen';

  @override
  String get quickSaveNeedFolder => 'Erstelle einen Ordner dafür';

  @override
  String quickSaveFileIn(String folder) {
    return 'In $folder ablegen';
  }

  @override
  String get quickSaveCreateFirstFolder => 'Erstelle deinen ersten Ordner';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'Ordner sind, wie du später etwas wiederfindest';

  @override
  String get quickSaveNewChip => 'Neu';

  @override
  String get quickSaveSaved => 'In Shoto gesichert';

  @override
  String quickSaveFiled(String folder) {
    return 'In $folder abgelegt.';
  }

  @override
  String get quickSaveFailedTitle => 'Bild konnte nicht gelesen werden';

  @override
  String get quickSaveFailedBody => 'Versuche, es noch einmal zu teilen.';

  @override
  String quickSaveSkipped(int count) {
    return 'Nur die ersten $count wurden übernommen';
  }

  @override
  String get dupTitle => 'Duplikate finden';

  @override
  String get dupScanning => 'Suche nach Duplikaten';

  @override
  String get dupReading => 'Deine Mediathek wird gelesen …';

  @override
  String dupProgress(int done, int total) {
    return '$done von $total Screenshots geprüft';
  }

  @override
  String get dupNoneTitle => 'Keine Duplikate gefunden';

  @override
  String get dupNoneBody =>
      'Deine Screenshot-Mediathek ist bereits aufgeräumt.';

  @override
  String get dupScanAgain => 'Erneut scannen';

  @override
  String dupReclaimable(String size) {
    return 'Bis zu $size können frei werden';
  }

  @override
  String get dupNothingSelected => 'Nichts ausgewählt';

  @override
  String dupDeleteButton(int count, String size) {
    return '$count löschen · $size frei';
  }

  @override
  String dupDeleteTitle(int count) {
    return '$count Kopien löschen?';
  }

  @override
  String get dupDeleteMessage =>
      'Dies löscht sie endgültig von deinem Gerät. Die zum Behalten markierten Kopien sind nicht betroffen.';

  @override
  String dupDeleted(int count, String size) {
    return '$count gelöscht · $size frei';
  }

  @override
  String dupSets(int count) {
    return '$count Gruppen';
  }

  @override
  String get dupBest => 'BESTE';

  @override
  String get dupKeepAll => 'Alle behalten';

  @override
  String get dupKeepingAll => 'Alle bleiben – es wird nichts gelöscht';

  @override
  String get dupUndo => 'Rückgängig';

  @override
  String dupFrees(String size) {
    return 'Macht $size frei';
  }

  @override
  String get safeShareTitle => 'Safe Share';

  @override
  String get safeShareScanning => 'Suche nach privaten Angaben';

  @override
  String get safeShareOnDevice => 'Gelesen wird auf deinem Handy.';

  @override
  String get safeShareCleanTitle => 'Nichts Privates gefunden';

  @override
  String get safeShareCleanBody =>
      'In diesem Screenshot wurden keine Kartennummern, Kontonummern, Codes oder Kontaktdaten entdeckt. Du kannst ihn so teilen.';

  @override
  String get safeShareUnreadableTitle =>
      'Screenshot konnte nicht gelesen werden';

  @override
  String get safeShareUnreadableBody =>
      'Der Text darin ließ sich nicht erkennen.';

  @override
  String get safeShareShareUnchanged => 'Unverändert teilen';

  @override
  String get safeShareShareAnyway => 'Trotzdem teilen';

  @override
  String get safeShareShareProtected => 'Geschützte Kopie teilen';

  @override
  String get safeShareFailed =>
      'Die geschützte Kopie ließ sich nicht erstellen.';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count private Angaben gefunden',
      one: '1 private Angabe gefunden',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'Das Prüfen ist immer gratis.';

  @override
  String get safeShareCleanAction => 'Diesen Screenshot säubern';

  @override
  String get safeShareShareAsIs => 'Ohne Änderungen teilen';

  @override
  String get safeShareHowTitle => 'Abgedeckt, endgültig';

  @override
  String get safeShareHowBody =>
      'Jede private Angabe wird mit einem vollen Block abgedeckt, bevor die Kopie dein Handy verlässt. Nichts wird verwischt und nichts lässt sich zurücklesen – die abgedeckte Kopie ist die einzige Fassung, die existiert.';

  @override
  String get safeShareTreatmentCover => 'Abdecken';

  @override
  String get safeShareTreatmentKeep => 'Behalten';

  @override
  String get safeShareBuilding => 'Deine saubere Kopie entsteht';

  @override
  String get safeShareNothingSelected => 'Es ändert sich nichts';

  @override
  String get safeShareLockedPreview =>
      'Freischalten, um die saubere Fassung zu sehen';

  @override
  String get safeShareReviewTitle => 'Sieh dir jede an';

  @override
  String safeShareFound(int count) {
    return '$count Stellen abgedeckt';
  }

  @override
  String get stitchTitle => 'Screenshots verbinden';

  @override
  String get stitchWorking => 'Überlappung wird gesucht';

  @override
  String get stitchWorkingBody =>
      'Es wird abgeglichen, wo jeder Screenshot den letzten fortsetzt.';

  @override
  String get stitchFailed => 'Verbinden nicht möglich';

  @override
  String get stitchSave => 'In Galerie sichern';

  @override
  String get stitchSaved => 'In deiner Galerie gesichert';

  @override
  String get stitchDiscard => 'Verwerfen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonClose => 'Schließen';

  @override
  String get searchTitle => 'Deine Screenshots durchsuchen';

  @override
  String get searchHint => 'Nach Wörtern oder Bildinhalten suchen';

  @override
  String get searchIntro =>
      'Jedes Wort, das in einem Bild steht, oder was das Bild zeigt – probier „Katze“, „Tier“, „Essen“ oder „Beleg“.';

  @override
  String get searchNoneTitle => 'Keine Treffer';

  @override
  String searchNoneBody(String query) {
    return 'Hier steht oder zeigt nichts „$query“.';
  }

  @override
  String get paywallTitle => 'Shoto Pro freischalten';

  @override
  String get paywallSubtitle => 'Alles unten, mit einem Abo.';

  @override
  String get paywallMonthly => 'Monatlich';

  @override
  String get paywallYearly => 'Jährlich';

  @override
  String paywallSave(int percent) {
    return '$percent % sparen';
  }

  @override
  String get paywallPerYear => '/Jahr';

  @override
  String get paywallPerMonth => '/Monat';

  @override
  String get paywallPreviewPricing =>
      'Abos sind noch nicht aktiv — Preise dienen der Vorschau.';

  @override
  String get paywallNotSetUp =>
      'Abos sind noch nicht eingerichtet — schau bald wieder vorbei.';

  @override
  String get paywallContinue => 'Weiter';

  @override
  String get paywallUnavailable => 'Noch nicht verfügbar';

  @override
  String get paywallRestore => 'Käufe wiederherstellen';

  @override
  String get paywallLegal =>
      'Verlängert sich automatisch bis zur Kündigung. Jederzeit in den Kontoeinstellungen im App Store oder bei Google Play kündbar. Mit dem Fortfahren stimmst du unseren Nutzungsbedingungen und der Datenschutzerklärung zu.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'Shoto Pro';

  @override
  String get subPremiumBody => 'Jede Funktion für dich freigeschaltet.';

  @override
  String get subDevUnlock => 'Testerzugang';

  @override
  String get subDevUnlockBody =>
      'Auf diesem Gerät freigeschaltet – kein echtes Abo';

  @override
  String get subUnlockEverything => 'Alles freischalten';

  @override
  String get proWelcomeTitle => 'Du bist auf Pro';

  @override
  String get proWelcomeBody =>
      'Jede Funktion ist freigeschaltet. Es gibt nichts weiter einzurichten.';

  @override
  String get proWelcomeAction => 'Loslegen';

  @override
  String get featSafeShare => 'Safe Share';

  @override
  String get featSafeShareBody =>
      'Findet Kartennummern, Adressen, Namen und Kontaktdaten und deckt jedes davon mit einem massiven Balken ab. Der Text drumherum bleibt, das Bild bleibt lesbar – und die gesendete Kopie hat keine Ebene, die sich entfernen lässt.';

  @override
  String get featActions => 'Screenshots zu Aktionen machen';

  @override
  String get featActionsBody =>
      'Einen Link öffnen, an eine Adresse schreiben, einen Bestätigungscode oder eine IBAN kopieren – direkt aus dem Bild, ohne etwas abzutippen.';

  @override
  String get featDuplicates => 'Duplikate finden';

  @override
  String get featDuplicatesBody =>
      'Erkennt fast identische Aufnahmen, die du doppelt behalten hast, und räumt sie weg – immer erst mit einer Durchsicht.';

  @override
  String get featStitch => 'Lange Screenshots verbinden';

  @override
  String get featStitchBody =>
      'Fügt eine Scroll-Aufnahme wieder zu einem hohen Bild zusammen, mit automatisch gefundener und entfernter Überlappung.';

  @override
  String get featUnlimited => 'Keine Grenze für deine Mediathek';

  @override
  String featUnlimitedBody(Object count) {
    return 'Die Gratisstufe ordnet $count Screenshots. Pro nimmt die Zahl weg.';
  }

  @override
  String get featSafeShareHow =>
      'Zu finden, was in einem Screenshot privat ist, ist gratis und unbegrenzt. Bezahlt wird dafür, aus diesen Funden eine saubere Kopie zu machen: jede ausgewählte Angabe wird im Export abgedeckt, und der Export ist flach – keine Ebene, die sich rückgängig machen lässt.';

  @override
  String get featSafeSharePoint1 =>
      'Kartennummern werden per Luhn und IBANs per Modulo 97 geprüft – diese beiden werden also bewiesen statt geraten, genau bei der Angabe, die am schwersten wiegt.';

  @override
  String get featSafeSharePoint2 =>
      'Erkennt außerdem Namen, Adressen, Bestellnummern, Bestätigungscodes, Telefonnummern und E-Mail-Adressen.';

  @override
  String get featSafeSharePoint3 =>
      'Du siehst vor dem Senden alles Gefundene und kannst jede Angabe sichtbar lassen, wenn die App danebenlag. Der ursprüngliche Screenshot wird nie angetastet.';

  @override
  String get featActionsHow =>
      'Was in einem Screenshot steht, wird zu etwas, das du benutzen kannst. Shoto greift die nützlichen Teile heraus und setzt auf jeden eine Schaltfläche.';

  @override
  String get featActionsPoint1 =>
      'Links, E-Mail-Adressen, IBANs, Bestätigungscodes, Termine und Paketnummern werden für dich gefunden.';

  @override
  String get featActionsPoint2 =>
      'Ein Tippen zum Öffnen oder Kopieren – kein Zeichen mehr vom Bild ablesen.';

  @override
  String get featActionsPoint3 =>
      'Funktioniert mit den Screenshots, die du schon hast, nicht nur mit neuen.';

  @override
  String get featStitchHow =>
      'Eine Scroll-Aufnahme muss auf Handys, die sie können, gestartet werden, solange du noch auf der Seite bist. Shoto arbeitet danach: Wähle zwei oder mehr Aufnahmen aus deiner Mediathek – auch solche, die dir jemand geschickt hat – und es findet die Überlappung und fügt sie zu einem hohen Bild.';

  @override
  String get featStitchPoint1 =>
      'Der wiederholte Streifen zwischen zwei Aufnahmen wird automatisch gefunden und entfernt.';

  @override
  String get featStitchPoint2 =>
      'Du siehst die Naht, bevor etwas gesichert wird – automatische Erkennung ist gut, aber nie sicher.';

  @override
  String get featStitchPoint3 =>
      'Das verbundene Bild wird wie jedes andere in deiner Galerie gesichert.';

  @override
  String get featDuplicatesHow =>
      'Einzeln hineingeteilte Aufnahmen erzeugen selten Duplikate. Ein Schwung aus „Seit deinem letzten Blick“ schon – du bist schnell, und zwei Aufnahmen derselben Sache bleiben beide. Shoto vergleicht, wie eine Aufnahme aussieht, nicht Name oder Größe, und fängt so auch ein erneutes Senden oder einen anderen Zuschnitt.';

  @override
  String get featDuplicatesPoint1 =>
      'Gruppiert, was gleich aussieht, und schlägt die Kopie zum Behalten vor.';

  @override
  String get featDuplicatesPoint2 =>
      'Zeigt, wie viel Platz jede Gruppe freimacht, bevor du irgendetwas entscheidest.';

  @override
  String get featDuplicatesPoint3 =>
      'Es wird nichts gelöscht, bevor du die Gruppe durchgesehen und bestätigt hast.';

  @override
  String get featUnlimitedHow =>
      'Die Gratisstufe ist eine echte, brauchbare App: Sichern, Ordner, Favoriten und volle Suche, ohne Konto und ohne Upload. Sie hat genau eine Grenze – wie viele Screenshots sie ordnet – und Pro hebt sie auf. Alles, was du schon geordnet hast, bleibt genau dort.';

  @override
  String get featUnlimitedPoint1 =>
      'Ordner sind in der Gratisstufe unbegrenzt und waren immer so gedacht.';

  @override
  String get featUnlimitedPoint2 =>
      'Zu benennen, wofür ein Screenshot ist, ist ebenfalls gratis und unbegrenzt.';

  @override
  String get featUnlimitedPoint3 =>
      'An die Grenze zu stoßen heißt, dass Shoto dein Aufbewahrungsort geworden ist. Dabei wird nichts gelöscht.';

  @override
  String get includedSubtitle => 'Jede Pro-Funktion, erklärt.';

  @override
  String get includedHint =>
      'Tippe eine Funktion an, um zu sehen, wie sie arbeitet';

  @override
  String get includedHowLabel => 'So funktioniert es';

  @override
  String get includedActiveTitle => 'Dein Plan ist aktiv';

  @override
  String get includedActiveBody =>
      'Alles unten ist für dieses Konto freigeschaltet.';

  @override
  String get includedLockedTitle => 'Noch nicht freigeschaltet';

  @override
  String get includedLockedBody =>
      'Lies, was jede Funktion wirklich tut, und entscheide dann.';

  @override
  String get includedFreeTitle => 'Was dir die Gratisstufe gibt';

  @override
  String includedFreeBody(int count) {
    return '$count geordnete Screenshots, unbegrenzte Ordner und volle Suche – dauerhaft gratis.';
  }

  @override
  String get onboardingCta => 'Loslegen';

  @override
  String get onboardingPromise => 'Deine Screenshots bleiben auf deinem Handy.';

  @override
  String get actionsTitle => 'Aktionen';

  @override
  String get actionsWorking => 'Screenshot wird gelesen';

  @override
  String get actionsWorkingBody => 'Suche nach Nummern, Links und Codes.';

  @override
  String get actionsNoneTitle => 'Nichts zu tun';

  @override
  String get actionsNoneBody =>
      'In diesem Screenshot wurden keine Links, Codes oder Kontonummern gefunden.';

  @override
  String get actionsCopy => 'Kopieren';

  @override
  String get actionsCopied => 'Kopiert';

  @override
  String get actionsNoApp => 'Keine App auf diesem Gerät kann das.';

  @override
  String get devModeOn => 'Entwicklermodus an – jede Funktion freigeschaltet';

  @override
  String get devModeBadge => 'ENTWICKLERMODUS';

  @override
  String get devModeOffTitle => 'Entwicklermodus ausschalten?';

  @override
  String get devModeOffBody =>
      'Shoto fällt auf diesem Gerät auf die Gratisstufe zurück, damit du Paywall und Grenzen erneut testen kannst.';

  @override
  String get devModeOffConfirm => 'Ausschalten';

  @override
  String get devAccessTitle => 'Entwicklerzugang';

  @override
  String get devAccessBody =>
      'Gib den vierstelligen Code ein, um jede Pro-Funktion auf diesem Gerät freizuschalten.';

  @override
  String get devWrongCode => 'Falscher Code';

  @override
  String devTapToDisable(int count) {
    return '$count× tippen zum Ausschalten';
  }

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get kindCard => 'eine Kartennummer';

  @override
  String get kindIban => 'ein Bankkonto';

  @override
  String get kindCode => 'ein Bestätigungscode';

  @override
  String get kindNationalId => 'eine Ausweisnummer';

  @override
  String get kindEmail => 'eine E-Mail-Adresse';

  @override
  String get kindLink => 'ein Link';

  @override
  String get actionEmailAction => 'Schreiben';

  @override
  String get actionOpen => 'Öffnen';

  @override
  String get kindEvent => 'ein Termin';

  @override
  String get kindPlace => 'ein Ort';

  @override
  String get kindWifi => 'ein WLAN';

  @override
  String get kindTracking => 'eine Sendung';

  @override
  String get actionAddToCalendar => 'Zum Kalender hinzufügen';

  @override
  String get actionOpenMaps => 'In Maps öffnen';

  @override
  String get actionDirections => 'Route';

  @override
  String get actionCopyNetwork => 'Namen kopieren';

  @override
  String get actionTrack => 'Verfolgen';

  @override
  String get actionEventUntitled => 'Termin';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Screenshots',
      one: '1 Screenshot',
      zero: 'Keine Screenshots',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$position von $total';
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
      other: '$count Gruppen Duplikate',
      one: '1 Gruppe Duplikate',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count ähnliche Kopien';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Funde',
      one: '1 Fund',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'Speicher';

  @override
  String get settingsDuplicatesHint =>
      'Screenshots erkennen, die du doppelt gemacht hast';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'Was enthalten ist';

  @override
  String settingsFeatureCount(int count) {
    return '$count Funktionen, ein Plan';
  }

  @override
  String get settingsShareHint => 'Erzähl es jemandem, der es braucht';

  @override
  String get settingsShareText =>
      'Shoto hält meine Screenshots von allein geordnet – alles bleibt auf dem Handy.';

  @override
  String get settingsCacheMeasuring => 'Wird gemessen …';

  @override
  String settingsCacheSize(String size) {
    return '$size an Vorschaubildern';
  }

  @override
  String get homeSafeShareHint =>
      'Öffne einen Screenshot und tippe dann auf Safe Share.';

  @override
  String get homeStitchHint =>
      'Halte zwei oder mehr Screenshots in deiner Mediathek gedrückt und tippe dann auf Verbinden.';

  @override
  String stitchLimit(int count) {
    return 'Bis zu $count Screenshots auf einmal verbinden.';
  }

  @override
  String get shareChoiceTitle => 'Was soll Shoto damit machen?';

  @override
  String get shareChoiceProtect => 'Private Angaben abdecken';

  @override
  String get shareChoiceProtectHint =>
      'Privates verbergen und weiterschicken. Es wird hier nicht gespeichert.';

  @override
  String get shareChoiceSave => 'In Shoto speichern';

  @override
  String get shareChoiceSaveHint => 'Zur Bibliothek hinzufügen und ablegen.';

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Screenshots gesichert. In einen Ordner legen?',
      one: 'Screenshot gesichert. In einen Ordner legen?',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count Screenshots verbunden';
  }

  @override
  String stitchResultTrimmed(int count) {
    return '$count px wiederholter Inhalt entfernt';
  }

  @override
  String get errorLoadScreenshots =>
      'Deine Screenshots konnten nicht geladen werden.';

  @override
  String get errorLoadFolders => 'Deine Ordner konnten nicht geladen werden.';

  @override
  String get errorScanDuplicates =>
      'Es konnte nicht nach Duplikaten gesucht werden.';

  @override
  String get errorDeleteSelected =>
      'Die ausgewählten Screenshots konnten nicht gelöscht werden.';

  @override
  String get errorStitchFailed =>
      'Diese Screenshots konnten nicht verbunden werden.';

  @override
  String get errorStitchSave =>
      'Das verbundene Bild konnte nicht gesichert werden.';

  @override
  String get errorOnboarding =>
      'Laden fehlgeschlagen. Bitte öffne die App erneut.';

  @override
  String get errorSignInCancelled => 'Die Anmeldung wurde abgebrochen.';

  @override
  String get errorSignInInterrupted =>
      'Die Anmeldung wurde unterbrochen. Bitte versuche es erneut.';

  @override
  String get errorNetwork => 'Netzwerkfehler. Bitte prüfe deine Verbindung.';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgegangen. Bitte versuche es erneut.';

  @override
  String get errorPlans => 'Die Abopläne konnten nicht geladen werden.';

  @override
  String get errorPurchase =>
      'Der Kauf ist fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get errorNoSubscription =>
      'Für dieses Konto wurde kein aktives Abo gefunden.';

  @override
  String get errorRestore => 'Käufe konnten nicht wiederhergestellt werden.';

  @override
  String get errorStitchTooFew =>
      'Wähle mindestens zwei Screenshots zum Verbinden.';

  @override
  String errorStitchTooMany(int count) {
    return 'Es können bis zu $count Screenshots auf einmal verbunden werden.';
  }

  @override
  String get errorStitchUnreadable =>
      'Einer der Screenshots konnte nicht gelesen werden.';

  @override
  String get errorStitchWidths =>
      'Diese Screenshots sind unterschiedlich breit und können daher nicht zum selben Scroll gehören.';

  @override
  String get errorStitchNoOverlap =>
      'Diese Screenshots überlappen sich nicht. Verbinden klappt nur bei Aufnahmen derselben Seite, die beim Scrollen entstanden sind.';

  @override
  String get errorStitchOverlap =>
      'Die Überlappung zwischen diesen Screenshots ließ sich nicht auflösen.';

  @override
  String get errorStitchTooTall =>
      'Das verbundene Bild wäre zu hoch. Versuche, weniger Screenshots zu verbinden.';

  @override
  String get errorStitchEncode =>
      'Das verbundene Bild konnte nicht kodiert werden.';

  @override
  String get errorRedactionSave =>
      'Die geschützte Kopie konnte nicht gesichert werden.';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Screenshots gesichert',
      one: 'Screenshot gesichert',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'Groß';

  @override
  String get densityMedium => 'Mittel';

  @override
  String get densitySmall => 'Klein';

  @override
  String get sensitiveCard => 'Kartennummer';

  @override
  String get sensitiveIban => 'Bankkonto';

  @override
  String get sensitiveCode => 'Bestätigungscode';

  @override
  String get sensitiveNationalId => 'Ausweisnummer';

  @override
  String get sensitiveEmail => 'E-Mail-Adresse';

  @override
  String get sensitivePhone => 'Telefonnummer';

  @override
  String get sensitiveAddress => 'Adresse';

  @override
  String get sensitiveName => 'Name';

  @override
  String get sensitiveOrderNumber => 'Bestellnummer';

  @override
  String get sensitiveNumber => 'Nummer';

  @override
  String get onbSkip => 'Überspringen';

  @override
  String get onbNext => 'Weiter';

  @override
  String get onbInsideTitle => 'Was steckt in deinen Screenshots?';

  @override
  String get onbInsideBody =>
      'Bordkarten, Bestätigungscodes, ein Foto deines Ausweises. Dinge, die du nie posten würdest.';

  @override
  String get onbSendTitle => 'Verschick sie trotzdem';

  @override
  String get onbSendBody =>
      'Shoto verdeckt das Private zuerst und zeigt dir jede Abdeckung, bevor sie rausgeht.';

  @override
  String get onbYoursTitle => 'Nichts bewegt sich ohne dich';

  @override
  String get onbYoursBody =>
      'Deine Galerie wird nie geöffnet. Nur was du übergibst, bleibt.';

  @override
  String get onbFolderExample => 'Belege';

  @override
  String get onbSearchExample => 'beleg';

  @override
  String get importTitle => 'Screenshots hinzufügen';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Screenshots importiert',
      one: '1 Screenshot importiert',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return '$imported von $picked importiert';
  }

  @override
  String get importFailed => 'Diese Screenshots konnten nicht gesichert werden';

  @override
  String get homeToolImportSubtitle =>
      'Von deinem Handy wählen – deine Galerie wird nie gelesen';

  @override
  String get importPickerUnavailable =>
      'Die Fotoauswahl ließ sich nicht öffnen';

  @override
  String get searchWorking => 'Deine Screenshots werden gelesen …';

  @override
  String get settingsBackup => 'Sichern & wiederherstellen';

  @override
  String get settingsBackupHint =>
      'Eine Kopie deiner Mediathek in einer Datei behalten';

  @override
  String get backupTitle => 'Sicherung';

  @override
  String get backupIntro =>
      'Deine Mediathek lebt auf diesem Handy und nirgends sonst. Eine Sicherung ist die Kopie, die es überlebt, wenn du es verlierst.';

  @override
  String get backupCreateTitle => 'Sicherung erstellen';

  @override
  String get backupCreateBody =>
      'Packt jeden Screenshot, jeden Ordner und jede Markierung in eine Datei und lässt dich dann wählen, wo sie liegt.';

  @override
  String get backupCreateAction => 'Sicherung erstellen';

  @override
  String get backupWorking => 'Deine Mediathek wird gepackt …';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots Screenshots gesichert',
      one: '1 Screenshot gesichert',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders Ordner',
      one: '1 Ordner',
    );
    return '$_temp0 und $_temp1';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots Screenshots gesichert',
      one: '1 Screenshot gesichert',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped konnten nicht gelesen werden',
      one: '1 konnte nicht gelesen werden',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get backupFailed => 'Die Sicherung konnte nicht abgeschlossen werden';

  @override
  String get backupPrivacyNote =>
      'Die Datei entsteht auf diesem Handy und geht nur dorthin, wohin du sie sendest. Es wird nichts hochgeladen.';

  @override
  String get restoreTitle => 'Sicherung wiederherstellen';

  @override
  String get restoreBody =>
      'Fügt alles aus einer Sicherungsdatei zu dieser Mediathek hinzu. Nichts, was schon hier ist, wird entfernt.';

  @override
  String get restoreAction => 'Wiederherstellen';

  @override
  String get restoreWorking => 'Deine Mediathek wird zurückgelegt …';

  @override
  String get restoreConfirmTitle => 'Diese Sicherung wiederherstellen?';

  @override
  String get restoreConfirmMessage =>
      'Alles in der Datei wird deiner Mediathek hinzugefügt. Deine jetzigen Screenshots bleiben genau so, wie sie sind.';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots Screenshots wiederhergestellt',
      one: '1 Screenshot wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders Ordner',
      one: '1 Ordner',
    );
    return '$_temp0 und $_temp1';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots Screenshots wiederhergestellt',
      one: '1 Screenshot wiederhergestellt',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped wurden übersprungen',
      one: '1 wurde übersprungen',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get restoreNotABackup => 'Diese Datei ist keine Shoto-Sicherung';

  @override
  String get restoreFailed =>
      'Die Wiederherstellung konnte nicht abgeschlossen werden';

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String get settingsContactSupport => 'Support kontaktieren';

  @override
  String get supportSubject => 'Shoto Support';

  @override
  String get supportNoMailApp =>
      'Keine E-Mail-App gefunden. Die Adresse wurde stattdessen kopiert.';

  @override
  String get supportGreeting => 'Hallo Shoto-Team,';

  @override
  String get dateToday => 'Heute';

  @override
  String get dateYesterday => 'Gestern';

  @override
  String get dateThisWeek => 'Früher diese Woche';

  @override
  String get dateThisMonth => 'Früher diesen Monat';

  @override
  String get librarySortNewest => 'Neueste zuerst';

  @override
  String get librarySortOldest => 'Älteste zuerst';

  @override
  String get librarySortLabel => 'Reihenfolge';

  @override
  String get libraryShowOnly => 'Nur zeigen';

  @override
  String get libraryShowEverything => 'Alles';

  @override
  String libraryScanPrompt(int count) {
    return '$count Screenshots lesen';
  }

  @override
  String get libraryScanning => 'Wird gelesen …';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ordner gibt es hier schon',
      one: '1 Ordner gibt es hier schon',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'Diese Namen stehen in deiner Mediathek und in der Sicherung. Gleicher Name heißt nicht immer gleicher Ordner, also entscheidest du das hier.';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'und $count weitere',
      one: 'und 1 weiterer',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'Zusammenlegen';

  @override
  String get restoreClashMergeBody =>
      'Screenshots kommen in die Ordner, die du schon hast.';

  @override
  String get restoreClashSeparate => 'Getrennt halten';

  @override
  String get restoreClashSeparateBody =>
      'Erstellt einen zweiten Ordner mit demselben Namen. Nichts Bestehendes wird angetastet.';

  @override
  String get intentBuy => 'Kaufen';

  @override
  String get intentRead => 'Lesen';

  @override
  String get intentReply => 'Antworten';

  @override
  String get intentTry => 'Ausprobieren';

  @override
  String get intentVisit => 'Besuchen';

  @override
  String get intentBuyWaiting => 'Zu kaufen';

  @override
  String get intentReadWaiting => 'Zu lesen';

  @override
  String get intentReplyWaiting => 'Zu beantworten';

  @override
  String get intentTryWaiting => 'Auszuprobieren';

  @override
  String get intentVisitWaiting => 'Zu besuchen';

  @override
  String get intentWatch => 'Ansehen';

  @override
  String get intentListen => 'Anhören';

  @override
  String get intentCook => 'Kochen';

  @override
  String get intentBook => 'Buchen';

  @override
  String get intentPay => 'Bezahlen';

  @override
  String get intentSend => 'Senden';

  @override
  String get intentDownload => 'Herunterladen';

  @override
  String get intentApply => 'Bewerben';

  @override
  String get intentCompare => 'Vergleichen';

  @override
  String get intentFix => 'Reparieren';

  @override
  String get intentWatchWaiting => 'Anzusehen';

  @override
  String get intentListenWaiting => 'Anzuhören';

  @override
  String get intentCookWaiting => 'Zu kochen';

  @override
  String get intentBookWaiting => 'Zu buchen';

  @override
  String get intentPayWaiting => 'Zu bezahlen';

  @override
  String get intentSendWaiting => 'Zu senden';

  @override
  String get intentDownloadWaiting => 'Herunterzuladen';

  @override
  String get intentApplyWaiting => 'Zu bewerben';

  @override
  String get intentCompareWaiting => 'Zu vergleichen';

  @override
  String get intentFixWaiting => 'Zu reparieren';

  @override
  String get intentMore => 'Mehr';

  @override
  String get intentSectionCommon => 'Vorgefertigt';

  @override
  String get intentSectionYours => 'Deine';

  @override
  String get intentYoursEmpty =>
      'Ein Verb, das du selbst schreibst, arbeitet genau wie die oben.';

  @override
  String get intentNewAction => 'Selbst schreiben';

  @override
  String get intentNewTitle => 'Benenne es selbst';

  @override
  String get intentEditTitle => 'Diesen bearbeiten';

  @override
  String get intentNameLabel => 'Das Verb';

  @override
  String get intentNameHint => 'Zurückschicken, stornieren, anrufen …';

  @override
  String get intentIconLabel => 'Symbol';

  @override
  String intentDeleteTitle(String label) {
    return '„$label“ löschen?';
  }

  @override
  String get intentDeleteMessage =>
      'Die Screenshots bleiben, wo sie sind. Sie warten nur auf nichts mehr.';

  @override
  String get intentSelectionAction => 'Markieren als';

  @override
  String intentSelectionApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Screenshots markiert',
      one: '1 Screenshot markiert',
    );
    return '$_temp0';
  }

  @override
  String get intentPrompt => 'Wofür er ist, wenn du magst';

  @override
  String get intentSkip => 'Nichts Bestimmtes';

  @override
  String get intentWaitingTitle => 'Wartet auf dich';

  @override
  String get intentNothingWaiting => 'Nichts wartet auf dich';

  @override
  String get intentAllDone =>
      'Du hast alles erledigt, was du dir aufgehoben hast.';

  @override
  String get intentMarkDone => 'Erledigt';

  @override
  String get intentUndo => 'Zurücklegen';

  @override
  String get intentDoneToast => 'Abgehakt';

  @override
  String get intentChange => 'Ändern, wofür das ist';

  @override
  String get intentClear => 'Für nichts Bestimmtes';

  @override
  String intentEmptyOne(String verb) {
    return 'Hier gibt es nichts zu $verb';
  }

  @override
  String get intentEmptyBody =>
      'Screenshots, die du markierst, landen hier, bis du sie abhakst.';

  @override
  String intentDoneCount(int count) {
    return '$count erledigt';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Wochen',
      one: 'vor 1 Woche',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Monaten',
      one: 'vor 1 Monat',
    );
    return '$_temp0';
  }
}
