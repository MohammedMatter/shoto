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
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsSignOutTitle => '¿Cerrar sesión?';

  @override
  String get authWelcome => 'Bienvenido a SHOTO';

  @override
  String get authSubtitle =>
      'Iniciar sesión mantiene tu suscripción contigo al cambiar de teléfono. Tus capturas se quedan en este dispositivo de todos modos: una cuenta nunca se las lleva.';

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
      'Guarda lo que pertenece a SHOTO. Todo lo demás se queda donde está.';

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
      'SHOTO puede listar lo que captures a partir de ahora, para que guardes las pocas que importan. Nada entra en tu biblioteca hasta que tú lo digas.';

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
  String get triageNothingNew => 'No hay nada nuevo que revisar';

  @override
  String get settingsYourName => 'Tu nombre';

  @override
  String get settingsYourNameHint =>
      'Para que Safe Share lo tape cuando aparezca';

  @override
  String get settingsYourNameNotSet => 'Sin definir';

  @override
  String get ownerNameTitle => 'Tu nombre';

  @override
  String get ownerNameBody =>
      'Safe Share encuentra los números de tarjeta y los códigos por su propia aritmética. Un nombre solo lo encuentra si ya conoce el tuyo. Se escribe una vez, se queda en este teléfono y no se envía a ningún sitio.';

  @override
  String get ownerNameFieldHint => 'El nombre que imprime tu banco';

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
      'Elige algunas de tu teléfono ahora, o comparte una captura en SHOTO desde cualquier app.';

  @override
  String get homeEmptyImportCta => 'Elegir desde mi teléfono';

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
      'Comparte una captura con SHOTO o añádela con el botón +. Tu galería nunca se lee: solo se guarda lo que entregas.';

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
      'SHOTO guarda las capturas que compartes con él en su propio álbum. Necesita acceso a fotos para escribir ahí y volver a leerlas; nunca consulta el resto de tu galería.';

  @override
  String get permissionPartialTitle => 'Se necesita acceso completo';

  @override
  String get permissionPartialMessage =>
      'Ahora mismo SHOTO solo ve unas pocas fotos que elegiste a mano, así que no puede llegar a su propio álbum. Elige «Permitir todas» para continuar.';

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
  String get settingsShare => 'Compartir SHOTO';

  @override
  String get settingsPrivacyNote =>
      'SHOTO solo guarda las capturas que le entregas, y todo lo que hace con ellas —leer texto, buscar duplicados— ocurre en este dispositivo. Tus imágenes nunca se suben. Hay tres cosas que tú activas: ofrecer capturas nuevas lee tu álbum de capturas para poder preguntarte por ellas, una cuenta envía solo tu correo para que la suscripción sobreviva a un cambio de teléfono, y los informes de errores envían qué falló: el código, nunca una imagen.';

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
  String get foldersRenameTitle => 'Renombrar carpeta';

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
  String get quickSaveTitleOne => 'Guardar en SHOTO';

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
  String get quickSaveSaved => 'Guardado en SHOTO';

  @override
  String quickSaveFiled(String folder) {
    return 'Archivado en $folder.';
  }

  @override
  String get quickSaveFailedTitle => 'No se pudo leer esa imagen';

  @override
  String get quickSaveFailedBody => 'Prueba a compartirla otra vez.';

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
  String get paywallTitle => 'Desbloquea SHOTO Pro';

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
  String get paywallContinue => 'Continuar';

  @override
  String get paywallUnavailable => 'Aún no disponible';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get paywallLegal =>
      'Se renueva automáticamente hasta que la canceles. Cancela cuando quieras desde tu cuenta de App Store o Google Play. Al continuar aceptas nuestros Términos y la Política de privacidad.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'SHOTO Pro';

  @override
  String get subPremiumBody => 'Todas las funciones desbloqueadas.';

  @override
  String get subDevUnlock => 'Acceso de prueba';

  @override
  String get subDevUnlockBody =>
      'Desbloqueado solo en este dispositivo — no es una suscripción real';

  @override
  String get subUnlockEverything => 'Desbloquea todo';

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
  String get featUnlimited => 'Sin límite para tu biblioteca';

  @override
  String featUnlimitedBody(Object count) {
    return 'La versión gratuita organiza $count capturas. Pro elimina el número.';
  }

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
      'Lo que esté escrito dentro de una captura se convierte en algo que puedes usar. SHOTO extrae las partes útiles y pone un botón en cada una.';

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
  String get featStitchHow =>
      'La captura con desplazamiento, en los móviles que la tienen, hay que iniciarla mientras sigues en la página. SHOTO funciona después: elige dos o más capturas que ya tengas en tu biblioteca — incluidas las que te haya enviado alguien — y calcula dónde se solapan y las une en una sola imagen alta.';

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
      'Compartir capturas de una en una casi nunca genera duplicados. Guardar un lote desde \"Desde la última vez\", sí: vas rápido y acabas guardando dos capturas de lo mismo. SHOTO las compara por su aspecto y no por su nombre o tamaño, así que detecta esas, y además un reenvío u otro recorte.';

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
      'La versión gratuita es una app real y usable: guardar, carpetas, favoritos y búsqueda completa, sin cuenta y sin subir nada. Tiene un único límite —cuántas capturas organiza— y Pro lo quita. Todo lo que ya organizaste se queda donde está.';

  @override
  String get featUnlimitedPoint1 =>
      'Las carpetas son ilimitadas en la versión gratuita, como debe ser.';

  @override
  String get featUnlimitedPoint2 =>
      'Nombrar para qué es una captura también es gratis e ilimitado.';

  @override
  String get featUnlimitedPoint3 =>
      'Llegar al límite significa que SHOTO ya es donde guardas las cosas. Nada se borra al llegar.';

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
      'SHOTO volverá al plan gratis en este dispositivo, para que puedas probar el muro de pago y los límites otra vez.';

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
      'SHOTO ordena mis capturas solo, y todo se queda en el teléfono.';

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
  String get onbPileTitle => 'Mil capturas, un solo montón';

  @override
  String get onbPileBody =>
      'Capturas para recordar. Una semana después está enterrada bajo otras cuatrocientas.';

  @override
  String get onbChooseTitle => 'SHOTO nunca lee tu galería';

  @override
  String get onbChooseBody =>
      'Nada llega solo. Tú compartes una captura con la app: esa es toda la regla.';

  @override
  String get onbSafeShareTitle => 'La captura que sí puedes enviar';

  @override
  String get onbSafeShareBody =>
      'El número de tarjeta queda bajo un bloque sólido: la etiqueta de al lado se mantiene y la captura se sigue entendiendo. Revisas cada tapado antes de enviar.';

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
  String get restoreNotABackup => 'Ese archivo no es una copia de SHOTO';

  @override
  String get restoreFailed => 'No se pudo terminar la restauración';

  @override
  String get settingsHelp => 'Ayuda';

  @override
  String get settingsContactSupport => 'Contactar con soporte';

  @override
  String get supportSubject => 'Soporte de SHOTO';

  @override
  String get supportNoMailApp =>
      'No hay ninguna app de correo. Se copió la dirección.';

  @override
  String get supportGreeting => 'Hola, equipo de SHOTO:';

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
  String get intentChange => 'Cambiar para qué es';

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
}
