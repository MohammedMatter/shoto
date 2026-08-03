// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonRetry => 'حاول مرة ثانية';

  @override
  String get commonSomethingWentWrong => 'صار خطأ ما';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get navFolders => 'المجلدات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get tagline => 'لقطاتك، مرتّبة';

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingAfternoon => 'مساء الخير';

  @override
  String get homeGreetingEvening => 'مساء الخير';

  @override
  String get homeInboxEmpty => 'ما في شي محفوظ';

  @override
  String get homeInboxEmptySubtitle => 'شارك لقطة مع SHOTO لتبدأ';

  @override
  String get homeInboxClear => 'كله مرتّب';

  @override
  String get homeInboxClearSubtitle => 'ما في شي ينتظر الترتيب';

  @override
  String get homeInboxCountSubtitle => 'لقطات لسه ما رتّبتها';

  @override
  String get homeStatScreenshots => 'لقطات';

  @override
  String get homeStatFavorites => 'مفضّلة';

  @override
  String get homeStatFolders => 'مجلدات';

  @override
  String get homeToolsTitle => 'شو بيقدر يعمل SHOTO';

  @override
  String get homeToolSafeShare => 'مشاركة آمنة';

  @override
  String get homeToolSafeShareSubtitle => 'أخفِ التفاصيل الخاصة أولاً';

  @override
  String get homeToolDuplicates => 'كشف المكرر';

  @override
  String get homeToolDuplicatesSubtitle => 'وفّر مساحة';

  @override
  String get homeToolSearch => 'بحث داخل الصور';

  @override
  String get homeToolSearchSubtitle => 'دوّر على نص جوّا صورك';

  @override
  String get homeToolStitch => 'دمج اللقطات الطويلة';

  @override
  String get homeToolStitchSubtitle => 'اجمع لقطات التمرير بصورة وحدة';

  @override
  String get homeRecent => 'الأحدث';

  @override
  String get libraryPickForMerge => 'اختار لقطتين أو أكتر لنفس الصفحة';

  @override
  String get libraryPickForProtect => 'اختار اللقطة يلي بدك تحميها';

  @override
  String get libraryActionProtect => 'احمِ';

  @override
  String get homeToolsTitleShort => 'اعمل شي';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get libraryEmptyTitle => 'ما في شي محفوظ بعد';

  @override
  String get libraryEmptyMessage =>
      'شيّر لقطة لـSHOTO، أو أضفها بزر +. معرض صورك ما بينقرأ — بس اللي تعطيه بينحفظ.';

  @override
  String get libraryNoFavoritesTitle => 'ما في مفضّلة بعد';

  @override
  String get libraryNoFavoritesMessage =>
      'اضغط على القلب في أي لقطة لتنحفظ هون.';

  @override
  String get libraryFilterAll => 'الكل';

  @override
  String get libraryFilterFavorites => 'المفضّلة';

  @override
  String get libraryFilterUnsorted => 'غير مرتّبة';

  @override
  String get libraryNoUnsortedTitle => 'كل شي مرتّب';

  @override
  String get libraryNoUnsortedMessage =>
      'ما في شي مستنّيك. اللقطات الجديدة بتنزل هون لحدّ ما ترتّبها أو تحطّها بالمفضّلة.';

  @override
  String librarySelectedCount(int count) {
    return '$count محدّدة';
  }

  @override
  String get librarySelectAll => 'تحديد الكل';

  @override
  String get libraryActionMerge => 'دمج';

  @override
  String get libraryActionMove => 'نقل';

  @override
  String get libraryActionDelete => 'حذف';

  @override
  String get libraryDeleteTitle => 'حذف اللقطات؟';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رح تنحذف $count لقطة من جهازك نهائياً.',
      few: 'رح تنحذف $count لقطات من جهازك نهائياً.',
      two: 'رح تنحذف لقطتين من جهازك نهائياً.',
      one: 'رح تنحذف لقطة وحدة من جهازك نهائياً.',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'بدنا إذن الوصول للصور';

  @override
  String get permissionNeededMessage =>
      'SHOTO بيحفظ اللقطات اللي بتشاركها معه في ألبوم خاص فيه. بحاجة لإذن الصور ليكتب فيه ويقرأ منه — وما بيطّلع على باقي معرضك أبداً.';

  @override
  String get permissionPartialTitle => 'بدنا إذن كامل للصور';

  @override
  String get permissionPartialMessage =>
      'حالياً SHOTO بيشوف بس صور قليلة اخترتها بإيدك، فما بيقدر يوصل لألبومه. اختر «السماح للكل» لتكمل.';

  @override
  String get permissionOpenSettings => 'افتح الإعدادات';

  @override
  String get rulesTitle => 'القواعد';

  @override
  String get rulesSubtitle => 'ترتيب بيصير من دونك';

  @override
  String get rulesTeachHeadline => 'بطّل ترتّب لقطاتك بإيدك';

  @override
  String get rulesTeachIntro =>
      'القاعدة جملة وحدة: لما تكون اللقطة بهالشكل، حطّها بهالمجلد. اكتبها مرة، وكل لقطة بتطابقها بتروح لهناك لحالها — لحظة ما توصل.';

  @override
  String get rulesTeachExample =>
      'مثال: لما تحتوي اللقطة على رقم بطاقة ← حطّها في مجلد الفواتير.';

  @override
  String get rulesTeachStep1Title => '١. وصّف اللقطة';

  @override
  String get rulesTeachStep1Body =>
      'كلمة مكتوبة فيها، أو شي ظاهر بالصورة، أو بيانات خاصة جوّاها.';

  @override
  String get rulesTeachStep2Title => '٢. اختر المجلد';

  @override
  String get rulesTeachStep2Body => 'وين بدك اللقطات المطابقة تروح.';

  @override
  String get rulesTeachStep3Title => '٣. وخلص';

  @override
  String get rulesTeachStep3Body =>
      'من هون ورايح SHOTO بيرتّبها عنك. وتقدر كمان تشغّل قواعدك على اللقطات المنتظرة من قبل.';

  @override
  String get rulesTeachShow => 'كيف بتشتغل القواعد؟';

  @override
  String get rulesTeachHide => 'فهمت';

  @override
  String get rulesStartTemplates => 'أو ابدأ من مثال جاهز';

  @override
  String get rulesTemplateReceipts => 'فواتير وإيصالات';

  @override
  String get rulesTemplateReceiptsWhy =>
      'أي لقطة فيها رقم بطاقة أو مبلغ إجمالي';

  @override
  String get rulesTemplateTickets => 'تذاكر وحجوزات';

  @override
  String get rulesTemplateTicketsWhy => 'بطاقات صعود، حجوزات، تأكيدات طلبات';

  @override
  String get rulesTemplateCodes => 'رموز وكلمات سر';

  @override
  String get rulesTemplateCodesWhy => 'رموز التحقق وأي شي شكله كلمة سر';

  @override
  String get rulesTemplateAnimals => 'صور حيوانات';

  @override
  String get rulesTemplateAnimalsWhy =>
      'بتعتمد على اللي ظاهر بالصورة، مش على الكلام فيها';

  @override
  String get rulesTemplatePicked => 'اختر مجلد وبتكون جاهزة للحفظ.';

  @override
  String get rulesEmptyTitle => 'ما في قواعد بعد';

  @override
  String get rulesNew => 'قاعدة جديدة';

  @override
  String get rulesNeedFolderFirst =>
      'اعمل مجلد أول — القاعدة بحاجة لمكان تحطّ فيه.';

  @override
  String get rulesDeleteTitle => 'حذف هالقاعدة؟';

  @override
  String get rulesDeleteMessage => 'اللقطات اللي رتّبتها من قبل بتضل مكانها.';

  @override
  String rulesWhenIt(String summary) {
    return 'لما $summary';
  }

  @override
  String get rulesBacklogTitle => 'رتّب المتراكم';

  @override
  String get rulesBacklogIdle =>
      'بيشغّل قواعدك على اللقطات اللي لسه مش داخل أي مجلد. وأي شي رتّبته بإيدك بيضل زي ما هو.';

  @override
  String rulesBacklogRunning(int done, int total) {
    return 'بنفحص $done من $total…';
  }

  @override
  String get rulesBacklogNothing => 'ما ضل شي غير مرتّب.';

  @override
  String rulesBacklogResult(int filed, int examined) {
    return 'رتّبنا $filed من أصل $examined لقطة غير مرتّبة.';
  }

  @override
  String get rulesRunNow => 'شغّل القواعد هلق';

  @override
  String get ruleBuilderTitle => 'قاعدة جديدة';

  @override
  String get ruleBuilderIntro => 'سؤالين: شو بترتّب، ووين بتروح.';

  @override
  String get ruleBuilderFolderLabel => 'وين يروح؟';

  @override
  String get ruleBuilderConditionLabel => 'شو بدك يرتّب؟';

  @override
  String get ruleBuilderConditionsLabel => 'كمان بتطابق';

  @override
  String get ruleBuilderAddCondition => 'شرط تاني';

  @override
  String get ruleBuilderMatchAll => 'لازم كلهم';

  @override
  String get ruleBuilderMatchAny => 'واحد بكفي';

  @override
  String get ruleBuilderMatchAllHelp => 'لازم اللقطة تحقق كل وحدة فيهم.';

  @override
  String get ruleBuilderMatchAnyHelp => 'يكفي وحدة منهم تتحقق.';

  @override
  String get ruleBuilderSave => 'احفظ القاعدة';

  @override
  String get ruleBuilderIncomplete => 'اختر شو يرتّب، ووين يروح';

  @override
  String ruleBuilderPreview(String folder, String summary) {
    return 'حطّها في $folder لما اللقطة $summary.';
  }

  @override
  String get ruleBuilderPreviewTitle => 'قاعدتك بالكلمات';

  @override
  String get conditionTextContains => 'تحتوي كلمة';

  @override
  String get conditionTextContainsHelp =>
      'بيفحص النص اللي SHOTO بيقرأه جوّا الصورة، وبيطابق كلمات كاملة — \"كود\" ما رح تشتغل على \"باركود\". استخدم كلمة فعلاً بتكون مكتوبة على هيك نوع لقطات.';

  @override
  String get conditionTextContainsHint =>
      'كلمة مكتوبة فيها — «فاتورة»، «تذكرة»';

  @override
  String get conditionShowsSubject => 'بتُظهر شي';

  @override
  String get conditionShowsSubjectHelp =>
      'بيفحص شو *في* الصورة، مش شو مكتوب فيها. الكلمة لازم تطابق كلمة الموديل نفسها، فاضغط وحدة من مكتبتك تحت بدل ما تخمّن.';

  @override
  String get conditionShowsSubjectHint =>
      'شو ظاهر فيها — «قطة»، «حيوان»، «أكل»';

  @override
  String get conditionContainsSensitive => 'فيها بيانات خاصة';

  @override
  String get conditionContainsSensitiveHelp =>
      'نفس الفحوصات اللي بتستخدمها المشاركة الآمنة — أرقام البطاقات بتمرّ على تحقّق حقيقي، فرقم طلب ما بينحسب بطاقة.';

  @override
  String get conditionHasAnyText => 'فيها نص مقروء';

  @override
  String get conditionHasAnyTextHelp =>
      'بتتحقق لأي صورة فيها كلام أصلاً. مفيدة لفصل اللقطات عن الصور المحفوظة.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsTheme => 'الثيم';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'غامق';

  @override
  String get settingsGridDensity => 'كثافة الشبكة';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSystem => 'تابع لغة جهازي';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'المعروض حالياً $language';
  }

  @override
  String get settingsBehaviour => 'السلوك';

  @override
  String get settingsHaptics => 'الاهتزاز عند اللمس';

  @override
  String get settingsHapticsHint => 'نبضة خفيفة لما تضغط';

  @override
  String get settingsConfirmDelete => 'اسأل قبل الحذف';

  @override
  String get settingsConfirmDeleteHint => 'الحذف ما بينرجع';

  @override
  String get settingsAutomation => 'الأتمتة';

  @override
  String get settingsAutomationCaption =>
      'اكتب قاعدة مرة وحدة وSHOTO بيرتّب اللقطات المطابقة لحظة ما توصل.';

  @override
  String get settingsRules => 'قواعد الترتيب';

  @override
  String get settingsRulesHint => 'خلّي SHOTO يرتّب عنك';

  @override
  String get settingsFindDuplicates => 'كشف المكرر';

  @override
  String get settingsClearCache => 'مسح ذاكرة الصور المؤقتة';

  @override
  String get settingsShare => 'شارك SHOTO';

  @override
  String get settingsSignOut => 'تسجيل الخروج';

  @override
  String get settingsSignOutTitle => 'تسجيل الخروج؟';

  @override
  String get settingsPrivacyNote =>
      'SHOTO ما بيقرأ معرض صورك أبداً. بيحتفظ بس باللقطات اللي بتشاركها معه، وكل شي بيعمله فيها — قراءة النص، كشف المكرر — بيصير على جهازك. ولا شي بينرفع لأي مكان.';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonRename => 'إعادة تسمية';

  @override
  String get commonShare => 'مشاركة';

  @override
  String get commonUnlock => 'فتح';

  @override
  String get foldersEmptyTitle => 'ما في مجلدات بعد';

  @override
  String get foldersEmptyMessage =>
      'المجلدات هي طريقتك تلاقي أشياءك بعدين. اعمل واحد للفواتير، واحد للوصفات — أي شي فعلاً بتدوّر عليه.';

  @override
  String get foldersNew => 'مجلد جديد';

  @override
  String get foldersCreate => 'أنشئ المجلد';

  @override
  String get foldersNameLabel => 'اسم المجلد';

  @override
  String get foldersNameHint => 'فواتير، وصفات، شغل…';

  @override
  String get foldersPrivate => 'خاص (قفل بالوجه أو البصمة)';

  @override
  String get foldersOptions => 'خيارات المجلد';

  @override
  String get foldersDelete => 'حذف المجلد';

  @override
  String get foldersDeleteKept => 'اللقطات اللي جوّاه بتضل موجودة';

  @override
  String foldersDeleteTitle(String name) {
    return 'حذف «$name»؟';
  }

  @override
  String get foldersDeleteMessage =>
      'المجلد بينحذف بس اللقطات اللي جوّاه بتضل في مكتبتك.';

  @override
  String get foldersRenameTitle => 'إعادة تسمية المجلد';

  @override
  String get foldersMoveTitle => 'انقلها لمجلد';

  @override
  String get foldersMoveRemove => 'أخرجها من المجلد';

  @override
  String get foldersMoveNone => 'ما في مجلدات بعد. اعمل واحد من تاب المجلدات.';

  @override
  String folderLockedTitle(String name) {
    return 'افتح «$name»';
  }

  @override
  String get folderLockedMessage => 'هالمجلد محمي. أثبت هويتك لتشوفه.';

  @override
  String get folderEmptyTitle => 'ما في شي هون بعد';

  @override
  String get folderEmptyMessage => 'انقل لقطات لهالمجلد من مكتبتك.';

  @override
  String get detailFavorite => 'مفضّلة';

  @override
  String get detailUnfavorite => 'أخرجها من المفضّلة';

  @override
  String get detailAddFavorite => 'أضفها للمفضّلة';

  @override
  String get detailActions => 'إجراءات';

  @override
  String get detailSafeShare => 'مشاركة آمنة';

  @override
  String get detailDeleteTitle => 'حذف اللقطة؟';

  @override
  String get detailDeleteMessage => 'رح تنحذف من جهازك نهائياً.';

  @override
  String get quickSaveTitleOne => 'احفظها في SHOTO';

  @override
  String quickSaveTitleMany(int count) {
    return 'احفظ $count لقطات';
  }

  @override
  String get quickSaveFileOne => 'رتّب هاي اللقطة';

  @override
  String quickSaveFileMany(int count) {
    return 'رتّب $count لقطات';
  }

  @override
  String get quickSavePickFolder => 'اختر مجلد';

  @override
  String get quickSaveNeedFolder => 'اعمل مجلد تحطهم فيه';

  @override
  String quickSaveFileIn(String folder) {
    return 'رتّبها في $folder';
  }

  @override
  String get quickSaveCreateFirstFolder => 'أنشئ أول مجلد إلك';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'المجلدات هي طريقتك تلاقي أشياءك بعدين';

  @override
  String get quickSaveNewChip => 'جديد';

  @override
  String get quickSaveSaved => 'انحفظت في SHOTO';

  @override
  String quickSaveFiled(String folder) {
    return 'انرتّبت في $folder.';
  }

  @override
  String get quickSaveFiledByRules => 'انرتّبت حسب قواعدك.';

  @override
  String get quickSaveNoRuleMatched =>
      'ما في قاعدة طابقت — انحفظت بمكتبتك بدون ترتيب.';

  @override
  String get quickSaveFailedTitle => 'ما قدرنا نقرأ الصورة';

  @override
  String get quickSaveFailedBody => 'جرّب تشاركها مرة ثانية.';

  @override
  String get quickSaveSignedOutTitle => 'سجّل دخولك أولاً';

  @override
  String get quickSaveSignedOutBody =>
      'مكتبتك مربوطة بحسابك. افتح SHOTO، سجّل دخول، وبعدين شاركها من جديد.';

  @override
  String quickSaveSkipped(int count) {
    return 'أخذنا أول $count بس';
  }

  @override
  String get dupTitle => 'كشف المكرر';

  @override
  String get dupScanning => 'بندوّر على المكرر';

  @override
  String get dupReading => 'بنقرأ مكتبتك…';

  @override
  String dupProgress(int done, int total) {
    return 'فحصنا $done من $total لقطة';
  }

  @override
  String get dupNoneTitle => 'ما في مكرر';

  @override
  String get dupNoneBody => 'مكتبتك نظيفة أصلاً.';

  @override
  String get dupScanAgain => 'افحص من جديد';

  @override
  String dupReclaimable(String size) {
    return 'ممكن تفضي لحد $size';
  }

  @override
  String get dupNothingSelected => 'ما في شي محدّد';

  @override
  String dupDeleteButton(int count, String size) {
    return 'احذف $count · وفّر $size';
  }

  @override
  String dupDeleteTitle(int count) {
    return 'حذف $count نسخة؟';
  }

  @override
  String get dupDeleteMessage =>
      'رح ينحذفوا من جهازك نهائياً. والنسخ المعلّمة للاحتفاظ ما بتتأثر.';

  @override
  String dupDeleted(int count, String size) {
    return 'انحذفت $count · وفّرنا $size';
  }

  @override
  String dupSets(int count) {
    return '$count مجموعات';
  }

  @override
  String get dupBest => 'الأفضل';

  @override
  String get dupKeepAll => 'احتفظ بالكل';

  @override
  String get dupKeepingAll => 'محتفظين بالكل — ما رح ينحذف إشي';

  @override
  String get dupUndo => 'تراجع';

  @override
  String dupFrees(String size) {
    return 'بيوفّر $size';
  }

  @override
  String get safeShareTitle => 'مشاركة آمنة';

  @override
  String get safeShareScanning => 'بنفحص التفاصيل الخاصة';

  @override
  String get safeShareOnDevice => 'القراءة بتصير على جهازك.';

  @override
  String get safeShareCleanTitle => 'ما لقينا شي خاص';

  @override
  String get safeShareCleanBody =>
      'ما في أرقام بطاقات ولا حسابات ولا رموز ولا بيانات تواصل بهاي اللقطة. فيك تشاركها زي ما هي.';

  @override
  String get safeShareUnreadableTitle => 'ما قدرنا نقرأ هاي اللقطة';

  @override
  String get safeShareUnreadableBody => 'النص اللي فيها ما انقرأ.';

  @override
  String get safeShareShareUnchanged => 'شاركها زي ما هي';

  @override
  String get safeShareShareAnyway => 'شاركها برضو';

  @override
  String get safeShareShareProtected => 'شارك نسخة محمية';

  @override
  String get safeShareFailed => 'ما قدرنا نبني النسخة المحمية.';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لقينا $count بيانات حساسة',
      two: 'لقينا بيانين حساسين',
      one: 'لقينا بيان حساس واحد',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'الفحص مجاني دائماً.';

  @override
  String get safeShareCleanAction => 'نظّف الصورة';

  @override
  String get safeShareShareAsIs => 'مشاركة بدون تعديل';

  @override
  String get safeShareHowTitle => 'مطموس نهائياً';

  @override
  String get safeShareHowBody =>
      'كل بيان حساس بينتغطى بمربع أسود صامد قبل ما النسخة تطلع من تلفونك. ما في تمويه وما في إشي بينقرأ من ورا — النسخة المطموسة هي الوحيدة اللي بتوجد.';

  @override
  String get safeShareTreatmentCover => 'تغطية';

  @override
  String get safeShareTreatmentKeep => 'اتركه';

  @override
  String get safeShareBuilding => 'بجهّز النسخة النظيفة';

  @override
  String get safeShareNothingSelected => 'ما في إشي رح يتغيّر';

  @override
  String get safeShareLockedPreview => 'افتح الميزة لتشوف النسخة النظيفة';

  @override
  String get safeShareReviewTitle => 'راجع كل واحد';

  @override
  String safeShareFound(int count) {
    return 'غطّينا $count أشياء';
  }

  @override
  String get stitchTitle => 'دمج اللقطات';

  @override
  String get stitchWorking => 'بندوّر على التداخل';

  @override
  String get stitchWorkingBody => 'بنطابق وين كل لقطة بتكمّل من اللي قبلها.';

  @override
  String get stitchFailed => 'ما قدرنا ندمج';

  @override
  String get stitchSave => 'احفظها بالمعرض';

  @override
  String get stitchSaved => 'انحفظت بمعرضك';

  @override
  String get stitchDiscard => 'تجاهل';

  @override
  String get commonDone => 'تم';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get searchTitle => 'دوّر بلقطاتك';

  @override
  String get searchHint => 'كلمات أو شو ظاهر بالصورة';

  @override
  String get searchIntro =>
      'أي كلمة مكتوبة جوّا الصورة، أو شو ظاهر فيها — جرّب «قطة»، «حيوان»، «أكل» أو «فاتورة».';

  @override
  String get searchNoneTitle => 'ما في نتائج';

  @override
  String searchNoneBody(String query) {
    return 'ما في شي هون بيقرأ أو بيشبه «$query».';
  }

  @override
  String get paywallTitle => 'افتح SHOTO Pro';

  @override
  String get paywallSubtitle => 'كل اللي تحت، باشتراك واحد.';

  @override
  String get paywallMonthly => 'شهري';

  @override
  String get paywallYearly => 'سنوي';

  @override
  String paywallSave(int percent) {
    return 'وفّر $percent٪';
  }

  @override
  String get paywallContinue => 'متابعة';

  @override
  String get paywallUnavailable => 'لسا مش متاح';

  @override
  String get paywallRestore => 'استعادة المشتريات';

  @override
  String get paywallLegal =>
      'بيتجدد تلقائياً لحد ما تلغيه. تقدر تلغي بأي وقت من إعدادات حسابك في App Store أو Google Play. بمتابعتك بتوافق على شروط الخدمة وسياسة الخصوصية.';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'SHOTO Pro';

  @override
  String get subPremiumBody => 'كل الميزات مفتوحة إلك.';

  @override
  String get subDevUnlock => 'وصول تجريبي';

  @override
  String get subDevUnlockBody => 'مفتوح على هالجهاز بس — مش اشتراك حقيقي';

  @override
  String get subUnlockEverything => 'افتح كل شي';

  @override
  String get proWelcomeTitle => 'صرت على Pro';

  @override
  String get proWelcomeBody => 'كل الميزات مفتوحة. ما في شي تاني لازم تظبطه.';

  @override
  String get proWelcomeAction => 'يلا نبلش';

  @override
  String get featRules => 'قواعد بترتّب عنك';

  @override
  String get featRulesBody =>
      'اكتب قاعدة مرة، وكل لقطة بتشاركها بترتّب حالها. إنت كاتب القاعدة، فدايماً بتعرف ليش راح الشي لهناك.';

  @override
  String get featSearch => 'بحث جوّا لقطاتك';

  @override
  String get featSearchBody =>
      'لاقي أي لقطة من الكلمات المكتوبة فيها، بالعربي أو الإنجليزي. ولا شي بينرفع — القراءة بتصير على جهازك.';

  @override
  String get featSafeShare => 'مشاركة آمنة';

  @override
  String get featSafeShareBody =>
      'بيستبدل أرقام البطاقات والعناوين والأسماء وبيانات التواصل ببدائل واقعية — نفس الطول ونفس التنسيق ونفس المكان. النسخة اللي بتبعتها ما بتبيّن معدّلة.';

  @override
  String get featActions => 'حوّل اللقطة لأفعال';

  @override
  String get featActionsBody =>
      'اتصل برقم، افتح رابط، انسخ رمز تحقق أو IBAN — مباشرة من الصورة، بدون ما تعيد كتابة إشي.';

  @override
  String get featDuplicates => 'كشف المكرر';

  @override
  String get featDuplicatesBody =>
      'شوف اللقطات شبه المتطابقة اللي احتفظت فيها مرتين وامسحها — ودايماً في خطوة مراجعة قبل.';

  @override
  String get featStitch => 'دمج اللقطات الطويلة';

  @override
  String get featStitchBody =>
      'ارجع اجمع لقطات التمرير بصورة وحدة طويلة، والتداخل بينلاقى وبينشال تلقائياً.';

  @override
  String get featUnlimited => 'مجلدات ولقطات بلا حدود';

  @override
  String get featUnlimitedBody =>
      'النسخة المجانية بتوقف عند كم مجلد وكم سكرين شوت. Pro بتشيل الحدين.';

  @override
  String get featRulesHow =>
      'القاعدة جملة إنت بتكتبها بنفسك: لما تكون اللقطة هيك، حطها بهالمجلد. كل لقطة جديدة بتتفحص على قواعدك أول ما توصل، فالترتيب بيبطّل إشي لازم تتذكره.';

  @override
  String get featRulesPoint1 =>
      'طابق على كلمات مكتوبة جوّا الصورة، أو على شو ظاهر فيها، أو على وجود بيانات حساسة.';

  @override
  String get featRulesPoint2 =>
      'اطلب تتحقق كل شروطك أو أي واحد منها، وتقدر تعكس أي شرط.';

  @override
  String get featRulesPoint3 =>
      'ما في تخمين. إنت كاتب القاعدة، فدايماً بتعرف ليش راحت اللقطة لهناك.';

  @override
  String get featSearchHow =>
      'SHOTO بيقرأ النص المكتوب جوّا كل لقطة وبيحفظه، فكلمة وحدة متذكّرها بتكفي تلاقي الصورة من جديد — بدون أسماء ملفات ولا مجلدات ولا تمرير.';

  @override
  String get featSearchPoint1 =>
      'بيقرأ عربي وإنجليزي، وبيطابق حتى لو الإملاء اختلف شوي.';

  @override
  String get featSearchPoint2 =>
      'كمان بتلاقي حسب شو ظاهر بالصورة — جرّب «فاتورة» أو «قطة» أو «أكل».';

  @override
  String get featSearchPoint3 =>
      'القراءة بتصير على جهازك. ولا شي بينرفع، فبتشتغل حتى بدون إنترنت.';

  @override
  String get featSafeShareHow =>
      'كشف البيانات الحساسة في أي صورة مجاني وبدون حدود. الاشتراك هو اللي بيحوّل الكشف لنسخة نظيفة: كل بيان بينرسم من جديد بنفس ألوان الصورة كقيمة تانية عادية.';

  @override
  String get featSafeSharePoint1 =>
      'أرقام البطاقات بتتفحّص بـ Luhn والحسابات البنكية بـ mod-97 — والبدائل بتعدّي نفس الفحص، فما بتبيّن مفبركة.';

  @override
  String get featSafeSharePoint2 =>
      'بيمسك كمان الأسماء والعناوين وأرقام الطلبات ورموز التحقق وأرقام الهواتف والإيميلات.';

  @override
  String get featSafeSharePoint3 =>
      'بتشوف كل تغيير قبل ما تبعت، وبتقدر تغطّي أو تترك أي واحد بدل الاستبدال. الصورة الأصلية ما بتتغيّر أبداً.';

  @override
  String get featActionsHow =>
      'أي إشي مكتوب جوّا اللقطة بيصير إشي بتقدر تستعمله. SHOTO بيطلّع المفيد وبيحط عليه زر.';

  @override
  String get featActionsPoint1 =>
      'أرقام الهاتف والروابط والإيميلات والـ IBAN ورموز التحقق بتنلاقى إلك.';

  @override
  String get featActionsPoint2 =>
      'ضغطة وحدة للاتصال أو الفتح أو النسخ — بدون ما تقرأ أرقام من صورة.';

  @override
  String get featActionsPoint3 =>
      'بتشتغل على اللقطات اللي عندك من قبل، مش بس الجديدة.';

  @override
  String get featStitchHow =>
      'صوّر كم لقطة وإنت نازل بمحادثة أو صفحة طويلة، وSHOTO بيحسب وين بيتداخلوا وبيرجّعهم صورة وحدة طويلة.';

  @override
  String get featStitchPoint1 =>
      'الشريط المكرر بين كل لقطتين بينلاقى وبينشال تلقائياً.';

  @override
  String get featStitchPoint2 =>
      'بتشوف الوصلة قبل ما ينحفظ إشي — الكشف التلقائي منيح بس مش أكيد دايماً.';

  @override
  String get featStitchPoint3 => 'الصورة المدموجة بتنحفظ بمعرضك زي أي صورة.';

  @override
  String get featDuplicatesHow =>
      'SHOTO بيقارن اللقطات بشكلها مش باسمها ولا حجمها، فبيمسك كمان شبه المتطابقة — إعادة إرسال، قصّة تانية، أو نفس الإشي متصوّر مرتين.';

  @override
  String get featDuplicatesPoint1 =>
      'بيجمّع اللي بيشبه بعضه وبيقترح النسخة اللي بتستاهل تضل.';

  @override
  String get featDuplicatesPoint2 =>
      'بيبيّن قدّيش مساحة بتفضى من كل مجموعة قبل ما تقرر إشي.';

  @override
  String get featDuplicatesPoint3 =>
      'ولا شي بينمسح لحد ما تراجع المجموعة وتأكّد.';

  @override
  String get featUnlimitedHow =>
      'النسخة المجانية تطبيق حقيقي بينشتغل فيه، مش تجربة — بس إله سقف. Pro بتشيل السقف، وكل شي رتبته بيضل مكانه بالظبط.';

  @override
  String get featUnlimitedPoint1 => 'مجلدات قد ما مكتبتك بتحتاج فعلياً.';

  @override
  String get featUnlimitedPoint2 =>
      'ما في حد لعدد اللقطات اللي بترتبها وبتحطها بالمفضلة.';

  @override
  String get featUnlimitedPoint3 =>
      'الحفظ والمجلدات والمفضلة وسجل البحث بيضلوا إلك بالحالتين.';

  @override
  String get includedSubtitle => 'كل ميزة بـ Pro، مشروحة.';

  @override
  String get includedHint => 'اضغط على أي ميزة تشوف كيف بتشتغل';

  @override
  String get includedHowLabel => 'كيف بتشتغل';

  @override
  String get includedActiveTitle => 'اشتراكك فعّال';

  @override
  String get includedActiveBody => 'كل اللي تحت مفتوح على هالحساب.';

  @override
  String get includedLockedTitle => 'لسا مش مفتوحة';

  @override
  String get includedLockedBody => 'اقرأ شو بتعمل كل وحدة فعلياً، وبعدين قرّر.';

  @override
  String get includedFreeTitle => 'شو بيعطيك المجاني';

  @override
  String includedFreeBody(int folders, int count) {
    return '$folders مجلدات و$count لقطة مرتّبة — وكمان الحفظ والمفضلة والمعرض، مجاناً للأبد.';
  }

  @override
  String get authWelcome => 'أهلاً بك في SHOTO';

  @override
  String get authSubtitle =>
      'سجّل دخولك لتحفظ وترتّب وتلاقي كل لقطاتك بمكان واحد.';

  @override
  String get authGoogle => 'تابع باستخدام Google';

  @override
  String get authApple => 'تابع باستخدام Apple';

  @override
  String get authLegal => 'بمتابعتك، بتوافق على شروط الخدمة وسياسة الخصوصية.';

  @override
  String get onboardingCta => 'يلا نبدأ';

  @override
  String get onboardingPromise => 'كل شي بيضل على جهازك.';

  @override
  String get actionsTitle => 'إجراءات';

  @override
  String get actionsWorking => 'بنقرأ اللقطة';

  @override
  String get actionsWorkingBody => 'بندوّر على أرقام وروابط ورموز.';

  @override
  String get actionsNoneTitle => 'ما في شي تعمله';

  @override
  String get actionsNoneBody =>
      'ما لقينا أرقام هواتف ولا روابط ولا رموز ولا أرقام حسابات بهاي اللقطة.';

  @override
  String get actionsCopy => 'نسخ';

  @override
  String get actionsCopied => 'اننسخ';

  @override
  String get actionsNoApp => 'ما في تطبيق على جهازك بيقدر يعمل هيك.';

  @override
  String get devModeOn => 'وضع المطوّر شغّال — كل الميزات مفتوحة';

  @override
  String get devModeBadge => 'وضع المطوّر';

  @override
  String get devModeOffTitle => 'تطفّي وضع المطوّر؟';

  @override
  String get devModeOffBody =>
      'SHOTO رح يرجع للمجاني على هالجهاز، فتقدر تجرّب الاشتراك والحدود من جديد.';

  @override
  String get devModeOffConfirm => 'أطفئه';

  @override
  String get devAccessTitle => 'وصول المطوّر';

  @override
  String get devAccessBody =>
      'أدخل الرمز المكوّن من 4 أرقام لفتح كل ميزات Pro على هالجهاز.';

  @override
  String get devWrongCode => 'رمز خطأ';

  @override
  String devTapToDisable(int count) {
    return 'اضغط $count× لتطفّيه';
  }

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get ruleSummaryEmpty => 'ما في شروط بعد — ما بترتّب إشي';

  @override
  String get ruleJoinAnd => ' و';

  @override
  String get ruleJoinOr => ' أو ';

  @override
  String ruleSaysWord(String value) {
    return 'فيها «$value»';
  }

  @override
  String ruleNotSaysWord(String value) {
    return 'ما فيها «$value»';
  }

  @override
  String ruleShows(String value) {
    return 'بتُظهر $value';
  }

  @override
  String ruleNotShows(String value) {
    return 'ما بتُظهر $value';
  }

  @override
  String ruleContains(String value) {
    return 'فيها $value';
  }

  @override
  String ruleNotContains(String value) {
    return 'ما فيها $value';
  }

  @override
  String get ruleHasText => 'فيها نص مقروء';

  @override
  String get ruleNoText => 'ما فيها نص مقروء';

  @override
  String get kindCard => 'رقم بطاقة';

  @override
  String get kindIban => 'رقم حساب بنكي';

  @override
  String get kindCode => 'رمز تحقق';

  @override
  String get kindNationalId => 'رقم هوية';

  @override
  String get kindEmail => 'عنوان بريد';

  @override
  String get kindPhone => 'رقم هاتف';

  @override
  String get kindLink => 'رابط';

  @override
  String get actionCall => 'اتصال';

  @override
  String get actionWhatsapp => 'واتساب';

  @override
  String get actionSms => 'رسالة';

  @override
  String get actionEmailAction => 'اكتب';

  @override
  String get actionOpen => 'افتح';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لقطة',
      few: '$count لقطات',
      two: 'لقطتين',
      one: 'لقطة وحدة',
      zero: 'ما في لقطات',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$position من $total';
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
      other: '$count مجموعات مكررة',
      two: 'مجموعتين مكررات',
      one: 'مجموعة مكررة وحدة',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count نسخ متشابهة';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لقينا $count أشياء',
      two: 'لقينا شيئين',
      one: 'لقينا شي واحد',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'التخزين';

  @override
  String get settingsDuplicatesHint => 'شوف اللقطات اللي أخذتها مرتين';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'شو بيشمل';

  @override
  String settingsFeatureCount(int count) {
    return '$count ميزات، خطة واحدة';
  }

  @override
  String get settingsShareHint => 'خبّر حدا محتاجه';

  @override
  String get settingsShareText =>
      'SHOTO بيرتّب لقطاتي لحاله — وكل شي بيضل على الجوال.';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsSignOutHint => 'لقطاتك بتضل على هالجهاز';

  @override
  String get settingsCacheMeasuring => 'بنقيس…';

  @override
  String settingsCacheSize(String size) {
    return '$size من المصغّرات';
  }

  @override
  String get homeSafeShareHint => 'افتح لقطة، وبعدين اضغط مشاركة آمنة.';

  @override
  String get homeStitchHint =>
      'اضغط مطوّلاً على لقطتين أو أكتر بمكتبتك، وبعدين اضغط دمج.';

  @override
  String stitchLimit(int count) {
    return 'تقدر تدمج لحد $count لقطات بالمرة.';
  }

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'انحفظت اللقطات. بدك تحطهم بمجلد؟',
      one: 'انحفظت اللقطة. بدك تحطها بمجلد؟',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return 'اندمجت $count لقطات';
  }

  @override
  String stitchResultTrimmed(int count) {
    return 'انشال $count بكسل من المحتوى المكرر';
  }

  @override
  String get errorLoadScreenshots => 'ما قدرنا نحمّل لقطاتك.';

  @override
  String get errorLoadFolders => 'ما قدرنا نحمّل مجلداتك.';

  @override
  String get errorLoadRules => 'ما قدرنا نحمّل قواعدك.';

  @override
  String get errorScanDuplicates => 'ما قدرنا نفحص المكرر.';

  @override
  String get errorDeleteSelected => 'ما قدرنا نحذف اللقطات المحددة.';

  @override
  String get errorStitchFailed => 'ما قدرنا ندمج هاي اللقطات.';

  @override
  String get errorStitchSave => 'ما قدرنا نحفظ الصورة المدموجة.';

  @override
  String get errorOnboarding => 'ما قدرنا نحمّل. سكّر التطبيق وافتحه من جديد.';

  @override
  String get errorSignInCancelled => 'تم إلغاء تسجيل الدخول.';

  @override
  String get errorSignInInterrupted => 'انقطع تسجيل الدخول. جرّب مرة ثانية.';

  @override
  String get errorNetwork => 'خطأ بالشبكة. تأكد من اتصالك.';

  @override
  String get errorGeneric => 'صار خطأ ما. جرّب مرة ثانية.';

  @override
  String get errorPlans => 'ما قدرنا نحمّل خطط الاشتراك.';

  @override
  String get errorPurchase => 'فشل الشراء. جرّب مرة ثانية.';

  @override
  String get errorNoSubscription => 'ما في اشتراك فعّال لهالحساب.';

  @override
  String get errorRestore => 'ما قدرنا نستعيد المشتريات.';

  @override
  String get errorStitchTooFew => 'اختار لقطتين على الأقل للدمج.';

  @override
  String errorStitchTooMany(int count) {
    return 'بتقدر تدمج لحد $count لقطات بالمرة.';
  }

  @override
  String get errorStitchUnreadable => 'وحدة من اللقطات ما قدرنا نقراها.';

  @override
  String get errorStitchWidths =>
      'هاي اللقطات عرضها مختلف، فما بتكون من نفس التمرير.';

  @override
  String get errorStitchNoOverlap =>
      'هاي اللقطات ما بينها تداخل. الدمج بيشتغل بس على لقطات لنفس الصفحة مأخوذة وإنت بتمرّر.';

  @override
  String get errorStitchOverlap => 'ما قدرنا نحدد التداخل بين هاي اللقطات.';

  @override
  String get errorStitchTooTall =>
      'الصورة المدموجة رح تكون طويلة كتير. جرّب تدمج لقطات أقل.';

  @override
  String get errorStitchEncode => 'ما قدرنا نحفظ الصورة المدموجة.';

  @override
  String get errorRedactionSave => 'ما قدرنا نحفظ النسخة المحمية.';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'انحفظت $count لقطة',
      many: 'انحفظت $count لقطة',
      few: 'انحفظت $count لقطات',
      two: 'انحفظت لقطتين',
      one: 'انحفظت لقطة',
      zero: 'ما انحفظ شي',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'كبير';

  @override
  String get densityMedium => 'متوسط';

  @override
  String get densitySmall => 'صغير';

  @override
  String get sensitiveCard => 'رقم البطاقة';

  @override
  String get sensitiveIban => 'حساب بنكي';

  @override
  String get sensitiveCode => 'رمز تحقق';

  @override
  String get sensitiveNationalId => 'رقم هوية';

  @override
  String get sensitiveEmail => 'بريد إلكتروني';

  @override
  String get sensitivePhone => 'رقم تلفون';

  @override
  String get sensitiveAddress => 'العنوان';

  @override
  String get sensitiveName => 'الاسم';

  @override
  String get sensitiveOrderNumber => 'رقم الطلب';

  @override
  String get sensitiveNumber => 'رقم';

  @override
  String get quickSaveByRules => 'خلّي قواعدي ترتّبها';

  @override
  String get ruleSeenTitle => 'شو شاف SHOTO في مكتبتك';

  @override
  String get ruleSeenEmpty =>
      'SHOTO لسا ما فحص جوّا لقطاتك. بيقرأ كل وحدة لحظة ما توصل، فهاي بتمتلي مع الحفظ.';

  @override
  String get ruleSeenHint =>
      'اضغط على وحدة — هاي بالضبط الكلمات اللي بيطلعها النموذج، فالقاعدة المبنية عليها رح تشتغل فعلاً.';

  @override
  String get onbSkip => 'تخطّي';

  @override
  String get onbNext => 'التالي';

  @override
  String get onbPileTitle => 'ألف لقطة شاشة، كومة وحدة';

  @override
  String get onbPileBody =>
      'بتصوّر الشاشة عشان تتذكّر. بعد أسبوع بتكون مدفونة تحت أربعمية غيرها.';

  @override
  String get onbChooseTitle => '‏SHOTO ما بيقرأ معرض صورك';

  @override
  String get onbChooseBody =>
      'ما في إشي بيوصل لحاله. إنت بتشارك اللقطة معه — وهاي كل القاعدة.';

  @override
  String get onbFileTitle => 'بتنحفظ بمكانها لحظة ما تبعتها';

  @override
  String get onbFileBody =>
      'اختار المجلد من شيت المشاركة نفسه. التطبيق ولا بيفتح.';

  @override
  String get onbFindTitle => 'دوّر على اللي جوّاها';

  @override
  String get onbFindBody =>
      'الكلمات المكتوبة داخل اللقطة، وكمان اللي الصورة بتوريه. اكتب «فاتورة»، أو «قطة».';

  @override
  String get onbProTitle => '‏SHOTO Pro';

  @override
  String get onbProBody =>
      'قواعد بترتّب اللقطات الجديدة عنك، وكل اللي تحت بيجي معها.';

  @override
  String onbProMore(int count) {
    return 'و$count غيرها';
  }

  @override
  String get onbFolderExample => 'فواتير';

  @override
  String get onbSearchExample => 'فاتورة';

  @override
  String get importTitle => 'أضف لقطات';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمّ استيراد $count لقطة',
      few: 'تمّ استيراد $count لقطات',
      two: 'تمّ استيراد لقطتين',
      one: 'تمّ استيراد لقطة',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return 'تمّ استيراد $imported من $picked';
  }

  @override
  String get importFailed => 'ما قدرت أحفظ هاي اللقطات';

  @override
  String get homeToolImportSubtitle => 'اختَر من تلفونك — معرض صورك ما بينقرأ';

  @override
  String get importPickerUnavailable => 'ما قدر يفتح معرض الاختيار';

  @override
  String rulePreviewMatches(int count, int indexed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رح تاخد $count لقطة من $indexed لقطة قرأها SHOTO',
      one: 'رح تاخد لقطة وحدة من $indexed لقطة قرأها SHOTO',
    );
    return '$_temp0';
  }

  @override
  String get rulePreviewNone => 'ما في شي من اللي قرأه SHOTO بيطابق هالقاعدة';

  @override
  String get rulePreviewNotIndexed =>
      'SHOTO لسا ما قرأ ولا لقطة من لقطاتك، فما في شي نجرّب عليه. بيقرأ كل وحدة أول ما توصل.';

  @override
  String rulePreviewTaken(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منهن بيروحوا لقاعدة فوق هاي.',
      one: 'وحدة منهن بتروح لقاعدة فوق هاي.',
    );
    return '$_temp0';
  }

  @override
  String get rulePreviewAllTaken =>
      'كل اللقطات اللي بتطابق هاي القاعدة مآخوذة أصلاً من قاعدة فوقها. ارفع هاي القاعدة لفوق إذا بدك ياها تكسب.';

  @override
  String get rulePreviewFloor =>
      'بيحسب بس اللي قرأه SHOTO لهلق. اللقطات الجديدة بتنفحص أول ما توصل.';

  @override
  String get ruleBuilderEditTitle => 'تعديل القاعدة';

  @override
  String get ruleBuilderEditIntro =>
      'التعديلات بتشتغل من هلق ورايح. اللقطات اللي رتّبتها القاعدة من قبل بتضل بمكانها.';

  @override
  String get ruleBuilderUpdate => 'حفظ التعديلات';

  @override
  String get rulesPriorityNote =>
      'اللقطة بتروح لأول قاعدة بتطابقها. استخدم الأسهم لتغيّر مين الأول.';

  @override
  String get rulesCardNotIndexed => 'لسا ما انقرأ إشي — ما في شي نفحص عليه';

  @override
  String rulesCardClaims(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بتاخد $count لقطة',
      one: 'بتاخد لقطة وحدة',
    );
    return '$_temp0';
  }

  @override
  String get rulesCardClaimsNone => 'لسا ما بتاخد ولا لقطة';

  @override
  String rulesCardOverruled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تطابقات بيروحوا لقاعدة فوقها',
      one: 'تطابق وحد بيروح لقاعدة فوقها',
    );
    return '$_temp0';
  }

  @override
  String get rulesMoveUp => 'رفع لفوق';

  @override
  String get rulesMoveDown => 'نزول لتحت';

  @override
  String rulesBacklogUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'في $count لقطة لسا ما انقرأت — شغّل مرة تانية لتكمّل.',
      one: 'في لقطة وحدة لسا ما انقرأت — شغّل مرة تانية لتكمّل.',
    );
    return '$_temp0';
  }

  @override
  String indexingProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لسا عم يقرأ لقطاتك — باقي $count',
      one: 'لسا عم يقرأ لقطاتك — باقي وحدة',
    );
    return '$_temp0';
  }

  @override
  String get ruleBuilderMatches => 'بتطابق';

  @override
  String get ruleBuilderMatchesNot => 'ما بتطابق';

  @override
  String get ruleBuilderMatchesNotHelp =>
      'القاعدة بتشتغل لما هالشي ما يكون موجود — مفيدة لاستثناء حالات معيّنة.';

  @override
  String rulePreviewAlreadyFiled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count منهن مرتّبين أصلاً بمجلدات، والتشغيل ما بيحرّك المرتّبة أبداً. بس اللقطات الجديدة رح تنرتّب هون.',
      one:
          'وحدة منهن مرتّبة أصلاً بمجلد، والتشغيل ما بيحرّك المرتّبة أبداً. بس اللقطات الجديدة رح تنرتّب هون.',
    );
    return '$_temp0';
  }

  @override
  String rulesCardAlreadyFiled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بتطابق $count، بس هنّ مرتّبين أصلاً بمكان تاني',
      one: 'بتطابق وحدة، بس هي مرتّبة أصلاً بمكان تاني',
    );
    return '$_temp0';
  }
}
