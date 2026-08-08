// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settingsCrashReports => 'Rapports de plantage';

  @override
  String get settingsCrashReportsHint =>
      'Envoyer des détails techniques en cas de problème';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutTitle => 'Se déconnecter ?';

  @override
  String get authWelcome => 'Bienvenue sur SHOTO';

  @override
  String get authSubtitle =>
      'Se connecter garde votre abonnement avec vous quand vous changez de téléphone. Vos captures restent sur cet appareil dans tous les cas — un compte ne les emporte jamais.';

  @override
  String get authGoogle => 'Continuer avec Google';

  @override
  String get authApple => 'Continuer avec Apple';

  @override
  String get authLegal =>
      'En continuant, vous acceptez nos Conditions et notre Politique de confidentialité.';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsSignOutHint => 'Vos captures restent sur cet appareil';

  @override
  String get settingsSignIn => 'Se connecter';

  @override
  String get settingsSignInHint =>
      'Facultatif. Sert uniquement à transférer un achat vers un autre téléphone.';

  @override
  String paywallTrialCta(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Commencer $days jours gratuits',
      one: 'Commencer 1 jour gratuit',
    );
    return '$_temp0';
  }

  @override
  String paywallTrialNote(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Gratuit pendant $days jours, puis $price. Annulez à tout moment avant la fin.',
      one:
          'Gratuit pendant un jour, puis $price. Annulez à tout moment avant la fin.',
    );
    return '$_temp0';
  }

  @override
  String get triageTitle => 'Depuis votre dernière visite';

  @override
  String get triageBody =>
      'Gardez ce qui a sa place dans SHOTO. Tout le reste ne bouge pas.';

  @override
  String get triageKeep => 'Garder';

  @override
  String get triageSkip => 'Passer';

  @override
  String get triageFinish => 'Terminé';

  @override
  String triageProgress(int index, int total) {
    return '$index sur $total';
  }

  @override
  String triageNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles captures',
      one: '1 nouvelle capture',
    );
    return '$_temp0';
  }

  @override
  String triageKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gardées',
      one: '1 gardée',
      zero: 'Rien de gardé',
    );
    return '$_temp0';
  }

  @override
  String get triageReview => 'Passer en revue';

  @override
  String get triageInviteDecline => 'Pas maintenant';

  @override
  String get settingsTriage => 'Proposer les nouvelles captures';

  @override
  String get settingsTriageHint =>
      'Montre ce que vous capturez ; ne garde rien de lui-même';

  @override
  String get triageNothingNew => 'Rien de nouveau à revoir';

  @override
  String get settingsYourName => 'Votre nom';

  @override
  String get settingsYourNameHint =>
      'Pour que Safe Share le masque quand il apparaît';

  @override
  String get settingsYourNameNotSet => 'Non défini';

  @override
  String get ownerNameTitle => 'Votre nom';

  @override
  String get ownerNameBody =>
      'Safe Share trouve les numéros de carte et les codes par leur propre arithmétique. Un nom, il ne le trouve que s\'il connaît déjà le vôtre. Saisi une fois, conservé sur ce téléphone, jamais envoyé nulle part.';

  @override
  String get ownerNameFieldHint => 'Le nom que votre banque imprime';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonSomethingWentWrong => 'Une erreur est survenue';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'Accueil';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navFolders => 'Dossiers';

  @override
  String get navSettings => 'Réglages';

  @override
  String get tagline => 'Vos captures, rangées';

  @override
  String get homeGreetingMorning => 'Bonjour';

  @override
  String get homeGreetingAfternoon => 'Bon après-midi';

  @override
  String get homeGreetingEvening => 'Bonsoir';

  @override
  String get homeInboxEmpty => 'Rien d\'enregistré pour l\'instant';

  @override
  String get homeInboxEmptySubtitle =>
      'Choisissez-en quelques-unes sur votre téléphone, ou partagez une capture vers SHOTO depuis n\'importe quelle app.';

  @override
  String get homeEmptyImportCta => 'Choisir sur mon téléphone';

  @override
  String get homeInboxClear => 'Tout est rangé';

  @override
  String get homeInboxClearSubtitle => 'Plus rien à trier';

  @override
  String get homeInboxCountSubtitle =>
      'Captures que vous n\'avez pas encore classées';

  @override
  String get homeStatScreenshots => 'Captures';

  @override
  String get homeStatFavorites => 'Favoris';

  @override
  String get homeStatFolders => 'Dossiers';

  @override
  String get homeToolsTitle => 'Outils';

  @override
  String get homeToolsTitleEmpty => 'Commencez ici';

  @override
  String get homeToolSafeShare => 'Partage protégé';

  @override
  String get homeToolSafeShareSubtitle => 'Masquez d\'abord les infos privées';

  @override
  String get homeToolDuplicates => 'Trouver les doublons';

  @override
  String get homeToolDuplicatesSubtitle => 'Libérez de l\'espace';

  @override
  String get homeToolSearch => 'Chercher dedans';

  @override
  String get homeToolSearchSubtitle => 'Trouvez du texte dans vos images';

  @override
  String get homeToolStitch => 'Assembler les captures longues';

  @override
  String get homeToolStitchSubtitle => 'Réunissez une capture défilante';

  @override
  String get homeRecent => 'Récentes';

  @override
  String get libraryPickForMerge =>
      'Choisissez deux captures ou plus de la même page';

  @override
  String get libraryPickForProtect => 'Choisissez la capture à protéger';

  @override
  String get libraryActionProtect => 'Protéger';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String get libraryEmptyTitle => 'Rien d\'enregistré pour l\'instant';

  @override
  String get libraryEmptyMessage =>
      'Partagez une capture vers SHOTO, ou ajoutez-en une avec le bouton +. Votre galerie n\'est jamais lue : seul ce que vous confiez est conservé.';

  @override
  String get libraryNoFavoritesTitle => 'Aucun favori';

  @override
  String get libraryNoFavoritesMessage =>
      'Touchez le cœur d\'une capture pour l\'enregistrer ici.';

  @override
  String get libraryFilterAll => 'Toutes';

  @override
  String get libraryFilterFavorites => 'Favoris';

  @override
  String get libraryTraitSensitive => 'Sensible';

  @override
  String get libraryTraitLink => 'Liens';

  @override
  String get libraryTraitContact => 'Tél. ou e-mail';

  @override
  String get libraryTraitCode => 'Codes';

  @override
  String get libraryTraitEvent => 'Dates';

  @override
  String get libraryCertaintyVerified => 'Vérifié par somme de contrôle';

  @override
  String get libraryCertaintyRead => 'Lu dans le texte de vos captures';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count pas encore lues';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return 'Aucune capture avec $trait';
  }

  @override
  String get libraryNoTraitMessage =>
      'Aucune des captures lues ne contient cela.';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'Rien trouvé dans ce qui a été lu. $count captures n\'ont jamais été lues, elles ne peuvent donc pas encore correspondre.';
  }

  @override
  String get libraryShowAll => 'Tout afficher';

  @override
  String get libraryFilterUnsorted => 'Non classées';

  @override
  String get libraryNoUnsortedTitle => 'Tout est classé';

  @override
  String get libraryNoUnsortedMessage =>
      'Rien ne vous attend. Les nouvelles captures arrivent ici jusqu\'à ce que vous les classiez ou les mettiez en favori.';

  @override
  String librarySelectedCount(int count) {
    return '$count sélectionnées';
  }

  @override
  String get librarySelectAll => 'Tout sélectionner';

  @override
  String get libraryActionMerge => 'Assembler';

  @override
  String get libraryActionMove => 'Déplacer';

  @override
  String get libraryActionDelete => 'Supprimer';

  @override
  String get libraryDeleteTitle => 'Supprimer ces captures ?';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count captures seront définitivement supprimées de votre appareil.',
      one: '1 capture sera définitivement supprimée de votre appareil.',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'Accès aux photos requis';

  @override
  String get permissionNeededMessage =>
      'SHOTO garde les captures que vous lui partagez dans son propre album. Il a besoin de l\'accès aux photos pour y écrire et les relire — il ne parcourt jamais le reste de votre galerie.';

  @override
  String get permissionPartialTitle => 'Accès complet requis';

  @override
  String get permissionPartialMessage =>
      'SHOTO ne voit actuellement que quelques photos choisies à la main et ne peut donc pas atteindre son propre album. Choisissez « Autoriser tout » pour continuer.';

  @override
  String get permissionOpenSettings => 'Ouvrir les réglages';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsGridDensity => 'Densité de la grille';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Suivre mon téléphone';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Actuellement $language';
  }

  @override
  String get settingsBehaviour => 'Comportement';

  @override
  String get settingsHaptics => 'Retour haptique';

  @override
  String get settingsHapticsHint => 'Une petite vibration quand vous appuyez';

  @override
  String get settingsConfirmDelete => 'Demander avant de supprimer';

  @override
  String get settingsConfirmDeleteHint => 'Une suppression est définitive';

  @override
  String get settingsFindDuplicates => 'Trouver les doublons';

  @override
  String get settingsClearCache => 'Vider le cache d\'images';

  @override
  String get settingsShare => 'Partager SHOTO';

  @override
  String get settingsPrivacyNote =>
      'SHOTO ne garde que les captures que vous lui confiez, et tout ce qu\'il en fait — lire le texte, chercher les doublons — se passe sur cet appareil. Vos images ne sont jamais envoyées ailleurs. Trois choses s\'activent par vous : proposer les nouvelles captures lit votre album de captures pour pouvoir vous les soumettre, un compte n\'envoie que votre e-mail pour qu\'un abonnement survive à un changement de téléphone, et les rapports de plantage envoient ce qui a planté — le code, jamais une image.';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonRename => 'Renommer';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonUnlock => 'Déverrouiller';

  @override
  String get foldersEmptyTitle => 'Aucun dossier';

  @override
  String get foldersEmptyMessage =>
      'Les dossiers sont ce qui vous permet de retrouver les choses. Créez-en un pour les reçus, un pour les recettes — ce que vous cherchez vraiment.';

  @override
  String get foldersNew => 'Nouveau dossier';

  @override
  String get foldersCreate => 'Créer le dossier';

  @override
  String get foldersNameLabel => 'Nom du dossier';

  @override
  String get foldersNameHint => 'Reçus, Recettes, Travail…';

  @override
  String get foldersPrivate => 'Privé (verrouillage visage ou empreinte)';

  @override
  String get foldersPrivateFace => 'Privé (verrouillage visage)';

  @override
  String get foldersPrivateFingerprint => 'Privé (verrouillage empreinte)';

  @override
  String get foldersPrivateGeneric => 'Privé (verrouillé)';

  @override
  String get foldersOptions => 'Options du dossier';

  @override
  String get foldersDelete => 'Supprimer le dossier';

  @override
  String get foldersDeleteKept => 'Les captures à l’intérieur sont conservées';

  @override
  String foldersDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get foldersDeleteMessage =>
      'Le dossier est supprimé mais les captures qu’il contenait restent dans votre bibliothèque.';

  @override
  String get foldersRenameTitle => 'Renommer le dossier';

  @override
  String get foldersMoveTitle => 'Déplacer vers un dossier';

  @override
  String get foldersMoveRemove => 'Retirer du dossier';

  @override
  String get foldersMoveNone =>
      'Aucun dossier. Créez-en un depuis l’onglet Dossiers.';

  @override
  String folderLockedTitle(String name) {
    return 'Déverrouiller « $name »';
  }

  @override
  String get folderLockedMessage =>
      'Ce dossier est protégé. Authentifiez-vous pour l’ouvrir.';

  @override
  String get folderEmptyTitle => 'Rien ici pour l’instant';

  @override
  String get folderEmptyMessage =>
      'Déplacez des captures dans ce dossier depuis votre bibliothèque.';

  @override
  String get detailFavorite => 'Favori';

  @override
  String get detailUnfavorite => 'Retirer des favoris';

  @override
  String get detailAddFavorite => 'Ajouter aux favoris';

  @override
  String get detailActions => 'Actions';

  @override
  String get detailSafeShare => 'Partage protégé';

  @override
  String get detailDeleteTitle => 'Supprimer cette capture ?';

  @override
  String get detailDeleteMessage =>
      'Elle sera définitivement supprimée de votre appareil.';

  @override
  String get quickSaveTitleOne => 'Enregistrer dans SHOTO';

  @override
  String quickSaveTitleMany(int count) {
    return 'Enregistrer $count captures';
  }

  @override
  String get quickSaveFileOne => 'Classer cette capture';

  @override
  String quickSaveFileMany(int count) {
    return 'Classer $count captures';
  }

  @override
  String get quickSavePickFolder => 'Choisissez un dossier';

  @override
  String get quickSaveNeedFolder => 'Créez un dossier où les mettre';

  @override
  String quickSaveFileIn(String folder) {
    return 'Classer dans $folder';
  }

  @override
  String get quickSaveCreateFirstFolder => 'Créez votre premier dossier';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'Les dossiers sont ce qui vous permet de retrouver les choses';

  @override
  String get quickSaveNewChip => 'Nouveau';

  @override
  String get quickSaveSaved => 'Enregistré dans SHOTO';

  @override
  String quickSaveFiled(String folder) {
    return 'Classé dans $folder.';
  }

  @override
  String get quickSaveFailedTitle => 'Impossible de lire cette image';

  @override
  String get quickSaveFailedBody => 'Essayez de la partager à nouveau.';

  @override
  String quickSaveSkipped(int count) {
    return 'Seules les $count premières ont été prises';
  }

  @override
  String get dupTitle => 'Trouver les doublons';

  @override
  String get dupScanning => 'Recherche des doublons';

  @override
  String get dupReading => 'Lecture de votre bibliothèque…';

  @override
  String dupProgress(int done, int total) {
    return '$done captures vérifiées sur $total';
  }

  @override
  String get dupNoneTitle => 'Aucun doublon';

  @override
  String get dupNoneBody => 'Votre bibliothèque est déjà propre.';

  @override
  String get dupScanAgain => 'Analyser à nouveau';

  @override
  String dupReclaimable(String size) {
    return 'Jusqu’à $size peuvent être libérés';
  }

  @override
  String get dupNothingSelected => 'Rien de sélectionné';

  @override
  String dupDeleteButton(int count, String size) {
    return 'Supprimer $count · libérer $size';
  }

  @override
  String dupDeleteTitle(int count) {
    return 'Supprimer $count copies ?';
  }

  @override
  String get dupDeleteMessage =>
      'Elles seront définitivement supprimées de votre appareil. Les copies marquées à conserver ne sont pas touchées.';

  @override
  String dupDeleted(int count, String size) {
    return '$count supprimées · $size libérés';
  }

  @override
  String dupSets(int count) {
    return '$count groupes';
  }

  @override
  String get dupBest => 'MEILLEURE';

  @override
  String get dupKeepAll => 'Tout garder';

  @override
  String get dupKeepingAll => 'Tout est conservé — rien ne sera supprimé';

  @override
  String get dupUndo => 'Annuler';

  @override
  String dupFrees(String size) {
    return 'Libère $size';
  }

  @override
  String get safeShareTitle => 'Partage protégé';

  @override
  String get safeShareScanning => 'Recherche de données privées';

  @override
  String get safeShareOnDevice => 'La lecture se fait sur votre téléphone.';

  @override
  String get safeShareCleanTitle => 'Rien de privé trouvé';

  @override
  String get safeShareCleanBody =>
      'Aucun numéro de carte, compte, code ou contact détecté. Vous pouvez la partager telle quelle.';

  @override
  String get safeShareUnreadableTitle => 'Impossible de lire cette capture';

  @override
  String get safeShareUnreadableBody => 'Le texte n’a pas pu être reconnu.';

  @override
  String get safeShareShareUnchanged => 'Partager telle quelle';

  @override
  String get safeShareShareAnyway => 'Partager quand même';

  @override
  String get safeShareShareProtected => 'Partager la copie protégée';

  @override
  String get safeShareFailed => 'Impossible de créer la copie protégée.';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count données privées trouvées',
      one: '1 donnée privée trouvée',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'L\'analyse est toujours gratuite.';

  @override
  String get safeShareCleanAction => 'Nettoyer cette capture';

  @override
  String get safeShareShareAsIs => 'Partager sans modification';

  @override
  String get safeShareHowTitle => 'Masqué, définitivement';

  @override
  String get safeShareHowBody =>
      'Chaque donnée privée est recouverte d\'un bloc plein avant que la copie ne quitte votre téléphone. Aucun flou, rien à récupérer : la copie masquée est la seule qui existe.';

  @override
  String get safeShareTreatmentCover => 'Masquer';

  @override
  String get safeShareTreatmentKeep => 'Garder';

  @override
  String get safeShareBuilding => 'Préparation de votre copie propre';

  @override
  String get safeShareNothingSelected => 'Rien ne changera';

  @override
  String get safeShareLockedPreview => 'Débloquez pour voir la version propre';

  @override
  String get safeShareReviewTitle => 'Vérifiez chacune';

  @override
  String safeShareFound(int count) {
    return '$count éléments masqués';
  }

  @override
  String get stitchTitle => 'Assembler les captures';

  @override
  String get stitchWorking => 'Recherche du recouvrement';

  @override
  String get stitchWorkingBody =>
      'Recherche de l’endroit où chaque capture reprend la précédente.';

  @override
  String get stitchFailed => 'Fusion impossible';

  @override
  String get stitchSave => 'Enregistrer dans la galerie';

  @override
  String get stitchSaved => 'Enregistrée dans votre galerie';

  @override
  String get stitchDiscard => 'Abandonner';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonClose => 'Fermer';

  @override
  String get searchTitle => 'Cherchez dans vos captures';

  @override
  String get searchHint => 'Des mots ou ce que montre l’image';

  @override
  String get searchIntro =>
      'N’importe quel mot écrit dans l’image, ou ce qu’elle montre — essayez « chat », « animal », « nourriture » ou « reçu ».';

  @override
  String get searchNoneTitle => 'Aucun résultat';

  @override
  String searchNoneBody(String query) {
    return 'Rien ici ne se lit ni ne ressemble à « $query ».';
  }

  @override
  String get paywallTitle => 'Débloquez SHOTO Pro';

  @override
  String get paywallSubtitle => 'Tout ce qui suit, avec un seul abonnement.';

  @override
  String get paywallMonthly => 'Mensuel';

  @override
  String get paywallYearly => 'Annuel';

  @override
  String paywallSave(int percent) {
    return 'Économisez $percent %';
  }

  @override
  String get paywallContinue => 'Continuer';

  @override
  String get paywallUnavailable => 'Pas encore disponible';

  @override
  String get paywallRestore => 'Restaurer les achats';

  @override
  String get paywallLegal =>
      'Renouvellement automatique jusqu’à annulation. Annulable à tout moment depuis votre compte App Store ou Google Play. En continuant, vous acceptez nos Conditions et notre Politique de confidentialité.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'SHOTO Pro';

  @override
  String get subPremiumBody => 'Toutes les fonctions débloquées.';

  @override
  String get subDevUnlock => 'Accès de test';

  @override
  String get subDevUnlockBody =>
      'Débloqué sur cet appareil uniquement — pas un vrai abonnement';

  @override
  String get subUnlockEverything => 'Tout débloquer';

  @override
  String get proWelcomeTitle => 'Vous êtes sur Pro';

  @override
  String get proWelcomeBody =>
      'Toutes les fonctions sont débloquées. Il n\'y a rien d\'autre à configurer.';

  @override
  String get proWelcomeAction => 'Commencer';

  @override
  String get featSafeShare => 'Partage protégé';

  @override
  String get featSafeShareBody =>
      'Remplace numéros de carte, adresses, noms et coordonnées par des équivalents crédibles : même longueur, même format, même endroit. La copie envoyée ne semble pas retouchée.';

  @override
  String get featActions => 'Transformez vos captures en actions';

  @override
  String get featActionsBody =>
      'Ouvrez un lien, écrivez à une adresse, copiez un code de vérification ou un IBAN — directement depuis l\'image, sans rien retaper.';

  @override
  String get featDuplicates => 'Trouver les doublons';

  @override
  String get featDuplicatesBody =>
      'Repérez les captures presque identiques gardées en double et supprimez-les — toujours après relecture.';

  @override
  String get featStitch => 'Assembler les captures longues';

  @override
  String get featStitchBody =>
      'Réunissez une capture défilante en une seule image haute, le recouvrement étant détecté et retiré automatiquement.';

  @override
  String get featUnlimited => 'Aucun plafond pour votre bibliothèque';

  @override
  String featUnlimitedBody(Object count) {
    return 'La version gratuite organise $count captures. Pro supprime la limite.';
  }

  @override
  String get featSafeShareHow =>
      'Repérer ce qui est privé dans une capture est gratuit et illimité. Ce qui est payant, c\'est d\'en faire une copie propre : chaque donnée est redessinée dans les couleurs de la capture, sous la forme d\'une autre valeur tout aussi banale.';

  @override
  String get featSafeSharePoint1 =>
      'Les cartes sont vérifiées par Luhn et les IBAN par mod-97 — et les remplaçants passent les mêmes contrôles, donc rien ne paraît inventé.';

  @override
  String get featSafeSharePoint2 =>
      'Repère aussi les noms, adresses, numéros de commande, codes de vérification, téléphones et e-mails.';

  @override
  String get featSafeSharePoint3 =>
      'Vous voyez chaque changement avant l\'envoi et pouvez plutôt masquer ou garder chacun d\'eux. La capture d\'origine n\'est jamais modifiée.';

  @override
  String get featActionsHow =>
      'Tout ce qui est écrit dans une capture devient utilisable. SHOTO en extrait les éléments utiles et place un bouton sur chacun.';

  @override
  String get featActionsPoint1 =>
      'Les liens, adresses e-mail, IBAN, codes de vérification, dates et numéros de colis sont trouvés pour vous.';

  @override
  String get featActionsPoint2 =>
      'Un appui pour ouvrir ou copier — sans lire les caractères sur une image.';

  @override
  String get featActionsPoint3 =>
      'Fonctionne sur les captures que vous avez déjà, pas seulement sur les nouvelles.';

  @override
  String get featStitchHow =>
      'La capture avec défilement, sur les téléphones qui l’ont, doit être lancée pendant que vous êtes encore sur la page. SHOTO intervient après : choisissez deux captures ou plus déjà dans votre bibliothèque — y compris celles qu’on vous a envoyées — et il calcule où elles se recouvrent et les réassemble en une seule image haute.';

  @override
  String get featStitchPoint1 =>
      'La bande répétée entre deux captures est détectée et supprimée automatiquement.';

  @override
  String get featStitchPoint2 =>
      'Vous voyez le raccord avant tout enregistrement : la détection automatique est bonne, jamais certaine.';

  @override
  String get featStitchPoint3 =>
      'L’image assemblée est enregistrée dans votre galerie comme n’importe quelle photo.';

  @override
  String get featDuplicatesHow =>
      'Partager les captures une par une ne crée presque jamais de doublons. En garder un lot depuis « Depuis votre dernière visite », si : vous allez vite et vous gardez deux captures de la même chose. SHOTO les compare d’après leur apparence plutôt que leur nom ou leur taille : il repère donc celles-là, ainsi qu’un renvoi ou un autre recadrage.';

  @override
  String get featDuplicatesPoint1 =>
      'Regroupe ce qui se ressemble et suggère la copie à conserver.';

  @override
  String get featDuplicatesPoint2 =>
      'Indique l’espace libéré par chaque groupe avant que vous ne décidiez quoi que ce soit.';

  @override
  String get featDuplicatesPoint3 =>
      'Rien n’est supprimé tant que vous n’avez pas revu le groupe et confirmé.';

  @override
  String get featUnlimitedHow =>
      'La version gratuite est une vraie application : enregistrement, dossiers, favoris et recherche complète, sans compte et sans rien téléverser. Elle n\'a qu\'un seul plafond — le nombre de captures organisées — et Pro le supprime. Tout ce que vous avez déjà organisé reste en place.';

  @override
  String get featUnlimitedPoint1 =>
      'Les dossiers sont illimités en version gratuite, comme il se doit.';

  @override
  String get featUnlimitedPoint2 =>
      'Nommer l\'usage d\'une capture est aussi gratuit et illimité.';

  @override
  String get featUnlimitedPoint3 =>
      'Atteindre le plafond signifie que SHOTO est devenu l\'endroit où vous rangez vos choses. Rien n\'est supprimé.';

  @override
  String get includedSubtitle => 'Chaque fonction Pro, expliquée.';

  @override
  String get includedHint =>
      'Touchez une fonctionnalité pour voir comment elle marche';

  @override
  String get includedHowLabel => 'Comment ça marche';

  @override
  String get includedActiveTitle => 'Votre abonnement est actif';

  @override
  String get includedActiveBody =>
      'Tout ce qui suit est débloqué sur ce compte.';

  @override
  String get includedLockedTitle => 'Pas encore débloqué';

  @override
  String get includedLockedBody =>
      'Lisez ce que chacune fait vraiment, puis décidez.';

  @override
  String get includedFreeTitle => 'Ce que la version gratuite vous donne';

  @override
  String includedFreeBody(int count) {
    return '$count captures organisées, dossiers illimités et recherche complète — gratuit pour toujours.';
  }

  @override
  String get onboardingCta => 'Commencer';

  @override
  String get onboardingPromise => 'Vos captures restent sur votre téléphone.';

  @override
  String get actionsTitle => 'Actions';

  @override
  String get actionsWorking => 'Lecture de la capture';

  @override
  String get actionsWorkingBody => 'Recherche de numéros, liens et codes.';

  @override
  String get actionsNoneTitle => 'Rien à faire';

  @override
  String get actionsNoneBody =>
      'Aucun numéro, lien, code ou compte trouvé dans cette capture.';

  @override
  String get actionsCopy => 'Copier';

  @override
  String get actionsCopied => 'Copié';

  @override
  String get actionsNoApp =>
      'Aucune application de cet appareil ne peut faire cela.';

  @override
  String get devModeOn => 'Mode développeur actif — tout est débloqué';

  @override
  String get devModeBadge => 'MODE DÉVELOPPEUR';

  @override
  String get devModeOffTitle => 'Désactiver le mode développeur ?';

  @override
  String get devModeOffBody =>
      'SHOTO reviendra à la version gratuite sur cet appareil, pour retester le paywall et les limites.';

  @override
  String get devModeOffConfirm => 'Désactiver';

  @override
  String get devAccessTitle => 'Accès développeur';

  @override
  String get devAccessBody =>
      'Saisissez le code à 4 chiffres pour débloquer toutes les fonctions Pro sur cet appareil.';

  @override
  String get devWrongCode => 'Code incorrect';

  @override
  String devTapToDisable(int count) {
    return 'Touchez $count× pour désactiver';
  }

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get kindCard => 'un numéro de carte';

  @override
  String get kindIban => 'un compte bancaire';

  @override
  String get kindCode => 'un code de vérification';

  @override
  String get kindNationalId => 'un numéro d’identité';

  @override
  String get kindEmail => 'une adresse e-mail';

  @override
  String get kindLink => 'un lien';

  @override
  String get actionEmailAction => 'Écrire';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get kindEvent => 'un événement';

  @override
  String get kindPlace => 'un lieu';

  @override
  String get kindWifi => 'un réseau Wi-Fi';

  @override
  String get kindTracking => 'un colis';

  @override
  String get actionAddToCalendar => 'Ajouter au calendrier';

  @override
  String get actionOpenMaps => 'Ouvrir dans Maps';

  @override
  String get actionDirections => 'Itinéraire';

  @override
  String get actionCopyNetwork => 'Copier le nom';

  @override
  String get actionTrack => 'Suivre';

  @override
  String get actionEventUntitled => 'Événement';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count captures',
      one: '1 capture',
      zero: 'Aucune capture',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$position sur $total';
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
      other: '$count groupes de doublons',
      one: '1 groupe de doublons',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count copies similaires';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments trouvés',
      one: '1 élément trouvé',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'Stockage';

  @override
  String get settingsDuplicatesHint => 'Repérez les captures prises deux fois';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'Ce qui est inclus';

  @override
  String settingsFeatureCount(int count) {
    return '$count fonctions, un seul abonnement';
  }

  @override
  String get settingsShareHint => 'Parlez-en à quelqu’un qui en a besoin';

  @override
  String get settingsShareText =>
      'SHOTO range mes captures tout seul — tout reste sur le téléphone.';

  @override
  String get settingsCacheMeasuring => 'Mesure…';

  @override
  String settingsCacheSize(String size) {
    return '$size de miniatures';
  }

  @override
  String get homeSafeShareHint =>
      'Ouvrez une capture, puis touchez Partage protégé.';

  @override
  String get homeStitchHint =>
      'Appuyez longuement sur deux captures ou plus, puis touchez Assembler.';

  @override
  String stitchLimit(int count) {
    return 'Vous pouvez assembler jusqu’à $count captures à la fois.';
  }

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Captures enregistrées. Les ajouter à un dossier ?',
      one: 'Capture enregistrée. L’ajouter à un dossier ?',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count captures assemblées';
  }

  @override
  String stitchResultTrimmed(int count) {
    return '$count px de contenu répété supprimés';
  }

  @override
  String get errorLoadScreenshots => 'Impossible de charger vos captures.';

  @override
  String get errorLoadFolders => 'Impossible de charger vos dossiers.';

  @override
  String get errorScanDuplicates => 'Impossible de rechercher les doublons.';

  @override
  String get errorDeleteSelected =>
      'Impossible de supprimer les captures sélectionnées.';

  @override
  String get errorStitchFailed => 'Ces captures n’ont pas pu être assemblées.';

  @override
  String get errorStitchSave =>
      'L’image assemblée n’a pas pu être enregistrée.';

  @override
  String get errorOnboarding => 'Chargement impossible. Rouvrez l’application.';

  @override
  String get errorSignInCancelled => 'La connexion a été annulée.';

  @override
  String get errorSignInInterrupted =>
      'La connexion a été interrompue. Réessayez.';

  @override
  String get errorNetwork => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get errorGeneric => 'Une erreur est survenue. Réessayez.';

  @override
  String get errorPlans => 'Impossible de charger les abonnements.';

  @override
  String get errorPurchase => 'Achat échoué. Réessayez.';

  @override
  String get errorNoSubscription => 'Aucun abonnement actif pour ce compte.';

  @override
  String get errorRestore => 'Impossible de restaurer les achats.';

  @override
  String get errorStitchTooFew =>
      'Choisissez au moins deux captures à fusionner.';

  @override
  String errorStitchTooMany(int count) {
    return 'Jusqu\'à $count captures peuvent être fusionnées à la fois.';
  }

  @override
  String get errorStitchUnreadable =>
      'L\'une des captures n\'a pas pu être lue.';

  @override
  String get errorStitchWidths =>
      'Ces captures ont des largeurs différentes ; elles ne peuvent pas faire partie du même défilement.';

  @override
  String get errorStitchNoOverlap =>
      'Ces captures ne se chevauchent pas. La fusion ne fonctionne qu\'avec des captures de la même page prises en défilant.';

  @override
  String get errorStitchOverlap =>
      'Le chevauchement entre ces captures n\'a pas pu être déterminé.';

  @override
  String get errorStitchTooTall =>
      'L\'image fusionnée serait trop haute. Essayez d\'en fusionner moins.';

  @override
  String get errorStitchEncode =>
      'L\'image fusionnée n\'a pas pu être encodée.';

  @override
  String get errorRedactionSave =>
      'La copie protégée n\'a pas pu être enregistrée.';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count captures enregistrées',
      one: 'Capture enregistrée',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'Grand';

  @override
  String get densityMedium => 'Moyen';

  @override
  String get densitySmall => 'Petit';

  @override
  String get sensitiveCard => 'Numéro de carte';

  @override
  String get sensitiveIban => 'Compte bancaire';

  @override
  String get sensitiveCode => 'Code de vérification';

  @override
  String get sensitiveNationalId => 'Numéro d\'identité';

  @override
  String get sensitiveEmail => 'Adresse e-mail';

  @override
  String get sensitivePhone => 'Numéro de téléphone';

  @override
  String get sensitiveAddress => 'Adresse';

  @override
  String get sensitiveName => 'Nom';

  @override
  String get sensitiveOrderNumber => 'Numéro de commande';

  @override
  String get sensitiveNumber => 'Numéro';

  @override
  String get onbSkip => 'Passer';

  @override
  String get onbNext => 'Suivant';

  @override
  String get onbPileTitle => 'Mille captures, un seul tas';

  @override
  String get onbPileBody =>
      'Vous capturez pour vous souvenir. Une semaine plus tard, c’est enfoui sous quatre cents autres.';

  @override
  String get onbChooseTitle => 'SHOTO ne lit jamais votre galerie';

  @override
  String get onbChooseBody =>
      'Rien n’arrive tout seul. Vous partagez une capture vers l’app : c’est toute la règle.';

  @override
  String get onbFileTitle => 'Classée dès que vous l’envoyez';

  @override
  String get onbFileBody =>
      'Choisissez un dossier depuis le menu de partage. L’app ne s’ouvre même pas.';

  @override
  String get onbFindTitle => 'Cherchez ce qu’il y a dedans';

  @override
  String get onbFindBody =>
      'Les mots écrits dans la capture, et ce que l’image montre. Tapez « reçu » ou « chien ».';

  @override
  String get onbSafeShareTitle => 'La capture que vous pouvez vraiment envoyer';

  @override
  String get onbSafeShareBody =>
      'Un numéro de carte en devient un autre — même longueur, même place, toujours valide. Personne ne voit la retouche.';

  @override
  String get onbFolderExample => 'Reçus';

  @override
  String get onbSearchExample => 'reçu';

  @override
  String get importTitle => 'Ajouter des captures';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count captures importées',
      one: '1 capture importée',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return '$imported sur $picked importées';
  }

  @override
  String get importFailed => 'Impossible d\'enregistrer ces captures';

  @override
  String get homeToolImportSubtitle =>
      'Choisissez sur votre téléphone ; votre galerie n\'est jamais lue';

  @override
  String get importPickerUnavailable =>
      'Le sélecteur de photos n\'a pas pu s\'ouvrir';

  @override
  String get searchWorking => 'Lecture de vos captures…';

  @override
  String get settingsBackup => 'Sauvegarde et restauration';

  @override
  String get settingsBackupHint =>
      'Gardez une copie de votre bibliothèque dans un fichier';

  @override
  String get backupTitle => 'Sauvegarde';

  @override
  String get backupIntro =>
      'Votre bibliothèque n\'existe que sur ce téléphone. La sauvegarde, c\'est la copie qui reste si vous le perdez.';

  @override
  String get backupCreateTitle => 'Créer une sauvegarde';

  @override
  String get backupCreateBody =>
      'Rassemble chaque capture, dossier et libellé dans un fichier, puis vous choisissez où le garder.';

  @override
  String get backupCreateAction => 'Créer la sauvegarde';

  @override
  String get backupWorking => 'Assemblage de votre bibliothèque…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots captures sauvegardées',
      one: '1 capture sauvegardée',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders dossiers',
      one: '1 dossier',
    );
    return '$_temp0 et $_temp1';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots captures sauvegardées',
      one: '1 capture sauvegardée',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped n\'ont pas pu être lues',
      one: '1 n\'a pas pu être lue',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get backupFailed => 'La sauvegarde n\'a pas pu aller au bout';

  @override
  String get backupPrivacyNote =>
      'Le fichier est créé sur ce téléphone et ne part que là où vous l\'envoyez. Rien n\'est téléversé.';

  @override
  String get restoreTitle => 'Restaurer une sauvegarde';

  @override
  String get restoreBody =>
      'Ajoute tout le contenu du fichier à cette bibliothèque. Rien de ce qui s\'y trouve n\'est retiré.';

  @override
  String get restoreAction => 'Restaurer';

  @override
  String get restoreWorking => 'Remise en place de votre bibliothèque…';

  @override
  String get restoreConfirmTitle => 'Restaurer cette sauvegarde ?';

  @override
  String get restoreConfirmMessage =>
      'Tout le contenu du fichier est ajouté à votre bibliothèque. Vos captures actuelles restent exactement telles quelles.';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots captures restaurées',
      one: '1 capture restaurée',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders dossiers',
      one: '1 dossier',
    );
    return '$_temp0 et $_temp1';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots captures restaurées',
      one: '1 capture restaurée',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped ont été ignorées',
      one: '1 a été ignorée',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get restoreNotABackup => 'Ce fichier n\'est pas une sauvegarde SHOTO';

  @override
  String get restoreFailed => 'La restauration n\'a pas pu aller au bout';

  @override
  String get settingsHelp => 'Aide';

  @override
  String get settingsContactSupport => 'Contacter le support';

  @override
  String get supportSubject => 'Support SHOTO';

  @override
  String get supportNoMailApp =>
      'Aucune app de messagerie. L\'adresse a été copiée.';

  @override
  String get supportGreeting => 'Bonjour l\'équipe SHOTO,';

  @override
  String get dateToday => 'Aujourd\'hui';

  @override
  String get dateYesterday => 'Hier';

  @override
  String get dateThisWeek => 'Cette semaine';

  @override
  String get dateThisMonth => 'Ce mois-ci';

  @override
  String get librarySortNewest => 'Plus récentes d\'abord';

  @override
  String get librarySortOldest => 'Plus anciennes d\'abord';

  @override
  String get librarySortLabel => 'Ordre';

  @override
  String get libraryShowOnly => 'Afficher uniquement';

  @override
  String get libraryShowEverything => 'Tout';

  @override
  String libraryScanPrompt(int count) {
    return 'Lire $count captures';
  }

  @override
  String get libraryScanning => 'Lecture…';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dossiers existent déjà ici',
      one: '1 dossier existe déjà ici',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'Ces noms sont dans votre bibliothèque et dans la sauvegarde. Un même nom n\'est pas toujours le même dossier : à vous de décider.';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'et $count de plus',
      one: 'et 1 de plus',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'Les réunir';

  @override
  String get restoreClashMergeBody =>
      'Les captures vont dans les dossiers que vous avez déjà.';

  @override
  String get restoreClashSeparate => 'Les garder séparés';

  @override
  String get restoreClashSeparateBody =>
      'Crée un second dossier du même nom. Rien d\'existant n\'est touché.';

  @override
  String get intentBuy => 'Acheter';

  @override
  String get intentRead => 'Lire';

  @override
  String get intentReply => 'Répondre';

  @override
  String get intentTry => 'Essayer';

  @override
  String get intentVisit => 'Visiter';

  @override
  String get intentBuyWaiting => 'À acheter';

  @override
  String get intentReadWaiting => 'À lire';

  @override
  String get intentReplyWaiting => 'À répondre';

  @override
  String get intentTryWaiting => 'À essayer';

  @override
  String get intentVisitWaiting => 'À visiter';

  @override
  String get intentWatch => 'Regarder';

  @override
  String get intentListen => 'Écouter';

  @override
  String get intentCook => 'Cuisiner';

  @override
  String get intentBook => 'Réserver';

  @override
  String get intentPay => 'Payer';

  @override
  String get intentSend => 'Envoyer';

  @override
  String get intentDownload => 'Télécharger';

  @override
  String get intentApply => 'Postuler';

  @override
  String get intentCompare => 'Comparer';

  @override
  String get intentFix => 'Réparer';

  @override
  String get intentWatchWaiting => 'À regarder';

  @override
  String get intentListenWaiting => 'À écouter';

  @override
  String get intentCookWaiting => 'À cuisiner';

  @override
  String get intentBookWaiting => 'À réserver';

  @override
  String get intentPayWaiting => 'À payer';

  @override
  String get intentSendWaiting => 'À envoyer';

  @override
  String get intentDownloadWaiting => 'À télécharger';

  @override
  String get intentApplyWaiting => 'À postuler';

  @override
  String get intentCompareWaiting => 'À comparer';

  @override
  String get intentFixWaiting => 'À réparer';

  @override
  String get intentMore => 'Plus';

  @override
  String get intentSectionCommon => 'Prêtes à l\'emploi';

  @override
  String get intentSectionYours => 'Les vôtres';

  @override
  String get intentYoursEmpty =>
      'Un verbe que vous écrivez vous-même fonctionne exactement comme ceux du dessus.';

  @override
  String get intentNewAction => 'Écrivez le vôtre';

  @override
  String get intentNewTitle => 'Nommez-la vous-même';

  @override
  String get intentEditTitle => 'Modifier celle-ci';

  @override
  String get intentNameLabel => 'Le verbe';

  @override
  String get intentNameHint => 'La rendre, l\'annuler, les appeler…';

  @override
  String get intentIconLabel => 'Icône';

  @override
  String intentDeleteTitle(String label) {
    return 'Supprimer « $label » ?';
  }

  @override
  String get intentDeleteMessage =>
      'Les captures restent où elles sont. Elles cessent simplement d\'attendre quelque chose.';

  @override
  String get intentSelectionAction => 'Marquer comme';

  @override
  String intentSelectionApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count captures marquées',
      one: '1 capture marquée',
    );
    return '$_temp0';
  }

  @override
  String get intentPrompt => 'À quoi elle sert, si vous voulez';

  @override
  String get intentSkip => 'Rien de particulier';

  @override
  String get intentWaitingTitle => 'En attente';

  @override
  String get intentNothingWaiting => 'Rien en attente';

  @override
  String get intentAllDone =>
      'Vous avez terminé tout ce que vous aviez gardé pour plus tard.';

  @override
  String get intentMarkDone => 'Terminé';

  @override
  String get intentUndo => 'Remettre';

  @override
  String get intentDoneToast => 'Coché';

  @override
  String get intentChange => 'Changer l\'intention';

  @override
  String get intentClear => 'Rien de particulier';

  @override
  String intentEmptyOne(String verb) {
    return 'Rien à $verb ici';
  }

  @override
  String get intentEmptyBody =>
      'Les captures que vous marquez arrivent ici jusqu\'à ce que vous les cochiez.';

  @override
  String intentDoneCount(int count) {
    return '$count terminées';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count semaines',
      one: 'il y a 1 semaine',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count mois',
      one: 'il y a 1 mois',
    );
    return '$_temp0';
  }
}
