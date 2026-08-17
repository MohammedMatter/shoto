// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsCrashReports => 'Informes de errores';

  @override
  String get settingsCrashReportsHint =>
      'Enviar detalles técnicos cuando algo falla';

  @override
  String get settingsOnboarding => 'Ver la introducción otra vez';

  @override
  String get settingsOnboardingHint =>
      'Reproduce la secuencia de apertura de nuevo';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsSignOutTitle => '¿Cerrar sesión?';

  @override
  String get authWelcome => 'Bienvenido a Shoto';

  @override
  String get authWhy =>
      'No todo lo que guardas merece el mismo estante. Shoto les da a las capturas que de verdad te importan un lugar propio.';

  @override
  String get authGoogle => 'Continuar con Google';

  @override
  String get authApple => 'Continuar con Apple';

  @override
  String get authLegal =>
      'Al continuar, aceptas nuestros Términos y la Política de privacidad.';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsSignOutHint =>
      'Tus capturas se quedan en este dispositivo';

  @override
  String get settingsSignIn => 'Iniciar sesión';

  @override
  String get settingsSignInHint =>
      'Opcional. Solo hace falta para pasar una compra a otro teléfono.';

  @override
  String paywallTrialCta(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Empezar $days días gratis',
      one: 'Empezar 1 día gratis',
    );
    return '$_temp0';
  }

  @override
  String paywallTrialNote(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Gratis $days días y luego $price. Cancela cuando quieras antes de que acabe.',
      one:
          'Gratis un día y luego $price. Cancela cuando quieras antes de que acabe.',
    );
    return '$_temp0';
  }

  @override
  String get triageTitle => 'Desde la última vez';

  @override
  String get triageBody =>
      'Guarda lo que pertenece a Shoto. Todo lo demás se queda donde está.';

  @override
  String get triageKeep => 'Guardar';

  @override
  String get triageSkip => 'Omitir';

  @override
  String get triageFinish => 'Listo';

  @override
  String triageProgress(int index, int total) {
    return '$index de $total';
  }

  @override
  String triageNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas nuevas',
      one: '1 captura nueva',
    );
    return '$_temp0';
  }

  @override
  String triageKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guardadas',
      one: '1 guardada',
      zero: 'No se guardó nada',
    );
    return '$_temp0';
  }

  @override
  String get triageReview => 'Revisar';

  @override
  String get triageInviteDecline => 'Ahora no';

  @override
  String get triageInviteTitle => '¿Mostrar aquí las capturas nuevas?';

  @override
  String get triageInviteBody =>
      'Shoto puede listar lo que captures a partir de ahora, para que guardes las pocas que importan. Nada entra en tu biblioteca hasta que tú lo digas.';

  @override
  String get triageInviteAccept => 'Mostrarlas';

  @override
  String get triageInviteDismiss => 'No, gracias';

  @override
  String get settingsTriage => 'Ofrecer capturas nuevas';

  @override
  String get settingsTriageHint =>
      'Muestra lo que capturas; no guarda nada por su cuenta';

  @override
  String get settingsCaptureAlerts => 'Avisarme al instante';

  @override
  String get settingsCaptureAlertsHint =>
      'Una notificación discreta justo después de hacerla';

  @override
  String get settingsCaptureAlertsMuted =>
      'Las notificaciones de Shoto están desactivadas — actívalas en los ajustes del teléfono';

  @override
  String get settingsCaptureAlertsStopped =>
      'Android detuvo las comprobaciones. Abre Shoto una vez para reanudarlas';

  @override
  String get settingsCaptureAlertsWaiting => 'Vigilando. Aún no hay capturas';

  @override
  String settingsCaptureAlertsLastRun(String when) {
    return 'Última comprobación $when';
  }

  @override
  String timeAgoMinutes(int count) {
    return 'hace $count min';
  }

  @override
  String timeAgoHours(int count) {
    return 'hace $count h';
  }

  @override
  String timeAgoDays(int count) {
    return 'hace $count d';
  }

  @override
  String get settingsQuickTile => 'Acceso rápido';

  @override
  String get settingsQuickTileHint =>
      'Guarda tu última captura sin abrir el menú de compartir';

  @override
  String get settingsQuickTileAdded => 'Añadido a los ajustes rápidos';

  @override
  String get settingsQuickTileManual =>
      'Añádelo a mano: despliega los ajustes rápidos, toca editar y arrastra el acceso de Shoto.';

  @override
  String get settingsQuickTileSheetTitle => 'Dos gestos, desde cualquier app';

  @override
  String get settingsQuickTileSheetBody =>
      'Shoto puede estar en los Ajustes rápidos de tu móvil, junto a la linterna. Un toque archiva la captura que acabas de hacer: sin abrir la app y sin recorrer el menú de compartir.';

  @override
  String get settingsQuickTileStepPull =>
      'Desliza desde arriba en cualquier pantalla';

  @override
  String get settingsQuickTileStepTap =>
      'Toca el mosaico de Shoto y tu última captura queda archivada';

  @override
  String get settingsQuickTileStepStays =>
      'Se queda en el mismo sitio, al contrario que el menú de compartir';

  @override
  String get settingsQuickTileAdd => 'Añadir el mosaico';

  @override
  String get settingsQuickTileNote =>
      'Solo lee la captura que acabas de hacer. Nada sale de tu móvil.';

  @override
  String get folderIconsBasics => 'Básicos';

  @override
  String get folderIconsWork => 'Trabajo';

  @override
  String get folderIconsMoney => 'Dinero';

  @override
  String get folderIconsTravel => 'Viajes';

  @override
  String get folderIconsHome => 'Hogar y salud';

  @override
  String get folderIconsMedia => 'Medios';

  @override
  String get folderIconsPeople => 'Personas';

  @override
  String get folderIconsSymbols => 'Símbolos';

  @override
  String get folderIconsSocial => 'Redes sociales';

  @override
  String get folderIconsApps => 'Apps';

  @override
  String get quickTileOfferTitle => 'Guarda sin el menú de compartir';

  @override
  String get quickTileOfferBody =>
      'Añade un acceso rápido para tu última captura';

  @override
  String get triageNothingNew => 'No hay nada nuevo que revisar';

  @override
  String get reminderTitle => 'Recordármelo';

  @override
  String get reminderLaterToday => 'Más tarde hoy';

  @override
  String get reminderThisEvening => 'Esta tarde';

  @override
  String get reminderTomorrow => 'Mañana por la mañana';

  @override
  String get reminderNextWeek => 'La próxima semana';

  @override
  String get reminderPickTime => 'Elegir una hora';

  @override
  String get reminderClear => 'Quitar recordatorio';

  @override
  String get reminderNotificationTitle => 'Shoto';

  @override
  String get reminderMuted =>
      'Las notificaciones están desactivadas, así que esto no te llegará: actívalas en los ajustes del teléfono.';

  @override
  String get reminderUnsupported =>
      'Por ahora los recordatorios solo están disponibles en Android.';

  @override
  String reminderSet(String when) {
    return 'Recordatorio para $when';
  }

  @override
  String reminderPending(String when) {
    return 'Recordatorio para $when';
  }

  @override
  String get reminderNotificationBody => 'Querías volver a esta captura';

  @override
  String get remindersTitle => 'Recordatorios';

  @override
  String get remindersMissed => 'Perdidos';

  @override
  String get remindersUpcoming => 'Próximos';

  @override
  String get remindersNoneTitle => 'Sin recordatorios';

  @override
  String get remindersNoneBody =>
      'Abre las acciones de una captura y elige «Recordármelo» para volver a ella más tarde.';

  @override
  String get remindersClearOne => 'Quitar';

  @override
  String remindersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordatorios',
      one: '1 recordatorio',
    );
    return '$_temp0';
  }

  @override
  String remindersMissedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perdidos',
      one: '1 perdido',
    );
    return '$_temp0';
  }

  @override
  String remindersNextAt(String when) {
    return 'Siguiente $when';
  }

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonSomethingWentWrong => 'Algo salió mal';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'Inicio';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navFolders => 'Carpetas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get tagline => 'Tus capturas, ordenadas';

  @override
  String get homeGreetingMorning => 'Buenos días';

  @override
  String get homeGreetingAfternoon => 'Buenas tardes';

  @override
  String get homeGreetingEvening => 'Buenas noches';

  @override
  String get homeInboxEmpty => 'Todavía no hay nada guardado';

  @override
  String get homeInboxEmptySubtitle =>
      'Elige algunas de tu teléfono ahora, o comparte una captura en Shoto desde cualquier app.';

  @override
  String get homeEmptyImportCta => 'Elegir desde mi teléfono';

  @override
  String get homeNeedsYou => 'Te espera';

  @override
  String get homeInboxClear => 'Todo archivado';

  @override
  String get homeInboxClearSubtitle => 'No queda nada por ordenar';

  @override
  String get homeInboxCountSubtitle => 'Capturas que aún no has archivado';

  @override
  String get homeStatScreenshots => 'Capturas';

  @override
  String get homeStatFavorites => 'Favoritas';

  @override
  String get homeStatFolders => 'Carpetas';

  @override
  String get homeToolsTitle => 'Herramientas';

  @override
  String get homeToolsTitleEmpty => 'Empieza aquí';

  @override
  String get homeToolSafeShare => 'Compartir seguro';

  @override
  String get homeToolSafeShareSubtitle => 'Oculta antes los datos privados';

  @override
  String get homeToolDuplicates => 'Buscar duplicados';

  @override
  String get homeToolDuplicatesSubtitle => 'Libera espacio';

  @override
  String get homeToolSearch => 'Buscar dentro';

  @override
  String get homeToolSearchSubtitle => 'Encuentra texto en tus imágenes';

  @override
  String get homeToolStitch => 'Unir capturas largas';

  @override
  String get homeToolStitchSubtitle => 'Junta una captura con scroll';

  @override
  String get homeRecent => 'Recientes';

  @override
  String get libraryPickForMerge =>
      'Elige dos o más capturas de la misma página';

  @override
  String get libraryPickForProtect => 'Elige la captura que quieres proteger';

  @override
  String get libraryActionProtect => 'Proteger';

  @override
  String get homeSeeAll => 'Ver todo';

  @override
  String get libraryEmptyTitle => 'Aún no hay nada guardado';

  @override
  String get libraryEmptyMessage =>
      'Comparte una captura con Shoto o añádela con el botón +. Tu galería nunca se lee: solo se guarda lo que entregas.';

  @override
  String get libraryNoFavoritesTitle => 'Aún no hay favoritas';

  @override
  String get libraryNoFavoritesMessage =>
      'Pulsa el corazón de una captura para guardarla aquí.';

  @override
  String get libraryFilterAll => 'Todas';

  @override
  String get libraryFilterFavorites => 'Favoritas';

  @override
  String get libraryTraitSensitive => 'Sensible';

  @override
  String get libraryTraitLink => 'Enlaces';

  @override
  String get libraryTraitContact => 'Teléfono o correo';

  @override
  String get libraryTraitCode => 'Códigos';

  @override
  String get libraryTraitEvent => 'Fechas';

  @override
  String get libraryCertaintyVerified => 'Verificado por suma de control';

  @override
  String get libraryCertaintyRead => 'Leído del texto de tus capturas';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count sin leer aún';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return 'Ninguna captura con $trait';
  }

  @override
  String get libraryNoTraitMessage =>
      'Ninguna de las capturas leídas contiene esto.';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'No se encontró nada en lo leído. $count capturas nunca se han leído, así que aún no pueden coincidir.';
  }

  @override
  String get libraryShowAll => 'Mostrar todo';

  @override
  String get libraryFilterUnsorted => 'Sin ordenar';

  @override
  String get libraryNoUnsortedTitle => 'Todo está ordenado';

  @override
  String get libraryNoUnsortedMessage =>
      'No hay nada pendiente. Las capturas nuevas aparecen aquí hasta que las archives o las marques.';

  @override
  String librarySelectedCount(int count) {
    return '$count seleccionadas';
  }

  @override
  String get librarySelectAll => 'Seleccionar todo';

  @override
  String get librarySelect => 'Seleccionar';

  @override
  String get librarySelectPrompt => 'Selecciona capturas';

  @override
  String get libraryActionMerge => 'Unir';

  @override
  String get libraryActionMove => 'Mover';

  @override
  String get libraryActionDelete => 'Eliminar';

  @override
  String get libraryDeleteTitle => '¿Eliminar capturas?';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se eliminarán $count capturas de tu dispositivo de forma permanente.',
      one: 'Se eliminará 1 captura de tu dispositivo de forma permanente.',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'Se necesita acceso a fotos';

  @override
  String get permissionNeededMessage =>
      'Shoto guarda las capturas que compartes con él en su propio álbum. Necesita acceso a fotos para escribir ahí y volver a leerlas; nunca consulta el resto de tu galería.';

  @override
  String get permissionAskTitle => 'Shoto necesita ver su álbum de capturas';

  @override
  String get permissionAskMessage =>
      'Solo ese álbum, y solo para listar lo que contiene. Nada se sube, y nada entra en tu biblioteca hasta que tú lo elijas.';

  @override
  String get permissionAllow => 'Permitir acceso';

  @override
  String get permissionPartialTitle => 'Se necesita acceso completo';

  @override
  String get permissionPartialMessage =>
      'Ahora mismo Shoto solo ve unas pocas fotos que elegiste a mano, así que no puede llegar a su propio álbum. Elige «Permitir todas» para continuar.';

  @override
  String get permissionOpenSettings => 'Abrir ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsGridDensity => 'Densidad de cuadrícula';

  @override
  String get settingsAppearanceHint =>
      'Tema, color de acento y tamaño de cuadrícula';

  @override
  String get appearanceTint => 'Color de acento';

  @override
  String get appearanceTintHint =>
      'Botones, interruptores y todo lo seleccionado.';

  @override
  String get appearancePreview => 'Vista previa';

  @override
  String get tintTeal => 'Verde azulado';

  @override
  String get tintSlate => 'Pizarra';

  @override
  String get tintIndigo => 'Índigo';

  @override
  String get tintPlum => 'Ciruela';

  @override
  String get tintRose => 'Rosa';

  @override
  String get tintEmber => 'Brasa';

  @override
  String get tintAmber => 'Ámbar';

  @override
  String get tintMoss => 'Musgo';

  @override
  String get tintGarnet => 'Granate';

  @override
  String get tintBrass => 'Latón';

  @override
  String get tintFern => 'Helecho';

  @override
  String get tintJade => 'Jade';

  @override
  String get tintOlive => 'Oliva';

  @override
  String get tintCyan => 'Cian';

  @override
  String get tintDenim => 'Denim';

  @override
  String get tintViolet => 'Violeta';

  @override
  String get tintSky => 'Cielo';

  @override
  String get tintOrchid => 'Orquídea';

  @override
  String get tintFuchsia => 'Fucsia';

  @override
  String get tintClay => 'Arcilla';

  @override
  String get tintGraphite => 'Grafito';

  @override
  String get appearanceMoreColors => 'Más colores';

  @override
  String get appearanceSelectTint => 'Elegir color de acento';

  @override
  String get appearanceFolders => 'Tarjetas de carpeta';

  @override
  String get appearanceFolderCount => 'Número de capturas';

  @override
  String get appearanceFolderDate => 'Fecha de creación';

  @override
  String get appearanceFolderSize => 'Tarjetas por fila';

  @override
  String get appearanceLibrary => 'Cuadrícula de la biblioteca';

  @override
  String get appIcon => 'Icono de la app';

  @override
  String get appIconDefault => 'Original';

  @override
  String get appIconHint =>
      'Al cambiarlo, Shoto se cierra un momento mientras Android sustituye el icono.';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Seguir a mi teléfono';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Ahora en $language';
  }

  @override
  String get settingsBehaviour => 'Comportamiento';

  @override
  String get settingsHaptics => 'Respuesta háptica';

  @override
  String get settingsHapticsHint => 'Un pequeño toque al pulsar';

  @override
  String get settingsConfirmDelete => 'Preguntar antes de eliminar';

  @override
  String get settingsConfirmDeleteHint => 'Eliminar no se puede deshacer';

  @override
  String get settingsFindDuplicates => 'Buscar duplicados';

  @override
  String get settingsClearCache => 'Vaciar caché de imágenes';

  @override
  String get settingsShare => 'Compartir Shoto';

  @override
  String get settingsPrivacyNote =>
      'Shoto solo guarda las capturas que le entregas, y todo lo que hace con ellas —leer texto, buscar duplicados— ocurre en este dispositivo. Tus imágenes nunca se suben. Hay tres cosas que tú activas: ofrecer capturas nuevas lee tu álbum de capturas para poder preguntarte por ellas, una cuenta envía solo tu correo para que la suscripción sobreviva a un cambio de teléfono, y los informes de errores envían qué falló: el código, nunca una imagen.';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonRename => 'Renombrar';

  @override
  String get commonShare => 'Compartir';

  @override
  String get commonUnlock => 'Desbloquear';

  @override
  String get foldersEmptyTitle => 'Aún no hay carpetas';

  @override
  String get foldersEmptyMessage =>
      'Las carpetas son como encuentras las cosas después. Crea una para recibos, otra para recetas: lo que de verdad busques.';

  @override
  String get foldersNew => 'Nueva carpeta';

  @override
  String get foldersCreate => 'Crear carpeta';

  @override
  String get foldersNameLabel => 'Nombre de la carpeta';

  @override
  String get foldersNameHint => 'Recibos, Recetas, Trabajo…';

  @override
  String get foldersPrivate => 'Privada (bloqueo facial o huella)';

  @override
  String get foldersPrivateFace => 'Privada (bloqueo facial)';

  @override
  String get foldersPrivateFingerprint => 'Privada (bloqueo por huella)';

  @override
  String get foldersPrivateGeneric => 'Privada (bloqueada)';

  @override
  String get foldersOptions => 'Opciones de carpeta';

  @override
  String get foldersDelete => 'Eliminar carpeta';

  @override
  String get foldersDeleteKept => 'Las capturas de dentro se conservan';

  @override
  String foldersDeleteTitle(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get foldersDeleteMessage =>
      'La carpeta se elimina, pero las capturas de dentro siguen en tu biblioteca.';

  @override
  String get foldersEditTitle => 'Editar carpeta';

  @override
  String get foldersSearchHint => 'Buscar carpetas';

  @override
  String get foldersSortLabel => 'Ordenar carpetas';

  @override
  String get foldersSortRecent => 'Más recientes primero';

  @override
  String get foldersSortName => 'Nombre (A–Z)';

  @override
  String get foldersSortFullest => 'Más capturas';

  @override
  String get foldersNoMatchTitle => 'Ninguna carpeta coincide';

  @override
  String foldersNoMatchMessage(String query) {
    return 'Aquí no hay nada que se llame «$query». Prueba con parte del nombre.';
  }

  @override
  String get folderDefaultTrips => 'Planes de viaje';

  @override
  String get folderDefaultRecipes => 'Recetas';

  @override
  String get folderDefaultMedications => 'Medicamentos';

  @override
  String get folderDefaultAiNotes => 'Notas de IA';

  @override
  String get folderDefaultMoney => 'Dinero';

  @override
  String get folderDefaultWorkouts => 'Entrenamientos';

  @override
  String get folderDefaultMusic => 'Música';

  @override
  String get foldersMoveTitle => 'Mover a una carpeta';

  @override
  String get foldersMoveRemove => 'Quitar de la carpeta';

  @override
  String get foldersMoveNone =>
      'Aún no hay carpetas. Crea una desde la pestaña Carpetas.';

  @override
  String folderLockedTitle(String name) {
    return 'Desbloquear «$name»';
  }

  @override
  String get folderLockedMessage =>
      'Esta carpeta está protegida. Autentícate para verla.';

  @override
  String get folderEmptyTitle => 'Aquí no hay nada';

  @override
  String get folderEmptyMessage =>
      'Mueve capturas a esta carpeta desde tu biblioteca.';

  @override
  String get detailFavorite => 'Favorito';

  @override
  String get detailUnfavorite => 'Quitar de favoritos';

  @override
  String get detailAddFavorite => 'Añadir a favoritos';

  @override
  String a11yScreenshot(String date) {
    return 'Captura del $date';
  }

  @override
  String a11yScreenshotFavorite(String date) {
    return 'Captura del $date, favorita';
  }

  @override
  String get detailActions => 'Acciones';

  @override
  String get detailSafeShare => 'Compartir seguro';

  @override
  String get detailMore => 'Más';

  @override
  String get detailDeleteTitle => '¿Eliminar la captura?';

  @override
  String get detailDeleteMessage =>
      'Se eliminará de tu dispositivo de forma permanente.';

  @override
  String get quickSaveTitleOne => 'Guardar en Shoto';

  @override
  String quickSaveTitleMany(int count) {
    return 'Guardar $count capturas';
  }

  @override
  String get quickSaveFileOne => 'Archivar esta captura';

  @override
  String quickSaveFileMany(int count) {
    return 'Archivar $count capturas';
  }

  @override
  String get quickSavePickFolder => 'Elige una carpeta';

  @override
  String get quickSaveNeedFolder => 'Crea una carpeta donde ponerlas';

  @override
  String quickSaveFileIn(String folder) {
    return 'Archivar en $folder';
  }

  @override
  String get quickSaveCreateFirstFolder => 'Crea tu primera carpeta';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'Las carpetas son como encuentras las cosas después';

  @override
  String get quickSaveNewChip => 'Nueva';

  @override
  String get quickSaveSaved => 'Guardado en Shoto';

  @override
  String quickSaveFiled(String folder) {
    return 'Archivado en $folder.';
  }

  @override
  String get quickSaveFailedTitle => 'No se pudo leer esa imagen';

  @override
  String get quickSaveFailedBody => 'Prueba a compartirla otra vez.';

  @override
  String get quickSaveNoCaptureTitle => 'Todavía no hay ninguna captura';

  @override
  String get quickSaveNoCaptureBody =>
      'Haz una captura y vuelve a tocar el acceso rápido.';

  @override
  String get quickSaveNoAccessTitle => 'Shoto no puede ver tus capturas';

  @override
  String get quickSaveNoAccessBody =>
      'Abre Shoto, permite el acceso a las fotos y vuelve a probar.';

  @override
  String quickSaveSkipped(int count) {
    return 'Solo se tomaron las primeras $count';
  }

  @override
  String get dupTitle => 'Buscar duplicados';

  @override
  String get dupScanning => 'Buscando duplicados';

  @override
  String get dupReading => 'Leyendo tu biblioteca…';

  @override
  String dupProgress(int done, int total) {
    return 'Revisadas $done de $total capturas';
  }

  @override
  String get dupNoneTitle => 'No hay duplicados';

  @override
  String get dupNoneBody => 'Tu biblioteca ya está limpia.';

  @override
  String get dupScanAgain => 'Analizar otra vez';

  @override
  String dupReclaimable(String size) {
    return 'Se pueden liberar hasta $size';
  }

  @override
  String get dupNothingSelected => 'Nada seleccionado';

  @override
  String dupDeleteButton(int count, String size) {
    return 'Eliminar $count · liberar $size';
  }

  @override
  String dupDeleteTitle(int count) {
    return '¿Eliminar $count copias?';
  }

  @override
  String get dupDeleteMessage =>
      'Se eliminarán de tu dispositivo de forma permanente. Las copias marcadas para conservar no se tocan.';

  @override
  String dupDeleted(int count, String size) {
    return 'Eliminadas $count · liberado $size';
  }

  @override
  String dupSets(int count) {
    return '$count grupos';
  }

  @override
  String get dupBest => 'MEJOR';

  @override
  String get dupKeepAll => 'Conservar todo';

  @override
  String get dupKeepingAll => 'Se conservan todas: no se eliminará nada';

  @override
  String get dupUndo => 'Deshacer';

  @override
  String dupFrees(String size) {
    return 'Libera $size';
  }

  @override
  String get safeShareTitle => 'Compartir seguro';

  @override
  String get safeShareScanning => 'Buscando datos privados';

  @override
  String get safeShareOnDevice => 'La lectura ocurre en tu teléfono.';

  @override
  String get safeShareCleanTitle => 'No se encontró nada privado';

  @override
  String get safeShareCleanBody =>
      'No se han detectado números de tarjeta, cuentas, códigos ni datos de contacto. Puedes compartirla tal cual.';

  @override
  String get safeShareUnreadableTitle => 'No se pudo leer esta captura';

  @override
  String get safeShareUnreadableBody => 'No se pudo reconocer el texto.';

  @override
  String get safeShareShareUnchanged => 'Compartir sin cambios';

  @override
  String get safeShareShareAnyway => 'Compartir igualmente';

  @override
  String get safeShareShareProtected => 'Compartir copia protegida';

  @override
  String get safeShareKeepCopy => 'Guardar la copia en Shoto';

  @override
  String get safeShareFailed => 'No se pudo crear la copia protegida.';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count datos privados encontrados',
      one: '1 dato privado encontrado',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'El análisis siempre es gratis.';

  @override
  String get safeShareCleanAction => 'Limpiar esta captura';

  @override
  String get safeShareShareAsIs => 'Compartir sin cambios';

  @override
  String get safeShareHowTitle => 'Tapado de forma definitiva';

  @override
  String get safeShareHowBody =>
      'Cada dato privado se cubre con un bloque sólido antes de que la copia salga de tu teléfono. No hay desenfoque ni forma de recuperarlo: la copia tapada es la única que existe.';

  @override
  String get safeShareTreatmentCover => 'Tapar';

  @override
  String get safeShareTreatmentKeep => 'Dejar';

  @override
  String get safeShareBuilding => 'Preparando tu copia limpia';

  @override
  String get safeShareNothingSelected => 'No cambiará nada';

  @override
  String get safeShareLockedPreview => 'Desbloquea para ver la versión limpia';

  @override
  String get safeShareReviewTitle => 'Revisa cada uno';

  @override
  String safeShareFound(int count) {
    return '$count elementos cubiertos';
  }

  @override
  String get stitchTitle => 'Unir capturas';

  @override
  String get stitchWorking => 'Buscando el solapamiento';

  @override
  String get stitchWorkingBody =>
      'Comprobando dónde continúa cada captura desde la anterior.';

  @override
  String get stitchFailed => 'No se pudo unir';

  @override
  String get stitchSave => 'Guardar en la galería';

  @override
  String get stitchSaved => 'Guardada en tu galería';

  @override
  String get stitchDiscard => 'Descartar';

  @override
  String get commonDone => 'Hecho';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get searchTitle => 'Busca en tus capturas';

  @override
  String get searchHint => 'Palabras o lo que muestra una imagen';

  @override
  String get searchIntro =>
      'Cualquier palabra impresa en la imagen, o lo que muestra: prueba «gato», «animal», «comida» o «recibo».';

  @override
  String get searchNoneTitle => 'Sin resultados';

  @override
  String searchNoneBody(String query) {
    return 'Nada de aquí se lee ni se parece a «$query».';
  }

  @override
  String get paywallTitle => 'Desbloquea Shoto Pro';

  @override
  String get paywallSubtitle => 'Todo lo de abajo, en una sola suscripción.';

  @override
  String get paywallMonthly => 'Mensual';

  @override
  String get paywallYearly => 'Anual';

  @override
  String paywallSave(int percent) {
    return 'Ahorra $percent%';
  }

  @override
  String get paywallPerYear => '/año';

  @override
  String get paywallPerMonth => '/mes';

  @override
  String get paywallPreviewPricing =>
      'Las suscripciones aún no están activas — precios solo de muestra.';

  @override
  String get paywallNotSetUp =>
      'Las suscripciones aún no están configuradas — vuelve pronto.';

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallUnavailable => 'Aún no disponible';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get settingsRestoreHint => '¿Ya pagaste? Recupera tu suscripción.';

  @override
  String get settingsRestoreDone => 'Tu suscripción ha vuelto.';

  @override
  String get paywallLegal =>
      'Se renueva automáticamente hasta que la canceles. Cancela cuando quieras desde tu cuenta de App Store o Google Play. Al continuar aceptas nuestros Términos y la Política de privacidad.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'Shoto Pro';

  @override
  String get subPremiumBody => 'Todas las funciones desbloqueadas.';

  @override
  String subPremiumRenews(String date) {
    return 'Se renueva el $date';
  }

  @override
  String get quotaTitle => 'Biblioteca';

  @override
  String quotaUsed(int used, int limit) {
    return '$used de $limit';
  }

  @override
  String quotaLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count capturas en el plan gratuito',
      one: 'Queda 1 captura en el plan gratuito',
      zero: 'Sin espacio — Pro quita el límite',
    );
    return '$_temp0';
  }

  @override
  String get quotaUnlimited => 'Ilimitado';

  @override
  String get quotaUnlimitedNote => 'Sin límite en lo que guardas.';

  @override
  String get subDevUnlock => 'Acceso de prueba';

  @override
  String get subDevUnlockBody =>
      'Desbloqueado solo en este dispositivo — no es una suscripción real';

  @override
  String get subUnlockEverything => 'Desbloquea todo';

  @override
  String get trialUsed => 'Esta corre por nuestra cuenta: tu prueba gratis';

  @override
  String get trialFree => 'Prueba gratis';

  @override
  String get proOnly => 'Pro';

  @override
  String get proWelcomeTitle => 'Ya tienes Pro';

  @override
  String get proWelcomeBody =>
      'Todas las funciones están desbloqueadas. No hay nada más que configurar.';

  @override
  String get proWelcomeAction => 'Empezar';

  @override
  String get featSafeShare => 'Compartir seguro';

  @override
  String get featSafeShareBody =>
      'Encuentra números de tarjeta, direcciones, nombres y datos de contacto, y tapa cada uno con un bloque sólido. El texto de alrededor se mantiene y la captura se sigue entendiendo; la copia que envías no tiene ninguna capa que quitar.';

  @override
  String get featActions => 'Convierte capturas en acciones';

  @override
  String get featActionsBody =>
      'Abre un enlace, escribe a una dirección, copia un código de verificación o un IBAN: directamente desde la imagen, sin volver a teclear nada.';

  @override
  String get featTraits => 'Filtrar por lo que contienen';

  @override
  String get featTraitsBody =>
      'Muestra solo las capturas que llevan dentro un enlace, un teléfono, un código, una fecha o un número de tarjeta — reconocido en las palabras de la imagen.';

  @override
  String get featDuplicates => 'Buscar duplicados';

  @override
  String get featDuplicatesBody =>
      'Detecta capturas casi idénticas que guardaste dos veces y elimínalas, siempre con una revisión previa.';

  @override
  String get featStitch => 'Unir capturas largas';

  @override
  String get featStitchBody =>
      'Une una captura con scroll en una sola imagen alta, detectando y quitando el solapamiento automáticamente.';

  @override
  String get featUnlimited => 'Capturas ilimitadas';

  @override
  String featUnlimitedBody(Object count, Object folders) {
    return 'La versión gratuita organiza $count capturas y guarda $folders carpetas. Pro elimina ambos números.';
  }

  @override
  String get featUnlimitedBodyPro =>
      'Tu biblioteca no tiene límite: guarda todo lo que quieras.';

  @override
  String get featSafeShareHow =>
      'Detectar lo privado de una captura es gratis y sin límite. Lo que se paga es convertir esos hallazgos en una copia limpia: cada dato que dejes marcado se tapa en la imagen exportada, y esa imagen es plana, sin ninguna capa que deshacer.';

  @override
  String get featSafeSharePoint1 =>
      'Las tarjetas se verifican con Luhn y los IBAN con mod-97: esos dos se demuestran en vez de adivinarse, justo en el dato que más importa.';

  @override
  String get featSafeSharePoint2 =>
      'También detecta nombres, direcciones, números de pedido, códigos de verificación, teléfonos y correos.';

  @override
  String get featSafeSharePoint3 =>
      'Ves todo lo encontrado antes de enviar y puedes dejar a la vista lo que la app haya marcado por error. La captura original nunca se modifica.';

  @override
  String get featActionsHow =>
      'Lo que esté escrito dentro de una captura se convierte en algo que puedes usar. Shoto extrae las partes útiles y pone un botón en cada una.';

  @override
  String get featActionsPoint1 =>
      'Se encuentran por ti los enlaces, las direcciones de correo, los IBAN, los códigos de verificación, las fechas y los números de envío.';

  @override
  String get featActionsPoint2 =>
      'Un toque para abrir o copiar, sin leer caracteres de una imagen.';

  @override
  String get featActionsPoint3 =>
      'Funciona con las capturas que ya tienes, no solo con las nuevas.';

  @override
  String get featTraitsHow =>
      'Filtrar es gratis sobre todo lo que Shoto ya ha leído: la búsqueda, las acciones y Compartir seguro dejan texto reconocido, y cada filtro se deriva de ahí. Lo que se paga es leer el resto de la biblioteca de una pasada, para que un filtro vea también las capturas que ninguna otra función ha abierto todavía.';

  @override
  String get featTraitsPoint1 =>
      'Cinco filtros: números de tarjeta e IBAN, enlaces, teléfonos y correos, códigos de verificación, y fechas a las que se espera que acudas.';

  @override
  String get featTraitsPoint2 =>
      'Los números de tarjeta y los IBAN se demuestran por suma de verificación. El resto se lee de la imagen, así que se queda corto antes que afirmar de más.';

  @override
  String get featTraitsPoint3 =>
      'La biblioteca siempre dice cuántas capturas no se han leído nunca, para que un resultado vacío no se haga pasar por una ausencia. La lectura ocurre en el teléfono; no se sube nada.';

  @override
  String get featTint => 'Elige tu color de acento';

  @override
  String featTintBody(int count) {
    return '$count acentos para botones, interruptores y selecciones, cada uno ajustado para seguir siendo legible en claro y en oscuro.';
  }

  @override
  String get featTintHow =>
      'La mayoría de las apps te dan una fila de colores en bruto y dejan el contraste al azar; por eso un acento amarillo suele llegar con un texto blanco que nadie puede leer. Shoto guarda tu elección como una posición en la rueda de color, no como un color fijo, y calcula el tono exacto para el modo claro y para el oscuro, así que elijas el que elijas sostiene el texto con la misma fuerza que el color propio de la app.';

  @override
  String featTintPoint1(int count) {
    return '$count acentos, del verde azulado y el musgo al ámbar y la brasa, hasta la ciruela, el índigo y la pizarra.';
  }

  @override
  String get featTintPoint2 =>
      'Cada uno se calcula dos veces, una para el modo claro y otra para el oscuro, contra el mismo objetivo de contraste: ningún acento brilla en una pantalla oscura ni desaparece en una clara.';

  @override
  String get featTintPoint3 =>
      'El rojo de eliminar, el verde de hecho y el ámbar de aviso no cambian nunca, así que un color que significa algo nunca se vuelve decoración.';

  @override
  String get featStitchHow =>
      'La captura con desplazamiento, en los móviles que la tienen, hay que iniciarla mientras sigues en la página. Shoto funciona después: elige dos o más capturas que ya tengas en tu biblioteca — incluidas las que te haya enviado alguien — y calcula dónde se solapan y las une en una sola imagen alta.';

  @override
  String get featStitchPoint1 =>
      'La franja repetida entre dos capturas se detecta y se elimina automáticamente.';

  @override
  String get featStitchPoint2 =>
      'Ves la unión antes de guardar nada: la detección automática es buena, pero nunca infalible.';

  @override
  String get featStitchPoint3 =>
      'La imagen unida se guarda en tu galería como cualquier otra foto.';

  @override
  String get featDuplicatesHow =>
      'Compartir capturas de una en una casi nunca genera duplicados. Guardar un lote desde \"Desde la última vez\", sí: vas rápido y acabas guardando dos capturas de lo mismo. Shoto las compara por su aspecto y no por su nombre o tamaño, así que detecta esas, y además un reenvío u otro recorte.';

  @override
  String get featDuplicatesPoint1 =>
      'Agrupa lo que se parece y sugiere la copia que conviene conservar.';

  @override
  String get featDuplicatesPoint2 =>
      'Muestra cuánto espacio libera cada grupo antes de que decidas nada.';

  @override
  String get featDuplicatesPoint3 =>
      'No se borra nada hasta que revisas el grupo y lo confirmas.';

  @override
  String get featUnlimitedHow =>
      'La versión gratuita es una app real y usable: guardar, carpetas, favoritos y búsqueda completa, sin cuenta y sin subir nada. Tiene dos límites —cuántas capturas organiza y cuántas carpetas guarda— y Pro los quita. Todo lo que ya organizaste se queda donde está.';

  @override
  String featUnlimitedPoint1(Object count) {
    return 'La versión gratuita guarda $count carpetas, justo las que Shoto te da al empezar. Pro también elimina ese número.';
  }

  @override
  String get featUnlimitedPoint2 =>
      'Nombrar para qué es una captura también es gratis e ilimitado.';

  @override
  String get featUnlimitedPoint3 =>
      'Llegar al límite significa que Shoto ya es donde guardas las cosas. Nada se borra al llegar.';

  @override
  String get includedSubtitle => 'Cada función Pro, explicada.';

  @override
  String get includedHint => 'Toca una función para ver cómo funciona';

  @override
  String get includedHowLabel => 'Cómo funciona';

  @override
  String get includedActiveTitle => 'Tu plan está activo';

  @override
  String get includedActiveBody =>
      'Todo lo de abajo está desbloqueado en esta cuenta.';

  @override
  String get includedLockedTitle => 'Aún sin desbloquear';

  @override
  String get includedLockedBody =>
      'Lee qué hace cada una en realidad y luego decide.';

  @override
  String get includedFreeTitle => 'Lo que te da la versión gratuita';

  @override
  String includedFreeBody(int count) {
    return '$count capturas organizadas, carpetas ilimitadas y búsqueda completa: gratis para siempre.';
  }

  @override
  String get onboardingCta => 'Empezar';

  @override
  String get onboardingPromise => 'Tus capturas se quedan en tu teléfono.';

  @override
  String get actionsTitle => 'Acciones';

  @override
  String get actionsWorking => 'Leyendo la captura';

  @override
  String get actionsWorkingBody => 'Buscando números, enlaces y códigos.';

  @override
  String get actionsNoneTitle => 'Nada sobre lo que actuar';

  @override
  String get actionsNoneBody =>
      'No se encontraron números de teléfono, enlaces, códigos ni cuentas.';

  @override
  String get actionsCopy => 'Copiar';

  @override
  String get actionsCopied => 'Copiado';

  @override
  String get actionsNoApp => 'Ninguna app de este dispositivo puede hacer eso.';

  @override
  String get devModeOn => 'Modo desarrollador activo: todo desbloqueado';

  @override
  String get devModeBadge => 'MODO DESARROLLADOR';

  @override
  String get devModeOffTitle => '¿Desactivar el modo desarrollador?';

  @override
  String get devModeOffBody =>
      'Shoto volverá al plan gratis en este dispositivo, para que puedas probar el muro de pago y los límites otra vez.';

  @override
  String get devModeOffConfirm => 'Desactivar';

  @override
  String get devAccessTitle => 'Acceso de desarrollador';

  @override
  String get devAccessBody =>
      'Introduce el código de 4 dígitos para desbloquear todas las funciones Pro en este dispositivo.';

  @override
  String get devWrongCode => 'Código incorrecto';

  @override
  String devTapToDisable(int count) {
    return 'Toca $count× para desactivar';
  }

  @override
  String appVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get kindCard => 'un número de tarjeta';

  @override
  String get kindIban => 'una cuenta bancaria';

  @override
  String get kindCode => 'un código de verificación';

  @override
  String get kindNationalId => 'un número de identidad';

  @override
  String get kindEmail => 'un correo electrónico';

  @override
  String get kindLink => 'un enlace';

  @override
  String get actionEmailAction => 'Escribir';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get kindEvent => 'un evento';

  @override
  String get kindPlace => 'un lugar';

  @override
  String get kindWifi => 'una red Wi-Fi';

  @override
  String get kindTracking => 'un envío';

  @override
  String get actionAddToCalendar => 'Añadir al calendario';

  @override
  String get actionOpenMaps => 'Abrir en Maps';

  @override
  String get actionDirections => 'Cómo llegar';

  @override
  String get actionCopyNetwork => 'Copiar nombre';

  @override
  String get actionTrack => 'Rastrear';

  @override
  String get actionEventUntitled => 'Evento';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas',
      one: '1 captura',
      zero: 'Sin capturas',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$position de $total';
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
      other: '$count grupos de duplicados',
      one: '1 grupo de duplicados',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count copias parecidas';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos encontrados',
      one: '1 elemento encontrado',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'Almacenamiento';

  @override
  String get settingsDuplicatesHint => 'Detecta capturas que hiciste dos veces';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'Qué incluye';

  @override
  String settingsFeatureCount(int count) {
    return '$count funciones, un plan';
  }

  @override
  String get settingsShareHint => 'Cuéntaselo a quien lo necesite';

  @override
  String get settingsShareText =>
      'Shoto ordena mis capturas solo, y todo se queda en el teléfono.';

  @override
  String get settingsCacheMeasuring => 'Midiendo…';

  @override
  String settingsCacheSize(String size) {
    return '$size de miniaturas';
  }

  @override
  String get homeSafeShareHint => 'Abre una captura y pulsa Compartir seguro.';

  @override
  String get homeStitchHint =>
      'Mantén pulsadas dos o más capturas de tu biblioteca y pulsa Unir.';

  @override
  String stitchLimit(int count) {
    return 'Puedes unir hasta $count capturas a la vez.';
  }

  @override
  String get shareChoiceTitle => '¿Qué quieres que haga Shoto?';

  @override
  String get shareChoiceProtect => 'Tapar datos privados';

  @override
  String get shareChoiceProtectHint =>
      'Oculta lo privado y envíala. No se guarda aquí.';

  @override
  String get quickSaveCoverAction => 'Tapar';

  @override
  String get quickSaveCoverWhy => '¿Tiene datos privados?';

  @override
  String get shareChoiceSave => 'Guardar en Shoto';

  @override
  String get shareChoiceSaveHint => 'Añadirla a tu biblioteca y archivarla.';

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Capturas guardadas. ¿Las añades a una carpeta?',
      one: 'Captura guardada. ¿La añades a una carpeta?',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count capturas unidas';
  }

  @override
  String stitchResultTrimmed(int count) {
    return 'Se han quitado $count px de contenido repetido';
  }

  @override
  String get errorLoadScreenshots => 'No se pudieron cargar tus capturas.';

  @override
  String get errorLoadFolders => 'No se pudieron cargar tus carpetas.';

  @override
  String get errorSaveFolder => 'No se pudo guardar esa carpeta.';

  @override
  String get errorDeleteFolder => 'No se pudo eliminar esa carpeta.';

  @override
  String get errorScanDuplicates => 'No se pudo buscar duplicados.';

  @override
  String get errorDeleteSelected =>
      'No se pudieron eliminar las capturas seleccionadas.';

  @override
  String get errorStitchFailed => 'No se han podido unir estas capturas.';

  @override
  String get errorStitchSave => 'No se pudo guardar la imagen unida.';

  @override
  String get errorOnboarding => 'No se pudo cargar. Vuelve a abrir la app.';

  @override
  String get errorSignInCancelled => 'Se canceló el inicio de sesión.';

  @override
  String get errorSignInInterrupted =>
      'El inicio de sesión se interrumpió. Inténtalo de nuevo.';

  @override
  String get errorNetwork => 'Error de red. Comprueba tu conexión.';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorPlans => 'No se pudieron cargar los planes.';

  @override
  String get errorPurchase => 'La compra falló. Inténtalo de nuevo.';

  @override
  String get errorNoSubscription =>
      'No hay ninguna suscripción activa en esta cuenta.';

  @override
  String get errorRestore => 'No se pudieron restaurar las compras.';

  @override
  String get errorStitchTooFew => 'Elige al menos dos capturas para unir.';

  @override
  String errorStitchTooMany(int count) {
    return 'Se pueden unir hasta $count capturas a la vez.';
  }

  @override
  String get errorStitchUnreadable => 'No se pudo leer una de las capturas.';

  @override
  String get errorStitchWidths =>
      'Estas capturas tienen anchos distintos, así que no pueden ser parte del mismo desplazamiento.';

  @override
  String get errorStitchNoOverlap =>
      'Estas capturas no se superponen. Unir solo funciona con capturas de la misma página tomadas al desplazarte.';

  @override
  String get errorStitchOverlap =>
      'No se pudo determinar la superposición entre estas capturas.';

  @override
  String get errorStitchTooTall =>
      'La imagen unida sería demasiado alta. Prueba a unir menos capturas.';

  @override
  String get errorStitchEncode => 'No se pudo codificar la imagen unida.';

  @override
  String get errorRedactionSave => 'No se pudo guardar la copia protegida.';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas guardadas',
      one: 'Captura guardada',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'Grande';

  @override
  String get densityMedium => 'Mediano';

  @override
  String get densitySmall => 'Pequeño';

  @override
  String get sensitiveCard => 'Número de tarjeta';

  @override
  String get sensitiveIban => 'Cuenta bancaria';

  @override
  String get sensitiveCode => 'Código de verificación';

  @override
  String get sensitiveNationalId => 'Número de identidad';

  @override
  String get sensitiveEmail => 'Correo electrónico';

  @override
  String get sensitivePhone => 'Número de teléfono';

  @override
  String get sensitiveAddress => 'Dirección';

  @override
  String get sensitiveName => 'Nombre';

  @override
  String get sensitiveOrderNumber => 'Número de pedido';

  @override
  String get sensitiveNumber => 'Número';

  @override
  String get onbSkip => 'Omitir';

  @override
  String get onbNext => 'Siguiente';

  @override
  String get onbWelcomeBody =>
      'Un hogar para las capturas que vale la pena guardar. Archivadas, buscables y seguras de enviar.';

  @override
  String get onbSaveTitle => 'Guárdala en el momento en que la haces';

  @override
  String get onbSaveBody =>
      'Toca compartir en cualquier app y elige Shoto. Es la única forma de que entre algo.';

  @override
  String get onbChipAnyApp => 'Cualquier app';

  @override
  String get onbChipOneTap => 'Un toque';

  @override
  String get onbChipToFolder => 'Directo a una carpeta';

  @override
  String get onbFileTitle => 'Una biblioteca, no un carrete';

  @override
  String get onbFileBody =>
      'Todo lo que envías llega archivado y se queda justo donde lo pusiste.';

  @override
  String get onbChipFolders => 'Carpetas';

  @override
  String get onbChipFavourites => 'Favoritos';

  @override
  String get onbChipDuplicates => 'Buscador de duplicados';

  @override
  String get onbFindTitle => 'Encuentra las palabras dentro de una imagen';

  @override
  String get onbFindBody =>
      'Shoto lee tus capturas, así que basta con una palabra que recuerdes.';

  @override
  String get onbChipInsideText => 'Texto en imágenes';

  @override
  String get onbChipOffline => 'Funciona sin conexión';

  @override
  String get onbChipCards => 'Números de tarjeta';

  @override
  String get onbChipCodes => 'Códigos y documentos';

  @override
  String get onbChipPreview => 'Ves cada cobertura';

  @override
  String get onbChipGallery => 'La galería nunca se abre';

  @override
  String get onbChipOnDevice => 'Se queda en tu teléfono';

  @override
  String get onbSendTitle => 'Envíalas igualmente';

  @override
  String get onbSendBody =>
      'Shoto tapa lo privado primero y te muestra cada cobertura antes de que salga.';

  @override
  String get onbYoursTitle => 'Nada se mueve sin ti';

  @override
  String get onbYoursBody =>
      'Tu galería nunca se abre. Solo se guarda lo que tú entregas.';

  @override
  String get onbFolderExample => 'Recibos';

  @override
  String get onbSearchExample => 'recibo';

  @override
  String get importTitle => 'Añadir capturas';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas importadas',
      one: '1 captura importada',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return '$imported de $picked importadas';
  }

  @override
  String get importFailed => 'No se pudieron guardar esas capturas';

  @override
  String get homeToolImportSubtitle =>
      'Elige en tu teléfono; tu galería nunca se lee';

  @override
  String get importPickerUnavailable => 'No se pudo abrir el selector de fotos';

  @override
  String get searchWorking => 'Leyendo tus capturas…';

  @override
  String get settingsBackup => 'Copia y restauración';

  @override
  String get settingsBackupHint => 'Guarda tu biblioteca en un archivo';

  @override
  String get backupTitle => 'Copia de seguridad';

  @override
  String get backupIntro =>
      'Tu biblioteca vive en este teléfono y en ningún otro sitio. La copia es lo que queda si lo pierdes.';

  @override
  String get backupCreateTitle => 'Crear una copia';

  @override
  String get backupCreateBody =>
      'Reúne cada captura, carpeta y etiqueta en un archivo, y luego eliges dónde guardarlo.';

  @override
  String get backupCreateAction => 'Crear copia';

  @override
  String get backupWorking => 'Empaquetando tu biblioteca…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Se copiaron $screenshots capturas',
      one: 'Se copió 1 captura',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders carpetas',
      one: '1 carpeta',
    );
    return '$_temp0 y $_temp1';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Se copiaron $screenshots capturas',
      one: 'Se copió 1 captura',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'No se pudieron leer $skipped',
      one: 'No se pudo leer 1',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get backupFailed => 'No se pudo terminar la copia';

  @override
  String get backupPrivacyNote =>
      'El archivo se crea en este teléfono y solo va a donde tú lo envíes. No se sube nada.';

  @override
  String get restoreTitle => 'Restaurar una copia';

  @override
  String get restoreBody =>
      'Añade todo lo del archivo a esta biblioteca. No se quita nada de lo que ya tienes.';

  @override
  String get restoreAction => 'Restaurar';

  @override
  String get restoreWorking => 'Devolviendo tu biblioteca…';

  @override
  String get restoreConfirmTitle => '¿Restaurar esta copia?';

  @override
  String get restoreConfirmMessage =>
      'Todo lo del archivo se añade a tu biblioteca. Tus capturas actuales se quedan tal cual.';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Se restauraron $screenshots capturas',
      one: 'Se restauró 1 captura',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders carpetas',
      one: '1 carpeta',
    );
    return '$_temp0 y $_temp1';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: 'Se restauraron $screenshots capturas',
      one: 'Se restauró 1 captura',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: 'Se omitieron $skipped',
      one: 'Se omitió 1',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get restoreNotABackup => 'Ese archivo no es una copia de Shoto';

  @override
  String get restoreFailed => 'No se pudo terminar la restauración';

  @override
  String get settingsHelp => 'Ayuda';

  @override
  String get settingsContactSupport => 'Contactar con soporte';

  @override
  String get supportSubject => 'Soporte de Shoto';

  @override
  String get supportNoMailApp =>
      'No hay ninguna app de correo. Se copió la dirección.';

  @override
  String get supportGreeting => 'Hola, equipo de Shoto:';

  @override
  String get dateToday => 'Hoy';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String get dateThisWeek => 'Esta semana';

  @override
  String get dateThisMonth => 'Este mes';

  @override
  String get librarySortNewest => 'Más recientes primero';

  @override
  String get librarySortOldest => 'Más antiguas primero';

  @override
  String get librarySortLabel => 'Orden';

  @override
  String get libraryShowOnly => 'Mostrar solo';

  @override
  String get libraryShowEverything => 'Todo';

  @override
  String libraryScanPrompt(int count) {
    return 'Leer $count capturas';
  }

  @override
  String get libraryScanning => 'Leyendo…';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carpetas ya existen aquí',
      one: '1 carpeta ya existe aquí',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'Estos nombres están en tu biblioteca y en la copia. El mismo nombre no siempre es la misma carpeta, así que esto lo decides tú.';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'y $count más',
      one: 'y 1 más',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'Juntarlas';

  @override
  String get restoreClashMergeBody =>
      'Las capturas van a las carpetas que ya tienes.';

  @override
  String get restoreClashSeparate => 'Mantenerlas aparte';

  @override
  String get restoreClashSeparateBody =>
      'Crea una segunda carpeta con el mismo nombre. No se toca nada existente.';

  @override
  String get intentBuy => 'Comprar';

  @override
  String get intentRead => 'Leer';

  @override
  String get intentReply => 'Responder';

  @override
  String get intentTry => 'Probar';

  @override
  String get intentVisit => 'Visitar';

  @override
  String get intentBuyWaiting => 'Por comprar';

  @override
  String get intentReadWaiting => 'Por leer';

  @override
  String get intentReplyWaiting => 'Por responder';

  @override
  String get intentTryWaiting => 'Por probar';

  @override
  String get intentVisitWaiting => 'Por visitar';

  @override
  String get intentWatch => 'Ver';

  @override
  String get intentListen => 'Escuchar';

  @override
  String get intentCook => 'Cocinar';

  @override
  String get intentBook => 'Reservar';

  @override
  String get intentPay => 'Pagar';

  @override
  String get intentSend => 'Enviar';

  @override
  String get intentDownload => 'Descargar';

  @override
  String get intentApply => 'Postular';

  @override
  String get intentCompare => 'Comparar';

  @override
  String get intentFix => 'Arreglar';

  @override
  String get intentWatchWaiting => 'Por ver';

  @override
  String get intentListenWaiting => 'Por escuchar';

  @override
  String get intentCookWaiting => 'Por cocinar';

  @override
  String get intentBookWaiting => 'Por reservar';

  @override
  String get intentPayWaiting => 'Por pagar';

  @override
  String get intentSendWaiting => 'Por enviar';

  @override
  String get intentDownloadWaiting => 'Por descargar';

  @override
  String get intentApplyWaiting => 'Por postular';

  @override
  String get intentCompareWaiting => 'Por comparar';

  @override
  String get intentFixWaiting => 'Por arreglar';

  @override
  String get intentMore => 'Más';

  @override
  String get intentSectionCommon => 'Listas para usar';

  @override
  String get intentSectionYours => 'Tuyas';

  @override
  String get intentYoursEmpty =>
      'Un verbo que escribas tú funciona igual que los de arriba.';

  @override
  String get intentNewAction => 'Escribe el tuyo';

  @override
  String get intentNewTitle => 'Ponle tu nombre';

  @override
  String get intentEditTitle => 'Editar esta';

  @override
  String get intentNameLabel => 'El verbo';

  @override
  String get intentNameHint => 'Devolverlo, cancelarlo, llamarlos…';

  @override
  String get intentIconLabel => 'Icono';

  @override
  String intentDeleteTitle(String label) {
    return '¿Eliminar \"$label\"?';
  }

  @override
  String get intentDeleteMessage =>
      'Las capturas se quedan donde están. Solo dejan de esperar algo.';

  @override
  String get intentSelectionAction => 'Marcar como';

  @override
  String intentSelectionApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas marcadas',
      one: '1 captura marcada',
    );
    return '$_temp0';
  }

  @override
  String get intentPrompt => 'Para qué es, si quieres';

  @override
  String get intentSkip => 'Nada en particular';

  @override
  String get intentWaitingTitle => 'Te espera';

  @override
  String get intentNothingWaiting => 'Nada te espera';

  @override
  String get intentAllDone =>
      'Has terminado todo lo que guardaste para después.';

  @override
  String get intentMarkDone => 'Hecho';

  @override
  String get intentUndo => 'Devolver';

  @override
  String get intentDoneToast => 'Marcado';

  @override
  String intentListEnd(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Esas son las $count',
      one: 'Esa es la única',
    );
    return '$_temp0';
  }

  @override
  String get intentChange => 'Cambiar';

  @override
  String get intentClear => 'Para nada en concreto';

  @override
  String intentEmptyOne(String verb) {
    return 'Nada que $verb aquí';
  }

  @override
  String get intentEmptyBody =>
      'Las capturas que marques aparecen aquí hasta que las taches.';

  @override
  String intentProgress(int done, int total) {
    return '$done de $total hechas';
  }

  @override
  String intentDoneCount(int count) {
    return '$count terminadas';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count semanas',
      one: 'hace 1 semana',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count meses',
      one: 'hace 1 mes',
    );
    return '$_temp0';
  }

  @override
  String get copyTextSelect => 'Seleccionar texto';

  @override
  String get copyTextSelectAll => 'Seleccionar todo';

  @override
  String get copyTextHint => 'Mantén pulsado cualquier texto para copiarlo';

  @override
  String get copyTextPrompt => 'Arrastra para seleccionar';

  @override
  String get copyTextNone => 'Shoto no encuentra texto legible en esta captura';
}
