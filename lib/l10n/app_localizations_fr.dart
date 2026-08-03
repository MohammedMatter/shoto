// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
  String get homeInboxEmpty => 'Rien d\'enregistré';

  @override
  String get homeInboxEmptySubtitle =>
      'Partagez une capture vers SHOTO pour commencer';

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
  String get homeToolsTitle => 'Ce que SHOTO sait faire';

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
  String get homeToolsTitleShort => 'Faire quelque chose';

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
  String get rulesTitle => 'Règles';

  @override
  String get rulesSubtitle => 'Le classement qui se fait sans vous';

  @override
  String get rulesTeachHeadline => 'Arrêtez de trier vos captures à la main';

  @override
  String get rulesTeachIntro =>
      'Une règle tient en une phrase : quand une capture ressemble à ceci, range-la dans ce dossier. Écrivez-la une fois et chaque capture correspondante y atterrit toute seule — dès son arrivée.';

  @override
  String get rulesTeachExample =>
      'Par exemple : quand une capture contient un numéro de carte → range-la dans Reçus.';

  @override
  String get rulesTeachStep1Title => '1. Décrivez la capture';

  @override
  String get rulesTeachStep1Body =>
      'Un mot imprimé dessus, ce qu\'elle montre, ou des données privées dedans.';

  @override
  String get rulesTeachStep2Title => '2. Choisissez le dossier';

  @override
  String get rulesTeachStep2Body =>
      'Où les captures correspondantes doivent arriver.';

  @override
  String get rulesTeachStep3Title => '3. C\'est tout';

  @override
  String get rulesTeachStep3Body =>
      'SHOTO les classe pour vous à partir de là. Vous pouvez aussi appliquer vos règles aux captures déjà en attente.';

  @override
  String get rulesTeachShow => 'Comment marchent les règles ?';

  @override
  String get rulesTeachHide => 'Compris';

  @override
  String get rulesStartTemplates => 'Ou partez d\'un exemple';

  @override
  String get rulesTemplateReceipts => 'Reçus et factures';

  @override
  String get rulesTemplateReceiptsWhy =>
      'Tout ce qui porte un numéro de carte ou un total';

  @override
  String get rulesTemplateTickets => 'Billets et réservations';

  @override
  String get rulesTemplateTicketsWhy =>
      'Cartes d\'embarquement, réservations, confirmations de commande';

  @override
  String get rulesTemplateCodes => 'Codes et mots de passe';

  @override
  String get rulesTemplateCodesWhy =>
      'Codes à usage unique et tout ce qui ressemble à un mot de passe';

  @override
  String get rulesTemplateAnimals => 'Photos d\'animaux';

  @override
  String get rulesTemplateAnimalsWhy =>
      'Se base sur ce que montre l\'image, pas sur ses mots';

  @override
  String get rulesTemplatePicked =>
      'Choisissez un dossier et elle est prête à enregistrer.';

  @override
  String get rulesEmptyTitle => 'Aucune règle';

  @override
  String get rulesNew => 'Nouvelle règle';

  @override
  String get rulesNeedFolderFirst =>
      'Créez d\'abord un dossier — une règle a besoin d\'un endroit où classer.';

  @override
  String get rulesDeleteTitle => 'Supprimer cette règle ?';

  @override
  String get rulesDeleteMessage =>
      'Les captures déjà classées restent où elles sont.';

  @override
  String rulesWhenIt(String summary) {
    return 'Quand elle $summary';
  }

  @override
  String get rulesBacklogTitle => 'Rattraper le retard';

  @override
  String get rulesBacklogIdle =>
      'Applique vos règles aux captures qui ne sont dans aucun dossier. Ce que vous avez classé à la main n\'est pas touché.';

  @override
  String rulesBacklogRunning(int done, int total) {
    return 'Vérification de $done sur $total…';
  }

  @override
  String get rulesBacklogNothing => 'Plus rien à trier.';

  @override
  String rulesBacklogResult(int filed, int examined) {
    return '$filed captures classées sur $examined non triées.';
  }

  @override
  String get rulesRunNow => 'Appliquer les règles';

  @override
  String get ruleBuilderTitle => 'Nouvelle règle';

  @override
  String get ruleBuilderIntro =>
      'Deux questions : ce qu\'elle repère, et où ça va.';

  @override
  String get ruleBuilderFolderLabel => 'Où va-t-elle ?';

  @override
  String get ruleBuilderConditionLabel => 'Que doit-elle repérer ?';

  @override
  String get ruleBuilderConditionsLabel => 'Repère aussi';

  @override
  String get ruleBuilderAddCondition => 'En ajouter une';

  @override
  String get ruleBuilderMatchAll => 'Toutes';

  @override
  String get ruleBuilderMatchAny => 'N\'importe laquelle';

  @override
  String get ruleBuilderMatchAllHelp =>
      'La capture doit toutes les satisfaire.';

  @override
  String get ruleBuilderMatchAnyHelp => 'Il suffit qu\'une seule soit vraie.';

  @override
  String get ruleBuilderSave => 'Enregistrer la règle';

  @override
  String get ruleBuilderIncomplete => 'Choisissez quoi repérer, et un dossier';

  @override
  String ruleBuilderPreview(String folder, String summary) {
    return 'Classer dans $folder quand la capture $summary.';
  }

  @override
  String get ruleBuilderPreviewTitle => 'VOTRE RÈGLE, EN MOTS';

  @override
  String get conditionTextContains => 'contient un mot';

  @override
  String get conditionTextContainsHelp =>
      'Regarde le texte que SHOTO lit dans l\'image et cherche des mots entiers : « code » ne se déclenchera pas sur « barcode ». Utilisez un mot qui serait réellement imprimé sur ce type de capture.';

  @override
  String get conditionTextContainsHint =>
      'un mot écrit dessus — « facture », « billet »';

  @override
  String get conditionShowsSubject => 'montre quelque chose';

  @override
  String get conditionShowsSubjectHelp =>
      'Regarde ce que l\'image représente, pas ce qu\'elle dit. Le mot doit correspondre à celui du modèle : touchez-en un dans votre bibliothèque ci-dessous plutôt que de deviner.';

  @override
  String get conditionShowsSubjectHint =>
      'ce qu\'elle montre — « chat », « animal », « nourriture »';

  @override
  String get conditionContainsSensitive => 'contient des données privées';

  @override
  String get conditionContainsSensitiveHelp =>
      'Les mêmes contrôles que Partage protégé — les numéros de carte passent une vraie somme de contrôle, donc un numéro de commande n\'est pas pris pour une carte.';

  @override
  String get conditionHasAnyText => 'contient du texte lisible';

  @override
  String get conditionHasAnyTextHelp =>
      'Vrai pour toute image contenant des mots. Pratique pour séparer les captures des photos enregistrées.';

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
  String get settingsAutomation => 'Automatisation';

  @override
  String get settingsAutomationCaption =>
      'Écrivez une règle une fois et SHOTO classe les captures correspondantes dès leur arrivée.';

  @override
  String get settingsRules => 'Règles de classement';

  @override
  String get settingsRulesHint => 'Laissez SHOTO trier pour vous';

  @override
  String get settingsFindDuplicates => 'Trouver les doublons';

  @override
  String get settingsClearCache => 'Vider le cache d\'images';

  @override
  String get settingsShare => 'Partager SHOTO';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutTitle => 'Se déconnecter ?';

  @override
  String get settingsPrivacyNote =>
      'SHOTO ne lit jamais votre galerie. Il ne garde que les captures que vous lui partagez, et tout ce qu\'il en fait — lire le texte, chercher les doublons — se passe sur cet appareil. Rien n\'est jamais envoyé ailleurs.';

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
  String get quickSaveFiledByRules => 'Classé par vos règles.';

  @override
  String get quickSaveNoRuleMatched =>
      'Aucune règle ne correspond — laissée non triée dans votre bibliothèque.';

  @override
  String get quickSaveFailedTitle => 'Impossible de lire cette image';

  @override
  String get quickSaveFailedBody => 'Essayez de la partager à nouveau.';

  @override
  String get quickSaveSignedOutTitle => 'Connectez-vous d’abord à SHOTO';

  @override
  String get quickSaveSignedOutBody =>
      'Votre bibliothèque appartient à votre compte. Ouvrez SHOTO, connectez-vous, puis partagez à nouveau.';

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
  String get featRules => 'Des règles qui classent pour vous';

  @override
  String get featRulesBody =>
      'Écrivez une règle une fois et chaque capture partagée se classe seule. Vous avez écrit la règle, vous savez donc toujours pourquoi.';

  @override
  String get featSearch => 'Cherchez dans vos captures';

  @override
  String get featSearchBody =>
      'Retrouvez n’importe quelle capture par les mots qu’elle contient, en arabe ou en anglais. Rien n’est envoyé — la lecture se fait sur votre téléphone.';

  @override
  String get featSafeShare => 'Partage protégé';

  @override
  String get featSafeShareBody =>
      'Remplace numéros de carte, adresses, noms et coordonnées par des équivalents crédibles : même longueur, même format, même endroit. La copie envoyée ne semble pas retouchée.';

  @override
  String get featActions => 'Transformez vos captures en actions';

  @override
  String get featActionsBody =>
      'Appelez un numéro, ouvrez un lien, copiez un code ou un IBAN — directement depuis l’image, sans rien retaper.';

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
  String get featUnlimited => 'Dossiers et captures illimités';

  @override
  String get featUnlimitedBody =>
      'L\'offre gratuite s\'arrête à quelques dossiers et captures. Pro supprime les deux limites.';

  @override
  String get featRulesHow =>
      'Une règle est une phrase que vous écrivez vous-même : quand une capture ressemble à ceci, range-la dans ce dossier. Chaque nouvelle capture est confrontée à vos règles dès son arrivée, si bien que le classement cesse d’être quelque chose à penser.';

  @override
  String get featRulesPoint1 =>
      'Correspondance sur les mots imprimés dans l’image, sur ce que la photo montre, ou sur la présence de données sensibles.';

  @override
  String get featRulesPoint2 =>
      'Exigez toutes vos conditions ou n’importe laquelle d’entre elles, et inversez la condition de votre choix.';

  @override
  String get featRulesPoint3 =>
      'Rien n’est deviné. C’est vous qui avez écrit la règle, vous savez donc toujours pourquoi une capture a atterri là.';

  @override
  String get featSearchHow =>
      'SHOTO lit le texte imprimé dans chaque capture et le retient : un seul mot dont vous vous souvenez suffit à retrouver l’image — sans nom de fichier, sans dossier, sans faire défiler.';

  @override
  String get featSearchPoint1 =>
      'Lit l’arabe et l’anglais, et trouve encore le bon résultat quand l’orthographe diffère légèrement.';

  @override
  String get featSearchPoint2 =>
      'Cherche aussi d’après ce que montre l’image : essayez « reçu », « chat » ou « nourriture ».';

  @override
  String get featSearchPoint3 =>
      'La lecture se fait sur votre téléphone. Rien n’est envoyé, cela fonctionne donc aussi hors ligne.';

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
      'Numéros de téléphone, liens, adresses e-mail, IBAN et codes de vérification sont repérés pour vous.';

  @override
  String get featActionsPoint2 =>
      'Une seule touche pour appeler, ouvrir ou copier — sans relire des chiffres sur une image.';

  @override
  String get featActionsPoint3 =>
      'Fonctionne sur les captures que vous avez déjà, pas seulement sur les nouvelles.';

  @override
  String get featStitchHow =>
      'Prenez plusieurs captures en parcourant une longue conversation ou page : SHOTO calcule où elles se recouvrent et les réassemble en une seule image haute.';

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
      'SHOTO compare les captures d’après leur apparence plutôt que leur nom ou leur taille : il repère donc aussi les quasi-identiques — un renvoi, un autre recadrage, la même chose capturée deux fois.';

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
      'L\'offre gratuite est une vraie application utilisable, pas un essai — elle a simplement un plafond. Pro retire ce plafond, et tout ce que vous avez déjà organisé reste exactement où il est.';

  @override
  String get featUnlimitedPoint1 =>
      'Autant de dossiers que votre bibliothèque en a réellement besoin.';

  @override
  String get featUnlimitedPoint2 =>
      'Aucune limite au nombre de captures que vous classez et mettez en favori.';

  @override
  String get featUnlimitedPoint3 =>
      'L’enregistrement, les dossiers, les favoris et l’historique de recherche restent les vôtres dans tous les cas.';

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
  String includedFreeBody(int folders, int count) {
    return '$folders dossiers et $count captures organisées, plus l’enregistrement, les favoris et la galerie, gratuits pour toujours.';
  }

  @override
  String get authWelcome => 'Bienvenue sur SHOTO';

  @override
  String get authSubtitle =>
      'Connectez-vous pour enregistrer, organiser et retrouver toutes vos captures au même endroit.';

  @override
  String get authGoogle => 'Continuer avec Google';

  @override
  String get authApple => 'Continuer avec Apple';

  @override
  String get authLegal =>
      'En continuant, vous acceptez nos Conditions et notre Politique de confidentialité.';

  @override
  String get onboardingCta => 'Commencer';

  @override
  String get onboardingPromise => 'Tout reste sur votre téléphone.';

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
  String get ruleSummaryEmpty => 'Aucune condition — ne classe rien';

  @override
  String get ruleJoinAnd => ' et ';

  @override
  String get ruleJoinOr => ' ou ';

  @override
  String ruleSaysWord(String value) {
    return 'contient « $value »';
  }

  @override
  String ruleNotSaysWord(String value) {
    return 'ne contient pas « $value »';
  }

  @override
  String ruleShows(String value) {
    return 'montre $value';
  }

  @override
  String ruleNotShows(String value) {
    return 'ne montre pas $value';
  }

  @override
  String ruleContains(String value) {
    return 'contient $value';
  }

  @override
  String ruleNotContains(String value) {
    return 'ne contient pas $value';
  }

  @override
  String get ruleHasText => 'contient du texte lisible';

  @override
  String get ruleNoText => 'ne contient pas de texte lisible';

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
  String get kindPhone => 'un numéro de téléphone';

  @override
  String get kindLink => 'un lien';

  @override
  String get actionCall => 'Appeler';

  @override
  String get actionWhatsapp => 'WhatsApp';

  @override
  String get actionSms => 'Message';

  @override
  String get actionEmailAction => 'Écrire';

  @override
  String get actionOpen => 'Ouvrir';

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
  String get settingsAccount => 'Compte';

  @override
  String get settingsSignOutHint => 'Vos captures restent sur cet appareil';

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
  String get errorLoadRules => 'Impossible de charger vos règles.';

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
  String get quickSaveByRules => 'Laisser mes règles la classer';

  @override
  String get ruleSeenTitle => 'CE QUE SHOTO A VU DANS VOTRE BIBLIOTHÈQUE';

  @override
  String get ruleSeenEmpty =>
      'SHOTO n’a pas encore regardé dans vos captures. Il lit chacune à son arrivée, donc ceci se remplira.';

  @override
  String get ruleSeenHint =>
      'Touchez-en un : ce sont les mots exacts produits par le modèle, donc une règle bâtie dessus se déclenchera vraiment.';

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
  String get onbProTitle => 'SHOTO Pro';

  @override
  String get onbProBody =>
      'Les règles classent vos nouvelles captures à votre place, et tout ce qui suit est inclus.';

  @override
  String onbProMore(int count) {
    return 'et $count de plus';
  }

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
  String rulePreviewMatches(int count, int indexed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prendrait $count des $indexed captures que SHOTO a lues',
      one: 'Prendrait 1 des $indexed captures que SHOTO a lues',
    );
    return '$_temp0';
  }

  @override
  String get rulePreviewNone =>
      'Rien de ce que SHOTO a lu jusqu\'ici ne correspond';

  @override
  String get rulePreviewNotIndexed =>
      'SHOTO n\'a encore lu aucune de vos captures, il n\'y a donc rien à vérifier. Il lit chacune dès son arrivée.';

  @override
  String rulePreviewTaken(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d\'entre elles reviennent à une règle placée au-dessus.',
      one: '1 d\'entre elles revient à une règle placée au-dessus.',
    );
    return '$_temp0';
  }

  @override
  String get rulePreviewAllTaken =>
      'Toutes les captures correspondantes sont déjà prises par une règle au-dessus. Remontez cette règle si elle doit l\'emporter.';

  @override
  String get rulePreviewFloor =>
      'Ne compte que ce que SHOTO a déjà lu. Les nouvelles captures sont vérifiées dès leur arrivée.';

  @override
  String get ruleBuilderEditTitle => 'Modifier la règle';

  @override
  String get ruleBuilderEditIntro =>
      'Les modifications s\'appliquent à partir de maintenant. Les captures déjà classées restent où elles sont.';

  @override
  String get ruleBuilderUpdate => 'Enregistrer les modifications';

  @override
  String get rulesPriorityNote =>
      'Une capture va à la première règle qui correspond. Utilisez les flèches pour changer laquelle.';

  @override
  String get rulesCardNotIndexed =>
      'Rien de lu pour l\'instant — rien à vérifier';

  @override
  String rulesCardClaims(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Prend $count captures',
      one: 'Prend 1 capture',
    );
    return '$_temp0';
  }

  @override
  String get rulesCardClaimsNone => 'Ne prend encore rien';

  @override
  String rulesCardOverruled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count correspondances vont à une règle au-dessus',
      one: '1 correspondance va à une règle au-dessus',
    );
    return '$_temp0';
  }

  @override
  String get rulesMoveUp => 'Monter';

  @override
  String get rulesMoveDown => 'Descendre';

  @override
  String rulesBacklogUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count captures n\'ont pas encore été lues — relancez pour continuer.',
      one: '1 capture n\'a pas encore été lue — relancez pour continuer.',
    );
    return '$_temp0';
  }

  @override
  String indexingProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lecture de vos captures en cours — $count restantes',
      one: 'Lecture de vos captures en cours — 1 restante',
    );
    return '$_temp0';
  }

  @override
  String get ruleBuilderMatches => 'Correspond';

  @override
  String get ruleBuilderMatchesNot => 'NE correspond PAS';

  @override
  String get ruleBuilderMatchesNotHelp =>
      'La règle s\'applique quand ce n\'est pas le cas — pratique pour écarter une exception.';

  @override
  String rulePreviewAlreadyFiled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count d\'entre elles sont déjà dans des dossiers, et une exécution ne déplace jamais celles-là. Seules les nouvelles captures arriveront ici.',
      one:
          '1 d\'entre elles est déjà dans un dossier, et une exécution ne déplace jamais celles-là. Seules les nouvelles captures arriveront ici.',
    );
    return '$_temp0';
  }

  @override
  String rulesCardAlreadyFiled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Correspond à $count, mais elles sont déjà classées ailleurs',
      one: 'Correspond à 1, mais elle est déjà classée ailleurs',
    );
    return '$_temp0';
  }
}
