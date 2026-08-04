// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get commonCancel => 'منسوخ کریں';

  @override
  String get commonDelete => 'حذف کریں';

  @override
  String get commonRetry => 'دوبارہ کوشش کریں';

  @override
  String get commonSomethingWentWrong => 'کچھ غلط ہو گیا';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'ہوم';

  @override
  String get navLibrary => 'لائبریری';

  @override
  String get navFolders => 'فولڈرز';

  @override
  String get navSettings => 'ترتیبات';

  @override
  String get tagline => 'آپ کے اسکرین شاٹس، ترتیب سے';

  @override
  String get homeGreetingMorning => 'صبح بخیر';

  @override
  String get homeGreetingAfternoon => 'دوپہر بخیر';

  @override
  String get homeGreetingEvening => 'شام بخیر';

  @override
  String get homeInboxEmpty => 'کچھ محفوظ نہیں';

  @override
  String get homeInboxEmptySubtitle =>
      'شروع کرنے کے لیے کوئی اسکرین شاٹ SHOTO میں شیئر کریں';

  @override
  String get homeInboxClear => 'سب ترتیب میں ہے';

  @override
  String get homeInboxClearSubtitle => 'ترتیب کے انتظار میں کچھ نہیں';

  @override
  String get homeInboxCountSubtitle =>
      'وہ اسکرین شاٹس جو آپ نے ابھی فائل نہیں کیے';

  @override
  String get homeStatScreenshots => 'اسکرین شاٹس';

  @override
  String get homeStatFavorites => 'پسندیدہ';

  @override
  String get homeStatFolders => 'فولڈرز';

  @override
  String get homeToolsTitle => 'SHOTO کیا کر سکتا ہے';

  @override
  String get homeToolSafeShare => 'محفوظ اشتراک';

  @override
  String get homeToolSafeShareSubtitle => 'پہلے نجی تفصیلات چھپائیں';

  @override
  String get homeToolDuplicates => 'نقول تلاش کریں';

  @override
  String get homeToolDuplicatesSubtitle => 'جگہ خالی کریں';

  @override
  String get homeToolSearch => 'تصویر کے اندر تلاش';

  @override
  String get homeToolSearchSubtitle => 'اپنی تصویروں میں لکھا متن ڈھونڈیں';

  @override
  String get homeToolStitch => 'لمبے اسکرین شاٹ جوڑیں';

  @override
  String get homeToolStitchSubtitle => 'اسکرول کی گئی تصویریں ایک میں ملائیں';

  @override
  String get homeRecent => 'حالیہ';

  @override
  String get libraryPickForMerge =>
      'ایک ہی صفحے کے دو یا زیادہ اسکرین شاٹ چنیں';

  @override
  String get libraryPickForProtect => 'وہ اسکرین شاٹ چنیں جسے محفوظ کرنا ہے';

  @override
  String get libraryActionProtect => 'محفوظ کریں';

  @override
  String get homeToolsTitleShort => 'کچھ کریں';

  @override
  String get homeSeeAll => 'سب دیکھیں';

  @override
  String get libraryEmptyTitle => 'ابھی کچھ محفوظ نہیں';

  @override
  String get libraryEmptyMessage =>
      'کوئی اسکرین شاٹ SHOTO کو شیئر کریں، یا + بٹن سے شامل کریں۔ آپ کی گیلری کبھی نہیں پڑھی جاتی — صرف وہی محفوظ ہوتا ہے جو آپ دیں۔';

  @override
  String get libraryNoFavoritesTitle => 'ابھی کوئی پسندیدہ نہیں';

  @override
  String get libraryNoFavoritesMessage =>
      'کسی اسکرین شاٹ پر دل دبائیں تو وہ یہاں آ جائے گا۔';

  @override
  String get libraryFilterAll => 'سب';

  @override
  String get libraryFilterFavorites => 'پسندیدہ';

  @override
  String get libraryTraitSensitive => 'حساس';

  @override
  String get libraryTraitLink => 'لنکس';

  @override
  String get libraryTraitContact => 'فون یا ای میل';

  @override
  String get libraryTraitCode => 'کوڈز';

  @override
  String get libraryTraitEvent => 'تاریخیں';

  @override
  String get libraryCertaintyVerified => 'چیک سم سے تصدیق شدہ';

  @override
  String get libraryCertaintyRead => 'آپ کے اسکرین شاٹس کے متن سے پڑھا گیا';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count ابھی تک نہیں پڑھے گئے';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return '$trait والا کوئی اسکرین شاٹ نہیں';
  }

  @override
  String get libraryNoTraitMessage =>
      'پڑھے گئے کسی بھی اسکرین شاٹ میں یہ نہیں ہے۔';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'پڑھے گئے میں کچھ نہیں ملا۔ $count اسکرین شاٹس کبھی نہیں پڑھے گئے، اس لیے وہ ابھی میچ نہیں ہو سکتے۔';
  }

  @override
  String get libraryShowAll => 'سب دکھائیں';

  @override
  String get libraryFilterUnsorted => 'غیر ترتیب شدہ';

  @override
  String get libraryNoUnsortedTitle => 'سب کچھ ترتیب میں ہے';

  @override
  String get libraryNoUnsortedMessage =>
      'آپ کا کچھ باقی نہیں۔ نئے اسکرین شاٹ یہاں آتے ہیں جب تک آپ انہیں فولڈر میں نہ رکھیں یا پسندیدہ نہ بنائیں۔';

  @override
  String librarySelectedCount(int count) {
    return '$count منتخب';
  }

  @override
  String get librarySelectAll => 'سب منتخب کریں';

  @override
  String get libraryActionMerge => 'جوڑیں';

  @override
  String get libraryActionMove => 'منتقل کریں';

  @override
  String get libraryActionDelete => 'حذف کریں';

  @override
  String get libraryDeleteTitle => 'اسکرین شاٹس حذف کریں؟';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'یہ آپ کے آلے سے $count اسکرین شاٹس ہمیشہ کے لیے حذف کر دے گا۔',
      one: 'یہ آپ کے آلے سے 1 اسکرین شاٹ ہمیشہ کے لیے حذف کر دے گا۔',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'تصاویر تک رسائی درکار ہے';

  @override
  String get permissionNeededMessage =>
      'SHOTO آپ کے شیئر کیے گئے اسکرین شاٹس اپنے الگ البم میں رکھتا ہے۔ اس میں لکھنے اور پڑھنے کے لیے اجازت چاہیے — یہ آپ کی باقی گیلری کبھی نہیں دیکھتا۔';

  @override
  String get permissionPartialTitle => 'مکمل رسائی درکار ہے';

  @override
  String get permissionPartialMessage =>
      'اس وقت SHOTO صرف چند منتخب تصویریں دیکھ سکتا ہے، اس لیے اپنے البم تک نہیں پہنچ پاتا۔ جاری رکھنے کے لیے «سب کی اجازت» منتخب کریں۔';

  @override
  String get permissionOpenSettings => 'ترتیبات کھولیں';

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get settingsAppearance => 'ظاہری شکل';

  @override
  String get settingsTheme => 'تھیم';

  @override
  String get settingsThemeSystem => 'سسٹم';

  @override
  String get settingsThemeLight => 'روشن';

  @override
  String get settingsThemeDark => 'گہرا';

  @override
  String get settingsGridDensity => 'گرڈ کثافت';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get settingsLanguageSystem => 'میرے فون کے مطابق';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'اس وقت $language';
  }

  @override
  String get settingsBehaviour => 'طرزِ عمل';

  @override
  String get settingsHaptics => 'لمس پر ارتعاش';

  @override
  String get settingsHapticsHint => 'دبانے پر ہلکی سی تھپکی';

  @override
  String get settingsConfirmDelete => 'حذف سے پہلے پوچھیں';

  @override
  String get settingsConfirmDeleteHint => 'حذف واپس نہیں ہو سکتا';

  @override
  String get settingsFindDuplicates => 'نقول تلاش کریں';

  @override
  String get settingsClearCache => 'تصویری کیش صاف کریں';

  @override
  String get settingsShare => 'SHOTO شیئر کریں';

  @override
  String get settingsSignOut => 'سائن آؤٹ';

  @override
  String get settingsSignOutTitle => 'سائن آؤٹ کریں؟';

  @override
  String get settingsPrivacyNote =>
      'SHOTO آپ کی گیلری کبھی نہیں پڑھتا۔ یہ صرف وہی اسکرین شاٹس رکھتا ہے جو آپ اس میں شیئر کریں، اور ان کے ساتھ جو کچھ کرتا ہے — متن پڑھنا، نقول ڈھونڈنا — سب اسی آلے پر ہوتا ہے۔ کچھ بھی کہیں اپ لوڈ نہیں ہوتا۔';

  @override
  String get commonSave => 'محفوظ کریں';

  @override
  String get commonConfirm => 'تصدیق کریں';

  @override
  String get commonRename => 'نام بدلیں';

  @override
  String get commonShare => 'شیئر کریں';

  @override
  String get commonUnlock => 'کھولیں';

  @override
  String get foldersEmptyTitle => 'ابھی کوئی فولڈر نہیں';

  @override
  String get foldersEmptyMessage =>
      'فولڈر ہی وہ طریقہ ہیں جس سے آپ بعد میں چیزیں ڈھونڈتے ہیں۔ ایک رسیدوں کے لیے بنائیں، ایک ترکیبوں کے لیے — جو بھی آپ واقعی ڈھونڈتے ہیں۔';

  @override
  String get foldersNew => 'نیا فولڈر';

  @override
  String get foldersCreate => 'فولڈر بنائیں';

  @override
  String get foldersNameLabel => 'فولڈر کا نام';

  @override
  String get foldersNameHint => 'رسیدیں، ترکیبیں، کام…';

  @override
  String get foldersPrivate => 'نجی (چہرہ یا فنگر پرنٹ لاک)';

  @override
  String get foldersPrivateFace => 'نجی (چہرے کا لاک)';

  @override
  String get foldersPrivateFingerprint => 'نجی (فنگر پرنٹ لاک)';

  @override
  String get foldersPrivateGeneric => 'نجی (مقفل)';

  @override
  String get foldersOptions => 'فولڈر کے اختیارات';

  @override
  String get foldersDelete => 'فولڈر حذف کریں';

  @override
  String get foldersDeleteKept => 'اندر کے اسکرین شاٹس محفوظ رہیں گے';

  @override
  String foldersDeleteTitle(String name) {
    return '«$name» حذف کریں؟';
  }

  @override
  String get foldersDeleteMessage =>
      'فولڈر ہٹ جائے گا لیکن اندر کے اسکرین شاٹس آپ کی لائبریری میں رہیں گے۔';

  @override
  String get foldersRenameTitle => 'فولڈر کا نام بدلیں';

  @override
  String get foldersMoveTitle => 'فولڈر میں منتقل کریں';

  @override
  String get foldersMoveRemove => 'فولڈر سے نکالیں';

  @override
  String get foldersMoveNone =>
      'ابھی کوئی فولڈر نہیں۔ فولڈرز ٹیب سے ایک بنائیں۔';

  @override
  String folderLockedTitle(String name) {
    return '«$name» کھولیں';
  }

  @override
  String get folderLockedMessage =>
      'یہ فولڈر محفوظ ہے۔ دیکھنے کے لیے تصدیق کریں۔';

  @override
  String get folderEmptyTitle => 'یہاں ابھی کچھ نہیں';

  @override
  String get folderEmptyMessage =>
      'اپنی لائبریری سے اسکرین شاٹس اس فولڈر میں لے آئیں۔';

  @override
  String get detailFavorite => 'پسندیدہ';

  @override
  String get detailUnfavorite => 'پسندیدہ سے ہٹائیں';

  @override
  String get detailAddFavorite => 'پسندیدہ میں شامل کریں';

  @override
  String get detailActions => 'اقدامات';

  @override
  String get detailSafeShare => 'محفوظ اشتراک';

  @override
  String get detailDeleteTitle => 'اسکرین شاٹ حذف کریں؟';

  @override
  String get detailDeleteMessage =>
      'یہ آپ کے آلے سے ہمیشہ کے لیے حذف ہو جائے گا۔';

  @override
  String get quickSaveTitleOne => 'SHOTO میں محفوظ کریں';

  @override
  String quickSaveTitleMany(int count) {
    return '$count اسکرین شاٹس محفوظ کریں';
  }

  @override
  String get quickSaveFileOne => 'یہ اسکرین شاٹ فائل کریں';

  @override
  String quickSaveFileMany(int count) {
    return '$count اسکرین شاٹس فائل کریں';
  }

  @override
  String get quickSavePickFolder => 'فولڈر منتخب کریں';

  @override
  String get quickSaveNeedFolder => 'انہیں رکھنے کے لیے فولڈر بنائیں';

  @override
  String quickSaveFileIn(String folder) {
    return '$folder میں فائل کریں';
  }

  @override
  String get quickSaveCreateFirstFolder => 'اپنا پہلا فولڈر بنائیں';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'فولڈر ہی وہ طریقہ ہیں جس سے آپ بعد میں چیزیں ڈھونڈتے ہیں';

  @override
  String get quickSaveNewChip => 'نیا';

  @override
  String get quickSaveSaved => 'SHOTO میں محفوظ ہو گیا';

  @override
  String quickSaveFiled(String folder) {
    return '$folder میں فائل ہو گیا۔';
  }

  @override
  String get quickSaveFailedTitle => 'یہ تصویر پڑھی نہیں جا سکی';

  @override
  String get quickSaveFailedBody => 'دوبارہ شیئر کر کے دیکھیں۔';

  @override
  String get quickSaveSignedOutTitle => 'پہلے SHOTO میں سائن ان کریں';

  @override
  String get quickSaveSignedOutBody =>
      'آپ کی لائبریری آپ کے اکاؤنٹ سے جڑی ہے۔ SHOTO کھولیں، سائن ان کریں، پھر دوبارہ شیئر کریں۔';

  @override
  String quickSaveSkipped(int count) {
    return 'صرف پہلے $count لیے گئے';
  }

  @override
  String get dupTitle => 'نقول تلاش کریں';

  @override
  String get dupScanning => 'نقول تلاش کی جا رہی ہیں';

  @override
  String get dupReading => 'آپ کی لائبریری پڑھی جا رہی ہے…';

  @override
  String dupProgress(int done, int total) {
    return '$total میں سے $done جانچے گئے';
  }

  @override
  String get dupNoneTitle => 'کوئی نقل نہیں ملی';

  @override
  String get dupNoneBody => 'آپ کی لائبریری پہلے ہی صاف ہے۔';

  @override
  String get dupScanAgain => 'دوبارہ اسکین کریں';

  @override
  String dupReclaimable(String size) {
    return '$size تک جگہ خالی ہو سکتی ہے';
  }

  @override
  String get dupNothingSelected => 'کچھ منتخب نہیں';

  @override
  String dupDeleteButton(int count, String size) {
    return '$count حذف کریں · $size خالی';
  }

  @override
  String dupDeleteTitle(int count) {
    return '$count نقول حذف کریں؟';
  }

  @override
  String get dupDeleteMessage =>
      'یہ انہیں آپ کے آلے سے ہمیشہ کے لیے حذف کر دے گا۔ رکھی جانے والی نقول متاثر نہیں ہوں گی۔';

  @override
  String dupDeleted(int count, String size) {
    return '$count حذف · $size خالی';
  }

  @override
  String dupSets(int count) {
    return '$count سیٹ';
  }

  @override
  String get dupBest => 'بہترین';

  @override
  String get dupKeepAll => 'سب رکھیں';

  @override
  String get dupKeepingAll => 'سب رکھے جا رہے ہیں — کچھ حذف نہیں ہوگا';

  @override
  String get dupUndo => 'واپس';

  @override
  String dupFrees(String size) {
    return '$size خالی کرے گا';
  }

  @override
  String get safeShareTitle => 'محفوظ اشتراک';

  @override
  String get safeShareScanning => 'نجی تفصیلات کی جانچ ہو رہی ہے';

  @override
  String get safeShareOnDevice => 'پڑھنے کا عمل آپ کے فون پر ہوتا ہے۔';

  @override
  String get safeShareCleanTitle => 'کوئی نجی چیز نہیں ملی';

  @override
  String get safeShareCleanBody =>
      'اس اسکرین شاٹ میں کوئی کارڈ نمبر، اکاؤنٹ نمبر، کوڈ یا رابطہ تفصیل نہیں ملی۔ آپ اسے ویسے ہی شیئر کر سکتے ہیں۔';

  @override
  String get safeShareUnreadableTitle => 'یہ اسکرین شاٹ پڑھا نہیں جا سکا';

  @override
  String get safeShareUnreadableBody => 'اس میں موجود متن پہچانا نہیں جا سکا۔';

  @override
  String get safeShareShareUnchanged => 'ویسے ہی شیئر کریں';

  @override
  String get safeShareShareAnyway => 'پھر بھی شیئر کریں';

  @override
  String get safeShareShareProtected => 'محفوظ نقل شیئر کریں';

  @override
  String get safeShareFailed => 'محفوظ نقل نہیں بن سکی۔';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نجی تفصیلات ملیں',
      one: '1 نجی تفصیل ملی',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'جانچ ہمیشہ مفت ہے۔';

  @override
  String get safeShareCleanAction => 'یہ اسکرین شاٹ صاف کریں';

  @override
  String get safeShareShareAsIs => 'بغیر تبدیلی شیئر کریں';

  @override
  String get safeShareHowTitle => 'مستقل طور پر چھپا ہوا';

  @override
  String get safeShareHowBody =>
      'نقل آپ کے فون سے نکلنے سے پہلے ہر نجی تفصیل ٹھوس بلاک سے ڈھک دی جاتی ہے۔ نہ دھندلاہٹ، نہ واپس پڑھنے کا راستہ — ڈھکی ہوئی نقل ہی واحد نقل ہے۔';

  @override
  String get safeShareTreatmentCover => 'ڈھانپیں';

  @override
  String get safeShareTreatmentKeep => 'رہنے دیں';

  @override
  String get safeShareBuilding => 'آپ کی صاف نقل تیار ہو رہی ہے';

  @override
  String get safeShareNothingSelected => 'کچھ تبدیل نہیں ہوگا';

  @override
  String get safeShareLockedPreview => 'صاف نسخہ دیکھنے کے لیے کھولیں';

  @override
  String get safeShareReviewTitle => 'ہر ایک کو دیکھیں';

  @override
  String safeShareFound(int count) {
    return '$count چیزیں ڈھانپی گئیں';
  }

  @override
  String get stitchTitle => 'اسکرین شاٹس جوڑیں';

  @override
  String get stitchWorking => 'اوورلیپ تلاش کیا جا رہا ہے';

  @override
  String get stitchWorkingBody =>
      'ملایا جا رہا ہے کہ ہر اسکرین شاٹ پچھلے سے کہاں جُڑتا ہے۔';

  @override
  String get stitchFailed => 'جوڑا نہیں جا سکا';

  @override
  String get stitchSave => 'گیلری میں محفوظ کریں';

  @override
  String get stitchSaved => 'آپ کی گیلری میں محفوظ ہو گئی';

  @override
  String get stitchDiscard => 'رد کریں';

  @override
  String get commonDone => 'ہو گیا';

  @override
  String get commonBack => 'واپس';

  @override
  String get commonClose => 'بند کریں';

  @override
  String get searchTitle => 'اپنے اسکرین شاٹس میں تلاش کریں';

  @override
  String get searchHint => 'الفاظ یا تصویر میں جو دکھے';

  @override
  String get searchIntro =>
      'تصویر کے اندر لکھا کوئی لفظ، یا تصویر میں جو دکھے — «بلی»، «جانور»، «کھانا» یا «رسید» آزمائیں۔';

  @override
  String get searchNoneTitle => 'کوئی نتیجہ نہیں';

  @override
  String searchNoneBody(String query) {
    return 'یہاں کچھ بھی «$query» جیسا نہیں پڑھا یا دکھائی دیا۔';
  }

  @override
  String get paywallTitle => 'SHOTO Pro کھولیں';

  @override
  String get paywallSubtitle => 'نیچے سب کچھ، ایک ہی سبسکرپشن میں۔';

  @override
  String get paywallMonthly => 'ماہانہ';

  @override
  String get paywallYearly => 'سالانہ';

  @override
  String paywallSave(int percent) {
    return '$percent% بچائیں';
  }

  @override
  String get paywallContinue => 'جاری رکھیں';

  @override
  String get paywallUnavailable => 'ابھی دستیاب نہیں';

  @override
  String get paywallRestore => 'خریداریاں بحال کریں';

  @override
  String get paywallLegal =>
      'منسوخ کرنے تک خودکار تجدید ہوتی رہے گی۔ آپ کسی بھی وقت اپنے App Store یا Google Play اکاؤنٹ سے منسوخ کر سکتے ہیں۔ جاری رکھنے سے آپ ہماری شرائط اور رازداری کی پالیسی سے متفق ہوتے ہیں۔';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'SHOTO Pro';

  @override
  String get subPremiumBody => 'ہر فیچر آپ کے لیے کھلا ہے۔';

  @override
  String get subDevUnlock => 'ٹیسٹر رسائی';

  @override
  String get subDevUnlockBody => 'صرف اسی آلے پر کھلا — اصل سبسکرپشن نہیں';

  @override
  String get subUnlockEverything => 'سب کچھ کھولیں';

  @override
  String get proWelcomeTitle => 'آپ Pro پر ہیں';

  @override
  String get proWelcomeBody =>
      'ہر فیچر کھل گیا ہے۔ اور کچھ سیٹ کرنے کی ضرورت نہیں۔';

  @override
  String get proWelcomeAction => 'شروع کریں';

  @override
  String get featSearch => 'اسکرین شاٹس کے اندر تلاش';

  @override
  String get featSearchBody =>
      'اس میں لکھے الفاظ سے کوئی بھی اسکرین شاٹ ڈھونڈیں، عربی یا انگریزی میں۔ کچھ اپ لوڈ نہیں ہوتا — پڑھنا آپ کے فون پر ہوتا ہے۔';

  @override
  String get featSafeShare => 'محفوظ اشتراک';

  @override
  String get featSafeShareBody =>
      'کارڈ نمبر، پتے، نام اور رابطے کی تفصیلات کی جگہ حقیقت کے قریب متبادل رکھ دیتا ہے — وہی لمبائی، وہی ساخت، وہی جگہ۔ جو نقل آپ بھیجتے ہیں وہ ترمیم شدہ نہیں لگتی۔';

  @override
  String get featActions => 'اسکرین شاٹ کو عمل میں بدلیں';

  @override
  String get featActionsBody =>
      'نمبر پر کال کریں، لنک کھولیں، تصدیقی کوڈ یا IBAN کاپی کریں — سیدھا تصویر سے، کچھ دوبارہ لکھے بغیر۔';

  @override
  String get featDuplicates => 'نقول تلاش کریں';

  @override
  String get featDuplicatesBody =>
      'تقریباً ایک جیسے اسکرین شاٹ پہچانیں جو دو بار رکھے گئے اور انہیں ہٹا دیں — ہمیشہ پہلے جائزے کے ساتھ۔';

  @override
  String get featStitch => 'لمبے اسکرین شاٹ جوڑیں';

  @override
  String get featStitchBody =>
      'اسکرول کی گئی تصویریں دوبارہ ایک لمبی تصویر میں جوڑیں، اوورلیپ خود ڈھونڈ کر ہٹا دیا جاتا ہے۔';

  @override
  String get featUnlimited => 'لامحدود فولڈر اور اسکرین شاٹس';

  @override
  String get featUnlimitedBody =>
      'مفت درجہ چند فولڈرز اور اسکرین شاٹس پر رک جاتا ہے۔ Pro دونوں حدیں ہٹا دیتا ہے۔';

  @override
  String get featSearchHow =>
      'SHOTO ہر اسکرین شاٹ کے اندر لکھا متن پڑھ کر یاد رکھتا ہے، سو یاد آیا ہوا ایک لفظ ہی تصویر دوبارہ ڈھونڈنے کے لیے کافی ہے — نہ فائل کے نام، نہ فولڈر، نہ اسکرول۔';

  @override
  String get featSearchPoint1 =>
      'عربی اور انگریزی پڑھتا ہے، اور املا تھوڑا مختلف ہو تب بھی مماثلت پا لیتا ہے۔';

  @override
  String get featSearchPoint2 =>
      'تصویر میں جو دکھ رہا ہے اُس سے بھی ڈھونڈتا ہے — «رسید»، «بلی» یا «کھانا» آزمائیں۔';

  @override
  String get featSearchPoint3 =>
      'پڑھنے کا کام آپ کے فون پر ہوتا ہے۔ کچھ اپ لوڈ نہیں ہوتا، اس لیے آف لائن بھی چلتا ہے۔';

  @override
  String get featSafeShareHow =>
      'اسکرین شاٹ میں نجی تفصیلات ڈھونڈنا ہمیشہ مفت اور بلا حد ہے۔ ادائیگی ان تفصیلات کو صاف نقل میں بدلتی ہے: ہر تفصیل اسکرین شاٹ کے اپنے رنگوں میں ایک اور عام قدر کے طور پر دوبارہ لکھی جاتی ہے۔';

  @override
  String get featSafeSharePoint1 =>
      'کارڈ نمبر Luhn سے اور IBAN mod-97 سے جانچے جاتے ہیں — اور متبادل بھی وہی جانچ پاس کرتے ہیں، اس لیے کچھ بھی بناوٹی نہیں لگتا۔';

  @override
  String get featSafeSharePoint2 =>
      'نام، پتے، آرڈر نمبر، تصدیقی کوڈ، فون نمبر اور ای میل پتے بھی پکڑتا ہے۔';

  @override
  String get featSafeSharePoint3 =>
      'بھیجنے سے پہلے ہر تبدیلی نظر آتی ہے، اور آپ اس کی جگہ ڈھانپنا یا رہنے دینا چن سکتے ہیں۔ اصل اسکرین شاٹ کبھی نہیں بدلتا۔';

  @override
  String get featActionsHow =>
      'اسکرین شاٹ کے اندر جو کچھ لکھا ہے وہ قابلِ استعمال بن جاتا ہے۔ SHOTO کام کی چیزیں نکال کر ہر ایک پر ایک بٹن لگا دیتا ہے۔';

  @override
  String get featActionsPoint1 =>
      'فون نمبر، لنکس، ای میل پتے، IBAN اور تصدیقی کوڈ آپ کے لیے ڈھونڈ لیے جاتے ہیں۔';

  @override
  String get featActionsPoint2 =>
      'کال کرنے، کھولنے یا نقل کرنے کے لیے ایک ٹیپ — تصویر سے ہندسے پڑھنے کی ضرورت نہیں۔';

  @override
  String get featActionsPoint3 =>
      'آپ کے پاس پہلے سے موجود اسکرین شاٹس پر بھی چلتا ہے، صرف نئے پر نہیں۔';

  @override
  String get featStitchHow =>
      'لمبی گفتگو یا صفحہ اسکرول کرتے ہوئے چند شاٹ لیں، اور SHOTO معلوم کر لیتا ہے کہ وہ کہاں ایک دوسرے پر آتے ہیں اور انہیں ایک لمبی تصویر میں جوڑ دیتا ہے۔';

  @override
  String get featStitchPoint1 =>
      'دو شاٹس کے درمیان دہرائی گئی پٹی خود بخود پہچانی اور ہٹائی جاتی ہے۔';

  @override
  String get featStitchPoint2 =>
      'کچھ محفوظ کرنے سے پہلے آپ جوڑ دیکھ لیتے ہیں — خودکار شناخت اچھی ہے، مگر کبھی مکمل یقینی نہیں۔';

  @override
  String get featStitchPoint3 =>
      'جُڑی ہوئی تصویر باقی تصویروں کی طرح آپ کی گیلری میں محفوظ ہو جاتی ہے۔';

  @override
  String get featDuplicatesHow =>
      'SHOTO اسکرین شاٹس کا موازنہ نام یا حجم سے نہیں، شکل سے کرتا ہے — اس لیے تقریباً ایک جیسی نقلیں بھی پکڑ لیتا ہے: دوبارہ بھیجی گئی، مختلف کٹائی، یا دو بار لیا گیا وہی منظر۔';

  @override
  String get featDuplicatesPoint1 =>
      'جو ایک جیسا دکھتا ہے اسے گروہ میں رکھتا ہے اور رکھنے کے قابل نقل تجویز کرتا ہے۔';

  @override
  String get featDuplicatesPoint2 =>
      'آپ کے کچھ طے کرنے سے پہلے بتاتا ہے کہ ہر گروہ کتنی جگہ خالی کرے گا۔';

  @override
  String get featDuplicatesPoint3 =>
      'جب تک آپ گروہ دیکھ کر تصدیق نہ کریں، کچھ نہیں مٹتا۔';

  @override
  String get featUnlimitedHow =>
      'مفت درجہ ایک حقیقی، قابلِ استعمال ایپ ہے، آزمائش نہیں — بس اس کی ایک حد ہے۔ Pro وہ حد ہٹا دیتا ہے، اور جو کچھ آپ پہلے ترتیب دے چکے ہیں وہ بالکل اپنی جگہ رہتا ہے۔';

  @override
  String get featUnlimitedPoint1 =>
      'آپ کی لائبریری کو جتنے فولڈر واقعی چاہئیں، اُتنے۔';

  @override
  String get featUnlimitedPoint2 =>
      'آپ کتنے اسکرین شاٹس ترتیب دیتے اور پسندیدہ بناتے ہیں، اس پر کوئی حد نہیں۔';

  @override
  String get featUnlimitedPoint3 =>
      'محفوظ کرنا، فولڈرز، پسندیدہ اور تلاش کی تاریخ دونوں صورتوں میں آپ کے پاس رہتے ہیں۔';

  @override
  String get includedSubtitle => 'ہر Pro فیچر، وضاحت کے ساتھ۔';

  @override
  String get includedHint =>
      'کسی خوبی پر ٹیپ کریں تاکہ دیکھیں وہ کیسے کام کرتی ہے';

  @override
  String get includedHowLabel => 'یہ کیسے کام کرتا ہے';

  @override
  String get includedActiveTitle => 'آپ کا منصوبہ فعال ہے';

  @override
  String get includedActiveBody => 'نیچے دی گئی ہر چیز اس اکاؤنٹ پر کھلی ہے۔';

  @override
  String get includedLockedTitle => 'ابھی کھلا نہیں';

  @override
  String get includedLockedBody =>
      'پڑھیں کہ ہر خوبی اصل میں کیا کرتی ہے، پھر فیصلہ کریں۔';

  @override
  String get includedFreeTitle => 'مفت درجہ آپ کو کیا دیتا ہے';

  @override
  String includedFreeBody(int folders, int count) {
    return '$folders فولڈرز اور $count ترتیب شدہ اسکرین شاٹس — ساتھ محفوظ کرنا، پسندیدہ اور گیلری، ہمیشہ کے لیے مفت۔';
  }

  @override
  String get authWelcome => 'SHOTO میں خوش آمدید';

  @override
  String get authSubtitle =>
      'ہر اسکرین شاٹ ایک جگہ محفوظ، منظم اور تلاش کرنے کے لیے سائن ان کریں۔';

  @override
  String get authGoogle => 'Google کے ساتھ جاری رکھیں';

  @override
  String get authApple => 'Apple کے ساتھ جاری رکھیں';

  @override
  String get authLegal =>
      'جاری رکھنے سے آپ ہماری شرائط اور رازداری کی پالیسی سے متفق ہوتے ہیں۔';

  @override
  String get onboardingCta => 'شروع کریں';

  @override
  String get onboardingPromise => 'سب کچھ آپ کے فون پر رہتا ہے۔';

  @override
  String get actionsTitle => 'اقدامات';

  @override
  String get actionsWorking => 'اسکرین شاٹ پڑھا جا رہا ہے';

  @override
  String get actionsWorkingBody => 'نمبر، لنک اور کوڈ تلاش کیے جا رہے ہیں۔';

  @override
  String get actionsNoneTitle => 'کرنے کو کچھ نہیں';

  @override
  String get actionsNoneBody =>
      'اس اسکرین شاٹ میں کوئی فون نمبر، لنک، کوڈ یا اکاؤنٹ نمبر نہیں ملا۔';

  @override
  String get actionsCopy => 'کاپی کریں';

  @override
  String get actionsCopied => 'کاپی ہو گیا';

  @override
  String get actionsNoApp => 'اس آلے پر کوئی ایپ یہ نہیں کر سکتی۔';

  @override
  String get devModeOn => 'ڈویلپر موڈ آن — ہر فیچر کھلا';

  @override
  String get devModeBadge => 'ڈویلپر موڈ';

  @override
  String get devModeOffTitle => 'ڈویلپر موڈ بند کریں؟';

  @override
  String get devModeOffBody =>
      'اس آلے پر SHOTO مفت درجے پر واپس چلا جائے گا، تاکہ آپ پے وال اور حدیں دوبارہ آزما سکیں۔';

  @override
  String get devModeOffConfirm => 'بند کریں';

  @override
  String get devAccessTitle => 'ڈویلپر رسائی';

  @override
  String get devAccessBody =>
      'اس آلے پر ہر Pro فیچر کھولنے کے لیے 4 ہندسوں کا کوڈ درج کریں۔';

  @override
  String get devWrongCode => 'غلط کوڈ';

  @override
  String devTapToDisable(int count) {
    return 'بند کرنے کے لیے $count بار دبائیں';
  }

  @override
  String appVersion(String version) {
    return 'ورژن $version';
  }

  @override
  String get kindCard => 'کارڈ نمبر';

  @override
  String get kindIban => 'بینک اکاؤنٹ';

  @override
  String get kindCode => 'تصدیقی کوڈ';

  @override
  String get kindNationalId => 'شناختی نمبر';

  @override
  String get kindEmail => 'ای میل پتہ';

  @override
  String get kindPhone => 'فون نمبر';

  @override
  String get kindLink => 'لنک';

  @override
  String get actionCall => 'کال کریں';

  @override
  String get actionWhatsapp => 'واٹس ایپ';

  @override
  String get actionSms => 'پیغام';

  @override
  String get actionEmailAction => 'لکھیں';

  @override
  String get actionOpen => 'کھولیں';

  @override
  String get kindEvent => 'تقریب';

  @override
  String get kindPlace => 'مقام';

  @override
  String get kindWifi => 'وائی فائی نیٹ ورک';

  @override
  String get kindTracking => 'کھیپ';

  @override
  String get actionAddToCalendar => 'کیلنڈر میں شامل کریں';

  @override
  String get actionOpenMaps => 'میپس میں کھولیں';

  @override
  String get actionDirections => 'راستہ';

  @override
  String get actionCopyNetwork => 'نام کاپی کریں';

  @override
  String get actionTrack => 'ٹریک کریں';

  @override
  String get actionEventUntitled => 'تقریب';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اسکرین شاٹس',
      one: '1 اسکرین شاٹ',
      zero: 'کوئی اسکرین شاٹ نہیں',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$total میں سے $position';
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
      other: 'نقول کے $count سیٹ',
      one: 'نقول کا 1 سیٹ',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count ملتی جلتی نقول';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count چیزیں ملیں',
      one: '1 چیز ملی',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'اسٹوریج';

  @override
  String get settingsDuplicatesHint => 'وہ اسکرین شاٹس پہچانیں جو دو بار لیے';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'اس میں کیا شامل ہے';

  @override
  String settingsFeatureCount(int count) {
    return '$count فیچرز، ایک پلان';
  }

  @override
  String get settingsShareHint => 'کسی ضرورت مند کو بتائیں';

  @override
  String get settingsShareText =>
      'SHOTO میرے اسکرین شاٹس خود ترتیب دیتا ہے — سب کچھ فون پر رہتا ہے۔';

  @override
  String get settingsAccount => 'اکاؤنٹ';

  @override
  String get settingsSignOutHint => 'آپ کے اسکرین شاٹس اسی آلے پر رہیں گے';

  @override
  String get settingsCacheMeasuring => 'ماپا جا رہا ہے…';

  @override
  String settingsCacheSize(String size) {
    return 'تھمب نیلز کے $size';
  }

  @override
  String get homeSafeShareHint =>
      'کوئی اسکرین شاٹ کھولیں، پھر محفوظ اشتراک دبائیں۔';

  @override
  String get homeStitchHint =>
      'اپنی لائبریری میں دو یا زیادہ اسکرین شاٹس دبا کر رکھیں، پھر جوڑیں دبائیں۔';

  @override
  String stitchLimit(int count) {
    return 'ایک وقت میں زیادہ سے زیادہ $count اسکرین شاٹس جوڑ سکتے ہیں۔';
  }

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اسکرین شاٹس محفوظ ہو گئے۔ فولڈر میں ڈالیں؟',
      one: 'اسکرین شاٹ محفوظ ہو گیا۔ فولڈر میں ڈالیں؟',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count اسکرین شاٹس جُڑ گئے';
  }

  @override
  String stitchResultTrimmed(int count) {
    return 'دہرائے گئے مواد کے $count px ہٹا دیے گئے';
  }

  @override
  String get errorLoadScreenshots => 'آپ کے اسکرین شاٹس لوڈ نہیں ہو سکے۔';

  @override
  String get errorLoadFolders => 'آپ کے فولڈر لوڈ نہیں ہو سکے۔';

  @override
  String get errorScanDuplicates => 'نقول کے لیے اسکین نہیں ہو سکا۔';

  @override
  String get errorDeleteSelected => 'منتخب اسکرین شاٹس حذف نہیں ہو سکے۔';

  @override
  String get errorStitchFailed => 'یہ اسکرین شاٹس جوڑے نہیں جا سکے۔';

  @override
  String get errorStitchSave => 'جُڑی تصویر محفوظ نہیں ہو سکی۔';

  @override
  String get errorOnboarding => 'لوڈ نہیں ہو سکا۔ ایپ دوبارہ کھولیں۔';

  @override
  String get errorSignInCancelled => 'سائن ان منسوخ ہو گیا۔';

  @override
  String get errorSignInInterrupted => 'سائن ان میں خلل آیا۔ دوبارہ کوشش کریں۔';

  @override
  String get errorNetwork => 'نیٹ ورک کی خرابی۔ اپنا کنکشن دیکھیں۔';

  @override
  String get errorGeneric => 'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔';

  @override
  String get errorPlans => 'سبسکرپشن پلان لوڈ نہیں ہو سکے۔';

  @override
  String get errorPurchase => 'خریداری ناکام۔ دوبارہ کوشش کریں۔';

  @override
  String get errorNoSubscription =>
      'اس اکاؤنٹ کے لیے کوئی فعال سبسکرپشن نہیں ملی۔';

  @override
  String get errorRestore => 'خریداریاں بحال نہیں ہو سکیں۔';

  @override
  String get errorStitchTooFew => 'ملانے کے لیے کم از کم دو اسکرین شاٹ چنیں۔';

  @override
  String errorStitchTooMany(int count) {
    return 'ایک وقت میں $count اسکرین شاٹس تک ملائے جا سکتے ہیں۔';
  }

  @override
  String get errorStitchUnreadable => 'ایک اسکرین شاٹ پڑھا نہیں جا سکا۔';

  @override
  String get errorStitchWidths =>
      'ان اسکرین شاٹس کی چوڑائی مختلف ہے، اس لیے یہ ایک ہی اسکرول کا حصہ نہیں ہو سکتے۔';

  @override
  String get errorStitchNoOverlap =>
      'ان اسکرین شاٹس میں کوئی اوورلیپ نہیں۔ ملانا صرف ایک ہی صفحے کے، اسکرول کرتے ہوئے لیے گئے شاٹس پر کام کرتا ہے۔';

  @override
  String get errorStitchOverlap =>
      'ان اسکرین شاٹس کے درمیان اوورلیپ طے نہیں کیا جا سکا۔';

  @override
  String get errorStitchTooTall =>
      'ملی ہوئی تصویر بہت لمبی ہو جائے گی۔ کم اسکرین شاٹس ملا کر دیکھیں۔';

  @override
  String get errorStitchEncode => 'ملی ہوئی تصویر انکوڈ نہیں کی جا سکی۔';

  @override
  String get errorRedactionSave => 'محفوظ نقل سیو نہیں کی جا سکی۔';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اسکرین شاٹس محفوظ ہو گئے',
      one: 'اسکرین شاٹ محفوظ ہو گیا',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'بڑا';

  @override
  String get densityMedium => 'درمیانہ';

  @override
  String get densitySmall => 'چھوٹا';

  @override
  String get sensitiveCard => 'کارڈ نمبر';

  @override
  String get sensitiveIban => 'بینک اکاؤنٹ';

  @override
  String get sensitiveCode => 'تصدیقی کوڈ';

  @override
  String get sensitiveNationalId => 'شناختی نمبر';

  @override
  String get sensitiveEmail => 'ای میل پتہ';

  @override
  String get sensitivePhone => 'فون نمبر';

  @override
  String get sensitiveAddress => 'پتہ';

  @override
  String get sensitiveName => 'نام';

  @override
  String get sensitiveOrderNumber => 'آرڈر نمبر';

  @override
  String get sensitiveNumber => 'نمبر';

  @override
  String get onbSkip => 'چھوڑیں';

  @override
  String get onbNext => 'آگے';

  @override
  String get onbPileTitle => 'ہزار سکرین شاٹ، ایک ڈھیر';

  @override
  String get onbPileBody =>
      'آپ یاد رکھنے کے لیے سکرین شاٹ لیتے ہیں۔ ہفتے بعد وہ چار سو اور کے نیچے دب جاتا ہے۔';

  @override
  String get onbChooseTitle => 'SHOTO آپ کی گیلری کبھی نہیں پڑھتا';

  @override
  String get onbChooseBody =>
      'کچھ خود سے نہیں آتا۔ آپ سکرین شاٹ شیئر کرتے ہیں — بس یہی سارا اصول ہے۔';

  @override
  String get onbFileTitle => 'بھیجتے ہی اپنی جگہ پر';

  @override
  String get onbFileBody => 'شیئر شیٹ میں ہی فولڈر چنیں۔ ایپ کھلتی تک نہیں۔';

  @override
  String get onbFindTitle => 'جو ان کے اندر ہے، وہ ڈھونڈیں';

  @override
  String get onbFindBody =>
      'سکرین شاٹ میں لکھے الفاظ، اور تصویر میں جو دکھ رہا ہے۔ لکھیں ”رسید“ یا ”کتا“۔';

  @override
  String get onbProTitle => 'SHOTO Pro';

  @override
  String get onbProBody =>
      'قواعد آپ کے نئے سکرین شاٹ خود فائل کرتے ہیں، اور نیچے سب کچھ ساتھ آتا ہے۔';

  @override
  String onbProMore(int count) {
    return 'اور $count مزید';
  }

  @override
  String get onbFolderExample => 'رسیدیں';

  @override
  String get onbSearchExample => 'رسید';

  @override
  String get importTitle => 'اسکرین شاٹ شامل کریں';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اسکرین شاٹ درآمد ہو گئے',
      one: '1 اسکرین شاٹ درآمد ہو گیا',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return '$picked میں سے $imported درآمد ہوئے';
  }

  @override
  String get importFailed => 'یہ اسکرین شاٹ محفوظ نہیں ہو سکے';

  @override
  String get homeToolImportSubtitle =>
      'اپنے فون سے منتخب کریں — آپ کی گیلری نہیں پڑھی جاتی';

  @override
  String get importPickerUnavailable => 'تصویر چننے والا نہیں کھل سکا';

  @override
  String get searchWorking => 'آپ کے اسکرین شاٹس پڑھے جا رہے ہیں…';

  @override
  String get settingsBackup => 'بیک اپ اور بحالی';

  @override
  String get settingsBackupHint => 'اپنی لائبریری کی ایک نقل فائل میں رکھیں';

  @override
  String get backupTitle => 'بیک اپ';

  @override
  String get backupIntro =>
      'آپ کی لائبریری صرف اسی فون میں ہے، اور کہیں نہیں۔ فون گم ہو جائے تو بیک اپ ہی بچتا ہے۔';

  @override
  String get backupCreateTitle => 'بیک اپ بنائیں';

  @override
  String get backupCreateBody =>
      'ہر اسکرین شاٹ، فولڈر اور لیبل کو ایک فائل میں سمیٹتا ہے، پھر آپ طے کرتے ہیں کہ اسے کہاں رکھنا ہے۔';

  @override
  String get backupCreateAction => 'بیک اپ بنائیں';

  @override
  String get backupWorking => 'آپ کی لائبریری سمیٹی جا رہی ہے…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots اسکرین شاٹس',
      one: '1 اسکرین شاٹ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders فولڈرز',
      one: '1 فولڈر',
    );
    return '$_temp0 اور $_temp1 کا بیک اپ بن گیا';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots اسکرین شاٹس',
      one: '1 اسکرین شاٹ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped پڑھے نہ جا سکے',
      one: '1 پڑھا نہ جا سکا',
    );
    return '$_temp0 کا بیک اپ بنا۔ $_temp1۔';
  }

  @override
  String get backupFailed => 'بیک اپ مکمل نہ ہو سکا';

  @override
  String get backupPrivacyNote =>
      'فائل اسی فون پر بنتی ہے اور صرف وہیں جاتی ہے جہاں آپ بھیجیں۔ کچھ بھی اپ لوڈ نہیں ہوتا۔';

  @override
  String get restoreTitle => 'بیک اپ سے بحال کریں';

  @override
  String get restoreBody =>
      'بیک اپ فائل کی ہر چیز اس لائبریری میں شامل کرتا ہے۔ جو پہلے سے موجود ہے وہ نہیں ہٹتا۔';

  @override
  String get restoreAction => 'بحال کریں';

  @override
  String get restoreWorking => 'آپ کی لائبریری واپس رکھی جا رہی ہے…';

  @override
  String get restoreConfirmTitle => 'یہ بیک اپ بحال کریں؟';

  @override
  String get restoreConfirmMessage =>
      'فائل کی ہر چیز آپ کی لائبریری میں شامل ہو جائے گی۔ آپ کے موجودہ اسکرین شاٹس جوں کے توں رہیں گے۔';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots اسکرین شاٹس',
      one: '1 اسکرین شاٹ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders فولڈرز',
      one: '1 فولڈر',
    );
    return '$_temp0 اور $_temp1 بحال ہوئے';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots اسکرین شاٹس',
      one: '1 اسکرین شاٹ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped چھوڑ دیے گئے',
      one: '1 چھوڑ دیا گیا',
    );
    return '$_temp0 بحال ہوئے۔ $_temp1۔';
  }

  @override
  String get restoreNotABackup => 'یہ فائل SHOTO کا بیک اپ نہیں ہے';

  @override
  String get restoreFailed => 'بحالی مکمل نہ ہو سکی';

  @override
  String get settingsHelp => 'مدد';

  @override
  String get settingsContactSupport => 'سپورٹ سے رابطہ کریں';

  @override
  String get supportSubject => 'SHOTO سپورٹ';

  @override
  String get supportNoMailApp =>
      'کوئی ای میل ایپ نہیں ملی۔ پتہ کاپی کر دیا گیا ہے۔';

  @override
  String get supportGreeting => 'السلام علیکم SHOTO ٹیم،';

  @override
  String get dateToday => 'آج';

  @override
  String get dateYesterday => 'کل';

  @override
  String get dateThisWeek => 'اس ہفتے';

  @override
  String get dateThisMonth => 'اس مہینے';

  @override
  String get librarySortNewest => 'نئی پہلے';

  @override
  String get librarySortOldest => 'پرانی پہلے';

  @override
  String get librarySortLabel => 'ترتیب';

  @override
  String libraryScanPrompt(int count) {
    return '$count اسکرین شاٹس پڑھیں';
  }

  @override
  String get libraryScanning => 'پڑھا جا رہا ہے…';

  @override
  String restoreClashTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فولڈرز یہاں پہلے سے موجود ہیں',
      one: '1 فولڈر یہاں پہلے سے موجود ہے',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashBody =>
      'یہ نام آپ کی لائبریری میں بھی ہیں اور بیک اپ میں بھی۔ ایک ہی نام ہمیشہ ایک ہی فولڈر نہیں ہوتا، اس لیے یہ فیصلہ آپ کا ہے۔';

  @override
  String restoreClashMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اور $count مزید',
      one: 'اور 1 مزید',
    );
    return '$_temp0';
  }

  @override
  String get restoreClashMerge => 'انہیں ملا دیں';

  @override
  String get restoreClashMergeBody =>
      'اسکرین شاٹس آپ کے موجودہ فولڈرز میں جائیں گے۔';

  @override
  String get restoreClashSeparate => 'الگ رکھیں';

  @override
  String get restoreClashSeparateBody =>
      'اسی نام کا دوسرا فولڈر بنتا ہے۔ موجودہ کچھ بھی نہیں بدلتا۔';

  @override
  String get intentBuy => 'خریدیں';

  @override
  String get intentRead => 'پڑھیں';

  @override
  String get intentReply => 'جواب دیں';

  @override
  String get intentTry => 'آزمائیں';

  @override
  String get intentVisit => 'جائیں';

  @override
  String get intentBuyWaiting => 'خریدنے کے لیے';

  @override
  String get intentReadWaiting => 'پڑھنے کے لیے';

  @override
  String get intentReplyWaiting => 'جواب دینے کے لیے';

  @override
  String get intentTryWaiting => 'آزمانے کے لیے';

  @override
  String get intentVisitWaiting => 'جانے کے لیے';

  @override
  String get intentPrompt => 'اس کا کیا کریں گے؟';

  @override
  String get intentSkip => 'کچھ خاص نہیں';

  @override
  String get intentWaitingTitle => 'آپ کا انتظار';

  @override
  String get intentNothingWaiting => 'کچھ باقی نہیں';

  @override
  String get intentAllDone => 'بعد کے لیے محفوظ کیا سب کچھ مکمل ہو گیا۔';

  @override
  String get intentMarkDone => 'ہو گیا';

  @override
  String get intentUndo => 'واپس رکھیں';

  @override
  String get intentDoneToast => 'مکمل';

  @override
  String get intentChange => 'بدلیں کہ یہ کس لیے ہے';

  @override
  String get intentClear => 'کسی کام کے لیے نہیں';

  @override
  String intentEmptyOne(String verb) {
    return 'یہاں $verb کے لیے کچھ نہیں';
  }

  @override
  String get intentEmptyBody =>
      'آپ کے نشان زد اسکرین شاٹس یہاں رہیں گے جب تک آپ انہیں مکمل نہ کریں۔';

  @override
  String intentDoneCount(int count) {
    return '$count مکمل';
  }

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دن پہلے',
      one: '1 دن پہلے',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ہفتے پہلے',
      one: '1 ہفتہ پہلے',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مہینے پہلے',
      one: '1 مہینہ پہلے',
    );
    return '$_temp0';
  }
}
