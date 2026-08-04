// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonDelete => 'हटाएँ';

  @override
  String get commonRetry => 'फिर कोशिश करें';

  @override
  String get commonSomethingWentWrong => 'कुछ गड़बड़ हो गई';

  @override
  String get commonPro => 'PRO';

  @override
  String get navHome => 'होम';

  @override
  String get navLibrary => 'लाइब्रेरी';

  @override
  String get navFolders => 'फ़ोल्डर';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get tagline => 'आपके स्क्रीनशॉट, व्यवस्थित';

  @override
  String get homeGreetingMorning => 'सुप्रभात';

  @override
  String get homeGreetingAfternoon => 'नमस्कार';

  @override
  String get homeGreetingEvening => 'शुभ संध्या';

  @override
  String get homeInboxEmpty => 'कुछ सहेजा नहीं गया';

  @override
  String get homeInboxEmptySubtitle =>
      'शुरू करने के लिए कोई स्क्रीनशॉट SHOTO में साझा करें';

  @override
  String get homeInboxClear => 'सब व्यवस्थित है';

  @override
  String get homeInboxClearSubtitle => 'छाँटने के लिए कुछ बाकी नहीं';

  @override
  String get homeInboxCountSubtitle =>
      'वे स्क्रीनशॉट जो आपने अभी फ़ाइल नहीं किए';

  @override
  String get homeStatScreenshots => 'स्क्रीनशॉट';

  @override
  String get homeStatFavorites => 'पसंदीदा';

  @override
  String get homeStatFolders => 'फ़ोल्डर';

  @override
  String get homeToolsTitle => 'SHOTO क्या कर सकता है';

  @override
  String get homeToolSafeShare => 'सुरक्षित साझा';

  @override
  String get homeToolSafeShareSubtitle => 'पहले निजी जानकारी छिपाएँ';

  @override
  String get homeToolDuplicates => 'डुप्लिकेट खोजें';

  @override
  String get homeToolDuplicatesSubtitle => 'जगह खाली करें';

  @override
  String get homeToolSearch => 'तस्वीर के अंदर खोजें';

  @override
  String get homeToolSearchSubtitle => 'अपनी तस्वीरों में लिखा पाठ ढूँढें';

  @override
  String get homeToolStitch => 'लंबे स्क्रीनशॉट जोड़ें';

  @override
  String get homeToolStitchSubtitle => 'स्क्रॉल की गई तस्वीरें एक में मिलाएँ';

  @override
  String get homeRecent => 'हाल के';

  @override
  String get libraryPickForMerge =>
      'एक ही पेज के दो या ज़्यादा स्क्रीनशॉट चुनें';

  @override
  String get libraryPickForProtect =>
      'वह स्क्रीनशॉट चुनें जिसे सुरक्षित करना है';

  @override
  String get libraryActionProtect => 'सुरक्षित करें';

  @override
  String get homeToolsTitleShort => 'कुछ करें';

  @override
  String get homeSeeAll => 'सभी देखें';

  @override
  String get libraryEmptyTitle => 'अभी कुछ सहेजा नहीं गया';

  @override
  String get libraryEmptyMessage =>
      'कोई स्क्रीनशॉट SHOTO को साझा करें, या + बटन से जोड़ें। आपकी गैलरी कभी नहीं पढ़ी जाती — सिर्फ़ वही रखा जाता है जो आप देते हैं।';

  @override
  String get libraryNoFavoritesTitle => 'अभी कोई पसंदीदा नहीं';

  @override
  String get libraryNoFavoritesMessage =>
      'किसी स्क्रीनशॉट पर दिल दबाएँ, वह यहाँ आ जाएगा।';

  @override
  String get libraryFilterAll => 'सभी';

  @override
  String get libraryFilterFavorites => 'पसंदीदा';

  @override
  String get libraryTraitSensitive => 'संवेदनशील';

  @override
  String get libraryTraitLink => 'लिंक';

  @override
  String get libraryTraitContact => 'फ़ोन या ईमेल';

  @override
  String get libraryTraitCode => 'कोड';

  @override
  String get libraryTraitEvent => 'तारीख़ें';

  @override
  String get libraryCertaintyVerified => 'चेकसम से सत्यापित';

  @override
  String get libraryCertaintyRead => 'आपके स्क्रीनशॉट के टेक्स्ट से पढ़ा गया';

  @override
  String libraryLensNoteWithUnread(String basis, int count) {
    return '$basis · $count अभी तक नहीं पढ़े गए';
  }

  @override
  String libraryNoTraitTitle(String trait) {
    return '$trait वाला कोई स्क्रीनशॉट नहीं';
  }

  @override
  String get libraryNoTraitMessage =>
      'पढ़े गए किसी भी स्क्रीनशॉट में यह नहीं है।';

  @override
  String libraryNoTraitUnreadMessage(int count) {
    return 'पढ़े गए में कुछ नहीं मिला। $count स्क्रीनशॉट कभी नहीं पढ़े गए, इसलिए वे अभी मैच नहीं हो सकते।';
  }

  @override
  String get libraryShowAll => 'सभी दिखाएँ';

  @override
  String get libraryFilterUnsorted => 'बिना क्रम के';

  @override
  String get libraryNoUnsortedTitle => 'सब कुछ व्यवस्थित है';

  @override
  String get libraryNoUnsortedMessage =>
      'आपका कुछ भी बाकी नहीं है। नए स्क्रीनशॉट यहाँ आते हैं जब तक आप उन्हें फ़ोल्डर में न रखें या पसंदीदा न बनाएँ।';

  @override
  String librarySelectedCount(int count) {
    return '$count चुने गए';
  }

  @override
  String get librarySelectAll => 'सभी चुनें';

  @override
  String get libraryActionMerge => 'जोड़ें';

  @override
  String get libraryActionMove => 'ले जाएँ';

  @override
  String get libraryActionDelete => 'हटाएँ';

  @override
  String get libraryDeleteTitle => 'स्क्रीनशॉट हटाएँ?';

  @override
  String libraryDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'यह आपके डिवाइस से $count स्क्रीनशॉट हमेशा के लिए हटा देगा।',
      one: 'यह आपके डिवाइस से 1 स्क्रीनशॉट हमेशा के लिए हटा देगा।',
    );
    return '$_temp0';
  }

  @override
  String get permissionNeededTitle => 'फ़ोटो एक्सेस चाहिए';

  @override
  String get permissionNeededMessage =>
      'SHOTO आपके साझा किए स्क्रीनशॉट अपने अलग एल्बम में रखता है। उसमें लिखने और पढ़ने के लिए अनुमति चाहिए — यह आपकी बाकी गैलरी कभी नहीं देखता।';

  @override
  String get permissionPartialTitle => 'पूरी एक्सेस चाहिए';

  @override
  String get permissionPartialMessage =>
      'अभी SHOTO सिर्फ़ चुनी हुई कुछ तस्वीरें देख पाता है, इसलिए अपने एल्बम तक नहीं पहुँच सकता। जारी रखने के लिए «सभी को अनुमति दें» चुनें।';

  @override
  String get permissionOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsAppearance => 'दिखावट';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsThemeSystem => 'सिस्टम';

  @override
  String get settingsThemeLight => 'हल्का';

  @override
  String get settingsThemeDark => 'गहरा';

  @override
  String get settingsGridDensity => 'ग्रिड घनत्व';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsLanguageSystem => 'मेरे फ़ोन के अनुसार';

  @override
  String settingsLanguageSystemHint(String language) {
    return 'अभी $language';
  }

  @override
  String get settingsBehaviour => 'व्यवहार';

  @override
  String get settingsHaptics => 'स्पर्श कंपन';

  @override
  String get settingsHapticsHint => 'दबाने पर हल्की सी थपकी';

  @override
  String get settingsConfirmDelete => 'हटाने से पहले पूछें';

  @override
  String get settingsConfirmDeleteHint => 'हटाया हुआ वापस नहीं आता';

  @override
  String get settingsFindDuplicates => 'डुप्लिकेट खोजें';

  @override
  String get settingsClearCache => 'इमेज कैश साफ़ करें';

  @override
  String get settingsShare => 'SHOTO साझा करें';

  @override
  String get settingsSignOut => 'साइन आउट';

  @override
  String get settingsSignOutTitle => 'साइन आउट करें?';

  @override
  String get settingsPrivacyNote =>
      'SHOTO आपकी गैलरी कभी नहीं पढ़ता। यह सिर्फ़ वही स्क्रीनशॉट रखता है जो आप इसमें साझा करते हैं, और उनके साथ जो कुछ करता है — पाठ पढ़ना, डुप्लिकेट ढूँढना — सब इसी डिवाइस पर होता है। कुछ भी कहीं अपलोड नहीं होता।';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonConfirm => 'पुष्टि करें';

  @override
  String get commonRename => 'नाम बदलें';

  @override
  String get commonShare => 'साझा करें';

  @override
  String get commonUnlock => 'अनलॉक करें';

  @override
  String get foldersEmptyTitle => 'अभी कोई फ़ोल्डर नहीं';

  @override
  String get foldersEmptyMessage =>
      'फ़ोल्डर ही वह तरीका हैं जिससे आप बाद में चीज़ें ढूँढते हैं। एक रसीदों के लिए बनाएँ, एक व्यंजनों के लिए — जो भी आप सचमुच ढूँढते हैं।';

  @override
  String get foldersNew => 'नया फ़ोल्डर';

  @override
  String get foldersCreate => 'फ़ोल्डर बनाएँ';

  @override
  String get foldersNameLabel => 'फ़ोल्डर का नाम';

  @override
  String get foldersNameHint => 'रसीदें, व्यंजन, काम…';

  @override
  String get foldersPrivate => 'निजी (चेहरा या फ़िंगरप्रिंट लॉक)';

  @override
  String get foldersPrivateFace => 'निजी (चेहरा लॉक)';

  @override
  String get foldersPrivateFingerprint => 'निजी (फ़िंगरप्रिंट लॉक)';

  @override
  String get foldersPrivateGeneric => 'निजी (लॉक)';

  @override
  String get foldersOptions => 'फ़ोल्डर विकल्प';

  @override
  String get foldersDelete => 'फ़ोल्डर हटाएँ';

  @override
  String get foldersDeleteKept => 'अंदर के स्क्रीनशॉट सुरक्षित रहेंगे';

  @override
  String foldersDeleteTitle(String name) {
    return '«$name» हटाएँ?';
  }

  @override
  String get foldersDeleteMessage =>
      'फ़ोल्डर हट जाएगा लेकिन अंदर के स्क्रीनशॉट आपकी लाइब्रेरी में रहेंगे।';

  @override
  String get foldersRenameTitle => 'फ़ोल्डर का नाम बदलें';

  @override
  String get foldersMoveTitle => 'फ़ोल्डर में ले जाएँ';

  @override
  String get foldersMoveRemove => 'फ़ोल्डर से हटाएँ';

  @override
  String get foldersMoveNone =>
      'अभी कोई फ़ोल्डर नहीं। फ़ोल्डर टैब से एक बनाएँ।';

  @override
  String folderLockedTitle(String name) {
    return '«$name» अनलॉक करें';
  }

  @override
  String get folderLockedMessage =>
      'यह फ़ोल्डर सुरक्षित है। देखने के लिए प्रमाणित करें।';

  @override
  String get folderEmptyTitle => 'यहाँ अभी कुछ नहीं';

  @override
  String get folderEmptyMessage =>
      'अपनी लाइब्रेरी से स्क्रीनशॉट इस फ़ोल्डर में ले जाएँ।';

  @override
  String get detailFavorite => 'पसंदीदा';

  @override
  String get detailUnfavorite => 'पसंदीदा से हटाएँ';

  @override
  String get detailAddFavorite => 'पसंदीदा में जोड़ें';

  @override
  String get detailActions => 'क्रियाएँ';

  @override
  String get detailSafeShare => 'सुरक्षित साझा';

  @override
  String get detailDeleteTitle => 'स्क्रीनशॉट हटाएँ?';

  @override
  String get detailDeleteMessage => 'यह आपके डिवाइस से हमेशा के लिए हट जाएगा।';

  @override
  String get quickSaveTitleOne => 'SHOTO में सहेजें';

  @override
  String quickSaveTitleMany(int count) {
    return '$count स्क्रीनशॉट सहेजें';
  }

  @override
  String get quickSaveFileOne => 'यह स्क्रीनशॉट फ़ाइल करें';

  @override
  String quickSaveFileMany(int count) {
    return '$count स्क्रीनशॉट फ़ाइल करें';
  }

  @override
  String get quickSavePickFolder => 'फ़ोल्डर चुनें';

  @override
  String get quickSaveNeedFolder => 'इन्हें रखने के लिए फ़ोल्डर बनाएँ';

  @override
  String quickSaveFileIn(String folder) {
    return '$folder में फ़ाइल करें';
  }

  @override
  String get quickSaveCreateFirstFolder => 'अपना पहला फ़ोल्डर बनाएँ';

  @override
  String get quickSaveCreateFirstFolderWhy =>
      'फ़ोल्डर ही वह तरीका हैं जिससे आप बाद में चीज़ें ढूँढते हैं';

  @override
  String get quickSaveNewChip => 'नया';

  @override
  String get quickSaveSaved => 'SHOTO में सहेजा गया';

  @override
  String quickSaveFiled(String folder) {
    return '$folder में फ़ाइल हो गया।';
  }

  @override
  String get quickSaveFailedTitle => 'वह तस्वीर पढ़ी नहीं जा सकी';

  @override
  String get quickSaveFailedBody => 'इसे दोबारा साझा करके देखें।';

  @override
  String get quickSaveSignedOutTitle => 'पहले SHOTO में साइन इन करें';

  @override
  String get quickSaveSignedOutBody =>
      'आपकी लाइब्रेरी आपके खाते से जुड़ी है। SHOTO खोलें, साइन इन करें, फिर दोबारा साझा करें।';

  @override
  String quickSaveSkipped(int count) {
    return 'सिर्फ़ पहले $count लिए गए';
  }

  @override
  String get dupTitle => 'डुप्लिकेट खोजें';

  @override
  String get dupScanning => 'डुप्लिकेट खोजे जा रहे हैं';

  @override
  String get dupReading => 'आपकी लाइब्रेरी पढ़ी जा रही है…';

  @override
  String dupProgress(int done, int total) {
    return '$total में से $done जाँचे गए';
  }

  @override
  String get dupNoneTitle => 'कोई डुप्लिकेट नहीं मिला';

  @override
  String get dupNoneBody => 'आपकी लाइब्रेरी पहले से साफ़ है।';

  @override
  String get dupScanAgain => 'फिर से स्कैन करें';

  @override
  String dupReclaimable(String size) {
    return '$size तक जगह खाली हो सकती है';
  }

  @override
  String get dupNothingSelected => 'कुछ चयनित नहीं';

  @override
  String dupDeleteButton(int count, String size) {
    return '$count हटाएँ · $size खाली';
  }

  @override
  String dupDeleteTitle(int count) {
    return '$count प्रतियाँ हटाएँ?';
  }

  @override
  String get dupDeleteMessage =>
      'ये आपके डिवाइस से हमेशा के लिए हट जाएँगी। रखी जाने वाली प्रतियाँ प्रभावित नहीं होंगी।';

  @override
  String dupDeleted(int count, String size) {
    return '$count हटाए · $size खाली';
  }

  @override
  String dupSets(int count) {
    return '$count सेट';
  }

  @override
  String get dupBest => 'सर्वोत्तम';

  @override
  String get dupKeepAll => 'सब रखें';

  @override
  String get dupKeepingAll => 'सब रखे जा रहे हैं — कुछ नहीं हटेगा';

  @override
  String get dupUndo => 'पूर्ववत';

  @override
  String dupFrees(String size) {
    return '$size खाली करेगा';
  }

  @override
  String get safeShareTitle => 'सुरक्षित साझा';

  @override
  String get safeShareScanning => 'निजी जानकारी जाँची जा रही है';

  @override
  String get safeShareOnDevice => 'पढ़ना आपके फ़ोन पर ही होता है।';

  @override
  String get safeShareCleanTitle => 'कुछ निजी नहीं मिला';

  @override
  String get safeShareCleanBody =>
      'इस स्क्रीनशॉट में कोई कार्ड नंबर, खाता नंबर, कोड या संपर्क विवरण नहीं मिला। आप इसे वैसे ही साझा कर सकते हैं।';

  @override
  String get safeShareUnreadableTitle => 'यह स्क्रीनशॉट पढ़ा नहीं जा सका';

  @override
  String get safeShareUnreadableBody => 'इसमें मौजूद पाठ पहचाना नहीं जा सका।';

  @override
  String get safeShareShareUnchanged => 'वैसे ही साझा करें';

  @override
  String get safeShareShareAnyway => 'फिर भी साझा करें';

  @override
  String get safeShareShareProtected => 'सुरक्षित प्रति साझा करें';

  @override
  String get safeShareFailed => 'सुरक्षित प्रति नहीं बन सकी।';

  @override
  String safeShareFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count निजी जानकारियाँ मिलीं',
      one: '1 निजी जानकारी मिली',
    );
    return '$_temp0';
  }

  @override
  String get safeShareFreeScan => 'जाँच हमेशा मुफ़्त है।';

  @override
  String get safeShareCleanAction => 'यह स्क्रीनशॉट साफ़ करें';

  @override
  String get safeShareShareAsIs => 'बिना बदलाव के साझा करें';

  @override
  String get safeShareHowTitle => 'पक्के तौर पर ढका हुआ';

  @override
  String get safeShareHowBody =>
      'कॉपी आपके फ़ोन से निकलने से पहले हर निजी जानकारी ठोस ब्लॉक से ढक दी जाती है। न धुंधलापन, न वापस पढ़ने का कोई तरीका — ढकी हुई कॉपी ही इकलौती कॉपी है।';

  @override
  String get safeShareTreatmentCover => 'ढकें';

  @override
  String get safeShareTreatmentKeep => 'रहने दें';

  @override
  String get safeShareBuilding => 'आपकी साफ़ कॉपी तैयार हो रही है';

  @override
  String get safeShareNothingSelected => 'कुछ नहीं बदलेगा';

  @override
  String get safeShareLockedPreview => 'साफ़ संस्करण देखने के लिए अनलॉक करें';

  @override
  String get safeShareReviewTitle => 'हर एक जाँचें';

  @override
  String safeShareFound(int count) {
    return '$count चीज़ें ढकी गईं';
  }

  @override
  String get stitchTitle => 'स्क्रीनशॉट जोड़ें';

  @override
  String get stitchWorking => 'ओवरलैप ढूँढा जा रहा है';

  @override
  String get stitchWorkingBody =>
      'मिलाया जा रहा है कि हर स्क्रीनशॉट पिछले से कहाँ जुड़ता है।';

  @override
  String get stitchFailed => 'जोड़ा नहीं जा सका';

  @override
  String get stitchSave => 'गैलरी में सहेजें';

  @override
  String get stitchSaved => 'आपकी गैलरी में सहेजी गई';

  @override
  String get stitchDiscard => 'छोड़ें';

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonBack => 'वापस';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get searchTitle => 'अपने स्क्रीनशॉट में खोजें';

  @override
  String get searchHint => 'शब्द या तस्वीर में जो दिखे';

  @override
  String get searchIntro =>
      'तस्वीर में लिखा कोई शब्द, या तस्वीर में जो दिखे — «बिल्ली», «जानवर», «खाना» या «रसीद» आज़माएँ।';

  @override
  String get searchNoneTitle => 'कोई नतीजा नहीं';

  @override
  String searchNoneBody(String query) {
    return 'यहाँ कुछ भी «$query» जैसा नहीं पढ़ा या दिखा।';
  }

  @override
  String get paywallTitle => 'SHOTO Pro अनलॉक करें';

  @override
  String get paywallSubtitle => 'नीचे सब कुछ, एक ही सदस्यता में।';

  @override
  String get paywallMonthly => 'मासिक';

  @override
  String get paywallYearly => 'वार्षिक';

  @override
  String paywallSave(int percent) {
    return '$percent% बचाएँ';
  }

  @override
  String get paywallContinue => 'जारी रखें';

  @override
  String get paywallUnavailable => 'अभी उपलब्ध नहीं';

  @override
  String get paywallRestore => 'खरीदारी बहाल करें';

  @override
  String get paywallLegal =>
      'रद्द करने तक अपने आप नवीनीकृत होता रहेगा। आप कभी भी अपने App Store या Google Play खाते से रद्द कर सकते हैं। जारी रखने पर आप हमारी शर्तें और गोपनीयता नीति स्वीकार करते हैं।';

  @override
  String get subPremiumBadge => 'PRO';

  @override
  String get subPremiumTitle => 'SHOTO Pro';

  @override
  String get subPremiumBody => 'हर सुविधा आपके लिए खुली है।';

  @override
  String get subDevUnlock => 'टेस्टर ऐक्सेस';

  @override
  String get subDevUnlockBody =>
      'सिर्फ़ इसी डिवाइस पर खुला — असली सदस्यता नहीं';

  @override
  String get subUnlockEverything => 'सब कुछ खोलें';

  @override
  String get proWelcomeTitle => 'आप Pro पर हैं';

  @override
  String get proWelcomeBody =>
      'हर सुविधा खुल गई है। और कुछ सेट करने की ज़रूरत नहीं।';

  @override
  String get proWelcomeAction => 'शुरू करें';

  @override
  String get featSearch => 'स्क्रीनशॉट के अंदर खोजें';

  @override
  String get featSearchBody =>
      'उसमें लिखे शब्दों से कोई भी स्क्रीनशॉट ढूँढें, अरबी या अंग्रेज़ी में। कुछ अपलोड नहीं होता — पढ़ना आपके फ़ोन पर होता है।';

  @override
  String get featSafeShare => 'सुरक्षित साझा';

  @override
  String get featSafeShareBody =>
      'कार्ड नंबर, पते, नाम और संपर्क जानकारी की जगह असली जैसे विकल्प रख देता है — वही लंबाई, वही रूप, वही जगह। आप जो कॉपी भेजते हैं वह संपादित नहीं लगती।';

  @override
  String get featActions => 'स्क्रीनशॉट को क्रियाओं में बदलें';

  @override
  String get featActionsBody =>
      'नंबर पर कॉल करें, लिंक खोलें, कोड या IBAN कॉपी करें — सीधे तस्वीर से, कुछ दोबारा टाइप किए बिना।';

  @override
  String get featDuplicates => 'डुप्लिकेट खोजें';

  @override
  String get featDuplicatesBody =>
      'लगभग एक जैसे स्क्रीनशॉट पहचानें जो दो बार रखे गए और उन्हें हटाएँ — हमेशा पहले समीक्षा के साथ।';

  @override
  String get featStitch => 'लंबे स्क्रीनशॉट जोड़ें';

  @override
  String get featStitchBody =>
      'स्क्रॉल की गई तस्वीरों को एक लंबी तस्वीर में जोड़ें, ओवरलैप अपने आप ढूँढकर हटा दिया जाता है।';

  @override
  String get featUnlimited => 'असीमित फ़ोल्डर और स्क्रीनशॉट';

  @override
  String get featUnlimitedBody =>
      'मुफ़्त संस्करण कुछ ही फ़ोल्डर और स्क्रीनशॉट पर रुक जाता है। Pro दोनों सीमाएँ हटा देता है।';

  @override
  String get featSearchHow =>
      'SHOTO हर स्क्रीनशॉट के भीतर छपा पाठ पढ़कर याद रखता है, इसलिए याद आया एक शब्द ही तस्वीर दोबारा ढूँढने के लिए काफ़ी है — न फ़ाइल नाम, न फ़ोल्डर, न स्क्रॉल।';

  @override
  String get featSearchPoint1 =>
      'अरबी और अंग्रेज़ी पढ़ता है, और वर्तनी थोड़ी अलग हो तब भी मिलान कर लेता है।';

  @override
  String get featSearchPoint2 =>
      'तस्वीर में जो दिख रहा है उससे भी ढूँढता है — «रसीद», «बिल्ली» या «खाना» आज़माएँ।';

  @override
  String get featSearchPoint3 =>
      'पढ़ने का काम आपके फ़ोन पर होता है। कुछ भी अपलोड नहीं होता, इसलिए ऑफ़लाइन भी चलता है।';

  @override
  String get featSafeShareHow =>
      'स्क्रीनशॉट में निजी जानकारी ढूँढना हमेशा मुफ़्त और असीमित है। भुगतान उन नतीजों को साफ़ कॉपी में बदलता है: हर जानकारी स्क्रीनशॉट के अपने रंगों में दूसरी, उतनी ही आम जानकारी बनकर फिर से लिखी जाती है।';

  @override
  String get featSafeSharePoint1 =>
      'कार्ड नंबर Luhn से और IBAN mod-97 से जाँचे जाते हैं — और विकल्प भी वही जाँच पास करते हैं, इसलिए कुछ भी बनावटी नहीं लगता।';

  @override
  String get featSafeSharePoint2 =>
      'नाम, पते, ऑर्डर नंबर, सत्यापन कोड, फ़ोन नंबर और ईमेल भी पकड़ता है।';

  @override
  String get featSafeSharePoint3 =>
      'भेजने से पहले हर बदलाव दिखता है, और आप उसकी जगह ढकना या रहने देना चुन सकते हैं। मूल स्क्रीनशॉट कभी नहीं बदलता।';

  @override
  String get featActionsHow =>
      'स्क्रीनशॉट के भीतर जो कुछ लिखा है वह इस्तेमाल करने लायक बन जाता है। SHOTO काम की चीज़ें निकालकर हर एक पर एक बटन लगा देता है।';

  @override
  String get featActionsPoint1 =>
      'फ़ोन नंबर, लिंक, ईमेल पते, IBAN और सत्यापन कोड आपके लिए ढूँढ लिए जाते हैं।';

  @override
  String get featActionsPoint2 =>
      'कॉल करने, खोलने या कॉपी करने के लिए एक टैप — तस्वीर से अंक पढ़ने की ज़रूरत नहीं।';

  @override
  String get featActionsPoint3 =>
      'आपके पास पहले से मौजूद स्क्रीनशॉट पर भी चलता है, सिर्फ़ नए पर नहीं।';

  @override
  String get featStitchHow =>
      'लंबी चैट या पेज स्क्रॉल करते हुए कुछ शॉट लें, और SHOTO पता लगाता है कि वे कहाँ ओवरलैप होते हैं और उन्हें एक लंबी तस्वीर में जोड़ देता है।';

  @override
  String get featStitchPoint1 =>
      'दो शॉट के बीच दोहराई गई पट्टी अपने आप पहचानी और हटाई जाती है।';

  @override
  String get featStitchPoint2 =>
      'कुछ भी सहेजने से पहले आप जोड़ देख लेते हैं — स्वचालित पहचान अच्छी है, पर कभी पूरी तरह पक्की नहीं।';

  @override
  String get featStitchPoint3 =>
      'जुड़ी हुई तस्वीर बाकी तस्वीरों की तरह आपकी गैलरी में सहेजी जाती है।';

  @override
  String get featDuplicatesHow =>
      'SHOTO स्क्रीनशॉट की तुलना नाम या आकार से नहीं, दिखने से करता है — इसलिए लगभग एक जैसी प्रतियाँ भी पकड़ लेता है: दोबारा भेजी गई, अलग क्रॉप, या दो बार लिया गया वही दृश्य।';

  @override
  String get featDuplicatesPoint1 =>
      'जो एक जैसा दिखता है उसे समूह में रखता है और रखने लायक प्रति सुझाता है।';

  @override
  String get featDuplicatesPoint2 =>
      'आपके कुछ तय करने से पहले बताता है कि हर समूह कितनी जगह खाली करेगा।';

  @override
  String get featDuplicatesPoint3 =>
      'जब तक आप समूह देखकर पुष्टि न करें, कुछ भी नहीं मिटता।';

  @override
  String get featUnlimitedHow =>
      'मुफ़्त संस्करण एक असली, काम लायक ऐप है, ट्रायल नहीं — बस उसकी एक सीमा है। Pro वह सीमा हटा देता है, और जो कुछ आपने पहले से व्यवस्थित किया है वह ठीक वहीं रहता है।';

  @override
  String get featUnlimitedPoint1 =>
      'आपकी लाइब्रेरी को जितने फ़ोल्डर सचमुच चाहिए, उतने।';

  @override
  String get featUnlimitedPoint2 =>
      'आप कितने स्क्रीनशॉट फ़ाइल और पसंदीदा करते हैं, इस पर कोई सीमा नहीं।';

  @override
  String get featUnlimitedPoint3 =>
      'सहेजना, फ़ोल्डर, पसंदीदा और खोज इतिहास दोनों ही स्थिति में आपके रहते हैं।';

  @override
  String get includedSubtitle => 'हर Pro सुविधा, समझाई गई।';

  @override
  String get includedHint =>
      'किसी सुविधा पर टैप करके देखें वह कैसे काम करती है';

  @override
  String get includedHowLabel => 'यह कैसे काम करता है';

  @override
  String get includedActiveTitle => 'आपकी योजना सक्रिय है';

  @override
  String get includedActiveBody => 'नीचे दी गई हर चीज़ इस खाते पर खुली है।';

  @override
  String get includedLockedTitle => 'अभी खुला नहीं है';

  @override
  String get includedLockedBody =>
      'पढ़ें कि हर सुविधा असल में क्या करती है, फिर तय करें।';

  @override
  String get includedFreeTitle => 'मुफ़्त स्तर आपको क्या देता है';

  @override
  String includedFreeBody(int folders, int count) {
    return '$folders फ़ोल्डर और $count व्यवस्थित स्क्रीनशॉट — साथ में सहेजना, पसंदीदा और गैलरी, हमेशा के लिए मुफ़्त।';
  }

  @override
  String get authWelcome => 'SHOTO में आपका स्वागत है';

  @override
  String get authSubtitle =>
      'हर स्क्रीनशॉट एक जगह सहेजने, व्यवस्थित करने और ढूँढने के लिए साइन इन करें।';

  @override
  String get authGoogle => 'Google से जारी रखें';

  @override
  String get authApple => 'Apple से जारी रखें';

  @override
  String get authLegal =>
      'जारी रखने पर आप हमारी शर्तें और गोपनीयता नीति स्वीकार करते हैं।';

  @override
  String get onboardingCta => 'शुरू करें';

  @override
  String get onboardingPromise => 'सब कुछ आपके फ़ोन पर ही रहता है।';

  @override
  String get actionsTitle => 'क्रियाएँ';

  @override
  String get actionsWorking => 'स्क्रीनशॉट पढ़ा जा रहा है';

  @override
  String get actionsWorkingBody => 'नंबर, लिंक और कोड ढूँढे जा रहे हैं।';

  @override
  String get actionsNoneTitle => 'करने को कुछ नहीं';

  @override
  String get actionsNoneBody =>
      'इस स्क्रीनशॉट में कोई फ़ोन नंबर, लिंक, कोड या खाता नंबर नहीं मिला।';

  @override
  String get actionsCopy => 'कॉपी करें';

  @override
  String get actionsCopied => 'कॉपी हो गया';

  @override
  String get actionsNoApp => 'इस डिवाइस पर कोई ऐप यह नहीं कर सकता।';

  @override
  String get devModeOn => 'डेवलपर मोड चालू — हर सुविधा खुली';

  @override
  String get devModeBadge => 'डेवलपर मोड';

  @override
  String get devModeOffTitle => 'डेवलपर मोड बंद करें?';

  @override
  String get devModeOffBody =>
      'इस डिवाइस पर SHOTO मुफ़्त स्तर पर लौट जाएगा, ताकि आप पेवॉल और सीमाएँ फिर से आज़मा सकें।';

  @override
  String get devModeOffConfirm => 'बंद करें';

  @override
  String get devAccessTitle => 'डेवलपर पहुँच';

  @override
  String get devAccessBody =>
      'इस डिवाइस पर हर Pro सुविधा खोलने के लिए 4 अंकों का कोड डालें।';

  @override
  String get devWrongCode => 'ग़लत कोड';

  @override
  String devTapToDisable(int count) {
    return 'बंद करने के लिए $count× दबाएँ';
  }

  @override
  String appVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get kindCard => 'कार्ड नंबर';

  @override
  String get kindIban => 'बैंक खाता';

  @override
  String get kindCode => 'सत्यापन कोड';

  @override
  String get kindNationalId => 'पहचान संख्या';

  @override
  String get kindEmail => 'ईमेल पता';

  @override
  String get kindPhone => 'फ़ोन नंबर';

  @override
  String get kindLink => 'लिंक';

  @override
  String get actionCall => 'कॉल करें';

  @override
  String get actionWhatsapp => 'व्हाट्सएप';

  @override
  String get actionSms => 'संदेश';

  @override
  String get actionEmailAction => 'लिखें';

  @override
  String get actionOpen => 'खोलें';

  @override
  String get kindEvent => 'कार्यक्रम';

  @override
  String get kindPlace => 'स्थान';

  @override
  String get kindWifi => 'वाई-फ़ाई नेटवर्क';

  @override
  String get kindTracking => 'शिपमेंट';

  @override
  String get actionAddToCalendar => 'कैलेंडर में जोड़ें';

  @override
  String get actionOpenMaps => 'मैप्स में खोलें';

  @override
  String get actionDirections => 'दिशा-निर्देश';

  @override
  String get actionCopyNetwork => 'नाम कॉपी करें';

  @override
  String get actionTrack => 'ट्रैक करें';

  @override
  String get actionEventUntitled => 'कार्यक्रम';

  @override
  String countScreenshots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्क्रीनशॉट',
      one: '1 स्क्रीनशॉट',
      zero: 'कोई स्क्रीनशॉट नहीं',
    );
    return '$_temp0';
  }

  @override
  String countPosition(int position, int total) {
    return '$total में से $position';
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
      other: 'डुप्लिकेट के $count सेट',
      one: 'डुप्लिकेट का 1 सेट',
    );
    return '$_temp0';
  }

  @override
  String dupSimilarCopies(int count) {
    return '$count मिलती-जुलती प्रतियाँ';
  }

  @override
  String safeShareFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चीज़ें मिलीं',
      one: '1 चीज़ मिली',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorage => 'स्टोरेज';

  @override
  String get settingsDuplicatesHint => 'वे स्क्रीनशॉट पहचानें जो दो बार लिए';

  @override
  String get settingsPremium => 'Pro';

  @override
  String get settingsWhatsIncluded => 'इसमें क्या शामिल है';

  @override
  String settingsFeatureCount(int count) {
    return '$count सुविधाएँ, एक प्लान';
  }

  @override
  String get settingsShareHint => 'किसी ज़रूरतमंद को बताएँ';

  @override
  String get settingsShareText =>
      'SHOTO मेरे स्क्रीनशॉट खुद व्यवस्थित करता है — सब कुछ फ़ोन पर रहता है।';

  @override
  String get settingsAccount => 'खाता';

  @override
  String get settingsSignOutHint => 'आपके स्क्रीनशॉट इसी डिवाइस पर रहेंगे';

  @override
  String get settingsCacheMeasuring => 'माप रहे हैं…';

  @override
  String settingsCacheSize(String size) {
    return '$size थंबनेल';
  }

  @override
  String get homeSafeShareHint =>
      'कोई स्क्रीनशॉट खोलें, फिर सुरक्षित साझा दबाएँ।';

  @override
  String get homeStitchHint =>
      'अपनी लाइब्रेरी में दो या ज़्यादा स्क्रीनशॉट दबाकर रखें, फिर जोड़ें दबाएँ।';

  @override
  String stitchLimit(int count) {
    return 'एक बार में ज़्यादा से ज़्यादा $count स्क्रीनशॉट जोड़ सकते हैं।';
  }

  @override
  String shareSavedPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'स्क्रीनशॉट सहेजे गए। किसी फ़ोल्डर में डालें?',
      one: 'स्क्रीनशॉट सहेजा गया। किसी फ़ोल्डर में डालें?',
    );
    return '$_temp0';
  }

  @override
  String stitchResultMerged(int count) {
    return '$count स्क्रीनशॉट जुड़ गए';
  }

  @override
  String stitchResultTrimmed(int count) {
    return 'दोहराए गए $count px हटा दिए गए';
  }

  @override
  String get errorLoadScreenshots => 'आपके स्क्रीनशॉट लोड नहीं हो सके।';

  @override
  String get errorLoadFolders => 'आपके फ़ोल्डर लोड नहीं हो सके।';

  @override
  String get errorScanDuplicates => 'डुप्लिकेट स्कैन नहीं हो सका।';

  @override
  String get errorDeleteSelected => 'चयनित स्क्रीनशॉट हटाए नहीं जा सके।';

  @override
  String get errorStitchFailed => 'ये स्क्रीनशॉट जोड़े नहीं जा सके।';

  @override
  String get errorStitchSave => 'जुड़ी हुई तस्वीर सहेजी नहीं जा सकी।';

  @override
  String get errorOnboarding => 'लोड नहीं हो सका। ऐप दोबारा खोलें।';

  @override
  String get errorSignInCancelled => 'साइन इन रद्द हो गया।';

  @override
  String get errorSignInInterrupted =>
      'साइन इन में रुकावट आई। दोबारा कोशिश करें।';

  @override
  String get errorNetwork => 'नेटवर्क त्रुटि। अपना कनेक्शन जाँचें।';

  @override
  String get errorGeneric => 'कुछ गड़बड़ हो गई। दोबारा कोशिश करें।';

  @override
  String get errorPlans => 'सदस्यता प्लान लोड नहीं हो सके।';

  @override
  String get errorPurchase => 'खरीदारी विफल। दोबारा कोशिश करें।';

  @override
  String get errorNoSubscription =>
      'इस खाते के लिए कोई सक्रिय सदस्यता नहीं मिली।';

  @override
  String get errorRestore => 'खरीदारी बहाल नहीं हो सकी।';

  @override
  String get errorStitchTooFew => 'जोड़ने के लिए कम से कम दो स्क्रीनशॉट चुनें।';

  @override
  String errorStitchTooMany(int count) {
    return 'एक बार में $count स्क्रीनशॉट तक जोड़े जा सकते हैं।';
  }

  @override
  String get errorStitchUnreadable => 'एक स्क्रीनशॉट पढ़ा नहीं जा सका।';

  @override
  String get errorStitchWidths =>
      'इन स्क्रीनशॉट की चौड़ाई अलग है, इसलिए ये एक ही स्क्रॉल का हिस्सा नहीं हो सकते।';

  @override
  String get errorStitchNoOverlap =>
      'इन स्क्रीनशॉट में कोई ओवरलैप नहीं है। जोड़ना सिर्फ़ एक ही पेज के, स्क्रॉल करते हुए लिए गए स्क्रीनशॉट पर काम करता है।';

  @override
  String get errorStitchOverlap =>
      'इन स्क्रीनशॉट के बीच का ओवरलैप तय नहीं किया जा सका।';

  @override
  String get errorStitchTooTall =>
      'जुड़ी हुई छवि बहुत लंबी हो जाएगी। कम स्क्रीनशॉट जोड़कर देखें।';

  @override
  String get errorStitchEncode => 'जुड़ी हुई छवि एन्कोड नहीं की जा सकी।';

  @override
  String get errorRedactionSave => 'सुरक्षित प्रति सहेजी नहीं जा सकी।';

  @override
  String shareSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्क्रीनशॉट सहेजे गए',
      one: 'स्क्रीनशॉट सहेजा गया',
    );
    return '$_temp0';
  }

  @override
  String get densityLarge => 'बड़ा';

  @override
  String get densityMedium => 'मध्यम';

  @override
  String get densitySmall => 'छोटा';

  @override
  String get sensitiveCard => 'कार्ड नंबर';

  @override
  String get sensitiveIban => 'बैंक खाता';

  @override
  String get sensitiveCode => 'सत्यापन कोड';

  @override
  String get sensitiveNationalId => 'पहचान संख्या';

  @override
  String get sensitiveEmail => 'ईमेल पता';

  @override
  String get sensitivePhone => 'फ़ोन नंबर';

  @override
  String get sensitiveAddress => 'पता';

  @override
  String get sensitiveName => 'नाम';

  @override
  String get sensitiveOrderNumber => 'ऑर्डर नंबर';

  @override
  String get sensitiveNumber => 'नंबर';

  @override
  String get onbSkip => 'छोड़ें';

  @override
  String get onbNext => 'आगे';

  @override
  String get onbPileTitle => 'हज़ार स्क्रीनशॉट, एक ढेर';

  @override
  String get onbPileBody =>
      'आप याद रखने के लिए स्क्रीनशॉट लेते हैं। हफ़्ते भर बाद वह चार सौ और के नीचे दब जाता है।';

  @override
  String get onbChooseTitle => 'SHOTO आपकी गैलरी कभी नहीं पढ़ता';

  @override
  String get onbChooseBody =>
      'कुछ अपने आप नहीं आता। आप स्क्रीनशॉट शेयर करते हैं — बस यही पूरा नियम है।';

  @override
  String get onbFileTitle => 'भेजते ही सही जगह पर';

  @override
  String get onbFileBody => 'शेयर शीट में ही फ़ोल्डर चुनें। ऐप खुलता तक नहीं।';

  @override
  String get onbFindTitle => 'उनके अंदर जो है, वह खोजें';

  @override
  String get onbFindBody =>
      'स्क्रीनशॉट में लिखे शब्द, और तस्वीर में जो दिख रहा है। लिखें “रसीद” या “कुत्ता”।';

  @override
  String get onbProTitle => 'SHOTO Pro';

  @override
  String get onbProBody =>
      'नियम आपके नए स्क्रीनशॉट खुद फ़ाइल करते हैं, और नीचे सब कुछ साथ आता है।';

  @override
  String onbProMore(int count) {
    return 'और $count अन्य';
  }

  @override
  String get onbFolderExample => 'रसीदें';

  @override
  String get onbSearchExample => 'रसीद';

  @override
  String get importTitle => 'स्क्रीनशॉट जोड़ें';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्क्रीनशॉट इंपोर्ट हुए',
      one: '1 स्क्रीनशॉट इंपोर्ट हुआ',
    );
    return '$_temp0';
  }

  @override
  String importPartial(int imported, int picked) {
    return '$picked में से $imported इंपोर्ट हुए';
  }

  @override
  String get importFailed => 'ये स्क्रीनशॉट सेव नहीं हो सके';

  @override
  String get homeToolImportSubtitle =>
      'अपने फ़ोन से चुनें — आपकी गैलरी नहीं पढ़ी जाती';

  @override
  String get importPickerUnavailable => 'फ़ोटो पिकर नहीं खुल सका';

  @override
  String get searchWorking => 'आपके स्क्रीनशॉट पढ़े जा रहे हैं…';

  @override
  String get settingsBackup => 'बैकअप और पुनर्स्थापना';

  @override
  String get settingsBackupHint => 'अपनी लाइब्रेरी की एक कॉपी फ़ाइल में रखें';

  @override
  String get backupTitle => 'बैकअप';

  @override
  String get backupIntro =>
      'आपकी लाइब्रेरी सिर्फ़ इसी फ़ोन में है, और कहीं नहीं। फ़ोन खो जाए तो बैकअप ही बचता है।';

  @override
  String get backupCreateTitle => 'बैकअप बनाएँ';

  @override
  String get backupCreateBody =>
      'हर स्क्रीनशॉट, फ़ोल्डर और लेबल को एक फ़ाइल में समेटता है, फिर आप तय करते हैं कि उसे कहाँ रखना है।';

  @override
  String get backupCreateAction => 'बैकअप बनाएँ';

  @override
  String get backupWorking => 'आपकी लाइब्रेरी समेटी जा रही है…';

  @override
  String backupDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots स्क्रीनशॉट',
      one: '1 स्क्रीनशॉट',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders फ़ोल्डर',
      one: '1 फ़ोल्डर',
    );
    return '$_temp0 और $_temp1 का बैकअप बना';
  }

  @override
  String backupDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots स्क्रीनशॉट',
      one: '1 स्क्रीनशॉट',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped पढ़े नहीं जा सके',
      one: '1 पढ़ा नहीं जा सका',
    );
    return '$_temp0 का बैकअप बना। $_temp1।';
  }

  @override
  String get backupFailed => 'बैकअप पूरा नहीं हो सका';

  @override
  String get backupPrivacyNote =>
      'फ़ाइल इसी फ़ोन पर बनती है और सिर्फ़ वहीं जाती है जहाँ आप भेजते हैं। कुछ भी अपलोड नहीं होता।';

  @override
  String get restoreTitle => 'बैकअप से लौटाएँ';

  @override
  String get restoreBody =>
      'बैकअप फ़ाइल की हर चीज़ इस लाइब्रेरी में जोड़ता है। जो पहले से है वह हटता नहीं।';

  @override
  String get restoreAction => 'पुनर्स्थापित करें';

  @override
  String get restoreWorking => 'आपकी लाइब्रेरी लौटाई जा रही है…';

  @override
  String get restoreConfirmTitle => 'यह बैकअप लौटाएँ?';

  @override
  String get restoreConfirmMessage =>
      'फ़ाइल की हर चीज़ आपकी लाइब्रेरी में जुड़ जाएगी। आपके मौजूदा स्क्रीनशॉट जैसे हैं वैसे ही रहेंगे।';

  @override
  String restoreDone(int screenshots, int folders) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots स्क्रीनशॉट',
      one: '1 स्क्रीनशॉट',
    );
    String _temp1 = intl.Intl.pluralLogic(
      folders,
      locale: localeName,
      other: '$folders फ़ोल्डर',
      one: '1 फ़ोल्डर',
    );
    return '$_temp0 और $_temp1 लौटाए गए';
  }

  @override
  String restoreDoneWithSkips(int screenshots, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      screenshots,
      locale: localeName,
      other: '$screenshots स्क्रीनशॉट',
      one: '1 स्क्रीनशॉट',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: '$skipped छोड़े गए',
      one: '1 छोड़ा गया',
    );
    return '$_temp0 लौटाए गए। $_temp1।';
  }

  @override
  String get restoreNotABackup => 'यह फ़ाइल SHOTO का बैकअप नहीं है';

  @override
  String get restoreFailed => 'पुनर्स्थापना पूरी नहीं हो सकी';

  @override
  String get settingsHelp => 'सहायता';

  @override
  String get settingsContactSupport => 'सहायता से संपर्क करें';

  @override
  String get supportSubject => 'SHOTO सहायता';

  @override
  String get supportNoMailApp =>
      'कोई ईमेल ऐप नहीं मिला। पता कॉपी कर दिया गया है।';

  @override
  String get supportGreeting => 'नमस्ते SHOTO टीम,';

  @override
  String get dateToday => 'आज';

  @override
  String get dateYesterday => 'कल';

  @override
  String get dateThisWeek => 'इस हफ़्ते';

  @override
  String get dateThisMonth => 'इस महीने';

  @override
  String get librarySortNewest => 'नई पहले';

  @override
  String get librarySortOldest => 'पुरानी पहले';

  @override
  String get librarySortLabel => 'क्रम';

  @override
  String libraryScanPrompt(int count) {
    return '$count स्क्रीनशॉट पढ़ें';
  }

  @override
  String get libraryScanning => 'पढ़ा जा रहा है…';

  @override
  String restoreClashTitle(int count) {
    return '$count फ़ोल्डर यहाँ पहले से हैं';
  }

  @override
  String get restoreClashBody =>
      'ये नाम आपकी लाइब्रेरी में और बैकअप में दोनों जगह हैं। एक ही नाम हमेशा एक ही फ़ोल्डर नहीं होता, इसलिए यह फ़ैसला आपका है।';

  @override
  String restoreClashMore(int count) {
    return 'और $count अन्य';
  }

  @override
  String get restoreClashMerge => 'इन्हें मिला दें';

  @override
  String get restoreClashMergeBody =>
      'स्क्रीनशॉट आपके मौजूदा फ़ोल्डरों में जाएँगे।';

  @override
  String get restoreClashSeparate => 'अलग रखें';

  @override
  String get restoreClashSeparateBody =>
      'उसी नाम का दूसरा फ़ोल्डर बनता है। मौजूदा कुछ भी नहीं बदलता।';
}
