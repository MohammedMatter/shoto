// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get settingsCrashReports => 'Segnalazioni di arresto';

  @override
  String get settingsCrashReportsHint =>
      'Invia dettagli tecnici quando qualcosa va storto';

  @override
  String get settingsOnboarding => 'Rivedi l\'introduzione';

  @override
  String get settingsOnboardingHint =>
      'Riproduci di nuovo la sequenza iniziale';

  @override
  String get settingsSignOut => 'Esci';

  @override
  String get settingsSignOutTitle => 'Vuoi uscire?';

  @override
  String get authWelcome => 'Benvenuto in Shoto';

  @override
  String get authWhy =>
      'Non tutto quello che salvi merita lo stesso scaffale. Shoto dà agli screenshot a cui tieni davvero un posto tutto loro.';

  @override
  String get authGoogle => 'Continua con Google';

  @override
  String get authApple => 'Continua con Apple';

  @override
  String get authLegal =>
      'Continuando accetti i nostri Termini di servizio e l\'Informativa sulla privacy.';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSignOutHint =>
      'I tuoi screenshot restano su questo dispositivo';

  @override
  String get settingsSignIn => 'Accedi';

  @override
  String get settingsSignInHint =>
      'Facoltativo. Serve solo per spostare un acquisto su un altro telefono.';

  @override
  String paywallTrialCta(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Inizia $days giorni gratis',
      one: 'Inizia 1 giorno gratis',
    );
    return '$_temp0';
  }

  @override
  String paywallTrialNote(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Gratis per $days giorni, poi $price. Puoi annullare quando vuoi prima della fine.',
      one:
          'Gratis per un giorno, poi $price. Puoi annullare quando vuoi prima della fine.',
    );
    return '$_temp0';
  }

  @override
  String get triageTitle => 'Dall\'ultima volta';

  @override
  String get triageBody =>
      'Tieni ciò che ha senso in Shoto. Tutto il resto resta esattamente dov\'è.';

  @override
  String get triageKeep => 'Tieni';

  @override
  String get triageSkip => 'Salta';

  @override
  String get triageFinish => 'Fatto';

  @override
  String triageProgress(int index, int total) {
    return '$index di $total';
  }

  @override
  String triageNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuovi screenshot',
      one: '1 nuovo screenshot',
    );
    return '$_temp0';
  }

  @override
  String triageKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenuti',
      one: '1 tenuto',
      zero: 'Niente tenuto',
    );
    return '$_temp0';
  }

  @override
  String get triageReview => 'Rivedi';

  @override
  String get triageInviteDecline => 'Non ora';

  @override
  String get triageInviteTitle => 'Mostrare qui i nuovi screenshot?';

  @override
  String get triageInviteBody =>
      'Shoto può elencare ciò che catturi d\'ora in poi, così tieni i pochi che contano. Nulla entra nella tua libreria finché non lo decidi tu.';

  @override
  String get triageInviteAccept => 'Mostrali';

  @override
  String get triageInviteDismiss => 'No, grazie';

  @override
  String get settingsTriage => 'Proponi i nuovi screenshot';

  @override
  String get settingsTriageHint =>
      'Mostra quello che catturi; da solo non tiene nulla';

  @override
  String get settingsCaptureAlerts => 'Avvisami subito';

  @override
  String get settingsCaptureAlertsHint =>
      'Una notifica discreta subito dopo lo scatto';

  @override
  String get settingsCaptureAlertsMuted =>
      'Le notifiche di Shoto sono disattivate — attivale nelle impostazioni del telefono';

  @override
  String get settingsCaptureAlertsStopped =>
      'Android ha interrotto i controlli. Apri Shoto una volta per riavviarli';

  @override
  String get settingsCaptureAlertsWaiting =>
      'In ascolto. Ancora nessuno scatto';

  @override
  String settingsCaptureAlertsLastRun(String when) {
    return 'Ultimo controllo $when';
  }

  @override
  String timeAgoMinutes(int count) {
    return '$count min fa';
  }

  @override
  String timeAgoHours(int count) {
    return '$count h fa';
  }

  @override
  String timeAgoDays(int count) {
    return '$count g fa';
  }

  @override
  String get settingsQuickTile => 'Riquadro impostazioni rapide';

  @override
  String get settingsQuickTileHint =>
      'Salva l’ultimo screenshot senza aprire il menu di condivisione';

  @override
  String get settingsQuickTileAdded => 'Aggiunto alle impostazioni rapide';

  @override
  String get settingsQuickTileManual =>
      'Aggiungilo a mano: apri le impostazioni rapide, tocca modifica e trascina dentro il riquadro di Shoto.';

  @override
  String get settingsQuickTileSheetTitle => 'Due gesti, da qualsiasi app';

  @override
  String get settingsQuickTileSheetBody =>
      'Shoto può stare nelle Impostazioni rapide del telefono, accanto alla torcia. Un tocco archivia lo screenshot appena fatto: senza aprire l\'app e senza scorrere il menu di condivisione.';

  @override
  String get settingsQuickTileStepPull =>
      'Scorri dall\'alto in qualsiasi schermata';

  @override
  String get settingsQuickTileStepTap =>
      'Tocca il riquadro Shoto: l\'ultimo screenshot è archiviato';

  @override
  String get settingsQuickTileStepStays =>
      'Resta sempre nello stesso posto, a differenza del menu di condivisione';

  @override
  String get settingsQuickTileAdd => 'Aggiungi il riquadro';

  @override
  String get settingsQuickTileNote =>
      'Legge solo lo screenshot appena fatto. Niente esce dal telefono.';

  @override
  String get folderIconsBasics => 'Base';

  @override
  String get folderIconsWork => 'Lavoro';

  @override
  String get folderIconsMoney => 'Denaro';

  @override
  String get folderIconsTravel => 'Viaggi';

  @override
  String get folderIconsHome => 'Casa e salute';

  @override
  String get folderIconsMedia => 'Media';

  @override
  String get folderIconsPeople => 'Persone';

  @override
  String get folderIconsSymbols => 'Simboli';

  @override
  String get folderIconsSocial => 'Social';

  @override
  String get folderIconsApps => 'App';

  @override
  String get quickTileOfferTitle => 'Salva senza il menu di condivisione';

  @override
  String get quickTileOfferBody =>
      'Aggiungi una scorciatoia per il tuo ultimo screenshot';

  @override
  String get triageNothingNew => 'Niente di nuovo da rivedere';

  @override
  String get reminderTitle => 'Ricordamelo';

  @override
  String get reminderLaterToday => 'Più tardi oggi';

  @override
  String get reminderThisEvening => 'Stasera';

  @override
  String get reminderTomorrow => 'Domani mattina';

  @override
  String get reminderNextWeek => 'La prossima settimana';

  @override
  String get reminderPickTime => 'Scegli un orario';

  @override
  String get reminderClear => 'Rimuovi il promemoria';

  @override
  String get reminderNotificationTitle => 'Shoto';

  @override
  String get reminderMuted =>
      'Le notifiche sono disattivate, quindi non ti arriverà — attivale nelle impostazioni del telefono.';

  @override
  String get reminderUnsupported =>
      'Per ora i promemoria sono disponibili solo su Android.';

  @override
  String reminderSet(String when) {
    return 'Promemoria impostato per $when';
  }

  @override
  String reminderPending(String when) {
    return 'Promemoria per $when';
  }

  @override
  String get reminderNotificationBody => 'Volevi tornare su questo screenshot';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonSomethingWentWrong => 'Qualcosa è andato storto';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Libreria';

  @override
  String get navFolders => 'Cartelle';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get tagline => 'I tuoi screenshot, in ordine';

  @override
  String get homeGreetingMorning => 'Buongiorno';

  @override
  String get homeGreetingAfternoon => 'Buon pomeriggio';

  @override
  String get homeGreetingEvening => 'Buonasera';

  @override
  String get homeInboxEmpty => 'Ancora niente di salvato';

  @override
  String get homeInboxEmptySubtitle =>
      'Scegline qualcuno dal telefono adesso, oppure condividi uno screenshot in Shoto da qualsiasi app.';

  @override
  String get homeEmptyImportCta => 'Scegli dal mio telefono';

  @override
  String get homeNeedsYou => 'Ti aspetta';

  @override
  String get homeInboxClear => 'Tutto archiviato';

  @override
  String get homeInboxClearSubtitle => 'Niente in attesa di essere sistemato';

  @override
  String get homeInboxCountSubtitle =>
      'Screenshot che non hai ancora archiviato';

  @override
  String get homeStatScreenshots => 'Screenshot';

  @override
  String get homeStatFavorites => 'Preferiti';

  @override
  String get homeStatFolders => 'Cartelle';

  @override
  String get homeToolsTitle => 'Strumenti';

  @override
  String get homeToolsTitleEmpty => 'Comincia da qui';

  @override
  String get homeToolSafeShare => 'Safe share';

  @override
  String get homeToolSafeShareSubtitle => 'Prima nascondi i dati privati';

  @override
  String get homeToolDuplicates => 'Trova i doppioni';

  @override
  String get homeToolDuplicatesSubtitle => 'Libera spazio';

  @override
  String get homeToolSearch => 'Cerca dentro';

  @override
  String get homeToolSearchSubtitle => 'Trova il testo nelle tue immagini';

  @override
  String get homeToolStitch => 'Unisci scatti lunghi';

  @override
  String get homeToolStitchSubtitle => 'Ricomponi una cattura a scorrimento';

  @override
  String get homeRecent => 'Recenti';

  @override
  String get libraryPickForMerge =>
      'Scegli due o più scatti della stessa pagina';

  @override
  String get libraryPickForProtect => 'Scegli lo screenshot da proteggere';

  @override
  String get libraryActionProtect => 'Proteggi';

  @override
  String get homeSeeAll => 'Vedi tutti';

  @override
  String get libraryEmptyTitle => 'Ancora niente di salvato';

  @override
  String get libraryEmptyMessage =>
      'Condividi uno screenshot con Shoto, o aggiungine uno con il pulsante +. La tua galleria non viene mai letta: si tiene solo quello che consegni.';

  @override
  String get libraryNoFavoritesTitle => 'Ancora nessun preferito';

  @override
  String get libraryNoFavoritesMessage =>
      'Tocca il cuore su uno screenshot per salvarlo qui.';

  @override
  String get libraryFilterAll => 'Tutti';

  @override
  String get libraryFilterFavorites => 'Preferiti';

  @override
  String get libraryTraitSensitive => 'Sensibili';

  @override
  String get libraryTraitLink => 'Link';

  @override
  String get libraryTraitContact => 'Telefono o e-mail';

  @override
  String get libraryTraitCode => 'Codici';

  @override
  String get libraryTraitEvent => 'Date';

  @override
  String get libraryCertaintyVerified => 'Verificato con checksum';

  @override
  String get libraryCertaintyRead => 'Letto dal testo nei tuoi screenshot';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count non ancora letti';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return 'Nessuno screenshot con $trait';
  }

  @override
  String get libraryNoTraitMessage =>
      'Nessuno screenshot già letto ne contiene.';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'Niente trovato in ciò che è stato letto. $count screenshot non sono mai stati letti, quindi non possono ancora corrispondere.';
  }

  @override
  String get libraryShowAll => 'Mostra tutti';

  @override
  String get libraryFilterUnsorted => 'Da sistemare';

  @override
  String get libraryNoUnsortedTitle => 'È tutto archiviato';

  @override
  String get libraryNoUnsortedMessage =>
      'Niente ti aspetta. I nuovi screenshot restano qui finché non li archivi o li segni.';

  @override
  String librarySelectedCount(int count) {
    return '$count selezionati';
  }

  @override
  String get librarySelectAll => 'Seleziona tutto';

  @override
  String get librarySelect => 'Seleziona';

  @override
  String get librarySelectPrompt => 'Seleziona gli scatti';

  @override
  String get libraryActionMerge => 'Unisci';

  @override
  String get libraryActionMove => 'Sposta';

  @override
  String get libraryActionDelete => 'Elimina';

  @override
  String get libraryDeleteTitle => 'Eliminare gli screenshot?';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Questo eliminerà definitivamente $count screenshot dal tuo dispositivo.',
      one: 'Questo eliminerà definitivamente 1 screenshot dal tuo dispositivo.',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'Serve l\'accesso alle foto';

  @override
  String get permissionNeededMessage =>
      'Shoto tiene gli screenshot che condividi al suo interno in un album tutto suo. Gli serve l\'accesso alle foto per scriverci e rileggerli: il resto della tua galleria non viene mai elencato.';

  @override
  String get permissionAskTitle =>
      'Shoto deve vedere il suo album di screenshot';

  @override
  String get permissionAskMessage =>
      'Solo quell’album, e solo per elencare ciò che contiene. Nulla viene caricato online, e nulla entra nella tua libreria finché non lo scegli tu.';

  @override
  String get permissionAllow => 'Consenti accesso';

  @override
  String get permissionPartialTitle => 'Serve l\'accesso completo alle foto';

  @override
  String get permissionPartialMessage =>
      'Al momento Shoto vede solo poche foto che hai scelto a mano, quindi non riesce a raggiungere il suo album. Scegli «Consenti tutte» nel permesso foto per continuare.';

  @override
  String get permissionOpenSettings => 'Apri Impostazioni';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsGridDensity => 'Densità griglia';

  @override
  String get settingsAppearanceHint =>
      'Tema, colore d\'accento e dimensione della griglia';

  @override
  String get appearanceTint => 'Colore d\'accento';

  @override
  String get appearanceTintHint =>
      'Pulsanti, interruttori e tutto ciò che è selezionato.';

  @override
  String get appearancePreview => 'Anteprima';

  @override
  String get tintTeal => 'Petrolio';

  @override
  String get tintSlate => 'Ardesia';

  @override
  String get tintIndigo => 'Indaco';

  @override
  String get tintPlum => 'Prugna';

  @override
  String get tintRose => 'Rosa';

  @override
  String get tintEmber => 'Brace';

  @override
  String get tintAmber => 'Ambra';

  @override
  String get tintMoss => 'Muschio';

  @override
  String get tintGarnet => 'Granato';

  @override
  String get tintBrass => 'Ottone';

  @override
  String get tintFern => 'Felce';

  @override
  String get tintJade => 'Giada';

  @override
  String get tintOlive => 'Oliva';

  @override
  String get tintCyan => 'Ciano';

  @override
  String get tintDenim => 'Denim';

  @override
  String get tintViolet => 'Viola';

  @override
  String get tintSky => 'Cielo';

  @override
  String get tintOrchid => 'Orchidea';

  @override
  String get tintFuchsia => 'Fucsia';

  @override
  String get tintClay => 'Argilla';

  @override
  String get tintGraphite => 'Grafite';

  @override
  String get appearanceMoreColors => 'Altri colori';

  @override
  String get appearanceSelectTint => 'Scegli il colore d\'accento';

  @override
  String get appearanceFolders => 'Schede delle cartelle';

  @override
  String get appearanceFolderCount => 'Numero di scatti';

  @override
  String get appearanceFolderDate => 'Data di creazione';

  @override
  String get appearanceFolderSize => 'Schede per riga';

  @override
  String get appearanceLibrary => 'Griglia della libreria';

  @override
  String get appIcon => 'Icona dell\'app';

  @override
  String get appIconDefault => 'Originale';

  @override
  String get appIconHint =>
      'Cambiarla chiude Shoto per un istante, mentre Android sostituisce l\'icona.';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Come il telefono';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Ora mostra $language';
  }

  @override
  String get settingsBehaviour => 'Comportamento';

  @override
  String get settingsHaptics => 'Feedback aptico';

  @override
  String get settingsHapticsHint => 'Un piccolo tocco quando premi';

  @override
  String get settingsConfirmDelete => 'Chiedi prima di eliminare';

  @override
  String get settingsConfirmDeleteHint =>
      'L\'eliminazione non si può annullare';

  @override
  String get settingsFindDuplicates => 'Trova i doppioni';

  @override
  String get settingsClearCache => 'Svuota la cache immagini';

  @override
  String get settingsShare => 'Condividi Shoto';

  @override
  String get settingsPrivacyNote =>
      'Shoto tiene solo gli screenshot che gli dai, e tutto quello che ci fa — leggere il testo, trovare i doppioni — avviene su questo dispositivo. Le tue immagini non vengono mai caricate. Tre cose le attivi tu: proporre i nuovi screenshot legge il tuo album Screenshot per poterteli chiedere, un account invia solo il tuo indirizzo e-mail perché l\'abbonamento sopravviva a un cambio di telefono, e le segnalazioni di arresto inviano ciò che si è rotto — il codice, mai un\'immagine.';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonConfirm => 'Conferma';

  @override
  String get commonRename => 'Rinomina';

  @override
  String get commonShare => 'Condividi';

  @override
  String get commonUnlock => 'Sblocca';

  @override
  String get foldersEmptyTitle => 'Ancora nessuna cartella';

  @override
  String get foldersEmptyMessage =>
      'Le cartelle sono il modo per ritrovare le cose dopo. Falne una per gli scontrini, una per le ricette — quello che cerchi davvero.';

  @override
  String get foldersNew => 'Nuova cartella';

  @override
  String get foldersCreate => 'Crea cartella';

  @override
  String get foldersNameLabel => 'Nome cartella';

  @override
  String get foldersNameHint => 'Scontrini, Ricette, Lavoro…';

  @override
  String get foldersPrivate => 'Privata (blocco con volto o impronta)';

  @override
  String get foldersPrivateFace => 'Privata (blocco con volto)';

  @override
  String get foldersPrivateFingerprint => 'Privata (blocco con impronta)';

  @override
  String get foldersPrivateGeneric => 'Privata (bloccata)';

  @override
  String get foldersOptions => 'Opzioni cartella';

  @override
  String get foldersDelete => 'Elimina cartella';

  @override
  String get foldersDeleteKept => 'Gli screenshot dentro restano';

  @override
  String foldersDeleteTitle(String name) {
    return 'Eliminare «$name»?';
  }

  @override
  String get foldersDeleteMessage =>
      'La cartella viene rimossa ma gli screenshot dentro restano nella tua libreria.';

  @override
  String get foldersEditTitle => 'Modifica cartella';

  @override
  String get foldersSearchHint => 'Cerca cartelle';

  @override
  String get foldersSortLabel => 'Ordina cartelle';

  @override
  String get foldersSortRecent => 'Più recenti prima';

  @override
  String get foldersSortName => 'Nome (A–Z)';

  @override
  String get foldersSortFullest => 'Più screenshot';

  @override
  String get foldersNoMatchTitle => 'Nessuna cartella corrisponde';

  @override
  String foldersNoMatchMessage(String query) {
    return 'Qui non c\'è niente che si chiami «$query». Prova con una parte del nome.';
  }

  @override
  String get folderDefaultTrips => 'Piani di viaggio';

  @override
  String get folderDefaultRecipes => 'Ricette';

  @override
  String get folderDefaultMedications => 'Farmaci';

  @override
  String get folderDefaultAiNotes => 'Note IA';

  @override
  String get folderDefaultMoney => 'Soldi';

  @override
  String get folderDefaultWorkouts => 'Allenamenti';

  @override
  String get folderDefaultMusic => 'Musica';

  @override
  String get foldersMoveTitle => 'Sposta nella cartella';

  @override
  String get foldersMoveRemove => 'Togli dalla cartella';

  @override
  String get foldersMoveNone =>
      'Ancora nessuna cartella. Creane una dalla scheda Cartelle.';

  @override
  String folderLockedTitle(String name) {
    return 'Sblocca «$name»';
  }

  @override
  String get folderLockedMessage =>
      'Questa cartella è protetta. Autenticati per vederla.';

  @override
  String get folderEmptyTitle => 'Qui non c\'è ancora niente';

  @override
  String get folderEmptyMessage =>
      'Sposta gli screenshot in questa cartella dalla tua libreria.';

  @override
  String get detailFavorite => 'Preferito';

  @override
  String get detailUnfavorite => 'Togli dai preferiti';

  @override
  String get detailAddFavorite => 'Aggiungi ai preferiti';

  @override
  String a11yScreenshot(String date) {
    return 'Screenshot del $date';
  }

  @override
  String a11yScreenshotFavorite(String date) {
    return 'Screenshot del $date, preferito';
  }

  @override
  String get detailActions => 'Azioni';

  @override
  String get detailSafeShare => 'Safe share';

  @override
  String get detailMore => 'Altro';

  @override
  String get detailDeleteTitle => 'Eliminare lo screenshot?';

  @override
  String get detailDeleteMessage =>
      'Questo lo eliminerà definitivamente dal tuo dispositivo.';

  @override
  String get quickSaveTitleOne => 'Salva in Shoto';

  @override
  String quickSaveTitleMany(int count) {
    return 'Salva $count screenshot';
  }

  @override
  String get quickSaveFileOne => 'Archivia questo screenshot';

  @override
  String quickSaveFileMany(int count) {
    return 'Archivia $count screenshot';
  }

  @override
  String get quickSavePickFolder => 'Scegli una cartella';

  @override
  String get quickSaveNeedFolder => 'Crea una cartella dove metterli';

  @override
  String quickSaveFileIn(String folder) {
    return 'Archivia in $folder';
  }

  @override
  String get quickSaveCreateFirstFolder => 'Crea la tua prima cartella';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'Le cartelle sono il modo per ritrovare le cose dopo';

  @override
  String get quickSaveNewChip => 'Nuova';

  @override
  String get quickSaveSaved => 'Salvato in Shoto';

  @override
  String quickSaveFiled(String folder) {
    return 'Archiviato in $folder.';
  }

  @override
  String get quickSaveFailedTitle => 'Non sono riuscito a leggere l\'immagine';

  @override
  String get quickSaveFailedBody => 'Prova a condividerla di nuovo.';

  @override
  String get quickSaveNoCaptureTitle => 'Ancora nessuno screenshot';

  @override
  String get quickSaveNoCaptureBody =>
      'Fai uno screenshot, poi tocca di nuovo il riquadro.';

  @override
  String get quickSaveNoAccessTitle => 'Shoto non vede i tuoi screenshot';

  @override
  String get quickSaveNoAccessBody =>
      'Apri Shoto, consenti l’accesso alle foto e riprova.';

  @override
  String quickSaveSkipped(int count) {
    return 'Sono stati presi solo i primi $count';
  }

  @override
  String get dupTitle => 'Trova i doppioni';

  @override
  String get dupScanning => 'Cerco i doppioni';

  @override
  String get dupReading => 'Sto leggendo la tua libreria…';

  @override
  String dupProgress(int done, int total) {
    return 'Controllati $done di $total screenshot';
  }

  @override
  String get dupNoneTitle => 'Nessun doppione trovato';

  @override
  String get dupNoneBody => 'La tua libreria di screenshot è già pulita.';

  @override
  String get dupScanAgain => 'Cerca di nuovo';

  @override
  String dupReclaimable(String size) {
    return 'Si possono liberare fino a $size';
  }

  @override
  String get dupNothingSelected => 'Niente selezionato';

  @override
  String dupDeleteButton(int count, String size) {
    return 'Elimina $count · liberi $size';
  }

  @override
  String dupDeleteTitle(int count) {
    return 'Eliminare $count copie?';
  }

  @override
  String get dupDeleteMessage =>
      'Questo le elimina definitivamente dal tuo dispositivo. Le copie segnate da tenere non vengono toccate.';

  @override
  String dupDeleted(int count, String size) {
    return 'Eliminati $count · liberati $size';
  }

  @override
  String dupSets(int count) {
    return '$count gruppi';
  }

  @override
  String get dupBest => 'MIGLIORE';

  @override
  String get dupKeepAll => 'Tieni tutti';

  @override
  String get dupKeepingAll => 'Li tieni tutti — non verrà eliminato niente';

  @override
  String get dupUndo => 'Annulla';

  @override
  String dupFrees(String size) {
    return 'Libera $size';
  }

  @override
  String get safeShareTitle => 'Safe share';

  @override
  String get safeShareScanning => 'Controllo i dati privati';

  @override
  String get safeShareOnDevice => 'La lettura avviene sul tuo telefono.';

  @override
  String get safeShareCleanTitle => 'Niente di privato trovato';

  @override
  String get safeShareCleanBody =>
      'In questo screenshot non sono stati notati numeri di carta, numeri di conto, codici o contatti. Puoi condividerlo così com\'è.';

  @override
  String get safeShareUnreadableTitle =>
      'Non sono riuscito a leggere lo screenshot';

  @override
  String get safeShareUnreadableBody =>
      'Il testo al suo interno non è stato riconosciuto.';

  @override
  String get safeShareShareUnchanged => 'Condividi invariato';

  @override
  String get safeShareShareAnyway => 'Condividi comunque';

  @override
  String get safeShareShareProtected => 'Condividi la copia protetta';

  @override
  String get safeShareKeepCopy => 'Conserva la copia in Shoto';

  @override
  String get safeShareFailed => 'Non sono riuscito a creare la copia protetta.';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dati privati trovati',
      one: '1 dato privato trovato',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'Il controllo è sempre gratis.';

  @override
  String get safeShareCleanAction => 'Pulisci questo screenshot';

  @override
  String get safeShareShareAsIs => 'Condividi senza modifiche';

  @override
  String get safeShareHowTitle => 'Coperto, per sempre';

  @override
  String get safeShareHowBody =>
      'Ogni dato privato viene coperto con un blocco pieno prima che la copia lasci il telefono. Niente è sfocato e niente si può rileggere: la copia coperta è l\'unica versione che esiste.';

  @override
  String get safeShareTreatmentCover => 'Copri';

  @override
  String get safeShareTreatmentKeep => 'Tieni';

  @override
  String get safeShareBuilding => 'Sto creando la tua copia pulita';

  @override
  String get safeShareNothingSelected => 'Non cambierà nulla';

  @override
  String get safeShareLockedPreview => 'Sblocca per vedere la versione pulita';

  @override
  String get safeShareReviewTitle => 'Controllali uno per uno';

  @override
  String safeShareFound(int count) {
    return '$count elementi coperti';
  }

  @override
  String get stitchTitle => 'Unisci screenshot';

  @override
  String get stitchWorking => 'Cerco la sovrapposizione';

  @override
  String get stitchWorkingBody =>
      'Sto confrontando dove ogni screenshot continua dal precedente.';

  @override
  String get stitchFailed => 'Non è stato possibile unire';

  @override
  String get stitchSave => 'Salva in galleria';

  @override
  String get stitchSaved => 'Salvato nella tua galleria';

  @override
  String get stitchDiscard => 'Scarta';

  @override
  String get commonDone => 'Fatto';

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get searchTitle => 'Cerca nei tuoi screenshot';

  @override
  String get searchHint => 'Cerca parole o cosa mostra un\'immagine';

  @override
  String get searchIntro =>
      'Qualsiasi parola scritta dentro un\'immagine, o quello che l\'immagine mostra: prova «gatto», «animale», «cibo» o «scontrino».';

  @override
  String get searchNoneTitle => 'Nessun risultato';

  @override
  String searchNoneBody(String query) {
    return 'Qui niente dice o somiglia a «$query».';
  }

  @override
  String get paywallTitle => 'Sblocca Shoto Pro';

  @override
  String get paywallSubtitle =>
      'Tutto quello che segue, con un solo abbonamento.';

  @override
  String get paywallMonthly => 'Mensile';

  @override
  String get paywallYearly => 'Annuale';

  @override
  String paywallSave(int percent) {
    return 'Risparmi il $percent%';
  }

  @override
  String get paywallPerYear => '/anno';

  @override
  String get paywallPerMonth => '/mese';

  @override
  String get paywallPreviewPricing =>
      'Gli abbonamenti non sono ancora attivi — prezzi solo di anteprima.';

  @override
  String get paywallNotSetUp =>
      'Gli abbonamenti non sono ancora configurati — torna presto.';

  @override
  String get paywallContinue => 'Continua';

  @override
  String get paywallUnavailable => 'Non ancora disponibile';

  @override
  String get paywallRestore => 'Ripristina acquisti';

  @override
  String get settingsRestoreHint =>
      'Hai già pagato? Recupera il tuo abbonamento.';

  @override
  String get settingsRestoreDone => 'Il tuo abbonamento è tornato.';

  @override
  String get paywallLegal =>
      'Si rinnova automaticamente fino all\'annullamento. Puoi annullare quando vuoi dalle impostazioni account di App Store o Google Play. Continuando accetti i nostri Termini di servizio e l\'Informativa sulla privacy.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'Shoto Pro';

  @override
  String get subPremiumBody => 'Ogni funzione sbloccata per te.';

  @override
  String subPremiumRenews(String date) {
    return 'Si rinnova il $date';
  }

  @override
  String get quotaTitle => 'Libreria';

  @override
  String quotaUsed(int used, int limit) {
    return '$used di $limit';
  }

  @override
  String quotaLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshot rimasti nel piano gratuito',
      one: '1 screenshot rimasto nel piano gratuito',
      zero: 'Spazio esaurito — Pro toglie il limite',
    );
    return '$_temp0';
  }

  @override
  String get quotaUnlimited => 'Illimitato';

  @override
  String get quotaUnlimitedNote => 'Nessun limite a ciò che conservi.';

  @override
  String get subDevUnlock => 'Accesso tester';

  @override
  String get subDevUnlockBody =>
      'Sbloccato su questo dispositivo — non è un abbonamento vero';

  @override
  String get subUnlockEverything => 'Sblocca tutto';

  @override
  String get trialUsed => 'Questa offriamo noi — la tua prova gratuita';

  @override
  String get trialFree => 'Prova gratis';

  @override
  String get proOnly => 'Pro';

  @override
  String get proWelcomeTitle => 'Sei su Pro';

  @override
  String get proWelcomeBody =>
      'Ogni funzione è sbloccata. Non c\'è altro da impostare.';

  @override
  String get proWelcomeAction => 'Inizia a usarlo';

  @override
  String get featSafeShare => 'Safe share';

  @override
  String get featSafeShareBody =>
      'Trova numeri di carta, indirizzi, nomi e recapiti e copre ciascuno con un blocco pieno. Il testo intorno resta, così l\'immagine si capisce ancora — e la copia che invii non ha nessun livello da rimuovere.';

  @override
  String get featActions => 'Trasforma gli screenshot in azioni';

  @override
  String get featActionsBody =>
      'Apri un link, scrivi a un indirizzo, copia un codice di verifica o un IBAN — direttamente dall\'immagine, senza riscrivere niente.';

  @override
  String get featTraits => 'Filtra per quello che contengono';

  @override
  String get featTraitsBody =>
      'Mostra solo gli screenshot che contengono un link, un numero di telefono, un codice, una data o un numero di carta — riconosciuto nelle parole dell\'immagine.';

  @override
  String get featDuplicates => 'Trova i doppioni';

  @override
  String get featDuplicatesBody =>
      'Individua scatti quasi identici che hai tenuto due volte e li toglie di mezzo — sempre passando prima da una revisione.';

  @override
  String get featStitch => 'Unisci screenshot lunghi';

  @override
  String get featStitchBody =>
      'Ricompone una cattura a scorrimento in un\'unica immagine alta, trovando e togliendo la sovrapposizione da sola.';

  @override
  String get featUnlimited => 'Screenshot illimitati';

  @override
  String featUnlimitedBody(Object count, Object folders) {
    return 'La versione gratuita organizza $count screenshot e tiene $folders cartelle. Pro toglie entrambi i numeri.';
  }

  @override
  String get featUnlimitedBodyPro =>
      'La tua libreria non ha limiti: conserva quanto vuoi.';

  @override
  String get featSafeShareHow =>
      'Trovare ciò che è privato in uno screenshot è gratis e senza limiti. Si paga per trasformare quei ritrovamenti in una copia pulita: ogni dato che lasci selezionato viene coperto nell\'immagine esportata, che è piatta, senza livelli da annullare.';

  @override
  String get featSafeSharePoint1 =>
      'I numeri di carta sono verificati con Luhn e gli IBAN con il modulo 97: questi due sono dimostrati invece che indovinati, proprio sul dato che conta di più.';

  @override
  String get featSafeSharePoint2 =>
      'Riconosce anche nomi, indirizzi, numeri d\'ordine, codici di verifica, numeri di telefono e indirizzi e-mail.';

  @override
  String get featSafeSharePoint3 =>
      'Vedi tutto ciò che è stato trovato prima di inviare e puoi lasciare in chiaro quello che l\'app ha sbagliato. Lo screenshot originale non viene mai toccato.';

  @override
  String get featActionsHow =>
      'Quello che è scritto dentro uno screenshot diventa qualcosa che puoi usare. Shoto isola le parti utili e mette un pulsante su ognuna.';

  @override
  String get featActionsPoint1 =>
      'Link, indirizzi e-mail, IBAN, codici di verifica, date e numeri di spedizione vengono trovati per te.';

  @override
  String get featActionsPoint2 =>
      'Un tocco per aprire o copiare — niente più caratteri da leggere da un\'immagine.';

  @override
  String get featActionsPoint3 =>
      'Funziona sugli screenshot che hai già, non solo su quelli nuovi.';

  @override
  String get featTraitsHow =>
      'Filtrare è gratis su tutto quello che Shoto ha già letto: la ricerca, le azioni e Safe share lasciano ognuna del testo riconosciuto, e ogni filtro deriva da lì. Quello che paghi è leggere il resto della libreria in una sola passata, così un filtro vede anche gli screenshot che nessun\'altra funzione ha ancora aperto.';

  @override
  String get featTraitsPoint1 =>
      'Cinque filtri: numeri di carta e IBAN, link, numeri di telefono e indirizzi e-mail, codici di verifica, e date a cui devi presentarti.';

  @override
  String get featTraitsPoint2 =>
      'I numeri di carta e gli IBAN sono provati da un checksum. Il resto viene letto dall\'immagine, quindi conta per difetto invece di affermare troppo.';

  @override
  String get featTraitsPoint3 =>
      'La libreria dice sempre quanti screenshot non sono mai stati letti, così un risultato vuoto non viene spacciato per un\'assenza. La lettura avviene sul telefono, non viene caricato nulla.';

  @override
  String get featTint => 'Scegli il tuo colore d\'accento';

  @override
  String featTintBody(int count) {
    return '$count accenti per pulsanti, interruttori e selezioni, ognuno calibrato per restare leggibile sia in chiaro sia in scuro.';
  }

  @override
  String get featTintHow =>
      'Molte app ti mettono davanti una fila di colori grezzi e lasciano il contrasto al caso: ecco perché un accento giallo arriva quasi sempre con un testo bianco illeggibile. Shoto salva la tua scelta come posizione sulla ruota dei colori invece che come colore fisso, poi ricava la tonalità esatta per la modalità chiara e per quella scura — qualunque tu scelga regge il testo con la stessa forza del colore dell\'app.';

  @override
  String featTintPoint1(int count) {
    return '$count accenti, dal petrolio e il muschio all\'ambra e alla brace, fino a prugna, indaco e ardesia.';
  }

  @override
  String get featTintPoint2 =>
      'Ognuno viene calcolato due volte, una per la modalità chiara e una per quella scura, sullo stesso obiettivo di contrasto: nessun accento brilla su uno schermo scuro né sparisce su uno chiaro.';

  @override
  String get featTintPoint3 =>
      'Il rosso dell\'eliminazione, il verde del completato e l\'ambra degli avvisi non cambiano mai: un colore che significa qualcosa non diventa mai decorazione.';

  @override
  String get featStitchHow =>
      'La cattura a scorrimento, sui telefoni che ce l\'hanno, va avviata mentre sei ancora sulla pagina. Shoto lavora dopo: scegli due o più scatti già nella tua libreria — anche quelli che ti ha mandato qualcuno — e trova dove si sovrappongono e li unisce in un\'unica immagine alta.';

  @override
  String get featStitchPoint1 =>
      'La striscia ripetuta fra due scatti viene trovata e tolta da sola.';

  @override
  String get featStitchPoint2 =>
      'Vedi la giunzione prima che si salvi qualcosa: il riconoscimento automatico è buono, ma mai certo.';

  @override
  String get featStitchPoint3 =>
      'L\'immagine unita si salva nella tua galleria come qualsiasi altra foto.';

  @override
  String get featDuplicatesHow =>
      'Condividere gli scatti uno alla volta crea di rado doppioni. Tenere un blocco da «Dall\'ultima volta» sì: vai veloce, e due catture della stessa cosa restano entrambe. Shoto confronta l\'aspetto di uno scatto, non il nome o la dimensione, così prende anche un rinvio o un ritaglio diverso.';

  @override
  String get featDuplicatesPoint1 =>
      'Raggruppa quello che sembra uguale e suggerisce la copia da tenere.';

  @override
  String get featDuplicatesPoint2 =>
      'Mostra quanto spazio libera ogni gruppo prima che tu decida qualsiasi cosa.';

  @override
  String get featDuplicatesPoint3 =>
      'Niente viene eliminato finché non hai rivisto il gruppo e confermato.';

  @override
  String get featUnlimitedHow =>
      'La versione gratuita è un\'app vera e usabile: salvataggio, cartelle, preferiti e ricerca completa, senza account e senza caricare nulla. Ha due tetti — quanti screenshot organizza e quante cartelle tiene — e Pro li toglie entrambi. Tutto quello che hai già organizzato resta esattamente dov\'è.';

  @override
  String featUnlimitedPoint1(Object count) {
    return 'La versione gratuita tiene $count cartelle, esattamente quelle che Shoto ti dà all\'inizio. Pro toglie anche questo numero.';
  }

  @override
  String get featUnlimitedPoint2 =>
      'Anche dare un nome a ciò per cui serve uno screenshot è gratis e senza limiti.';

  @override
  String get featUnlimitedPoint3 =>
      'Arrivare al tetto vuol dire che Shoto è diventato il posto dove tieni le cose. Quando succede, non viene eliminato niente.';

  @override
  String get includedSubtitle => 'Ogni funzione Pro, spiegata.';

  @override
  String get includedHint => 'Tocca una funzione per vedere come funziona';

  @override
  String get includedHowLabel => 'Come funziona';

  @override
  String get includedActiveTitle => 'Il tuo piano è attivo';

  @override
  String get includedActiveBody =>
      'Tutto quello che segue è sbloccato su questo account.';

  @override
  String get includedLockedTitle => 'Non ancora sbloccato';

  @override
  String get includedLockedBody =>
      'Leggi cosa fa davvero ciascuna, poi decidi.';

  @override
  String get includedFreeTitle => 'Cosa ti dà la versione gratuita';

  @override
  String includedFreeBody(int count) {
    return '$count screenshot organizzati, cartelle illimitate e ricerca completa — gratis per sempre.';
  }

  @override
  String get onboardingCta => 'Inizia';

  @override
  String get onboardingPromise => 'I tuoi screenshot restano sul tuo telefono.';

  @override
  String get actionsTitle => 'Azioni';

  @override
  String get actionsWorking => 'Sto leggendo lo screenshot';

  @override
  String get actionsWorkingBody => 'Cerco numeri, link e codici.';

  @override
  String get actionsNoneTitle => 'Niente su cui agire';

  @override
  String get actionsNoneBody =>
      'In questo screenshot non sono stati trovati link, codici o numeri di conto.';

  @override
  String get actionsCopy => 'Copia';

  @override
  String get actionsCopied => 'Copiato';

  @override
  String get actionsNoApp => 'Nessuna app su questo dispositivo può farlo.';

  @override
  String get devModeOn =>
      'Modalità sviluppatore attiva — ogni funzione sbloccata';

  @override
  String get devModeBadge => 'MODALITÀ SVILUPPATORE';

  @override
  String get devModeOffTitle => 'Disattivare la modalità sviluppatore?';

  @override
  String get devModeOffBody =>
      'Shoto tornerà alla versione gratuita su questo dispositivo, così puoi riprovare il paywall e i limiti.';

  @override
  String get devModeOffConfirm => 'Disattiva';

  @override
  String get devAccessTitle => 'Accesso sviluppatore';

  @override
  String get devAccessBody =>
      'Inserisci il codice a 4 cifre per sbloccare ogni funzione Pro su questo dispositivo.';

  @override
  String get devWrongCode => 'Codice errato';

  @override
  String devTapToDisable(int count) {
    return 'Tocca $count× per disattivare';
  }

  @override
  String appVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get kindCard => 'un numero di carta';

  @override
  String get kindIban => 'un conto bancario';

  @override
  String get kindCode => 'un codice di verifica';

  @override
  String get kindNationalId => 'un numero di documento';

  @override
  String get kindEmail => 'un indirizzo e-mail';

  @override
  String get kindLink => 'un link';

  @override
  String get actionEmailAction => 'Scrivi';

  @override
  String get actionOpen => 'Apri';

  @override
  String get kindEvent => 'un evento';

  @override
  String get kindPlace => 'un luogo';

  @override
  String get kindWifi => 'una rete Wi-Fi';

  @override
  String get kindTracking => 'una spedizione';

  @override
  String get actionAddToCalendar => 'Aggiungi al calendario';

  @override
  String get actionOpenMaps => 'Apri in Maps';

  @override
  String get actionDirections => 'Indicazioni';

  @override
  String get actionCopyNetwork => 'Copia il nome';

  @override
  String get actionTrack => 'Traccia';

  @override
  String get actionEventUntitled => 'Evento';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshot',
      one: '1 screenshot',
      zero: 'Nessuno screenshot',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$position di $total';
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
      other: '$count gruppi di doppioni',
      one: '1 gruppo di doppioni',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count copie simili';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi trovati',
      one: '1 elemento trovato',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'Spazio';

  @override
  String get settingsDuplicatesHint =>
      'Individua gli screenshot che hai fatto due volte';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'Cosa è incluso';

  @override
  String settingsFeatureCount(int count) {
    return '$count funzioni, un solo piano';
  }

  @override
  String get settingsShareHint => 'Dillo a qualcuno che ne ha bisogno';

  @override
  String get settingsShareText =>
      'Shoto tiene i miei screenshot in ordine da solo — resta tutto sul telefono.';

  @override
  String get settingsCacheMeasuring => 'Sto misurando…';

  @override
  String settingsCacheSize(String size) {
    return '$size di miniature';
  }

  @override
  String get homeSafeShareHint => 'Apri uno screenshot, poi tocca Safe share.';

  @override
  String get homeStitchHint =>
      'Tieni premuti due o più screenshot nella libreria, poi tocca Unisci.';

  @override
  String stitchLimit(int count) {
    return 'Puoi unire fino a $count screenshot alla volta.';
  }

  @override
  String get shareChoiceTitle => 'Cosa deve farne Shoto?';

  @override
  String get shareChoiceProtect => 'Coprire i dati privati';

  @override
  String get shareChoiceProtectHint =>
      'Nascondi ciò che è privato e invialo. Non viene salvato qui.';

  @override
  String get quickSaveCoverAction => 'Copri';

  @override
  String get quickSaveCoverWhy => 'Contiene dati privati?';

  @override
  String get shareChoiceSave => 'Salva in Shoto';

  @override
  String get shareChoiceSaveHint => 'Aggiungilo alla libreria e archivialo.';

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Screenshot salvati. Vuoi metterli in una cartella?',
      one: 'Screenshot salvato. Vuoi metterlo in una cartella?',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count screenshot uniti';
  }

  @override
  String stitchResultTrimmed(int count) {
    return 'Tolti $count px di contenuto ripetuto';
  }

  @override
  String get errorLoadScreenshots =>
      'Non è stato possibile caricare i tuoi screenshot.';

  @override
  String get errorLoadFolders =>
      'Non è stato possibile caricare le tue cartelle.';

  @override
  String get errorSaveFolder => 'Non è stato possibile salvare la cartella.';

  @override
  String get errorDeleteFolder =>
      'Non è stato possibile eliminare la cartella.';

  @override
  String get errorScanDuplicates => 'Non è stato possibile cercare i doppioni.';

  @override
  String get errorDeleteSelected =>
      'Non è stato possibile eliminare gli screenshot selezionati.';

  @override
  String get errorStitchFailed =>
      'Questi screenshot non è stato possibile unirli.';

  @override
  String get errorStitchSave =>
      'L\'immagine unita non è stato possibile salvarla.';

  @override
  String get errorOnboarding => 'Caricamento non riuscito. Riapri l\'app.';

  @override
  String get errorSignInCancelled => 'L\'accesso è stato annullato.';

  @override
  String get errorSignInInterrupted =>
      'L\'accesso è stato interrotto. Riprova.';

  @override
  String get errorNetwork => 'Errore di rete. Controlla la connessione.';

  @override
  String get errorGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get errorPlans =>
      'Non è stato possibile caricare i piani di abbonamento.';

  @override
  String get errorPurchase => 'Acquisto non riuscito. Riprova.';

  @override
  String get errorNoSubscription =>
      'Nessun abbonamento attivo trovato per questo account.';

  @override
  String get errorRestore => 'Non è stato possibile ripristinare gli acquisti.';

  @override
  String get errorStitchTooFew => 'Scegli almeno due screenshot da unire.';

  @override
  String errorStitchTooMany(int count) {
    return 'Si possono unire fino a $count screenshot alla volta.';
  }

  @override
  String get errorStitchUnreadable =>
      'Uno degli screenshot non è stato possibile leggerlo.';

  @override
  String get errorStitchWidths =>
      'Questi screenshot hanno larghezze diverse, quindi non possono far parte dello stesso scorrimento.';

  @override
  String get errorStitchNoOverlap =>
      'Questi screenshot non si sovrappongono. L\'unione funziona solo su scatti della stessa pagina presi mentre si scorre.';

  @override
  String get errorStitchOverlap =>
      'La sovrapposizione fra questi screenshot non è stato possibile risolverla.';

  @override
  String get errorStitchTooTall =>
      'L\'immagine unita sarebbe troppo alta. Prova a unire meno screenshot.';

  @override
  String get errorStitchEncode =>
      'L\'immagine unita non è stato possibile codificarla.';

  @override
  String get errorRedactionSave =>
      'La copia protetta non è stato possibile salvarla.';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshot salvati',
      one: 'Screenshot salvato',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'Grande';

  @override
  String get densityMedium => 'Media';

  @override
  String get densitySmall => 'Piccola';

  @override
  String get sensitiveCard => 'Numero di carta';

  @override
  String get sensitiveIban => 'Conto bancario';

  @override
  String get sensitiveCode => 'Codice di verifica';

  @override
  String get sensitiveNationalId => 'Numero di documento';

  @override
  String get sensitiveEmail => 'Indirizzo e-mail';

  @override
  String get sensitivePhone => 'Numero di telefono';

  @override
  String get sensitiveAddress => 'Indirizzo';

  @override
  String get sensitiveName => 'Nome';

  @override
  String get sensitiveOrderNumber => 'Numero d\'ordine';

  @override
  String get sensitiveNumber => 'Numero';

  @override
  String get onbSkip => 'Salta';

  @override
  String get onbNext => 'Avanti';

  @override
  String get onbWelcomeBody =>
      'Una casa per gli screenshot che vale la pena tenere. Archiviati, cercabili e sicuri da inviare.';

  @override
  String get onbSaveTitle => 'Salvalo nell\'istante in cui lo fai';

  @override
  String get onbSaveBody =>
      'Tocca Condividi in qualsiasi app e scegli Shoto. È l\'unico modo in cui entra qualcosa.';

  @override
  String get onbChipAnyApp => 'Qualsiasi app';

  @override
  String get onbChipOneTap => 'Un tocco';

  @override
  String get onbChipToFolder => 'Dritto in una cartella';

  @override
  String get onbFileTitle => 'Una libreria, non un rullino';

  @override
  String get onbFileBody =>
      'Tutto quello che invii arriva archiviato e resta esattamente dove l\'hai messo.';

  @override
  String get onbChipFolders => 'Cartelle';

  @override
  String get onbChipFavourites => 'Preferiti';

  @override
  String get onbChipDuplicates => 'Trova duplicati';

  @override
  String get onbFindTitle => 'Trova le parole dentro un\'immagine';

  @override
  String get onbFindBody =>
      'Shoto legge i tuoi screenshot: basta una parola che ricordi.';

  @override
  String get onbChipInsideText => 'Testo nelle immagini';

  @override
  String get onbChipOffline => 'Funziona offline';

  @override
  String get onbChipCards => 'Numeri di carta';

  @override
  String get onbChipCodes => 'Codici e documenti';

  @override
  String get onbChipPreview => 'Vedi ogni copertura';

  @override
  String get onbChipGallery => 'La galleria non si apre mai';

  @override
  String get onbChipOnDevice => 'Resta sul tuo telefono';

  @override
  String get onbSendTitle => 'Mandali lo stesso';

  @override
  String get onbSendBody =>
      'Shoto copre prima le parti private, e ti mostra ogni copertura prima che parta.';

  @override
  String get onbYoursTitle => 'Niente si muove senza di te';

  @override
  String get onbYoursBody =>
      'La tua galleria non viene mai aperta. Resta solo ciò che consegni tu.';

  @override
  String get onbFolderExample => 'Scontrini';

  @override
  String get onbSearchExample => 'scontrino';

  @override
  String get importTitle => 'Aggiungi screenshot';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshot importati',
      one: '1 screenshot importato',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return '$imported di $picked importati';
  }

  @override
  String get importFailed => 'Non è stato possibile salvare quegli screenshot';

  @override
  String get homeToolImportSubtitle =>
      'Scegli dal telefono — la galleria non viene mai letta';

  @override
  String get importPickerUnavailable => 'Il selettore di foto non si è aperto';

  @override
  String get searchWorking => 'Sto leggendo i tuoi screenshot…';

  @override
  String get settingsBackup => 'Backup e ripristino';

  @override
  String get settingsBackupHint =>
      'Tieni una copia della tua libreria in un file';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupIntro =>
      'La tua libreria vive su questo telefono e da nessun\'altra parte. Un backup è la copia che sopravvive alla sua perdita.';

  @override
  String get backupCreateTitle => 'Crea un backup';

  @override
  String get backupCreateBody =>
      'Mette ogni screenshot, cartella ed etichetta in un unico file, poi ti fa scegliere dove tenerlo.';

  @override
  String get backupCreateAction => 'Crea backup';

  @override
  String get backupWorking => 'Sto impacchettando la tua libreria…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Salvati $screenshots screenshot',
      one: 'Salvato 1 screenshot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders cartelle',
      one: '1 cartella',
    );
    return '$_temp0 e $_temp1';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Salvati $screenshots screenshot',
      one: 'Salvato 1 screenshot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped non è stato possibile leggerli',
      one: '1 non è stato possibile leggerlo',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get backupFailed => 'Il backup non è stato completato';

  @override
  String get backupPrivacyNote =>
      'Il file viene creato su questo telefono e va solo dove lo mandi tu. Non viene caricato niente.';

  @override
  String get restoreTitle => 'Ripristina un backup';

  @override
  String get restoreBody =>
      'Aggiunge tutto quello che c\'è in un file di backup a questa libreria. Niente di ciò che è già qui viene rimosso.';

  @override
  String get restoreAction => 'Ripristina';

  @override
  String get restoreWorking => 'Sto rimettendo a posto la tua libreria…';

  @override
  String get restoreConfirmTitle => 'Ripristinare questo backup?';

  @override
  String get restoreConfirmMessage =>
      'Tutto quello che c\'è nel file viene aggiunto alla tua libreria. I tuoi screenshot attuali restano esattamente come sono.';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Ripristinati $screenshots screenshot',
      one: 'Ripristinato 1 screenshot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders cartelle',
      one: '1 cartella',
    );
    return '$_temp0 e $_temp1';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Ripristinati $screenshots screenshot',
      one: 'Ripristinato 1 screenshot',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped sono stati saltati',
      one: '1 è stato saltato',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get restoreNotABackup => 'Quel file non è un backup di Shoto';

  @override
  String get restoreFailed => 'Il ripristino non è stato completato';

  @override
  String get settingsHelp => 'Aiuto';

  @override
  String get settingsContactSupport => 'Contatta l\'assistenza';

  @override
  String get supportSubject => 'Assistenza Shoto';

  @override
  String get supportNoMailApp =>
      'Nessuna app e-mail trovata. L\'indirizzo è stato copiato.';

  @override
  String get supportGreeting => 'Ciao team Shoto,';

  @override
  String get dateToday => 'Oggi';

  @override
  String get dateYesterday => 'Ieri';

  @override
  String get dateThisWeek => 'All\'inizio di questa settimana';

  @override
  String get dateThisMonth => 'All\'inizio di questo mese';

  @override
  String get librarySortNewest => 'Prima i più recenti';

  @override
  String get librarySortOldest => 'Prima i più vecchi';

  @override
  String get librarySortLabel => 'Ordine';

  @override
  String get libraryShowOnly => 'Mostra solo';

  @override
  String get libraryShowEverything => 'Tutto';

  @override
  String libraryScanPrompt(int count) {
    return 'Leggi $count screenshot';
  }

  @override
  String get libraryScanning => 'Sto leggendo…';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartelle esistono già qui',
      one: '1 cartella esiste già qui',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'Questi nomi ci sono nella tua libreria e nel backup. Stesso nome non vuol dire sempre stessa cartella, quindi qui decidi tu.';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e altre $count',
      one: 'e 1 altra',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'Mettile insieme';

  @override
  String get restoreClashMergeBody =>
      'Gli screenshot vanno nelle cartelle che hai già.';

  @override
  String get restoreClashSeparate => 'Tienile separate';

  @override
  String get restoreClashSeparateBody =>
      'Crea una seconda cartella con lo stesso nome. Niente di esistente viene toccato.';

  @override
  String get intentBuy => 'Comprare';

  @override
  String get intentRead => 'Leggere';

  @override
  String get intentReply => 'Rispondere';

  @override
  String get intentTry => 'Provare';

  @override
  String get intentVisit => 'Visitare';

  @override
  String get intentBuyWaiting => 'Da comprare';

  @override
  String get intentReadWaiting => 'Da leggere';

  @override
  String get intentReplyWaiting => 'Da rispondere';

  @override
  String get intentTryWaiting => 'Da provare';

  @override
  String get intentVisitWaiting => 'Da visitare';

  @override
  String get intentWatch => 'Guardare';

  @override
  String get intentListen => 'Ascoltare';

  @override
  String get intentCook => 'Cucinare';

  @override
  String get intentBook => 'Prenotare';

  @override
  String get intentPay => 'Pagare';

  @override
  String get intentSend => 'Inviare';

  @override
  String get intentDownload => 'Scaricare';

  @override
  String get intentApply => 'Candidarsi';

  @override
  String get intentCompare => 'Confrontare';

  @override
  String get intentFix => 'Riparare';

  @override
  String get intentWatchWaiting => 'Da guardare';

  @override
  String get intentListenWaiting => 'Da ascoltare';

  @override
  String get intentCookWaiting => 'Da cucinare';

  @override
  String get intentBookWaiting => 'Da prenotare';

  @override
  String get intentPayWaiting => 'Da pagare';

  @override
  String get intentSendWaiting => 'Da inviare';

  @override
  String get intentDownloadWaiting => 'Da scaricare';

  @override
  String get intentApplyWaiting => 'Per candidarsi';

  @override
  String get intentCompareWaiting => 'Da confrontare';

  @override
  String get intentFixWaiting => 'Da riparare';

  @override
  String get intentMore => 'Altro';

  @override
  String get intentSectionCommon => 'Già pronti';

  @override
  String get intentSectionYours => 'I tuoi';

  @override
  String get intentYoursEmpty =>
      'Un verbo che scrivi tu funziona esattamente come quelli sopra.';

  @override
  String get intentNewAction => 'Scrivine uno tuo';

  @override
  String get intentNewTitle => 'Dagli un nome tu';

  @override
  String get intentEditTitle => 'Modifica questo';

  @override
  String get intentNameLabel => 'Il verbo';

  @override
  String get intentNameHint => 'Renderlo, disdirlo, chiamarli…';

  @override
  String get intentIconLabel => 'Icona';

  @override
  String intentDeleteTitle(String label) {
    return 'Eliminare «$label»?';
  }

  @override
  String get intentDeleteMessage =>
      'Gli screenshot restano dove sono. Solo, smettono di aspettare qualcosa.';

  @override
  String get intentSelectionAction => 'Segna come';

  @override
  String intentSelectionApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screenshot segnati',
      one: '1 screenshot segnato',
    );
    return '$_temp0';
  }

  @override
  String get intentPrompt => 'A cosa serve, se ti va';

  @override
  String get intentSkip => 'Niente in particolare';

  @override
  String get intentWaitingTitle => 'In attesa di te';

  @override
  String get intentNothingWaiting => 'Niente ti sta aspettando';

  @override
  String get intentAllDone =>
      'Hai finito tutto quello che avevi messo da parte.';

  @override
  String get intentMarkDone => 'Fatto';

  @override
  String get intentUndo => 'Rimettilo';

  @override
  String get intentDoneToast => 'Spuntato';

  @override
  String intentListEnd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sono tutte e $count',
      one: 'È l\'unica',
    );
    return '$_temp0';
  }

  @override
  String get intentChange => 'Cambia';

  @override
  String get intentClear => 'Non serve a niente di preciso';

  @override
  String intentEmptyOne(String verb) {
    return 'Qui non c\'è niente da $verb';
  }

  @override
  String get intentEmptyBody =>
      'Gli screenshot che segni restano qui finché non li spunti.';

  @override
  String intentProgress(int done, int total) {
    return '$done di $total fatte';
  }

  @override
  String intentDoneCount(int count) {
    return '$count finiti';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settimane fa',
      one: '1 settimana fa',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesi fa',
      one: '1 mese fa',
    );
    return '$_temp0';
  }

  @override
  String get copyTextSelect => 'Seleziona testo';

  @override
  String get copyTextSelectAll => 'Seleziona tutto';

  @override
  String get copyTextHint => 'Tieni premuto un testo per copiarlo';

  @override
  String get copyTextPrompt => 'Trascina per selezionare';

  @override
  String get copyTextNone =>
      'Shoto non trova testo leggibile in questo screenshot';
}
