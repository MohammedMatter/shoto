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
  String get libraryTraitSensitive => 'حساسة';

  @override
  String get libraryTraitLink => 'روابط';

  @override
  String get libraryTraitContact => 'رقم أو إيميل';

  @override
  String get libraryTraitCode => 'رموز';

  @override
  String get libraryTraitEvent => 'مواعيد';

  @override
  String get libraryCertaintyVerified => 'مؤكدة بخوارزمية تحقق';

  @override
  String get libraryCertaintyRead => 'مقروءة من النص داخل صورك';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count لم تُقرأ بعد';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return 'ما في صور فيها $trait';
  }

  @override
  String get libraryNoTraitMessage =>
      'كل الصور المقروءة ما فيها ولا وحدة من هدول.';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'ما لقينا شي بالمقروء. في $count صورة ما انقرأت أبداً، فما بنقدر نطابقها بعد.';
  }

  @override
  String get libraryShowAll => 'اعرض الكل';

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
  String get foldersPrivateFace => 'خاص (قفل بالوجه)';

  @override
  String get foldersPrivateFingerprint => 'خاص (قفل بالبصمة)';

  @override
  String get foldersPrivateGeneric => 'خاص (مقفل)';

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
  String get quickSaveFailedTitle => 'ما قدرنا نقرأ الصورة';

  @override
  String get quickSaveFailedBody => 'جرّب تشاركها مرة ثانية.';

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
  String get featUnlimited => 'بلا سقف لمكتبتك';

  @override
  String featUnlimitedBody(Object count) {
    return 'المجاني بيرتّب $count لقطة. برو بيشيل الرقم كلياً.';
  }

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
      'النسخة المجانية تطبيق حقيقي بيشتغل: حفظ، مجلدات، مفضلة، وبحث كامل، بدون حساب وبدون ما يطلع إشي من جهازك. في سقف واحد بس — كم لقطة بيرتّب — وبرو بيشيله. وكل شي رتّبته بيضل مكانه بالضبط.';

  @override
  String get featUnlimitedPoint1 =>
      'المجلدات بلا حدود بالمجاني، وهيك المفروض تكون من البداية.';

  @override
  String get featUnlimitedPoint2 =>
      'وتسمية شو الهدف من اللقطة كمان مجانية وبلا عدد.';

  @override
  String get featUnlimitedPoint3 =>
      'لما توصل للسقف يعني SHOTO صار المكان اللي بتحفظ فيه. وما بينحذف إشي وقتها.';

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
  String includedFreeBody(int count) {
    return '$count لقطة مرتّبة، مجلدات بلا حدود، والبحث كامل — مجاناً للأبد.';
  }

  @override
  String get authWelcome => 'أهلاً بك في SHOTO';

  @override
  String get authSubtitle =>
      'ما بتحتاج حساب لتستخدم SHOTO. سجّل دخول بس إذا بدك تنقل اشتراكك لجهاز تاني.';

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
  String get kindEvent => 'موعد';

  @override
  String get kindPlace => 'مكان';

  @override
  String get kindWifi => 'شبكة واي فاي';

  @override
  String get kindTracking => 'شحنة';

  @override
  String get actionAddToCalendar => 'أضف للتقويم';

  @override
  String get actionOpenMaps => 'افتح بالخرائط';

  @override
  String get actionDirections => 'الاتجاهات';

  @override
  String get actionCopyNetwork => 'انسخ الاسم';

  @override
  String get actionTrack => 'تتبّع';

  @override
  String get actionEventUntitled => 'موعد';

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
  String get settingsSignIn => 'تسجيل الدخول';

  @override
  String get settingsSignInHint => 'اختياري. بيلزم بس لنقل اشتراكك لجهاز تاني.';

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
  String get searchWorking => 'عم يقرأ لقطاتك…';

  @override
  String get settingsBackup => 'نسخة احتياطية واسترجاع';

  @override
  String get settingsBackupHint => 'خلّي نسخة من مكتبتك بملف';

  @override
  String get backupTitle => 'النسخة الاحتياطية';

  @override
  String get backupIntro =>
      'مكتبتك موجودة بهالتلفون وبس. النسخة الاحتياطية هي النسخة يلي بتضل معك إذا ضاع.';

  @override
  String get backupCreateTitle => 'اعمل نسخة احتياطية';

  @override
  String get backupCreateBody =>
      'بيجمع كل اللقطات والمجلدات والتسميات بملف واحد، وبعدين بتختار وين بتحفظه.';

  @override
  String get backupCreateAction => 'اعمل نسخة';

  @override
  String get backupWorking => 'عم يجمّع مكتبتك…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots لقطة',
      few: '$screenshots لقطات',
      two: 'لقطتين',
      one: 'لقطة وحدة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders مجلد',
      few: '$folders مجلدات',
      two: 'مجلدين',
      one: 'مجلد واحد',
    );
    return 'انحفظ $_temp0 و$_temp1';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots لقطة',
      few: '$screenshots لقطات',
      two: 'لقطتين',
      one: 'لقطة وحدة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped ما انقرأت',
      few: '$skipped ما انقرأوا',
      two: 'تنتين ما انقرأوا',
      one: 'وحدة ما انقرأت',
    );
    return 'انحفظ $_temp0. في $_temp1.';
  }

  @override
  String get backupFailed => 'ما قدر يكمّل النسخة الاحتياطية';

  @override
  String get backupPrivacyNote =>
      'الملف بينعمل بهالتلفون وبيروح بس لوين ما تبعتو. ما في شي بينرفع.';

  @override
  String get restoreTitle => 'استرجاع نسخة';

  @override
  String get restoreBody =>
      'بيضيف كل شي من ملف النسخة لمكتبتك. ما بينشال شي موجود.';

  @override
  String get restoreAction => 'استرجاع';

  @override
  String get restoreWorking => 'عم يرجّع مكتبتك…';

  @override
  String get restoreConfirmTitle => 'ترجّع هالنسخة؟';

  @override
  String get restoreConfirmMessage =>
      'كل شي بالملف بينضاف لمكتبتك. لقطاتك الحالية بتضل متل ما هي بالظبط.';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots لقطة',
      few: '$screenshots لقطات',
      two: 'لقطتين',
      one: 'لقطة وحدة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders مجلد',
      few: '$folders مجلدات',
      two: 'مجلدين',
      one: 'مجلد واحد',
    );
    return 'انسترجع $_temp0 و$_temp1';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots لقطة',
      few: '$screenshots لقطات',
      two: 'لقطتين',
      one: 'لقطة وحدة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped انتخطّت',
      few: '$skipped انتخطّوا',
      two: 'تنتين انتخطّوا',
      one: 'وحدة انتخطّت',
    );
    return 'انسترجع $_temp0. في $_temp1.';
  }

  @override
  String get restoreNotABackup => 'هالملف مش نسخة احتياطية من SHOTO';

  @override
  String get restoreFailed => 'ما قدر يكمّل الاسترجاع';

  @override
  String get settingsHelp => 'المساعدة';

  @override
  String get settingsContactSupport => 'تواصل مع الدعم';

  @override
  String get supportSubject => 'دعم SHOTO';

  @override
  String get supportNoMailApp => 'ما في تطبيق إيميل. اننسخ العنوان بدالو.';

  @override
  String get supportGreeting => 'مرحبا فريق SHOTO،';

  @override
  String get dateToday => 'اليوم';

  @override
  String get dateYesterday => 'مبارح';

  @override
  String get dateThisWeek => 'هالأسبوع';

  @override
  String get dateThisMonth => 'هالشهر';

  @override
  String get librarySortNewest => 'الأحدث أولاً';

  @override
  String get librarySortOldest => 'الأقدم أولاً';

  @override
  String get librarySortLabel => 'الترتيب';

  @override
  String libraryScanPrompt(int count) {
    return 'اقرأ $count صورة';
  }

  @override
  String get libraryScanning => 'عم نقرأ…';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'في $count مجلد موجود عندك أصلاً',
      few: 'في $count مجلدات موجودة عندك أصلاً',
      two: 'في مجلدين موجودين عندك أصلاً',
      one: 'في مجلد موجود عندك أصلاً',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'هاي الأسماء موجودة بمكتبتك وبالنسخة. نفس الاسم مش دايماً نفس المجلد، فالقرار إلك إنت.';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'و $count غيرهم',
      few: 'و $count غيرهم',
      two: 'واثنين غيرهم',
      one: 'وواحد غيره',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'اجمعهم مع بعض';

  @override
  String get restoreClashMergeBody => 'الصور بتروح للمجلدات الموجودة عندك.';

  @override
  String get restoreClashSeparate => 'خليهم منفصلين';

  @override
  String get restoreClashSeparateBody =>
      'بيعمل مجلد تاني بنفس الاسم. ولا شي موجود بينمس.';

  @override
  String get intentBuy => 'أشتري';

  @override
  String get intentRead => 'أقرأ';

  @override
  String get intentReply => 'أرد';

  @override
  String get intentTry => 'أجرّب';

  @override
  String get intentVisit => 'أزور';

  @override
  String get intentBuyWaiting => 'للشراء';

  @override
  String get intentReadWaiting => 'للقراءة';

  @override
  String get intentReplyWaiting => 'للرد';

  @override
  String get intentTryWaiting => 'للتجربة';

  @override
  String get intentVisitWaiting => 'للزيارة';

  @override
  String get intentWatch => 'أشاهد';

  @override
  String get intentListen => 'أسمع';

  @override
  String get intentCook => 'أطبخ';

  @override
  String get intentBook => 'أحجز';

  @override
  String get intentPay => 'أدفع';

  @override
  String get intentSend => 'أبعت';

  @override
  String get intentDownload => 'أنزّل';

  @override
  String get intentApply => 'أقدّم';

  @override
  String get intentCompare => 'أقارن';

  @override
  String get intentFix => 'أصلّح';

  @override
  String get intentWatchWaiting => 'للمشاهدة';

  @override
  String get intentListenWaiting => 'للاستماع';

  @override
  String get intentCookWaiting => 'للطبخ';

  @override
  String get intentBookWaiting => 'للحجز';

  @override
  String get intentPayWaiting => 'للدفع';

  @override
  String get intentSendWaiting => 'للإرسال';

  @override
  String get intentDownloadWaiting => 'للتنزيل';

  @override
  String get intentApplyWaiting => 'للتقديم';

  @override
  String get intentCompareWaiting => 'للمقارنة';

  @override
  String get intentFixWaiting => 'للتصليح';

  @override
  String get intentMore => 'المزيد';

  @override
  String get intentSectionCommon => 'جاهزة';

  @override
  String get intentSectionYours => 'تبعك';

  @override
  String get intentYoursEmpty =>
      'أي كلمة بتكتبها بإيدك بتشتغل تمامًا زي اللي فوق.';

  @override
  String get intentNewAction => 'اكتب وحدة بإيدك';

  @override
  String get intentNewTitle => 'سمّيها بإيدك';

  @override
  String get intentEditTitle => 'عدّل هاي';

  @override
  String get intentNameLabel => 'الفعل';

  @override
  String get intentNameHint => 'أرجّعها، ألغيها، أتصل فيهم…';

  @override
  String get intentIconLabel => 'الأيقونة';

  @override
  String intentDeleteTitle(String label) {
    return 'تحذف \"$label\"؟';
  }

  @override
  String get intentDeleteMessage => 'الصور بتضل مكانها. بس بتبطّل تستنى إشي.';

  @override
  String get intentSelectionAction => 'حدّد ليش';

  @override
  String intentSelectionApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صور تحددت',
      one: 'صورة وحدة تحددت',
    );
    return '$_temp0';
  }

  @override
  String get intentPrompt => 'شو رح تعمل فيها؟';

  @override
  String get intentSkip => 'ولا إشي محدد';

  @override
  String get intentWaitingTitle => 'مستني منك';

  @override
  String get intentNothingWaiting => 'ما في إشي مستني';

  @override
  String get intentAllDone => 'خلّصت كل اللي حفظته لبعدين.';

  @override
  String get intentMarkDone => 'خلص';

  @override
  String get intentUndo => 'رجّعها';

  @override
  String get intentDoneToast => 'تم';

  @override
  String get intentChange => 'غيّر ليش حافظها';

  @override
  String get intentClear => 'مش لإشي';

  @override
  String intentEmptyOne(String verb) {
    return 'ما في إشي هون $verb';
  }

  @override
  String get intentEmptyBody => 'الصور اللي بتحددها بتيجي هون لحد ما تشطّبها.';

  @override
  String intentDoneCount(int count) {
    return '$count خلصت';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count يوم',
      few: 'من $count أيام',
      two: 'من يومين',
      one: 'من يوم',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count أسبوع',
      few: 'من $count أسابيع',
      two: 'من أسبوعين',
      one: 'من أسبوع',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count شهر',
      few: 'من $count شهور',
      two: 'من شهرين',
      one: 'من شهر',
    );
    return '$_temp0';
  }
}
