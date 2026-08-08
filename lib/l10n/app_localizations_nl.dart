// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get settingsCrashReports => 'Crashrapporten';

  @override
  String get settingsCrashReportsHint =>
      'Technische details sturen als er iets misgaat';

  @override
  String get settingsSignOut => 'Uitloggen';

  @override
  String get settingsSignOutTitle => 'Uitloggen?';

  @override
  String get authWelcome => 'Welkom bij SHOTO';

  @override
  String get authSubtitle =>
      'Inloggen houdt je abonnement bij je als je van telefoon wisselt. Je screenshots blijven hoe dan ook op dit toestel — een account neemt ze nooit mee.';

  @override
  String get authGoogle => 'Doorgaan met Google';

  @override
  String get authApple => 'Doorgaan met Apple';

  @override
  String get authLegal =>
      'Door verder te gaan ga je akkoord met onze Servicevoorwaarden en het Privacybeleid.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSignOutHint => 'Je screenshots blijven op dit toestel';

  @override
  String get settingsSignIn => 'Inloggen';

  @override
  String get settingsSignInHint =>
      'Optioneel. Alleen nodig om een aankoop naar een andere telefoon te verhuizen.';

  @override
  String paywallTrialCta(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Start $days dagen gratis',
      one: 'Start 1 dag gratis',
    );
    return '$_temp0';
  }

  @override
  String paywallTrialNote(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          '$days dagen gratis, daarna $price. Je kunt altijd opzeggen voordat het afloopt.',
      one:
          'Een dag gratis, daarna $price. Je kunt altijd opzeggen voordat het afloopt.',
    );
    return '$_temp0';
  }

  @override
  String get triageTitle => 'Sinds je laatste blik';

  @override
  String get triageBody =>
      'Houd wat in SHOTO thuishoort. De rest blijft precies waar het staat.';

  @override
  String get triageKeep => 'Houden';

  @override
  String get triageSkip => 'Overslaan';

  @override
  String get triageFinish => 'Klaar';

  @override
  String triageProgress(int index, int total) {
    return '$index van $total';
  }

  @override
  String triageNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nieuwe screenshots',
      one: '1 nieuw screenshot',
    );
    return '$_temp0';
  }

  @override
  String triageKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gehouden',
      one: '1 gehouden',
      zero: 'Niets gehouden',
    );
    return '$_temp0';
  }

  @override
  String get triageReview => 'Bekijken';

  @override
  String get triageInviteDecline => 'Nu niet';

  @override
  String get triageInviteTitle => 'Nieuwe screenshots hier tonen?';

  @override
  String get triageInviteBody =>
      'SHOTO kan vanaf nu tonen wat je vastlegt, zodat je de paar bewaart die ertoe doen. Er komt niets in je bibliotheek tot jij dat zegt.';

  @override
  String get triageInviteAccept => 'Toon ze';

  @override
  String get triageInviteDismiss => 'Nee, bedankt';

  @override
  String get settingsTriage => 'Nieuwe screenshots aanbieden';

  @override
  String get settingsTriageHint =>
      'Laat zien wat je vastlegt; houdt uit zichzelf niets';

  @override
  String get triageNothingNew => 'Niets nieuws om te bekijken';

  @override
  String get settingsYourName => 'Je naam';

  @override
  String get settingsYourNameHint =>
      'Zodat Safe Share hem kan afdekken als hij opduikt';

  @override
  String get settingsYourNameNotSet => 'Niet ingesteld';

  @override
  String get ownerNameTitle => 'Je naam';

  @override
  String get ownerNameBody =>
      'Safe Share vindt kaartnummers en codes via hun eigen rekenregels. Een naam vindt het alleen als het de jouwe al kent. Eén keer getypt, blijft op deze telefoon, gaat nergens heen.';

  @override
  String get ownerNameFieldHint => 'De naam die je bank afdrukt';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get commonDelete => 'Verwijderen';

  @override
  String get commonRetry => 'Opnieuw proberen';

  @override
  String get commonSomethingWentWrong => 'Er ging iets mis';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'Start';

  @override
  String get navLibrary => 'Bibliotheek';

  @override
  String get navFolders => 'Mappen';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get tagline => 'Je screenshots, op orde';

  @override
  String get homeGreetingMorning => 'Goedemorgen';

  @override
  String get homeGreetingAfternoon => 'Goedemiddag';

  @override
  String get homeGreetingEvening => 'Goedenavond';

  @override
  String get homeInboxEmpty => 'Nog niets bewaard';

  @override
  String get homeInboxEmptySubtitle =>
      'Kies er nu een paar van je telefoon, of deel vanuit elke app een screenshot naar SHOTO.';

  @override
  String get homeEmptyImportCta => 'Kies van mijn telefoon';

  @override
  String get homeInboxClear => 'Alles opgeborgen';

  @override
  String get homeInboxClearSubtitle => 'Niets wacht om gesorteerd te worden';

  @override
  String get homeInboxCountSubtitle =>
      'Screenshots die je nog niet hebt opgeborgen';

  @override
  String get homeStatScreenshots => 'Screenshots';

  @override
  String get homeStatFavorites => 'Favorieten';

  @override
  String get homeStatFolders => 'Mappen';

  @override
  String get homeToolsTitle => 'Gereedschap';

  @override
  String get homeToolsTitleEmpty => 'Begin hier';

  @override
  String get homeToolSafeShare => 'Safe share';

  @override
  String get homeToolSafeShareSubtitle => 'Verberg eerst privégegevens';

  @override
  String get homeToolDuplicates => 'Dubbele vinden';

  @override
  String get homeToolDuplicatesSubtitle => 'Ruimte vrijmaken';

  @override
  String get homeToolSearch => 'Erin zoeken';

  @override
  String get homeToolSearchSubtitle => 'Vind tekst in je afbeeldingen';

  @override
  String get homeToolStitch => 'Lange shots samenvoegen';

  @override
  String get homeToolStitchSubtitle => 'Zet een scrollopname weer in elkaar';

  @override
  String get homeRecent => 'Recent';

  @override
  String get libraryPickForMerge =>
      'Kies twee of meer opnamen van dezelfde pagina';

  @override
  String get libraryPickForProtect => 'Kies het screenshot om te beschermen';

  @override
  String get libraryActionProtect => 'Beschermen';

  @override
  String get homeSeeAll => 'Alles bekijken';

  @override
  String get libraryEmptyTitle => 'Nog niets bewaard';

  @override
  String get libraryEmptyMessage =>
      'Deel een screenshot met SHOTO, of voeg er een toe met de +-knop. Je galerij wordt nooit gelezen — alleen wat je overhandigt blijft.';

  @override
  String get libraryNoFavoritesTitle => 'Nog geen favorieten';

  @override
  String get libraryNoFavoritesMessage =>
      'Tik op het hartje bij een screenshot om het hier te bewaren.';

  @override
  String get libraryFilterAll => 'Alle';

  @override
  String get libraryFilterFavorites => 'Favorieten';

  @override
  String get libraryTraitSensitive => 'Gevoelig';

  @override
  String get libraryTraitLink => 'Links';

  @override
  String get libraryTraitContact => 'Telefoon of e-mail';

  @override
  String get libraryTraitCode => 'Codes';

  @override
  String get libraryTraitEvent => 'Data';

  @override
  String get libraryCertaintyVerified => 'Met controlegetal bevestigd';

  @override
  String get libraryCertaintyRead => 'Gelezen uit de tekst in je screenshots';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count nog niet gelezen';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return 'Geen screenshots met $trait';
  }

  @override
  String get libraryNoTraitMessage =>
      'Geen enkel gelezen screenshot bevat hiervan iets.';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'Niets gevonden in wat gelezen is. $count screenshots zijn nooit gelezen en kunnen dus nog niet meedoen.';
  }

  @override
  String get libraryShowAll => 'Alles tonen';

  @override
  String get libraryFilterUnsorted => 'Ongesorteerd';

  @override
  String get libraryNoUnsortedTitle => 'Alles is opgeborgen';

  @override
  String get libraryNoUnsortedMessage =>
      'Er wacht niets op je. Nieuwe screenshots blijven hier tot je ze opbergt of markeert.';

  @override
  String librarySelectedCount(int count) {
    return '$count geselecteerd';
  }

  @override
  String get librarySelectAll => 'Alles selecteren';

  @override
  String get libraryActionMerge => 'Samenvoegen';

  @override
  String get libraryActionMove => 'Verplaatsen';

  @override
  String get libraryActionDelete => 'Verwijderen';

  @override
  String get libraryDeleteTitle => 'Screenshots verwijderen?';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dit verwijdert $count screenshots definitief van je toestel.',
      one: 'Dit verwijdert 1 screenshot definitief van je toestel.',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'Fototoegang nodig';

  @override
  String get permissionNeededMessage =>
      'SHOTO bewaart de screenshots die je erin deelt in een eigen album. Het heeft fototoegang nodig om daar te schrijven en ze terug te lezen — de rest van je galerij wordt nooit opgesomd.';

  @override
  String get permissionAskTitle =>
      'SHOTO moet zijn screenshot-album kunnen zien';

  @override
  String get permissionAskMessage =>
      'Alleen dat album, en alleen om te tonen wat erin zit. Er wordt niets geüpload, en er komt niets in je bibliotheek tot jij het kiest.';

  @override
  String get permissionAllow => 'Toegang toestaan';

  @override
  String get permissionPartialTitle => 'Volledige fototoegang nodig';

  @override
  String get permissionPartialMessage =>
      'SHOTO ziet nu alleen een paar foto\'s die je met de hand koos en komt zo niet bij zijn eigen album. Kies „Alle toestaan” bij de fotorechten om verder te gaan.';

  @override
  String get permissionOpenSettings => 'Instellingen openen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsAppearance => 'Weergave';

  @override
  String get settingsTheme => 'Thema';

  @override
  String get settingsThemeSystem => 'Systeem';

  @override
  String get settingsThemeLight => 'Licht';

  @override
  String get settingsThemeDark => 'Donker';

  @override
  String get settingsGridDensity => 'Rasterdichtheid';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsLanguageSystem => 'Zoals mijn telefoon';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Toont nu $language';
  }

  @override
  String get settingsBehaviour => 'Gedrag';

  @override
  String get settingsHaptics => 'Trilfeedback';

  @override
  String get settingsHapticsHint => 'Een klein tikje als je iets indrukt';

  @override
  String get settingsConfirmDelete => 'Vragen voor het verwijderen';

  @override
  String get settingsConfirmDeleteHint =>
      'Verwijderen kan niet ongedaan worden gemaakt';

  @override
  String get settingsFindDuplicates => 'Dubbele vinden';

  @override
  String get settingsClearCache => 'Afbeeldingscache legen';

  @override
  String get settingsShare => 'SHOTO delen';

  @override
  String get settingsPrivacyNote =>
      'SHOTO bewaart alleen de screenshots die je het geeft, en alles wat het ermee doet — tekst lezen, dubbele vinden — gebeurt op dit toestel. Je afbeeldingen worden nooit geüpload. Drie dingen zet je zelf aan: nieuwe screenshots aanbieden leest je Screenshots-album om ernaar te kunnen vragen, een account stuurt alleen je e-mailadres zodat een abonnement een nieuwe telefoon overleeft, en crashrapporten sturen wat er stukging — de code, nooit een afbeelding.';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonConfirm => 'Bevestigen';

  @override
  String get commonRename => 'Hernoemen';

  @override
  String get commonShare => 'Delen';

  @override
  String get commonUnlock => 'Ontgrendelen';

  @override
  String get foldersEmptyTitle => 'Nog geen mappen';

  @override
  String get foldersEmptyMessage =>
      'Mappen zijn hoe je dingen later terugvindt. Maak er een voor bonnetjes, een voor recepten — waar je echt naar gaat zoeken.';

  @override
  String get foldersNew => 'Nieuwe map';

  @override
  String get foldersCreate => 'Map maken';

  @override
  String get foldersNameLabel => 'Mapnaam';

  @override
  String get foldersNameHint => 'Bonnetjes, Recepten, Werk…';

  @override
  String get foldersPrivate => 'Privé (gezichts- of vingerafdrukslot)';

  @override
  String get foldersPrivateFace => 'Privé (gezichtsslot)';

  @override
  String get foldersPrivateFingerprint => 'Privé (vingerafdrukslot)';

  @override
  String get foldersPrivateGeneric => 'Privé (vergrendeld)';

  @override
  String get foldersOptions => 'Mapopties';

  @override
  String get foldersDelete => 'Map verwijderen';

  @override
  String get foldersDeleteKept => 'De screenshots erin blijven bestaan';

  @override
  String foldersDeleteTitle(String name) {
    return '„$name” verwijderen?';
  }

  @override
  String get foldersDeleteMessage =>
      'De map verdwijnt, maar de screenshots erin blijven in je bibliotheek.';

  @override
  String get foldersRenameTitle => 'Map hernoemen';

  @override
  String get foldersMoveTitle => 'Naar map verplaatsen';

  @override
  String get foldersMoveRemove => 'Uit de map halen';

  @override
  String get foldersMoveNone =>
      'Nog geen mappen. Maak er een via het tabblad Mappen.';

  @override
  String folderLockedTitle(String name) {
    return '„$name” ontgrendelen';
  }

  @override
  String get folderLockedMessage =>
      'Deze map is beveiligd. Verifieer jezelf om hem te bekijken.';

  @override
  String get folderEmptyTitle => 'Hier staat nog niets';

  @override
  String get folderEmptyMessage =>
      'Verplaats screenshots vanuit je bibliotheek naar deze map.';

  @override
  String get detailFavorite => 'Favoriet';

  @override
  String get detailUnfavorite => 'Uit favorieten halen';

  @override
  String get detailAddFavorite => 'Aan favorieten toevoegen';

  @override
  String get detailActions => 'Acties';

  @override
  String get detailSafeShare => 'Safe share';

  @override
  String get detailMore => 'Meer';

  @override
  String get detailDeleteTitle => 'Screenshot verwijderen?';

  @override
  String get detailDeleteMessage =>
      'Dit verwijdert het definitief van je toestel.';

  @override
  String get quickSaveTitleOne => 'Bewaren in SHOTO';

  @override
  String quickSaveTitleMany(int count) {
    return '$count screenshots bewaren';
  }

  @override
  String get quickSaveFileOne => 'Dit screenshot opbergen';

  @override
  String quickSaveFileMany(int count) {
    return '$count screenshots opbergen';
  }

  @override
  String get quickSavePickFolder => 'Kies een map';

  @override
  String get quickSaveNeedFolder => 'Maak een map om ze in te zetten';

  @override
  String quickSaveFileIn(String folder) {
    return 'Opbergen in $folder';
  }

  @override
  String get quickSaveCreateFirstFolder => 'Maak je eerste map';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'Mappen zijn hoe je dingen later terugvindt';

  @override
  String get quickSaveNewChip => 'Nieuw';

  @override
  String get quickSaveSaved => 'Bewaard in SHOTO';

  @override
  String quickSaveFiled(String folder) {
    return 'Opgeborgen in $folder.';
  }

  @override
  String get quickSaveFailedTitle => 'Kon die afbeelding niet lezen';

  @override
  String get quickSaveFailedBody => 'Probeer hem opnieuw te delen.';

  @override
  String quickSaveSkipped(int count) {
    return 'Alleen de eerste $count zijn overgenomen';
  }

  @override
  String get dupTitle => 'Dubbele vinden';

  @override
  String get dupScanning => 'Op zoek naar dubbele';

  @override
  String get dupReading => 'Je bibliotheek wordt gelezen…';

  @override
  String dupProgress(int done, int total) {
    return '$done van $total screenshots gecontroleerd';
  }

  @override
  String get dupNoneTitle => 'Geen dubbele gevonden';

  @override
  String get dupNoneBody => 'Je screenshotbibliotheek is al opgeruimd.';

  @override
  String get dupScanAgain => 'Opnieuw scannen';

  @override
  String dupReclaimable(String size) {
    return 'Er kan tot $size vrijkomen';
  }

  @override
  String get dupNothingSelected => 'Niets geselecteerd';

  @override
  String dupDeleteButton(int count, String size) {
    return '$count verwijderen · $size vrij';
  }

  @override
  String dupDeleteTitle(int count) {
    return '$count kopieën verwijderen?';
  }

  @override
  String get dupDeleteMessage =>
      'Dit verwijdert ze definitief van je toestel. De kopieën die je wilt houden blijven ongemoeid.';

  @override
  String dupDeleted(int count, String size) {
    return '$count verwijderd · $size vrijgemaakt';
  }

  @override
  String dupSets(int count) {
    return '$count groepen';
  }

  @override
  String get dupBest => 'BESTE';

  @override
  String get dupKeepAll => 'Alle houden';

  @override
  String get dupKeepingAll =>
      'Je houdt ze allemaal — er wordt niets verwijderd';

  @override
  String get dupUndo => 'Ongedaan maken';

  @override
  String dupFrees(String size) {
    return 'Maakt $size vrij';
  }

  @override
  String get safeShareTitle => 'Safe share';

  @override
  String get safeShareScanning => 'Op zoek naar privégegevens';

  @override
  String get safeShareOnDevice => 'Het lezen gebeurt op je telefoon.';

  @override
  String get safeShareCleanTitle => 'Niets privés gevonden';

  @override
  String get safeShareCleanBody =>
      'In dit screenshot zijn geen kaartnummers, rekeningnummers, codes of contactgegevens gezien. Je kunt het delen zoals het is.';

  @override
  String get safeShareUnreadableTitle => 'Kon dit screenshot niet lezen';

  @override
  String get safeShareUnreadableBody => 'De tekst erin werd niet herkend.';

  @override
  String get safeShareShareUnchanged => 'Ongewijzigd delen';

  @override
  String get safeShareShareAnyway => 'Toch delen';

  @override
  String get safeShareShareProtected => 'Beschermde kopie delen';

  @override
  String get safeShareFailed => 'Kon de beschermde kopie niet maken.';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count privégegevens gevonden',
      one: '1 privégegeven gevonden',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'Controleren is altijd gratis.';

  @override
  String get safeShareCleanAction => 'Dit screenshot schoonmaken';

  @override
  String get safeShareShareAsIs => 'Delen zonder wijzigingen';

  @override
  String get safeShareHowTitle => 'Afgedekt, voorgoed';

  @override
  String get safeShareHowBody =>
      'Elk privégegeven wordt met een dicht blok afgedekt voordat de kopie je telefoon verlaat. Niets is vervaagd en niets is terug te lezen — de afgedekte kopie is de enige versie die bestaat.';

  @override
  String get safeShareTreatmentCover => 'Afdekken';

  @override
  String get safeShareTreatmentKeep => 'Houden';

  @override
  String get safeShareBuilding => 'Je schone kopie wordt gemaakt';

  @override
  String get safeShareNothingSelected => 'Er verandert niets';

  @override
  String get safeShareLockedPreview => 'Ontgrendel om de schone versie te zien';

  @override
  String get safeShareReviewTitle => 'Bekijk ze stuk voor stuk';

  @override
  String safeShareFound(int count) {
    return '$count dingen afgedekt';
  }

  @override
  String get stitchTitle => 'Screenshots samenvoegen';

  @override
  String get stitchWorking => 'Op zoek naar de overlap';

  @override
  String get stitchWorkingBody =>
      'Er wordt gezocht waar elk screenshot verdergaat waar het vorige stopte.';

  @override
  String get stitchFailed => 'Samenvoegen lukte niet';

  @override
  String get stitchSave => 'Bewaren in galerij';

  @override
  String get stitchSaved => 'Bewaard in je galerij';

  @override
  String get stitchDiscard => 'Weggooien';

  @override
  String get commonDone => 'Klaar';

  @override
  String get commonBack => 'Terug';

  @override
  String get commonClose => 'Sluiten';

  @override
  String get searchTitle => 'Zoek in je screenshots';

  @override
  String get searchHint => 'Zoek woorden of wat een afbeelding toont';

  @override
  String get searchIntro =>
      'Elk woord dat in een afbeelding staat, of wat de afbeelding toont — probeer „kat”, „dier”, „eten” of „bonnetje”.';

  @override
  String get searchNoneTitle => 'Geen resultaten';

  @override
  String searchNoneBody(String query) {
    return 'Hier staat of lijkt niets op „$query”.';
  }

  @override
  String get paywallTitle => 'SHOTO Pro ontgrendelen';

  @override
  String get paywallSubtitle => 'Alles hieronder, met één abonnement.';

  @override
  String get paywallMonthly => 'Maandelijks';

  @override
  String get paywallYearly => 'Jaarlijks';

  @override
  String paywallSave(int percent) {
    return 'Bespaar $percent%';
  }

  @override
  String get paywallContinue => 'Doorgaan';

  @override
  String get paywallUnavailable => 'Nog niet beschikbaar';

  @override
  String get paywallRestore => 'Aankopen herstellen';

  @override
  String get paywallLegal =>
      'Verlengt automatisch tot je opzegt. Opzeggen kan altijd via je account-instellingen in de App Store of Google Play. Door verder te gaan ga je akkoord met onze Servicevoorwaarden en het Privacybeleid.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'SHOTO Pro';

  @override
  String get subPremiumBody => 'Elke functie voor je ontgrendeld.';

  @override
  String get subDevUnlock => 'Testertoegang';

  @override
  String get subDevUnlockBody =>
      'Ontgrendeld op dit toestel — geen echt abonnement';

  @override
  String get subUnlockEverything => 'Alles ontgrendelen';

  @override
  String get proWelcomeTitle => 'Je zit op Pro';

  @override
  String get proWelcomeBody =>
      'Elke functie is ontgrendeld. Er valt verder niets in te stellen.';

  @override
  String get proWelcomeAction => 'Aan de slag';

  @override
  String get featSafeShare => 'Safe share';

  @override
  String get featSafeShareBody =>
      'Vindt kaartnummers, adressen, namen en contactgegevens en dekt elk ervan af met een dicht blok. De tekst eromheen blijft staan, dus het beeld blijft leesbaar — en de verstuurde kopie heeft geen laag die je eraf kunt halen.';

  @override
  String get featActions => 'Maak van screenshots acties';

  @override
  String get featActionsBody =>
      'Open een link, schrijf naar een adres, kopieer een verificatiecode of een IBAN — rechtstreeks uit de afbeelding, zonder iets over te typen.';

  @override
  String get featDuplicates => 'Dubbele vinden';

  @override
  String get featDuplicatesBody =>
      'Spot bijna identieke opnamen die je dubbel bewaarde en ruimt ze op — altijd eerst met een controle.';

  @override
  String get featStitch => 'Lange screenshots samenvoegen';

  @override
  String get featStitchBody =>
      'Zet een scrollopname weer in elkaar tot één hoge afbeelding, met de overlap automatisch gevonden en weggehaald.';

  @override
  String get featUnlimited => 'Geen plafond voor je bibliotheek';

  @override
  String featUnlimitedBody(Object count) {
    return 'De gratis versie ordent $count screenshots. Pro haalt het getal weg.';
  }

  @override
  String get featSafeShareHow =>
      'Vinden wat privé is in een screenshot is gratis en onbeperkt. Je betaalt om die vondsten om te zetten in een schone kopie: elk gegeven dat je aangevinkt laat, wordt afgedekt in de geëxporteerde afbeelding, en die is plat — geen laag om ongedaan te maken.';

  @override
  String get featSafeSharePoint1 =>
      'Kaartnummers worden met Luhn gecontroleerd en IBANs met modulo 97: die twee zijn bewezen in plaats van geraden, precies bij het gegeven dat het zwaarst weegt.';

  @override
  String get featSafeSharePoint2 =>
      'Pikt ook namen, adressen, bestelnummers, verificatiecodes, telefoonnummers en e-mailadressen op.';

  @override
  String get featSafeSharePoint3 =>
      'Je ziet alles wat gevonden is voor je verstuurt en kunt laten staan wat de app verkeerd had. Het originele screenshot wordt nooit aangeraakt.';

  @override
  String get featActionsHow =>
      'Wat er in een screenshot staat, wordt iets wat je kunt gebruiken. SHOTO haalt de bruikbare stukken eruit en zet op elk een knop.';

  @override
  String get featActionsPoint1 =>
      'Links, e-mailadressen, IBANs, verificatiecodes, data en pakketnummers worden voor je gevonden.';

  @override
  String get featActionsPoint2 =>
      'Eén tik om te openen of te kopiëren — geen tekens meer van een plaatje aflezen.';

  @override
  String get featActionsPoint3 =>
      'Werkt op de screenshots die je al hebt, niet alleen op nieuwe.';

  @override
  String get featStitchHow =>
      'Een scrollopname moet op telefoons die het kunnen gestart worden terwijl je nog op de pagina bent. SHOTO werkt daarna: kies twee of meer opnamen die al in je bibliotheek staan — ook die iemand je stuurde — en het vindt waar ze overlappen en voegt ze tot één hoge afbeelding.';

  @override
  String get featStitchPoint1 =>
      'De herhaalde strook tussen twee opnamen wordt automatisch gevonden en weggehaald.';

  @override
  String get featStitchPoint2 =>
      'Je ziet de naad voordat er iets bewaard wordt — automatisch herkennen is goed, maar nooit zeker.';

  @override
  String get featStitchPoint3 =>
      'De samengevoegde afbeelding komt als elke andere foto in je galerij.';

  @override
  String get featDuplicatesHow =>
      'Opnamen één voor één indelen levert zelden dubbele op. Een reeks houden uit „Sinds je laatste blik” wel — je gaat snel, en twee opnamen van hetzelfde blijven allebei staan. SHOTO vergelijkt hoe een opname eruitziet, niet de naam of de grootte, dus het pakt ook een doorstuur of een andere uitsnede.';

  @override
  String get featDuplicatesPoint1 =>
      'Groepeert wat er hetzelfde uitziet en stelt de kopie voor die het waard is te houden.';

  @override
  String get featDuplicatesPoint2 =>
      'Laat zien hoeveel ruimte elke groep vrijmaakt voordat je iets beslist.';

  @override
  String get featDuplicatesPoint3 =>
      'Er wordt niets verwijderd tot je de groep hebt bekeken en bevestigd.';

  @override
  String get featUnlimitedHow =>
      'De gratis versie is een echte, bruikbare app: bewaren, mappen, favorieten en volledige zoekfunctie, zonder account en zonder uploads. Er is precies één plafond — hoeveel screenshots het ordent — en Pro haalt dat weg. Alles wat je al geordend hebt blijft precies waar het staat.';

  @override
  String get featUnlimitedPoint1 =>
      'Mappen zijn onbeperkt in de gratis versie, en dat was altijd de bedoeling.';

  @override
  String get featUnlimitedPoint2 =>
      'Benoemen waar een screenshot voor is, is ook gratis en onbeperkt.';

  @override
  String get featUnlimitedPoint3 =>
      'Tegen het plafond aanlopen betekent dat SHOTO je bewaarplek is geworden. Er wordt daarbij niets verwijderd.';

  @override
  String get includedSubtitle => 'Elke Pro-functie, uitgelegd.';

  @override
  String get includedHint => 'Tik op een functie om te zien hoe die werkt';

  @override
  String get includedHowLabel => 'Hoe het werkt';

  @override
  String get includedActiveTitle => 'Je abonnement is actief';

  @override
  String get includedActiveBody =>
      'Alles hieronder is ontgrendeld op dit account.';

  @override
  String get includedLockedTitle => 'Nog niet ontgrendeld';

  @override
  String get includedLockedBody =>
      'Lees wat elk ding echt doet en beslis daarna.';

  @override
  String get includedFreeTitle => 'Wat de gratis versie je geeft';

  @override
  String includedFreeBody(int count) {
    return '$count geordende screenshots, onbeperkt mappen en volledig zoeken — voorgoed gratis.';
  }

  @override
  String get onboardingCta => 'Aan de slag';

  @override
  String get onboardingPromise => 'Je screenshots blijven op je telefoon.';

  @override
  String get actionsTitle => 'Acties';

  @override
  String get actionsWorking => 'Het screenshot wordt gelezen';

  @override
  String get actionsWorkingBody => 'Op zoek naar nummers, links en codes.';

  @override
  String get actionsNoneTitle => 'Niets om mee te doen';

  @override
  String get actionsNoneBody =>
      'In dit screenshot zijn geen links, codes of rekeningnummers gevonden.';

  @override
  String get actionsCopy => 'Kopiëren';

  @override
  String get actionsCopied => 'Gekopieerd';

  @override
  String get actionsNoApp => 'Geen app op dit toestel kan dat.';

  @override
  String get devModeOn => 'Ontwikkelaarsmodus aan — elke functie ontgrendeld';

  @override
  String get devModeBadge => 'ONTWIKKELAARSMODUS';

  @override
  String get devModeOffTitle => 'Ontwikkelaarsmodus uitzetten?';

  @override
  String get devModeOffBody =>
      'SHOTO gaat op dit toestel terug naar de gratis versie, zodat je de paywall en de limieten opnieuw kunt testen.';

  @override
  String get devModeOffConfirm => 'Uitzetten';

  @override
  String get devAccessTitle => 'Ontwikkelaarstoegang';

  @override
  String get devAccessBody =>
      'Voer de 4-cijferige code in om elke Pro-functie op dit toestel te ontgrendelen.';

  @override
  String get devWrongCode => 'Verkeerde code';

  @override
  String devTapToDisable(int count) {
    return 'Tik $count× om uit te zetten';
  }

  @override
  String appVersion(String version) {
    return 'Versie $version';
  }

  @override
  String get kindCard => 'een kaartnummer';

  @override
  String get kindIban => 'een bankrekening';

  @override
  String get kindCode => 'een verificatiecode';

  @override
  String get kindNationalId => 'een identiteitsnummer';

  @override
  String get kindEmail => 'een e-mailadres';

  @override
  String get kindLink => 'een link';

  @override
  String get actionEmailAction => 'Schrijven';

  @override
  String get actionOpen => 'Openen';

  @override
  String get kindEvent => 'een afspraak';

  @override
  String get kindPlace => 'een plek';

  @override
  String get kindWifi => 'een wifinetwerk';

  @override
  String get kindTracking => 'een zending';

  @override
  String get actionAddToCalendar => 'Aan agenda toevoegen';

  @override
  String get actionOpenMaps => 'Openen in Maps';

  @override
  String get actionDirections => 'Route';

  @override
  String get actionCopyNetwork => 'Naam kopiëren';

  @override
  String get actionTrack => 'Volgen';

  @override
  String get actionEventUntitled => 'Afspraak';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshots',
      one: '1 screenshot',
      zero: 'Geen screenshots',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$position van $total';
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
      other: '$count groepen dubbele',
      one: '1 groep dubbele',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count vergelijkbare kopieën';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dingen gevonden',
      one: '1 ding gevonden',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'Opslag';

  @override
  String get settingsDuplicatesHint => 'Spot screenshots die je twee keer nam';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'Wat erbij zit';

  @override
  String settingsFeatureCount(int count) {
    return '$count functies, één abonnement';
  }

  @override
  String get settingsShareHint => 'Vertel het iemand die het nodig heeft';

  @override
  String get settingsShareText =>
      'SHOTO houdt mijn screenshots vanzelf op orde — alles blijft op de telefoon.';

  @override
  String get settingsCacheMeasuring => 'Wordt gemeten…';

  @override
  String settingsCacheSize(String size) {
    return '$size aan miniaturen';
  }

  @override
  String get homeSafeShareHint =>
      'Open een screenshot en tik dan op Safe share.';

  @override
  String get homeStitchHint =>
      'Houd twee of meer screenshots in je bibliotheek ingedrukt en tik dan op Samenvoegen.';

  @override
  String stitchLimit(int count) {
    return 'Voeg tot $count screenshots tegelijk samen.';
  }

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Screenshots bewaard. In een map zetten?',
      one: 'Screenshot bewaard. In een map zetten?',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count screenshots samengevoegd';
  }

  @override
  String stitchResultTrimmed(int count) {
    return '$count px herhaalde inhoud weggehaald';
  }

  @override
  String get errorLoadScreenshots =>
      'Je screenshots konden niet worden geladen.';

  @override
  String get errorLoadFolders => 'Je mappen konden niet worden geladen.';

  @override
  String get errorScanDuplicates => 'Er kon niet op dubbele worden gescand.';

  @override
  String get errorDeleteSelected =>
      'De geselecteerde screenshots konden niet worden verwijderd.';

  @override
  String get errorStitchFailed =>
      'Deze screenshots konden niet worden samengevoegd.';

  @override
  String get errorStitchSave =>
      'De samengevoegde afbeelding kon niet worden bewaard.';

  @override
  String get errorOnboarding => 'Laden lukte niet. Open de app opnieuw.';

  @override
  String get errorSignInCancelled => 'Het inloggen is geannuleerd.';

  @override
  String get errorSignInInterrupted =>
      'Het inloggen werd onderbroken. Probeer het opnieuw.';

  @override
  String get errorNetwork => 'Netwerkfout. Controleer je verbinding.';

  @override
  String get errorGeneric => 'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get errorPlans => 'De abonnementen konden niet worden geladen.';

  @override
  String get errorPurchase => 'De aankoop is mislukt. Probeer het opnieuw.';

  @override
  String get errorNoSubscription =>
      'Geen actief abonnement gevonden voor dit account.';

  @override
  String get errorRestore => 'Aankopen konden niet worden hersteld.';

  @override
  String get errorStitchTooFew =>
      'Kies minstens twee screenshots om samen te voegen.';

  @override
  String errorStitchTooMany(int count) {
    return 'Er kunnen tot $count screenshots tegelijk worden samengevoegd.';
  }

  @override
  String get errorStitchUnreadable =>
      'Een van de screenshots kon niet worden gelezen.';

  @override
  String get errorStitchWidths =>
      'Deze screenshots zijn verschillend breed en kunnen dus niet bij dezelfde scroll horen.';

  @override
  String get errorStitchNoOverlap =>
      'Deze screenshots overlappen niet. Samenvoegen werkt alleen bij opnamen van dezelfde pagina die tijdens het scrollen zijn gemaakt.';

  @override
  String get errorStitchOverlap =>
      'De overlap tussen deze screenshots kon niet worden bepaald.';

  @override
  String get errorStitchTooTall =>
      'De samengevoegde afbeelding zou te hoog worden. Probeer minder screenshots samen te voegen.';

  @override
  String get errorStitchEncode =>
      'De samengevoegde afbeelding kon niet worden gecodeerd.';

  @override
  String get errorRedactionSave =>
      'De beschermde kopie kon niet worden bewaard.';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshots bewaard',
      one: 'Screenshot bewaard',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'Groot';

  @override
  String get densityMedium => 'Gemiddeld';

  @override
  String get densitySmall => 'Klein';

  @override
  String get sensitiveCard => 'Kaartnummer';

  @override
  String get sensitiveIban => 'Bankrekening';

  @override
  String get sensitiveCode => 'Verificatiecode';

  @override
  String get sensitiveNationalId => 'Identiteitsnummer';

  @override
  String get sensitiveEmail => 'E-mailadres';

  @override
  String get sensitivePhone => 'Telefoonnummer';

  @override
  String get sensitiveAddress => 'Adres';

  @override
  String get sensitiveName => 'Naam';

  @override
  String get sensitiveOrderNumber => 'Bestelnummer';

  @override
  String get sensitiveNumber => 'Nummer';

  @override
  String get onbSkip => 'Overslaan';

  @override
  String get onbNext => 'Volgende';

  @override
  String get onbPileTitle => 'Duizend screenshots, één stapel';

  @override
  String get onbPileBody =>
      'Je maakt een screenshot om iets te onthouden. Een week later ligt het onder vierhonderd andere.';

  @override
  String get onbChooseTitle => 'SHOTO leest nooit je galerij';

  @override
  String get onbChooseBody =>
      'Er komt niets uit zichzelf binnen. Jij deelt een screenshot naar binnen — dat is de hele regel.';

  @override
  String get onbSafeShareTitle => 'Het screenshot dat je echt kunt versturen';

  @override
  String get onbSafeShareBody =>
      'Het kaartnummer verdwijnt onder een dicht blok — het label ernaast blijft staan, dus het beeld blijft leesbaar. Je controleert elke afdekking voor je verstuurt.';

  @override
  String get onbFolderExample => 'Bonnetjes';

  @override
  String get onbSearchExample => 'bonnetje';

  @override
  String get importTitle => 'Screenshots toevoegen';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshots geïmporteerd',
      one: '1 screenshot geïmporteerd',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return '$imported van $picked geïmporteerd';
  }

  @override
  String get importFailed => 'Die screenshots konden niet worden bewaard';

  @override
  String get homeToolImportSubtitle =>
      'Kies van je telefoon — je galerij wordt nooit gelezen';

  @override
  String get importPickerUnavailable => 'De fotokiezer ging niet open';

  @override
  String get searchWorking => 'Je screenshots worden gelezen…';

  @override
  String get settingsBackup => 'Back-up & herstel';

  @override
  String get settingsBackupHint =>
      'Bewaar een kopie van je bibliotheek in een bestand';

  @override
  String get backupTitle => 'Back-up';

  @override
  String get backupIntro =>
      'Je bibliotheek leeft op deze telefoon en nergens anders. Een back-up is de kopie die het overleeft als je hem kwijtraakt.';

  @override
  String get backupCreateTitle => 'Een back-up maken';

  @override
  String get backupCreateBody =>
      'Stopt elk screenshot, elke map en elk label in één bestand, en laat je dan kiezen waar je het bewaart.';

  @override
  String get backupCreateAction => 'Back-up maken';

  @override
  String get backupWorking => 'Je bibliotheek wordt ingepakt…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots screenshots in de back-up',
      one: '1 screenshot in de back-up',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders mappen',
      one: '1 map',
    );
    return '$_temp0 en $_temp1';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots screenshots in de back-up',
      one: '1 screenshot in de back-up',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped konden niet worden gelezen',
      one: '1 kon niet worden gelezen',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get backupFailed => 'De back-up kon niet worden afgemaakt';

  @override
  String get backupPrivacyNote =>
      'Het bestand wordt op deze telefoon gemaakt en gaat alleen waar jij het heen stuurt. Er wordt niets geüpload.';

  @override
  String get restoreTitle => 'Een back-up herstellen';

  @override
  String get restoreBody =>
      'Voegt alles uit een back-upbestand toe aan deze bibliotheek. Niets wat er al staat wordt verwijderd.';

  @override
  String get restoreAction => 'Herstellen';

  @override
  String get restoreWorking => 'Je bibliotheek wordt teruggezet…';

  @override
  String get restoreConfirmTitle => 'Deze back-up herstellen?';

  @override
  String get restoreConfirmMessage =>
      'Alles in het bestand wordt aan je bibliotheek toegevoegd. Je huidige screenshots blijven precies zoals ze zijn.';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots screenshots hersteld',
      one: '1 screenshot hersteld',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders mappen',
      one: '1 map',
    );
    return '$_temp0 en $_temp1';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots screenshots hersteld',
      one: '1 screenshot hersteld',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped zijn overgeslagen',
      one: '1 is overgeslagen',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get restoreNotABackup => 'Dat bestand is geen SHOTO-back-up';

  @override
  String get restoreFailed => 'Het herstellen kon niet worden afgemaakt';

  @override
  String get settingsHelp => 'Hulp';

  @override
  String get settingsContactSupport => 'Contact met support';

  @override
  String get supportSubject => 'SHOTO-support';

  @override
  String get supportNoMailApp =>
      'Geen e-mailapp gevonden. Het adres is in plaats daarvan gekopieerd.';

  @override
  String get supportGreeting => 'Hallo SHOTO-team,';

  @override
  String get dateToday => 'Vandaag';

  @override
  String get dateYesterday => 'Gisteren';

  @override
  String get dateThisWeek => 'Eerder deze week';

  @override
  String get dateThisMonth => 'Eerder deze maand';

  @override
  String get librarySortNewest => 'Nieuwste eerst';

  @override
  String get librarySortOldest => 'Oudste eerst';

  @override
  String get librarySortLabel => 'Volgorde';

  @override
  String get libraryShowOnly => 'Alleen tonen';

  @override
  String get libraryShowEverything => 'Alles';

  @override
  String libraryScanPrompt(int count) {
    return '$count screenshots lezen';
  }

  @override
  String get libraryScanning => 'Wordt gelezen…';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mappen bestaan hier al',
      one: '1 map bestaat hier al',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'Deze namen staan in je bibliotheek én in de back-up. Dezelfde naam betekent niet altijd dezelfde map, dus deze beslis jij.';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en nog $count',
      one: 'en nog 1',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'Bij elkaar zetten';

  @override
  String get restoreClashMergeBody =>
      'Screenshots gaan naar de mappen die je al hebt.';

  @override
  String get restoreClashSeparate => 'Apart houden';

  @override
  String get restoreClashSeparateBody =>
      'Maakt een tweede map met dezelfde naam. Er wordt niets bestaands aangeraakt.';

  @override
  String get intentBuy => 'Kopen';

  @override
  String get intentRead => 'Lezen';

  @override
  String get intentReply => 'Antwoorden';

  @override
  String get intentTry => 'Proberen';

  @override
  String get intentVisit => 'Bezoeken';

  @override
  String get intentBuyWaiting => 'Te kopen';

  @override
  String get intentReadWaiting => 'Te lezen';

  @override
  String get intentReplyWaiting => 'Te beantwoorden';

  @override
  String get intentTryWaiting => 'Te proberen';

  @override
  String get intentVisitWaiting => 'Te bezoeken';

  @override
  String get intentWatch => 'Kijken';

  @override
  String get intentListen => 'Luisteren';

  @override
  String get intentCook => 'Koken';

  @override
  String get intentBook => 'Boeken';

  @override
  String get intentPay => 'Betalen';

  @override
  String get intentSend => 'Versturen';

  @override
  String get intentDownload => 'Downloaden';

  @override
  String get intentApply => 'Solliciteren';

  @override
  String get intentCompare => 'Vergelijken';

  @override
  String get intentFix => 'Repareren';

  @override
  String get intentWatchWaiting => 'Te kijken';

  @override
  String get intentListenWaiting => 'Te beluisteren';

  @override
  String get intentCookWaiting => 'Te koken';

  @override
  String get intentBookWaiting => 'Te boeken';

  @override
  String get intentPayWaiting => 'Te betalen';

  @override
  String get intentSendWaiting => 'Te versturen';

  @override
  String get intentDownloadWaiting => 'Te downloaden';

  @override
  String get intentApplyWaiting => 'Op te solliciteren';

  @override
  String get intentCompareWaiting => 'Te vergelijken';

  @override
  String get intentFixWaiting => 'Te repareren';

  @override
  String get intentMore => 'Meer';

  @override
  String get intentSectionCommon => 'Kant-en-klaar';

  @override
  String get intentSectionYours => 'Van jou';

  @override
  String get intentYoursEmpty =>
      'Een werkwoord dat je zelf schrijft werkt precies zoals die hierboven.';

  @override
  String get intentNewAction => 'Schrijf je eigen';

  @override
  String get intentNewTitle => 'Geef het zelf een naam';

  @override
  String get intentEditTitle => 'Deze bewerken';

  @override
  String get intentNameLabel => 'Het werkwoord';

  @override
  String get intentNameHint => 'Terugsturen, annuleren, ze bellen…';

  @override
  String get intentIconLabel => 'Pictogram';

  @override
  String intentDeleteTitle(String label) {
    return '„$label” verwijderen?';
  }

  @override
  String get intentDeleteMessage =>
      'De screenshots blijven waar ze zijn. Ze wachten alleen nergens meer op.';

  @override
  String get intentSelectionAction => 'Markeren als';

  @override
  String intentSelectionApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshots gemarkeerd',
      one: '1 screenshot gemarkeerd',
    );
    return '$_temp0';
  }

  @override
  String get intentPrompt => 'Waar het voor is, als je wilt';

  @override
  String get intentSkip => 'Niets in het bijzonder';

  @override
  String get intentWaitingTitle => 'Wacht op jou';

  @override
  String get intentNothingWaiting => 'Niets wacht op jou';

  @override
  String get intentAllDone =>
      'Je hebt alles afgerond wat je voor later bewaarde.';

  @override
  String get intentMarkDone => 'Afgerond';

  @override
  String get intentUndo => 'Terugzetten';

  @override
  String get intentDoneToast => 'Afgevinkt';

  @override
  String get intentChange => 'Wijzig waar dit voor is';

  @override
  String get intentClear => 'Nergens voor';

  @override
  String intentEmptyOne(String verb) {
    return 'Hier is niets te $verb';
  }

  @override
  String get intentEmptyBody =>
      'Screenshots die je markeert blijven hier tot je ze afvinkt.';

  @override
  String intentDoneCount(int count) {
    return '$count afgerond';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weken geleden',
      one: '1 week geleden',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maanden geleden',
      one: '1 maand geleden',
    );
    return '$_temp0';
  }
}
