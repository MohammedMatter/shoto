// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get settingsCrashReports => 'Relatórios de falhas';

  @override
  String get settingsCrashReportsHint =>
      'Enviar detalhes técnicos quando algo dá errado';

  @override
  String get settingsSignOut => 'Sair';

  @override
  String get settingsSignOutTitle => 'Sair da conta?';

  @override
  String get authWelcome => 'Boas-vindas ao SHOTO';

  @override
  String get authSubtitle =>
      'Entrar mantém a sua assinatura com você quando trocar de telefone. As suas capturas ficam neste aparelho de qualquer forma — uma conta nunca as leva.';

  @override
  String get authGoogle => 'Continuar com o Google';

  @override
  String get authApple => 'Continuar com a Apple';

  @override
  String get authLegal =>
      'Ao continuar, você concorda com os nossos Termos de Serviço e a Política de Privacidade.';

  @override
  String get settingsAccount => 'Conta';

  @override
  String get settingsSignOutHint => 'As suas capturas ficam neste aparelho';

  @override
  String get settingsSignIn => 'Entrar';

  @override
  String get settingsSignInHint =>
      'Opcional. Só é preciso para levar uma compra para outro telefone.';

  @override
  String paywallTrialCta(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Começar $days dias grátis',
      one: 'Começar 1 dia grátis',
    );
    return '$_temp0';
  }

  @override
  String paywallTrialNote(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Grátis por $days dias, depois $price. Cancele quando quiser antes do fim.',
      one:
          'Grátis por um dia, depois $price. Cancele quando quiser antes do fim.',
    );
    return '$_temp0';
  }

  @override
  String get triageTitle => 'Desde a última vez';

  @override
  String get triageBody =>
      'Guarde o que faz sentido no SHOTO. Todo o resto fica exatamente onde está.';

  @override
  String get triageKeep => 'Guardar';

  @override
  String get triageSkip => 'Pular';

  @override
  String get triageFinish => 'Pronto';

  @override
  String triageProgress(int index, int total) {
    return '$index de $total';
  }

  @override
  String triageNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas novas',
      one: '1 captura nova',
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
      zero: 'Nada guardado',
    );
    return '$_temp0';
  }

  @override
  String get triageReview => 'Rever';

  @override
  String get triageInviteDecline => 'Agora não';

  @override
  String get triageInviteTitle => 'Mostrar aqui as capturas novas?';

  @override
  String get triageInviteBody =>
      'O SHOTO pode listar o que capturares a partir de agora, para guardares as poucas que importam. Nada entra na tua biblioteca até tu decidires.';

  @override
  String get triageInviteAccept => 'Mostrar';

  @override
  String get triageInviteDismiss => 'Não, obrigado';

  @override
  String get settingsTriage => 'Oferecer capturas novas';

  @override
  String get settingsTriageHint =>
      'Mostra o que você captura; sozinho não guarda nada';

  @override
  String get triageNothingNew => 'Nada de novo para rever';

  @override
  String get settingsYourName => 'O seu nome';

  @override
  String get settingsYourNameHint =>
      'Para o Safe Share poder cobri-lo quando aparecer';

  @override
  String get settingsYourNameNotSet => 'Não definido';

  @override
  String get ownerNameTitle => 'O seu nome';

  @override
  String get ownerNameBody =>
      'O Safe Share encontra números de cartão e códigos pela aritmética deles. Um nome só encontra se já souber o seu. Digitado uma vez, fica neste telefone, nunca é enviado a lugar nenhum.';

  @override
  String get ownerNameFieldHint => 'O nome que o seu banco imprime';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonRetry => 'Tentar de novo';

  @override
  String get commonSomethingWentWrong => 'Algo deu errado';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'Início';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navFolders => 'Pastas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get tagline => 'As suas capturas, organizadas';

  @override
  String get homeGreetingMorning => 'Bom dia';

  @override
  String get homeGreetingAfternoon => 'Boa tarde';

  @override
  String get homeGreetingEvening => 'Boa noite';

  @override
  String get homeInboxEmpty => 'Nada guardado ainda';

  @override
  String get homeInboxEmptySubtitle =>
      'Escolha algumas do seu telefone agora, ou compartilhe uma captura no SHOTO a partir de qualquer app.';

  @override
  String get homeEmptyImportCta => 'Escolher do meu telefone';

  @override
  String get homeInboxClear => 'Tudo arquivado';

  @override
  String get homeInboxClearSubtitle => 'Nada esperando para ser organizado';

  @override
  String get homeInboxCountSubtitle => 'Capturas que você ainda não arquivou';

  @override
  String get homeStatScreenshots => 'Capturas';

  @override
  String get homeStatFavorites => 'Favoritas';

  @override
  String get homeStatFolders => 'Pastas';

  @override
  String get homeToolsTitle => 'Ferramentas';

  @override
  String get homeToolsTitleEmpty => 'Comece por aqui';

  @override
  String get homeToolSafeShare => 'Safe share';

  @override
  String get homeToolSafeShareSubtitle => 'Esconda os dados privados primeiro';

  @override
  String get homeToolDuplicates => 'Encontrar duplicadas';

  @override
  String get homeToolDuplicatesSubtitle => 'Liberar espaço';

  @override
  String get homeToolSearch => 'Buscar dentro';

  @override
  String get homeToolSearchSubtitle => 'Encontre texto nas suas imagens';

  @override
  String get homeToolStitch => 'Juntar capturas longas';

  @override
  String get homeToolStitchSubtitle => 'Recomponha uma captura com rolagem';

  @override
  String get homeRecent => 'Recentes';

  @override
  String get libraryPickForMerge =>
      'Escolha duas ou mais capturas da mesma página';

  @override
  String get libraryPickForProtect => 'Escolha a captura a proteger';

  @override
  String get libraryActionProtect => 'Proteger';

  @override
  String get homeSeeAll => 'Ver todas';

  @override
  String get libraryEmptyTitle => 'Nada guardado ainda';

  @override
  String get libraryEmptyMessage =>
      'Compartilhe uma captura com o SHOTO, ou adicione uma com o botão +. A sua galeria nunca é lida — só fica o que você entrega.';

  @override
  String get libraryNoFavoritesTitle => 'Nenhuma favorita ainda';

  @override
  String get libraryNoFavoritesMessage =>
      'Toque no coração de uma captura para guardá-la aqui.';

  @override
  String get libraryFilterAll => 'Todas';

  @override
  String get libraryFilterFavorites => 'Favoritas';

  @override
  String get libraryTraitSensitive => 'Sensíveis';

  @override
  String get libraryTraitLink => 'Links';

  @override
  String get libraryTraitContact => 'Telefone ou e-mail';

  @override
  String get libraryTraitCode => 'Códigos';

  @override
  String get libraryTraitEvent => 'Datas';

  @override
  String get libraryCertaintyVerified => 'Verificado por checksum';

  @override
  String get libraryCertaintyRead => 'Lido do texto nas suas capturas';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count ainda não lidas';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return 'Nenhuma captura com $trait';
  }

  @override
  String get libraryNoTraitMessage => 'Nenhuma captura já lida contém isso.';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'Nada encontrado no que foi lido. $count capturas nunca foram lidas, então ainda não dá para casar com elas.';
  }

  @override
  String get libraryShowAll => 'Mostrar todas';

  @override
  String get libraryFilterUnsorted => 'Sem organizar';

  @override
  String get libraryNoUnsortedTitle => 'Está tudo arquivado';

  @override
  String get libraryNoUnsortedMessage =>
      'Nada espera por você. Capturas novas ficam aqui até você arquivar ou marcar.';

  @override
  String librarySelectedCount(int count) {
    return '$count selecionadas';
  }

  @override
  String get librarySelectAll => 'Selecionar tudo';

  @override
  String get libraryActionMerge => 'Juntar';

  @override
  String get libraryActionMove => 'Mover';

  @override
  String get libraryActionDelete => 'Excluir';

  @override
  String get libraryDeleteTitle => 'Excluir capturas?';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Isto vai excluir $count capturas do seu aparelho para sempre.',
      one: 'Isto vai excluir 1 captura do seu aparelho para sempre.',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'É preciso acesso às fotos';

  @override
  String get permissionNeededMessage =>
      'O SHOTO guarda as capturas que você compartilha com ele num álbum próprio. Ele precisa de acesso às fotos para escrever lá e lê-las de volta — o resto da sua galeria nunca é listado.';

  @override
  String get permissionAskTitle =>
      'O SHOTO precisa de ver o seu álbum de capturas';

  @override
  String get permissionAskMessage =>
      'Apenas esse álbum, e apenas para listar o que contém. Nada é enviado para a nuvem, e nada entra na tua biblioteca até tu escolheres.';

  @override
  String get permissionAllow => 'Permitir acesso';

  @override
  String get permissionPartialTitle => 'É preciso acesso total às fotos';

  @override
  String get permissionPartialMessage =>
      'No momento o SHOTO só vê algumas fotos que você escolheu à mão, então não alcança o próprio álbum. Escolha «Permitir todas» na permissão de fotos para continuar.';

  @override
  String get permissionOpenSettings => 'Abrir Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsGridDensity => 'Densidade da grade';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Igual ao meu telefone';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'Mostrando $language';
  }

  @override
  String get settingsBehaviour => 'Comportamento';

  @override
  String get settingsHaptics => 'Retorno tátil';

  @override
  String get settingsHapticsHint => 'Um toque leve quando você pressiona';

  @override
  String get settingsConfirmDelete => 'Perguntar antes de excluir';

  @override
  String get settingsConfirmDeleteHint => 'Excluir não dá para desfazer';

  @override
  String get settingsFindDuplicates => 'Encontrar duplicadas';

  @override
  String get settingsClearCache => 'Limpar cache de imagens';

  @override
  String get settingsShare => 'Compartilhar o SHOTO';

  @override
  String get settingsPrivacyNote =>
      'O SHOTO guarda só as capturas que você entrega, e tudo o que faz com elas — ler texto, encontrar duplicadas — acontece neste aparelho. As suas imagens nunca são enviadas. Três coisas são você quem liga: oferecer capturas novas lê o seu álbum de capturas para poder perguntar sobre elas, uma conta envia só o seu e-mail para a assinatura sobreviver a uma troca de telefone, e os relatórios de falha enviam o que quebrou — o código, nunca uma imagem.';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonRename => 'Renomear';

  @override
  String get commonShare => 'Compartilhar';

  @override
  String get commonUnlock => 'Desbloquear';

  @override
  String get foldersEmptyTitle => 'Nenhuma pasta ainda';

  @override
  String get foldersEmptyMessage =>
      'As pastas são como você encontra as coisas depois. Faça uma para recibos, uma para receitas — o que você realmente vai procurar.';

  @override
  String get foldersNew => 'Nova pasta';

  @override
  String get foldersCreate => 'Criar pasta';

  @override
  String get foldersNameLabel => 'Nome da pasta';

  @override
  String get foldersNameHint => 'Recibos, Receitas, Trabalho…';

  @override
  String get foldersPrivate => 'Privada (bloqueio por rosto ou digital)';

  @override
  String get foldersPrivateFace => 'Privada (bloqueio por rosto)';

  @override
  String get foldersPrivateFingerprint => 'Privada (bloqueio por digital)';

  @override
  String get foldersPrivateGeneric => 'Privada (bloqueada)';

  @override
  String get foldersOptions => 'Opções da pasta';

  @override
  String get foldersDelete => 'Excluir pasta';

  @override
  String get foldersDeleteKept => 'As capturas de dentro continuam';

  @override
  String foldersDeleteTitle(String name) {
    return 'Excluir «$name»?';
  }

  @override
  String get foldersDeleteMessage =>
      'A pasta some, mas as capturas de dentro continuam na sua biblioteca.';

  @override
  String get foldersRenameTitle => 'Renomear pasta';

  @override
  String get foldersMoveTitle => 'Mover para a pasta';

  @override
  String get foldersMoveRemove => 'Tirar da pasta';

  @override
  String get foldersMoveNone => 'Nenhuma pasta ainda. Crie uma na aba Pastas.';

  @override
  String folderLockedTitle(String name) {
    return 'Desbloquear «$name»';
  }

  @override
  String get folderLockedMessage =>
      'Esta pasta é protegida. Autentique-se para vê-la.';

  @override
  String get folderEmptyTitle => 'Ainda não há nada aqui';

  @override
  String get folderEmptyMessage =>
      'Mova capturas da sua biblioteca para esta pasta.';

  @override
  String get detailFavorite => 'Favorita';

  @override
  String get detailUnfavorite => 'Tirar dos favoritos';

  @override
  String get detailAddFavorite => 'Adicionar aos favoritos';

  @override
  String get detailActions => 'Ações';

  @override
  String get detailSafeShare => 'Safe share';

  @override
  String get detailMore => 'Mais';

  @override
  String get detailDeleteTitle => 'Excluir a captura?';

  @override
  String get detailDeleteMessage =>
      'Isto vai excluí-la do seu aparelho para sempre.';

  @override
  String get quickSaveTitleOne => 'Salvar no SHOTO';

  @override
  String quickSaveTitleMany(int count) {
    return 'Salvar $count capturas';
  }

  @override
  String get quickSaveFileOne => 'Arquivar esta captura';

  @override
  String quickSaveFileMany(int count) {
    return 'Arquivar $count capturas';
  }

  @override
  String get quickSavePickFolder => 'Escolha uma pasta';

  @override
  String get quickSaveNeedFolder => 'Crie uma pasta para colocá-las';

  @override
  String quickSaveFileIn(String folder) {
    return 'Arquivar em $folder';
  }

  @override
  String get quickSaveCreateFirstFolder => 'Crie a sua primeira pasta';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'As pastas são como você encontra as coisas depois';

  @override
  String get quickSaveNewChip => 'Nova';

  @override
  String get quickSaveSaved => 'Salvo no SHOTO';

  @override
  String quickSaveFiled(String folder) {
    return 'Arquivado em $folder.';
  }

  @override
  String get quickSaveFailedTitle => 'Não deu para ler essa imagem';

  @override
  String get quickSaveFailedBody => 'Tente compartilhar de novo.';

  @override
  String quickSaveSkipped(int count) {
    return 'Só as primeiras $count foram aceitas';
  }

  @override
  String get dupTitle => 'Encontrar duplicadas';

  @override
  String get dupScanning => 'Procurando duplicadas';

  @override
  String get dupReading => 'Lendo a sua biblioteca…';

  @override
  String dupProgress(int done, int total) {
    return '$done de $total capturas verificadas';
  }

  @override
  String get dupNoneTitle => 'Nenhuma duplicada encontrada';

  @override
  String get dupNoneBody => 'A sua biblioteca de capturas já está limpa.';

  @override
  String get dupScanAgain => 'Procurar de novo';

  @override
  String dupReclaimable(String size) {
    return 'Dá para liberar até $size';
  }

  @override
  String get dupNothingSelected => 'Nada selecionado';

  @override
  String dupDeleteButton(int count, String size) {
    return 'Excluir $count · liberar $size';
  }

  @override
  String dupDeleteTitle(int count) {
    return 'Excluir $count cópias?';
  }

  @override
  String get dupDeleteMessage =>
      'Isto as exclui do seu aparelho para sempre. As cópias marcadas para ficar não são afetadas.';

  @override
  String dupDeleted(int count, String size) {
    return '$count excluídas · $size liberados';
  }

  @override
  String dupSets(int count) {
    return '$count grupos';
  }

  @override
  String get dupBest => 'MELHOR';

  @override
  String get dupKeepAll => 'Ficar com todas';

  @override
  String get dupKeepingAll => 'Ficando com todas — nada será excluído';

  @override
  String get dupUndo => 'Desfazer';

  @override
  String dupFrees(String size) {
    return 'Libera $size';
  }

  @override
  String get safeShareTitle => 'Safe share';

  @override
  String get safeShareScanning => 'Verificando dados privados';

  @override
  String get safeShareOnDevice => 'A leitura acontece no seu telefone.';

  @override
  String get safeShareCleanTitle => 'Nada privado encontrado';

  @override
  String get safeShareCleanBody =>
      'Nesta captura não foram vistos números de cartão, números de conta, códigos nem contatos. Você pode compartilhá-la como está.';

  @override
  String get safeShareUnreadableTitle => 'Não deu para ler esta captura';

  @override
  String get safeShareUnreadableBody => 'O texto dela não foi reconhecido.';

  @override
  String get safeShareShareUnchanged => 'Compartilhar sem mudar';

  @override
  String get safeShareShareAnyway => 'Compartilhar mesmo assim';

  @override
  String get safeShareShareProtected => 'Compartilhar a cópia protegida';

  @override
  String get safeShareFailed => 'Não deu para montar a cópia protegida.';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados privados encontrados',
      one: '1 dado privado encontrado',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'Verificar é sempre grátis.';

  @override
  String get safeShareCleanAction => 'Limpar esta captura';

  @override
  String get safeShareShareAsIs => 'Compartilhar sem alterações';

  @override
  String get safeShareHowTitle => 'Tapado, de vez';

  @override
  String get safeShareHowBody =>
      'Cada dado privado é coberto com um bloco sólido antes de a cópia sair do seu telefone. Nada fica borrado e nada dá para ler de volta — a cópia coberta é a única versão que existe.';

  @override
  String get safeShareTreatmentCover => 'Cobrir';

  @override
  String get safeShareTreatmentKeep => 'Manter';

  @override
  String get safeShareBuilding => 'Montando a sua cópia limpa';

  @override
  String get safeShareNothingSelected => 'Nada vai mudar';

  @override
  String get safeShareLockedPreview => 'Desbloqueie para ver a versão limpa';

  @override
  String get safeShareReviewTitle => 'Confira uma por uma';

  @override
  String safeShareFound(int count) {
    return '$count coisas cobertas';
  }

  @override
  String get stitchTitle => 'Juntar capturas';

  @override
  String get stitchWorking => 'Procurando a sobreposição';

  @override
  String get stitchWorkingBody =>
      'Casando onde cada captura continua a anterior.';

  @override
  String get stitchFailed => 'Não deu para juntar';

  @override
  String get stitchSave => 'Salvar na galeria';

  @override
  String get stitchSaved => 'Salvo na sua galeria';

  @override
  String get stitchDiscard => 'Descartar';

  @override
  String get commonDone => 'Pronto';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get searchTitle => 'Buscar nas suas capturas';

  @override
  String get searchHint => 'Busque palavras ou o que a imagem mostra';

  @override
  String get searchIntro =>
      'Qualquer palavra escrita dentro de uma imagem, ou o que a imagem mostra — tente «gato», «animal», «comida» ou «recibo».';

  @override
  String get searchNoneTitle => 'Nenhum resultado';

  @override
  String searchNoneBody(String query) {
    return 'Aqui nada diz nem se parece com «$query».';
  }

  @override
  String get paywallTitle => 'Desbloquear o SHOTO Pro';

  @override
  String get paywallSubtitle => 'Tudo abaixo, numa assinatura só.';

  @override
  String get paywallMonthly => 'Mensal';

  @override
  String get paywallYearly => 'Anual';

  @override
  String paywallSave(int percent) {
    return 'Economize $percent%';
  }

  @override
  String get paywallContinue => 'Continuar';

  @override
  String get paywallUnavailable => 'Ainda não disponível';

  @override
  String get paywallRestore => 'Restaurar compras';

  @override
  String get paywallLegal =>
      'Renova automaticamente até você cancelar. Cancele quando quiser nos ajustes da sua conta na App Store ou no Google Play. Ao continuar você concorda com os nossos Termos de Serviço e a Política de Privacidade.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'SHOTO Pro';

  @override
  String get subPremiumBody => 'Todos os recursos desbloqueados para você.';

  @override
  String get subDevUnlock => 'Acesso de testador';

  @override
  String get subDevUnlockBody =>
      'Desbloqueado neste aparelho — não é uma assinatura de verdade';

  @override
  String get subUnlockEverything => 'Desbloquear tudo';

  @override
  String get proWelcomeTitle => 'Você está no Pro';

  @override
  String get proWelcomeBody =>
      'Todos os recursos estão desbloqueados. Não há mais nada para configurar.';

  @override
  String get proWelcomeAction => 'Começar a usar';

  @override
  String get featSafeShare => 'Safe share';

  @override
  String get featSafeShareBody =>
      'Encontra números de cartão, endereços, nomes e contatos e cobre cada um com um bloco sólido. O texto ao redor continua, então a imagem ainda faz sentido — e a cópia enviada não tem camada nenhuma para remover.';

  @override
  String get featActions => 'Transforme capturas em ações';

  @override
  String get featActionsBody =>
      'Abra um link, escreva para um endereço, copie um código de verificação ou um IBAN — direto da imagem, sem redigitar nada.';

  @override
  String get featDuplicates => 'Encontrar duplicadas';

  @override
  String get featDuplicatesBody =>
      'Acha capturas quase iguais que você guardou duas vezes e tira do caminho — sempre com uma revisão antes.';

  @override
  String get featStitch => 'Juntar capturas longas';

  @override
  String get featStitchBody =>
      'Recompõe uma captura com rolagem numa imagem alta só, achando e removendo a sobreposição sozinho.';

  @override
  String get featUnlimited => 'Sem teto para a sua biblioteca';

  @override
  String featUnlimitedBody(Object count) {
    return 'A versão grátis organiza $count capturas. O Pro tira o número.';
  }

  @override
  String get featSafeShareHow =>
      'Achar o que é privado numa captura é grátis e ilimitado. O que se paga é transformar esses achados numa cópia limpa: cada dado que você deixar marcado é coberto na imagem exportada, e essa imagem é plana, sem nenhuma camada para desfazer.';

  @override
  String get featSafeSharePoint1 =>
      'Números de cartão passam por Luhn e IBANs por módulo 97: esses dois são provados em vez de adivinhados, justo no dado que mais importa.';

  @override
  String get featSafeSharePoint2 =>
      'Também pega nomes, endereços, números de pedido, códigos de verificação, telefones e e-mails.';

  @override
  String get featSafeSharePoint3 =>
      'Você vê tudo que foi encontrado antes de enviar e pode deixar à mostra o que o app marcou errado. A captura original nunca é tocada.';

  @override
  String get featActionsHow =>
      'O que estiver escrito dentro de uma captura vira algo que dá para usar. O SHOTO separa as partes úteis e põe um botão em cada uma.';

  @override
  String get featActionsPoint1 =>
      'Links, e-mails, IBANs, códigos de verificação, datas e números de encomenda são achados para você.';

  @override
  String get featActionsPoint2 =>
      'Um toque para abrir ou copiar — sem ler caracteres de uma imagem.';

  @override
  String get featActionsPoint3 =>
      'Funciona nas capturas que você já tem, não só nas novas.';

  @override
  String get featStitchHow =>
      'A captura com rolagem, nos telefones que têm, precisa começar enquanto você ainda está na página. O SHOTO trabalha depois: escolha duas ou mais capturas já na sua biblioteca — inclusive as que alguém te mandou — e ele acha onde elas se sobrepõem e junta tudo numa imagem alta.';

  @override
  String get featStitchPoint1 =>
      'A faixa repetida entre duas capturas é achada e removida sozinha.';

  @override
  String get featStitchPoint2 =>
      'Você vê a emenda antes de salvar qualquer coisa — a detecção automática é boa, mas nunca certa.';

  @override
  String get featStitchPoint3 =>
      'A imagem juntada é salva na sua galeria como qualquer outra foto.';

  @override
  String get featDuplicatesHow =>
      'Compartilhar uma de cada vez raramente cria duplicadas. Guardar um lote de «Desde a última vez» cria — você vai rápido, e duas capturas da mesma coisa ficam as duas. O SHOTO compara pela aparência da captura, não pelo nome ou tamanho, então também pega um reenvio ou um corte diferente.';

  @override
  String get featDuplicatesPoint1 =>
      'Agrupa o que parece igual e sugere a cópia que vale a pena guardar.';

  @override
  String get featDuplicatesPoint2 =>
      'Mostra quanto espaço cada grupo libera antes de você decidir qualquer coisa.';

  @override
  String get featDuplicatesPoint3 =>
      'Nada é excluído até você rever o grupo e confirmar.';

  @override
  String get featUnlimitedHow =>
      'A versão grátis é um app de verdade e utilizável: salvar, pastas, favoritas e busca completa, sem conta e sem enviar nada. Ela tem exatamente um teto — quantas capturas organiza — e o Pro tira. Tudo o que você já organizou fica exatamente onde está.';

  @override
  String get featUnlimitedPoint1 =>
      'As pastas são ilimitadas na versão grátis, e sempre foi para ser assim.';

  @override
  String get featUnlimitedPoint2 =>
      'Dar nome ao que serve uma captura também é grátis e sem limite.';

  @override
  String get featUnlimitedPoint3 =>
      'Bater no teto quer dizer que o SHOTO virou o lugar onde você guarda as coisas. Nada é excluído quando isso acontece.';

  @override
  String get includedSubtitle => 'Cada recurso Pro, explicado.';

  @override
  String get includedHint => 'Toque num recurso para ver como funciona';

  @override
  String get includedHowLabel => 'Como funciona';

  @override
  String get includedActiveTitle => 'O seu plano está ativo';

  @override
  String get includedActiveBody => 'Tudo abaixo está desbloqueado nesta conta.';

  @override
  String get includedLockedTitle => 'Ainda não desbloqueado';

  @override
  String get includedLockedBody =>
      'Leia o que cada um faz de verdade e depois decida.';

  @override
  String get includedFreeTitle => 'O que a versão grátis te dá';

  @override
  String includedFreeBody(int count) {
    return '$count capturas organizadas, pastas ilimitadas e busca completa — grátis para sempre.';
  }

  @override
  String get onboardingCta => 'Começar';

  @override
  String get onboardingPromise => 'As suas capturas ficam no seu telefone.';

  @override
  String get actionsTitle => 'Ações';

  @override
  String get actionsWorking => 'Lendo a captura';

  @override
  String get actionsWorkingBody => 'Procurando números, links e códigos.';

  @override
  String get actionsNoneTitle => 'Nada para fazer';

  @override
  String get actionsNoneBody =>
      'Nesta captura não foram encontrados links, códigos nem números de conta.';

  @override
  String get actionsCopy => 'Copiar';

  @override
  String get actionsCopied => 'Copiado';

  @override
  String get actionsNoApp => 'Nenhum app deste aparelho consegue fazer isso.';

  @override
  String get devModeOn =>
      'Modo desenvolvedor ligado — todos os recursos desbloqueados';

  @override
  String get devModeBadge => 'MODO DESENVOLVEDOR';

  @override
  String get devModeOffTitle => 'Desligar o modo desenvolvedor?';

  @override
  String get devModeOffBody =>
      'O SHOTO volta para a versão grátis neste aparelho, para você testar o paywall e os limites de novo.';

  @override
  String get devModeOffConfirm => 'Desligar';

  @override
  String get devAccessTitle => 'Acesso de desenvolvedor';

  @override
  String get devAccessBody =>
      'Digite o código de 4 dígitos para desbloquear todos os recursos Pro neste aparelho.';

  @override
  String get devWrongCode => 'Código errado';

  @override
  String devTapToDisable(int count) {
    return 'Toque $count× para desligar';
  }

  @override
  String appVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get kindCard => 'um número de cartão';

  @override
  String get kindIban => 'uma conta bancária';

  @override
  String get kindCode => 'um código de verificação';

  @override
  String get kindNationalId => 'um número de documento';

  @override
  String get kindEmail => 'um endereço de e-mail';

  @override
  String get kindLink => 'um link';

  @override
  String get actionEmailAction => 'Escrever';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get kindEvent => 'um evento';

  @override
  String get kindPlace => 'um lugar';

  @override
  String get kindWifi => 'uma rede Wi-Fi';

  @override
  String get kindTracking => 'uma encomenda';

  @override
  String get actionAddToCalendar => 'Adicionar ao calendário';

  @override
  String get actionOpenMaps => 'Abrir no Maps';

  @override
  String get actionDirections => 'Como chegar';

  @override
  String get actionCopyNetwork => 'Copiar o nome';

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
      zero: 'Nenhuma captura',
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
      other: '$count grupos de duplicadas',
      one: '1 grupo de duplicadas',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count cópias parecidas';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coisas encontradas',
      one: '1 coisa encontrada',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'Armazenamento';

  @override
  String get settingsDuplicatesHint =>
      'Ache capturas que você tirou duas vezes';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'O que está incluído';

  @override
  String settingsFeatureCount(int count) {
    return '$count recursos, um plano';
  }

  @override
  String get settingsShareHint => 'Conte para alguém que precisa';

  @override
  String get settingsShareText =>
      'O SHOTO mantém as minhas capturas organizadas sozinho — fica tudo no telefone.';

  @override
  String get settingsCacheMeasuring => 'Medindo…';

  @override
  String settingsCacheSize(String size) {
    return '$size de miniaturas';
  }

  @override
  String get homeSafeShareHint => 'Abra uma captura e toque em Safe share.';

  @override
  String get homeStitchHint =>
      'Segure duas ou mais capturas na sua biblioteca e toque em Juntar.';

  @override
  String stitchLimit(int count) {
    return 'Junte até $count capturas por vez.';
  }

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Capturas salvas. Colocar numa pasta?',
      one: 'Captura salva. Colocar numa pasta?',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count capturas juntadas';
  }

  @override
  String stitchResultTrimmed(int count) {
    return '$count px de conteúdo repetido removidos';
  }

  @override
  String get errorLoadScreenshots => 'Não deu para carregar as suas capturas.';

  @override
  String get errorLoadFolders => 'Não deu para carregar as suas pastas.';

  @override
  String get errorScanDuplicates => 'Não deu para procurar duplicadas.';

  @override
  String get errorDeleteSelected =>
      'Não deu para excluir as capturas selecionadas.';

  @override
  String get errorStitchFailed => 'Não deu para juntar estas capturas.';

  @override
  String get errorStitchSave => 'Não deu para salvar a imagem juntada.';

  @override
  String get errorOnboarding => 'Não deu para carregar. Abra o app de novo.';

  @override
  String get errorSignInCancelled => 'A entrada foi cancelada.';

  @override
  String get errorSignInInterrupted =>
      'A entrada foi interrompida. Tente de novo.';

  @override
  String get errorNetwork => 'Erro de rede. Verifique a sua conexão.';

  @override
  String get errorGeneric => 'Algo deu errado. Tente de novo.';

  @override
  String get errorPlans => 'Não deu para carregar os planos de assinatura.';

  @override
  String get errorPurchase => 'A compra falhou. Tente de novo.';

  @override
  String get errorNoSubscription =>
      'Nenhuma assinatura ativa encontrada para esta conta.';

  @override
  String get errorRestore => 'Não deu para restaurar as compras.';

  @override
  String get errorStitchTooFew =>
      'Escolha pelo menos duas capturas para juntar.';

  @override
  String errorStitchTooMany(int count) {
    return 'Dá para juntar até $count capturas de uma vez.';
  }

  @override
  String get errorStitchUnreadable => 'Não deu para ler uma das capturas.';

  @override
  String get errorStitchWidths =>
      'Estas capturas têm larguras diferentes, então não podem ser da mesma rolagem.';

  @override
  String get errorStitchNoOverlap =>
      'Estas capturas não se sobrepõem. Juntar só funciona com capturas da mesma página feitas durante a rolagem.';

  @override
  String get errorStitchOverlap =>
      'Não deu para resolver a sobreposição entre estas capturas.';

  @override
  String get errorStitchTooTall =>
      'A imagem juntada ficaria alta demais. Tente juntar menos capturas.';

  @override
  String get errorStitchEncode => 'Não deu para codificar a imagem juntada.';

  @override
  String get errorRedactionSave => 'Não deu para salvar a cópia protegida.';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capturas salvas',
      one: 'Captura salva',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'Grande';

  @override
  String get densityMedium => 'Média';

  @override
  String get densitySmall => 'Pequena';

  @override
  String get sensitiveCard => 'Número de cartão';

  @override
  String get sensitiveIban => 'Conta bancária';

  @override
  String get sensitiveCode => 'Código de verificação';

  @override
  String get sensitiveNationalId => 'Número de documento';

  @override
  String get sensitiveEmail => 'Endereço de e-mail';

  @override
  String get sensitivePhone => 'Número de telefone';

  @override
  String get sensitiveAddress => 'Endereço';

  @override
  String get sensitiveName => 'Nome';

  @override
  String get sensitiveOrderNumber => 'Número do pedido';

  @override
  String get sensitiveNumber => 'Número';

  @override
  String get onbSkip => 'Pular';

  @override
  String get onbNext => 'Avançar';

  @override
  String get onbPileTitle => 'Mil capturas, uma pilha só';

  @override
  String get onbPileBody =>
      'Você captura para lembrar. Uma semana depois está enterrada embaixo de outras quatrocentas.';

  @override
  String get onbChooseTitle => 'O SHOTO nunca lê a sua galeria';

  @override
  String get onbChooseBody =>
      'Nada chega sozinho. É você que compartilha uma captura para dentro — a regra é essa.';

  @override
  String get onbSafeShareTitle => 'A captura que dá mesmo para enviar';

  @override
  String get onbSafeShareBody =>
      'O número do cartão fica sob um bloco sólido — a etiqueta ao lado continua, então a imagem ainda faz sentido. Você confere cada marcação antes de enviar.';

  @override
  String get onbFolderExample => 'Recibos';

  @override
  String get onbSearchExample => 'recibo';

  @override
  String get importTitle => 'Adicionar capturas';

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
  String get importFailed => 'Não deu para salvar essas capturas';

  @override
  String get homeToolImportSubtitle =>
      'Escolha do seu telefone — a galeria nunca é lida';

  @override
  String get importPickerUnavailable => 'O seletor de fotos não abriu';

  @override
  String get searchWorking => 'Lendo as suas capturas…';

  @override
  String get settingsBackup => 'Backup e restauração';

  @override
  String get settingsBackupHint =>
      'Guarde uma cópia da sua biblioteca num arquivo';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupIntro =>
      'A sua biblioteca vive neste telefone e em nenhum outro lugar. Um backup é a cópia que sobrevive à perda dele.';

  @override
  String get backupCreateTitle => 'Criar um backup';

  @override
  String get backupCreateBody =>
      'Empacota cada captura, pasta e etiqueta num arquivo só, e depois deixa você escolher onde guardar.';

  @override
  String get backupCreateAction => 'Criar backup';

  @override
  String get backupWorking => 'Empacotando a sua biblioteca…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots capturas salvas no backup',
      one: '1 captura salva no backup',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders pastas',
      one: '1 pasta',
    );
    return '$_temp0 e $_temp1';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots capturas salvas no backup',
      one: '1 captura salva no backup',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped não deu para ler',
      one: '1 não deu para ler',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get backupFailed => 'Não deu para terminar o backup';

  @override
  String get backupPrivacyNote =>
      'O arquivo é montado neste telefone e só vai para onde você mandar. Nada é enviado.';

  @override
  String get restoreTitle => 'Restaurar um backup';

  @override
  String get restoreBody =>
      'Adiciona tudo de um arquivo de backup a esta biblioteca. Nada do que já está aqui é removido.';

  @override
  String get restoreAction => 'Restaurar';

  @override
  String get restoreWorking => 'Colocando a sua biblioteca de volta…';

  @override
  String get restoreConfirmTitle => 'Restaurar este backup?';

  @override
  String get restoreConfirmMessage =>
      'Tudo o que está no arquivo é adicionado à sua biblioteca. As suas capturas atuais ficam exatamente como estão.';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots capturas restauradas',
      one: '1 captura restaurada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders pastas',
      one: '1 pasta',
    );
    return '$_temp0 e $_temp1';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots capturas restauradas',
      one: '1 captura restaurada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped foram puladas',
      one: '1 foi pulada',
    );
    return '$_temp0. $_temp1.';
  }

  @override
  String get restoreNotABackup => 'Esse arquivo não é um backup do SHOTO';

  @override
  String get restoreFailed => 'Não deu para terminar a restauração';

  @override
  String get settingsHelp => 'Ajuda';

  @override
  String get settingsContactSupport => 'Falar com o suporte';

  @override
  String get supportSubject => 'Suporte SHOTO';

  @override
  String get supportNoMailApp =>
      'Nenhum app de e-mail encontrado. O endereço foi copiado.';

  @override
  String get supportGreeting => 'Olá, equipe SHOTO,';

  @override
  String get dateToday => 'Hoje';

  @override
  String get dateYesterday => 'Ontem';

  @override
  String get dateThisWeek => 'No começo desta semana';

  @override
  String get dateThisMonth => 'No começo deste mês';

  @override
  String get librarySortNewest => 'Mais recentes primeiro';

  @override
  String get librarySortOldest => 'Mais antigas primeiro';

  @override
  String get librarySortLabel => 'Ordem';

  @override
  String get libraryShowOnly => 'Mostrar só';

  @override
  String get libraryShowEverything => 'Tudo';

  @override
  String libraryScanPrompt(int count) {
    return 'Ler $count capturas';
  }

  @override
  String get libraryScanning => 'Lendo…';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pastas já existem aqui',
      one: '1 pasta já existe aqui',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'Estes nomes estão na sua biblioteca e no backup. Mesmo nome nem sempre quer dizer mesma pasta, então esta é você quem decide.';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e mais $count',
      one: 'e mais 1',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'Juntar as duas';

  @override
  String get restoreClashMergeBody =>
      'As capturas vão para as pastas que você já tem.';

  @override
  String get restoreClashSeparate => 'Manter separadas';

  @override
  String get restoreClashSeparateBody =>
      'Cria uma segunda pasta com o mesmo nome. Nada do que existe é tocado.';

  @override
  String get intentBuy => 'Comprar';

  @override
  String get intentRead => 'Ler';

  @override
  String get intentReply => 'Responder';

  @override
  String get intentTry => 'Testar';

  @override
  String get intentVisit => 'Visitar';

  @override
  String get intentBuyWaiting => 'Para comprar';

  @override
  String get intentReadWaiting => 'Para ler';

  @override
  String get intentReplyWaiting => 'Para responder';

  @override
  String get intentTryWaiting => 'Para testar';

  @override
  String get intentVisitWaiting => 'Para visitar';

  @override
  String get intentWatch => 'Assistir';

  @override
  String get intentListen => 'Ouvir';

  @override
  String get intentCook => 'Cozinhar';

  @override
  String get intentBook => 'Reservar';

  @override
  String get intentPay => 'Pagar';

  @override
  String get intentSend => 'Enviar';

  @override
  String get intentDownload => 'Baixar';

  @override
  String get intentApply => 'Candidatar-se';

  @override
  String get intentCompare => 'Comparar';

  @override
  String get intentFix => 'Consertar';

  @override
  String get intentWatchWaiting => 'Para assistir';

  @override
  String get intentListenWaiting => 'Para ouvir';

  @override
  String get intentCookWaiting => 'Para cozinhar';

  @override
  String get intentBookWaiting => 'Para reservar';

  @override
  String get intentPayWaiting => 'Para pagar';

  @override
  String get intentSendWaiting => 'Para enviar';

  @override
  String get intentDownloadWaiting => 'Para baixar';

  @override
  String get intentApplyWaiting => 'Para se candidatar';

  @override
  String get intentCompareWaiting => 'Para comparar';

  @override
  String get intentFixWaiting => 'Para consertar';

  @override
  String get intentMore => 'Mais';

  @override
  String get intentSectionCommon => 'Prontos';

  @override
  String get intentSectionYours => 'Seus';

  @override
  String get intentYoursEmpty =>
      'Um verbo que você escreve funciona igualzinho aos de cima.';

  @override
  String get intentNewAction => 'Escreva o seu';

  @override
  String get intentNewTitle => 'Dê o nome você mesmo';

  @override
  String get intentEditTitle => 'Editar este';

  @override
  String get intentNameLabel => 'O verbo';

  @override
  String get intentNameHint => 'Devolver, cancelar, ligar para eles…';

  @override
  String get intentIconLabel => 'Ícone';

  @override
  String intentDeleteTitle(String label) {
    return 'Excluir «$label»?';
  }

  @override
  String get intentDeleteMessage =>
      'As capturas ficam onde estão. Só param de esperar por algo.';

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
  String get intentPrompt => 'Para que serve, se você quiser';

  @override
  String get intentSkip => 'Nada em especial';

  @override
  String get intentWaitingTitle => 'Esperando por você';

  @override
  String get intentNothingWaiting => 'Nada esperando por você';

  @override
  String get intentAllDone =>
      'Você terminou tudo o que tinha guardado para depois.';

  @override
  String get intentMarkDone => 'Feito';

  @override
  String get intentUndo => 'Colocar de volta';

  @override
  String get intentDoneToast => 'Riscado da lista';

  @override
  String get intentChange => 'Mudar para que isto serve';

  @override
  String get intentClear => 'Não é para nada';

  @override
  String intentEmptyOne(String verb) {
    return 'Aqui não há nada para $verb';
  }

  @override
  String get intentEmptyBody =>
      'As capturas que você marca ficam aqui até você riscar da lista.';

  @override
  String intentDoneCount(int count) {
    return '$count concluídas';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count semanas',
      one: 'há 1 semana',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há $count meses',
      one: 'há 1 mês',
    );
    return '$_temp0';
  }
}
