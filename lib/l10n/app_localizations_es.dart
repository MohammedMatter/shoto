// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

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
  String get homeInboxEmpty => 'Nada guardado';

  @override
  String get homeInboxEmptySubtitle =>
      'Comparte una captura con SHOTO para empezar';

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
  String get homeToolsTitle => 'Qué puede hacer SHOTO';

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
  String get homeToolsTitleShort => 'Haz algo';

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
  String get rulesTitle => 'Reglas';

  @override
  String get rulesSubtitle => 'Archivado que ocurre sin ti';

  @override
  String get rulesTeachHeadline => 'Deja de ordenar capturas a mano';

  @override
  String get rulesTeachIntro =>
      'Una regla es una frase: cuando una captura sea así, archívala en esa carpeta. Escríbela una vez y cada captura que coincida irá sola allí, en cuanto llegue.';

  @override
  String get rulesTeachExample =>
      'Por ejemplo: cuando una captura contenga un número de tarjeta → archívala en Recibos.';

  @override
  String get rulesTeachStep1Title => '1. Describe la captura';

  @override
  String get rulesTeachStep1Body =>
      'Una palabra impresa en ella, algo que muestra o datos privados dentro.';

  @override
  String get rulesTeachStep2Title => '2. Elige la carpeta';

  @override
  String get rulesTeachStep2Body =>
      'Dónde deben acabar las capturas que coincidan.';

  @override
  String get rulesTeachStep3Title => '3. Ya está';

  @override
  String get rulesTeachStep3Body =>
      'A partir de ahí SHOTO las archiva por ti. También puedes aplicar tus reglas a las capturas que ya estaban esperando.';

  @override
  String get rulesTeachShow => '¿Cómo funcionan las reglas?';

  @override
  String get rulesTeachHide => 'Entendido';

  @override
  String get rulesStartTemplates => 'O empieza con un ejemplo';

  @override
  String get rulesTemplateReceipts => 'Recibos y facturas';

  @override
  String get rulesTemplateReceiptsWhy =>
      'Cualquier cosa con un número de tarjeta o un total';

  @override
  String get rulesTemplateTickets => 'Billetes y reservas';

  @override
  String get rulesTemplateTicketsWhy =>
      'Tarjetas de embarque, reservas, confirmaciones de pedido';

  @override
  String get rulesTemplateCodes => 'Códigos y contraseñas';

  @override
  String get rulesTemplateCodesWhy =>
      'Códigos de un solo uso y cualquier cosa que parezca una contraseña';

  @override
  String get rulesTemplateAnimals => 'Fotos de animales';

  @override
  String get rulesTemplateAnimalsWhy =>
      'Se fija en lo que muestra la imagen, no en sus palabras';

  @override
  String get rulesTemplatePicked =>
      'Elige una carpeta y estará lista para guardar.';

  @override
  String get rulesEmptyTitle => 'Aún no hay reglas';

  @override
  String get rulesNew => 'Nueva regla';

  @override
  String get rulesNeedFolderFirst =>
      'Crea antes una carpeta: una regla necesita dónde archivar.';

  @override
  String get rulesDeleteTitle => '¿Eliminar esta regla?';

  @override
  String get rulesDeleteMessage =>
      'Las capturas que ya archivó se quedan donde están.';

  @override
  String rulesWhenIt(String summary) {
    return 'Cuando $summary';
  }

  @override
  String get rulesBacklogTitle => 'Ponte al día';

  @override
  String get rulesBacklogIdle =>
      'Aplica tus reglas a las capturas que aún no están en ninguna carpeta. Lo que archivaste a mano no se toca.';

  @override
  String rulesBacklogRunning(int done, int total) {
    return 'Revisando $done de $total…';
  }

  @override
  String get rulesBacklogNothing => 'No queda nada sin ordenar.';

  @override
  String rulesBacklogResult(int filed, int examined) {
    return 'Archivadas $filed de $examined capturas sin ordenar.';
  }

  @override
  String get rulesRunNow => 'Aplicar reglas ahora';

  @override
  String get ruleBuilderTitle => 'Nueva regla';

  @override
  String get ruleBuilderIntro => 'Dos preguntas: qué coincide y a dónde va.';

  @override
  String get ruleBuilderFolderLabel => '¿A dónde va?';

  @override
  String get ruleBuilderConditionLabel => '¿Qué debe coincidir?';

  @override
  String get ruleBuilderConditionsLabel => 'También coincide con';

  @override
  String get ruleBuilderAddCondition => 'Añadir otra';

  @override
  String get ruleBuilderMatchAll => 'Todas';

  @override
  String get ruleBuilderMatchAny => 'Cualquiera';

  @override
  String get ruleBuilderMatchAllHelp =>
      'La captura tiene que cumplirlas todas.';

  @override
  String get ruleBuilderMatchAnyHelp => 'Basta con que se cumpla una.';

  @override
  String get ruleBuilderSave => 'Guardar regla';

  @override
  String get ruleBuilderIncomplete => 'Elige qué coincide y una carpeta';

  @override
  String ruleBuilderPreview(String folder, String summary) {
    return 'Archivar en $folder cuando la captura $summary.';
  }

  @override
  String get ruleBuilderPreviewTitle => 'TU REGLA, EN PALABRAS';

  @override
  String get conditionTextContains => 'dice una palabra';

  @override
  String get conditionTextContainsHelp =>
      'Mira el texto que SHOTO lee dentro de la imagen y busca palabras completas: «code» no se activará con «barcode». Usa una palabra que de verdad aparecería impresa en ese tipo de captura.';

  @override
  String get conditionTextContainsHint =>
      'una palabra impresa — «factura», «billete»';

  @override
  String get conditionShowsSubject => 'muestra algo';

  @override
  String get conditionShowsSubjectHelp =>
      'Mira de qué es la imagen, no lo que dice. La palabra tiene que coincidir con la del modelo, así que toca una de tu biblioteca abajo en vez de adivinar.';

  @override
  String get conditionShowsSubjectHint =>
      'qué muestra — «gato», «animal», «comida»';

  @override
  String get conditionContainsSensitive => 'contiene datos privados';

  @override
  String get conditionContainsSensitiveHelp =>
      'Las mismas comprobaciones de Compartir seguro: los números de tarjeta pasan una suma de control real, así que un número de pedido no se confunde con uno.';

  @override
  String get conditionHasAnyText => 'tiene texto legible';

  @override
  String get conditionHasAnyTextHelp =>
      'Cierto para cualquier imagen con palabras. Útil para separar capturas de fotos guardadas.';

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
  String get settingsAutomation => 'Automatización';

  @override
  String get settingsAutomationCaption =>
      'Escribe una regla una vez y SHOTO archiva las capturas que coincidan en cuanto llegan.';

  @override
  String get settingsRules => 'Reglas de archivado';

  @override
  String get settingsRulesHint => 'Deja que SHOTO ordene por ti';

  @override
  String get settingsFindDuplicates => 'Buscar duplicados';

  @override
  String get settingsClearCache => 'Vaciar caché de imágenes';

  @override
  String get settingsShare => 'Compartir SHOTO';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsSignOutTitle => '¿Cerrar sesión?';

  @override
  String get settingsPrivacyNote =>
      'SHOTO nunca lee tu galería. Solo guarda las capturas que compartes con él, y todo lo que hace con ellas —leer texto, buscar duplicados— ocurre en este dispositivo. Nunca se sube nada.';

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
  String get quickSaveFiledByRules => 'Archivado por tus reglas.';

  @override
  String get quickSaveNoRuleMatched =>
      'Ninguna regla coincidió: queda sin ordenar en tu biblioteca.';

  @override
  String get quickSaveFailedTitle => 'No se pudo leer esa imagen';

  @override
  String get quickSaveFailedBody => 'Prueba a compartirla otra vez.';

  @override
  String get quickSaveSignedOutTitle => 'Inicia sesión en SHOTO primero';

  @override
  String get quickSaveSignedOutBody =>
      'Tu biblioteca pertenece a tu cuenta. Abre SHOTO, inicia sesión y compártelo de nuevo.';

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
  String get featRules => 'Reglas que archivan por ti';

  @override
  String get featRulesBody =>
      'Escribe una regla una vez y cada captura que compartas se archiva sola. Tú escribiste la regla, así que siempre sabes por qué.';

  @override
  String get featSearch => 'Busca dentro de tus capturas';

  @override
  String get featSearchBody =>
      'Encuentra cualquier captura por las palabras escritas en ella, en árabe o inglés. No se sube nada: la lectura ocurre en tu teléfono.';

  @override
  String get featSafeShare => 'Compartir seguro';

  @override
  String get featSafeShareBody =>
      'Cambia números de tarjeta, direcciones, nombres y datos de contacto por sustitutos realistas: misma longitud, mismo formato, mismo sitio. La copia que envías no parece editada.';

  @override
  String get featActions => 'Convierte capturas en acciones';

  @override
  String get featActionsBody =>
      'Llama a un número, abre un enlace, copia un código o un IBAN: directo desde la imagen, sin reescribir nada.';

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
  String get featUnlimited => 'Carpetas y capturas ilimitadas';

  @override
  String get featUnlimitedBody =>
      'El plan gratuito se detiene en unas pocas carpetas y capturas. Pro elimina ambos límites.';

  @override
  String get featRulesHow =>
      'Una regla es una frase que escribes tú: cuando una captura sea así, guárdala en esa carpeta. Cada captura nueva se comprueba con tus reglas al llegar, así que archivar deja de ser algo que tengas que recordar.';

  @override
  String get featRulesPoint1 =>
      'Coincide por las palabras impresas dentro de la imagen, por lo que muestra la foto o por si contiene algo sensible.';

  @override
  String get featRulesPoint2 =>
      'Pide que se cumplan todas tus condiciones o cualquiera de ellas, y puedes invertir cualquier condición.';

  @override
  String get featRulesPoint3 =>
      'No se adivina nada. La regla la escribiste tú, así que siempre sabes por qué una captura acabó donde acabó.';

  @override
  String get featSearchHow =>
      'SHOTO lee el texto impreso dentro de cada captura y lo recuerda, así que una sola palabra que recuerdes basta para volver a encontrar la imagen: sin nombres de archivo, sin carpetas, sin desplazarte.';

  @override
  String get featSearchPoint1 =>
      'Lee árabe e inglés, y sigue encontrando resultados aunque la escritura varíe un poco.';

  @override
  String get featSearchPoint2 =>
      'También busca por lo que muestra la imagen: prueba «recibo», «gato» o «comida».';

  @override
  String get featSearchPoint3 =>
      'La lectura ocurre en tu teléfono. No se sube nada, así que también funciona sin conexión.';

  @override
  String get featSafeShareHow =>
      'Detectar lo privado de una captura es gratis y sin límite. Lo que se paga es convertir esos hallazgos en una copia limpia: cada dato se redibuja con los colores de la propia captura como otro valor igual de corriente.';

  @override
  String get featSafeSharePoint1 =>
      'Las tarjetas se verifican con Luhn y los IBAN con mod-97, y los sustitutos superan las mismas comprobaciones, así que nada parece inventado.';

  @override
  String get featSafeSharePoint2 =>
      'También detecta nombres, direcciones, números de pedido, códigos de verificación, teléfonos y correos.';

  @override
  String get featSafeSharePoint3 =>
      'Ves cada cambio antes de enviar y puedes taparlo o dejarlo tal cual. La captura original nunca se modifica.';

  @override
  String get featActionsHow =>
      'Lo que esté escrito dentro de una captura se convierte en algo que puedes usar. SHOTO extrae las partes útiles y pone un botón en cada una.';

  @override
  String get featActionsPoint1 =>
      'Se detectan por ti los números de teléfono, enlaces, correos, IBAN y códigos de verificación.';

  @override
  String get featActionsPoint2 =>
      'Un toque para llamar, abrir o copiar, sin leer dígitos de una imagen.';

  @override
  String get featActionsPoint3 =>
      'Funciona con las capturas que ya tienes, no solo con las nuevas.';

  @override
  String get featStitchHow =>
      'Haz varias capturas mientras recorres un chat o una página larga y SHOTO calcula dónde se solapan y las vuelve a unir en una sola imagen alta.';

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
      'SHOTO compara las capturas por su aspecto y no por su nombre o tamaño, así que también detecta las casi idénticas: un reenvío, otro recorte, lo mismo capturado dos veces.';

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
      'El plan gratuito es una app real y utilizable, no una prueba: solo tiene un techo. Pro quita ese techo, y todo lo que ya organizaste se queda exactamente donde está.';

  @override
  String get featUnlimitedPoint1 =>
      'Tantas carpetas como realmente necesite tu biblioteca.';

  @override
  String get featUnlimitedPoint2 =>
      'Sin límite de capturas que archivas y marcas como favoritas.';

  @override
  String get featUnlimitedPoint3 =>
      'Guardar, carpetas, favoritos y el historial de búsqueda siguen siendo tuyos en cualquier caso.';

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
  String get includedFreeTitle => 'Lo que te da el plan gratis';

  @override
  String includedFreeBody(int folders, int count) {
    return '$folders carpetas y $count capturas organizadas, además de guardar, favoritos y la galería, gratis para siempre.';
  }

  @override
  String get authWelcome => 'Bienvenido a SHOTO';

  @override
  String get authSubtitle =>
      'Inicia sesión para guardar, ordenar y encontrar cada captura en un solo sitio.';

  @override
  String get authGoogle => 'Continuar con Google';

  @override
  String get authApple => 'Continuar con Apple';

  @override
  String get authLegal =>
      'Al continuar, aceptas nuestros Términos y la Política de privacidad.';

  @override
  String get onboardingCta => 'Empezar';

  @override
  String get onboardingPromise => 'Todo se queda en tu teléfono.';

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
  String get ruleSummaryEmpty => 'Sin condiciones: no archiva nada';

  @override
  String get ruleJoinAnd => ' y ';

  @override
  String get ruleJoinOr => ' o ';

  @override
  String ruleSaysWord(String value) {
    return 'dice «$value»';
  }

  @override
  String ruleNotSaysWord(String value) {
    return 'no dice «$value»';
  }

  @override
  String ruleShows(String value) {
    return 'muestra $value';
  }

  @override
  String ruleNotShows(String value) {
    return 'no muestra $value';
  }

  @override
  String ruleContains(String value) {
    return 'contiene $value';
  }

  @override
  String ruleNotContains(String value) {
    return 'no contiene $value';
  }

  @override
  String get ruleHasText => 'tiene texto legible';

  @override
  String get ruleNoText => 'no tiene texto legible';

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
  String get kindPhone => 'un número de teléfono';

  @override
  String get kindLink => 'un enlace';

  @override
  String get actionCall => 'Llamar';

  @override
  String get actionWhatsapp => 'WhatsApp';

  @override
  String get actionSms => 'Mensaje';

  @override
  String get actionEmailAction => 'Escribir';

  @override
  String get actionOpen => 'Abrir';

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
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsSignOutHint =>
      'Tus capturas se quedan en este dispositivo';

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
  String get errorLoadRules => 'No se pudieron cargar tus reglas.';

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
  String get quickSaveByRules => 'Que lo archiven mis reglas';

  @override
  String get ruleSeenTitle => 'LO QUE SHOTO HA VISTO EN TU BIBLIOTECA';

  @override
  String get ruleSeenEmpty =>
      'SHOTO aún no ha mirado dentro de tus capturas. Lee cada una al llegar, así que esto se irá llenando.';

  @override
  String get ruleSeenHint =>
      'Toca una: son las palabras exactas que produce el modelo, así que una regla hecha con ellas sí funcionará.';

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
  String get onbFileTitle => 'Archivada en cuanto la envías';

  @override
  String get onbFileBody =>
      'Elige una carpeta desde el propio menú de compartir. La app ni se abre.';

  @override
  String get onbFindTitle => 'Busca lo que hay dentro';

  @override
  String get onbFindBody =>
      'Las palabras escritas en la captura, y lo que muestra la imagen. Escribe «recibo» o «perro».';

  @override
  String get onbProTitle => 'SHOTO Pro';

  @override
  String get onbProBody =>
      'Las reglas archivan tus capturas nuevas por ti, y todo lo de abajo viene incluido.';

  @override
  String onbProMore(int count) {
    return 'y $count más';
  }

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
  String rulePreviewMatches(int count, int indexed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se llevaría $count de las $indexed capturas que SHOTO ha leído',
      one: 'Se llevaría 1 de las $indexed capturas que SHOTO ha leído',
    );
    return '$_temp0';
  }

  @override
  String get rulePreviewNone =>
      'Nada de lo que SHOTO ha leído hasta ahora coincide';

  @override
  String get rulePreviewNotIndexed =>
      'SHOTO todavía no ha leído ninguna de tus capturas, así que no hay nada con lo que comprobarlo. Lee cada una según llega.';

  @override
  String rulePreviewTaken(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de ellas se las lleva una regla por encima de esta.',
      one: '1 de ellas se la lleva una regla por encima de esta.',
    );
    return '$_temp0';
  }

  @override
  String get rulePreviewAllTaken =>
      'Todas las capturas que coinciden ya se las lleva una regla superior. Sube esta regla si quieres que gane.';

  @override
  String get rulePreviewFloor =>
      'Cuenta solo lo que SHOTO ha leído hasta ahora. Las capturas nuevas se comprueban según llegan.';

  @override
  String get ruleBuilderEditTitle => 'Editar regla';

  @override
  String get ruleBuilderEditIntro =>
      'Los cambios se aplican de ahora en adelante. Las capturas que ya archivó se quedan donde están.';

  @override
  String get ruleBuilderUpdate => 'Guardar cambios';

  @override
  String get rulesPriorityNote =>
      'Una captura va a la primera regla que coincide. Usa las flechas para cambiar cuál es.';

  @override
  String get rulesCardNotIndexed =>
      'Nada leído aún: nada con lo que comprobarlo';

  @override
  String rulesCardClaims(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se lleva $count capturas',
      one: 'Se lleva 1 captura',
    );
    return '$_temp0';
  }

  @override
  String get rulesCardClaimsNone => 'Todavía no se lleva nada';

  @override
  String rulesCardOverruled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coincidencias van a una regla superior',
      one: '1 coincidencia va a una regla superior',
    );
    return '$_temp0';
  }

  @override
  String get rulesMoveUp => 'Subir';

  @override
  String get rulesMoveDown => 'Bajar';

  @override
  String rulesBacklogUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Quedan $count capturas sin leer: ejecútalo otra vez para continuar.',
      one: 'Queda 1 captura sin leer: ejecútalo otra vez para continuar.',
    );
    return '$_temp0';
  }

  @override
  String indexingProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aún leyendo tus capturas: quedan $count',
      one: 'Aún leyendo tus capturas: queda 1',
    );
    return '$_temp0';
  }

  @override
  String get ruleBuilderMatches => 'Coincide';

  @override
  String get ruleBuilderMatchesNot => 'NO coincide';

  @override
  String get ruleBuilderMatchesNotHelp =>
      'La regla se activa cuando esto no se cumple: úsalo para dejar fuera una excepción.';

  @override
  String rulePreviewAlreadyFiled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count de ellas ya están en carpetas, y una ejecución nunca mueve esas. Aquí solo se archivarán capturas nuevas.',
      one:
          '1 de ellas ya está en una carpeta, y una ejecución nunca mueve esas. Aquí solo se archivarán capturas nuevas.',
    );
    return '$_temp0';
  }

  @override
  String rulesCardAlreadyFiled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Coincide con $count, pero ya están archivadas en otro sitio',
      one: 'Coincide con 1, pero ya está archivada en otro sitio',
    );
    return '$_temp0';
  }
}
