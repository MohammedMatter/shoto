import 'dart:ui' show PlatformDispatcher;

import 'package:hijri/hijri_calendar.dart';

import 'package:shoto/core/utils/text_cues.dart';
import 'package:shoto/features/smart_actions/data/services/extraction.dart';
import 'package:shoto/features/smart_actions/domain/entities/action_details.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

/// Finds appointments in the text of a screenshot.
///
/// This is the one detector in the feature that reads an *intent* rather than
/// an entity. Everything else here answers "is there a phone number on this
/// screen"; this one answers "is this screen something the user is going to
/// have to be somewhere for", and that is a much easier question to get wrong.
///
/// Three rules keep it honest, and between them they throw away the great
/// majority of the dates on a phone:
///
/// 1. **The past is barely an event.** A chat timestamp, a transaction date,
///    a "sent 3 minutes ago" — screenshots are full of dates, and virtually
///    all of them already happened. Rejecting the past removes more false
///    positives than every other rule here combined.
///
///    A month of it is nonetheless allowed back, because photographing an
///    invitation and opening it a few days later is a real thing people do,
///    and losing that case entirely was the wrong trade. What makes the
///    window safe is that it comes with a *stricter* gate than the future
///    does: inside it the screen has to name the occasion, and a clock time
///    beside the date counts for nothing. That asymmetry is the whole design
///    — a recent date with a time on it describes every chat header ever
///    captured, and a recent date next to the word "دعوة" describes an
///    invitation.
/// 2. **Three years out is not an event either.** That range is where card
///    expiry dates, warranties and licence renewals live.
/// 3. **A date needs a reason.** Either a clock time sits beside it — a date
///    with a time on it is an appointment almost by definition — or a word
///    nearby says what kind of thing it is (invitation, meeting, booking,
///    موعد, دعوة). A bare future date with neither is left alone.
///
/// What survives is handed to the user as a *pre-filled calendar form*, never
/// a silent write. That is what makes the remaining judgement calls
/// acceptable — the ambiguous ones especially. `05/12` is the fifth of
/// December in Amman and the twelfth of May in Chicago, and no amount of
/// pattern matching settles it; the device's region decides, and the user sees
/// the answer on a form with a Save button before it becomes real.
abstract class EventExtractor {
  EventExtractor._();

  /// [now] and [dayFirst] exist so this is testable without a clock or a
  /// device region. In the app both are left null.
  static List<Extraction> findIn(String text, {DateTime? now, bool? dayFirst}) {
    if (text.length < 6) return const [];

    final DateTime reference = now ?? DateTime.now();
    final DateTime today = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    final bool dmy = dayFirst ?? _deviceUsesDayFirst();

    final List<_Line> lines = _linesOf(text);
    final String haystack = text.toLowerCase();

    final List<_DateHit> hits = <_DateHit>[];
    // Month names first: "12 May 2026" also contains nothing a numeric pattern
    // wants, but "2026-05-12" *does* contain "05-12", so the specific spelling
    // has to claim its characters before the loose one looks at them.
    _findNamedDates(text, hits);
    _findHijriDates(text, hits);
    _findNumericDates(text, hits, dmy);
    hits.sort((_DateHit a, _DateHit b) => a.start.compareTo(b.start));

    final List<Extraction> found = <Extraction>[];
    final Set<String> seen = <String>{};

    for (final _DateHit hit in hits) {
      if (_overlapsFound(found, hit.start, hit.end)) continue;
      if (_sitsInsideUrl(text, hit.start)) continue;

      final DateTime? day = hit.resolve(today);
      if (day == null) continue;
      if (day.difference(today).inDays > _maxDaysAhead) continue;

      final bool alreadyHappened = day.isBefore(today);
      if (alreadyHappened && today.difference(day).inDays > _maxDaysBehind) {
        continue;
      }

      final int lineIndex = _lineIndexOf(lines, hit.start);
      final _TimeHit? time = _timeNear(text, lines, lineIndex, hit);
      final bool cue = _hasCueNear(haystack, hit.start, hit.end);

      if (alreadyHappened) {
        // Inside the recent-past window a clock time is *not* enough, even
        // though it is enough for a future date. A chat screenshot is made of
        // recent dates with times beside them — that is precisely the
        // population this window lets back in, and requiring the occasion to
        // name itself is what keeps them out.
        if (!cue) continue;
      } else if (time == null) {
        // Rule 3, plus the extra caution a year-less numeric date needs:
        // "3/4" is a date only if something on the screen is behaving like a
        // schedule.
        if (hit.needsTime) continue;
        if (!cue) continue;
      }

      final DateTime start = time == null
          ? day
          : DateTime(day.year, day.month, day.day, time.hour, time.minute);
      final DateTime? end = time?.endHour == null
          ? null
          : DateTime(
              day.year,
              day.month,
              day.day,
              time!.endHour!,
              time.endMinute!,
            );

      final String value = '${start.toIso8601String()}|${time == null}';
      if (!seen.add(value)) continue;

      final int titleLine = _titleLineFor(lines, lineIndex);
      final String display = text
          .substring(
            hit.start,
            time == null ? hit.end : _maxOf(hit.end, time.end),
          )
          .trim();

      found.add(
        Extraction(
          DetectedAction(
            kind: DetectedActionKind.event,
            value: value,
            display: display,
            details: EventDetails(
              title: titleLine < 0 ? null : lines[titleLine].text.trim(),
              start: start,
              end: end,
              allDay: time == null,
              location: _locationNear(lines, lineIndex),
              notes: _notesBetween(lines, titleLine, lineIndex),
            ),
          ),
          hit.start,
          time == null ? hit.end : _maxOf(hit.end, time.end),
        ),
      );

      if (found.length == _maxEvents) break;
    }

    return found;
  }

  /// Two events off one screenshot is already generous; a wall of them means
  /// the detector is reading a calendar grid, not an invitation.
  static const int _maxEvents = 3;

  /// Roughly three years. Past this the dates on a phone stop being plans and
  /// start being expiry dates.
  static const int _maxDaysAhead = 1096;

  /// How far back an occasion can still be worth a calendar entry.
  ///
  /// A month covers "I screenshotted the invitation last week"; anything older
  /// is a record rather than a plan, and adding a party from two years ago to
  /// a calendar does nothing for anybody.
  static const int _maxDaysBehind = 30;

  // -------------------------------------------------------------------
  // Region
  // -------------------------------------------------------------------

  /// Which way round `05/12` is read.
  ///
  /// Month-first is a short list and everywhere else is day-first, so the
  /// question is asked that way round: an unknown region gets the answer that
  /// is right for most of the planet, and for every language this app speaks
  /// except one.
  static bool _deviceUsesDayFirst() {
    const Set<String> monthFirst = <String>{'US', 'PH', 'FM', 'MH', 'PW'};
    final String? country = PlatformDispatcher.instance.locale.countryCode;
    if (country == null) return true;
    return !monthFirst.contains(country.toUpperCase());
  }

  // -------------------------------------------------------------------
  // Dates
  // -------------------------------------------------------------------

  /// `2026-05-12`. Unambiguous by construction, so it is matched first and
  /// never consults the region.
  static final RegExp _isoDate = RegExp(
    r'(?<![0-9])([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})(?![0-9])',
  );

  /// `12/05/2026`, `12-05-2026`, and the spaced spellings OCR produces from
  /// them.
  ///
  /// The backreference forces one separator for the whole date — without it
  /// `12/05-2026` matches, and a date spelled that way is layout noise rather
  /// than a date.
  ///
  /// The spaces around the separator are not cosmetic tolerance. A printed
  /// invitation sets its date in a wide decorative face, and recognition comes
  /// back with `12 / 5 / 2026` — which the unspaced pattern misses completely.
  /// Allowing them lets `12 - 5 - 2026` in, which could be arithmetic; the
  /// future-plus-reason gate is what makes that acceptable.
  static final RegExp _slashDate = RegExp(
    r'(?<![0-9])([0-9]{1,2})[ \t]*([/-])[ \t]*([0-9]{1,2})'
    r'[ \t]*\2[ \t]*([0-9]{2,4})(?![0-9])',
  );

  /// `12.05.2026`, and only with a four-digit year.
  ///
  /// The short-year form is given up deliberately: `1.2.30` is a version
  /// number far more often than it is a date, and there is no way to tell them
  /// apart. Insisting on four digits costs a spelling almost nobody writes and
  /// removes the whole class of false positives.
  static final RegExp _dotDate = RegExp(
    r'(?<![0-9A-Za-z.])([0-9]{1,2})\.([0-9]{1,2})\.([0-9]{4})(?![0-9.])',
  );

  /// `12/5` with no year at all. Only the slash spelling, because `12-5` is a
  /// range and `12.5` is a number.
  static final RegExp _shortDate = RegExp(
    r'(?<![0-9/])([0-9]{1,2})/([0-9]{1,2})(?![0-9/])',
  );

  static void _findNumericDates(
    String text,
    List<_DateHit> hits,
    bool dayFirst,
  ) {
    for (final RegExpMatch m in _isoDate.allMatches(text)) {
      hits.add(
        _DateHit(
          start: m.start,
          end: m.end,
          year: int.parse(m.group(1)!),
          month: int.parse(m.group(2)!),
          day: int.parse(m.group(3)!),
        ),
      );
    }

    for (final RegExp pattern in <RegExp>[_slashDate, _dotDate]) {
      final bool separatorIsCaptured = pattern == _slashDate;
      for (final RegExpMatch m in pattern.allMatches(text)) {
        if (_claims(hits, m.start, m.end)) continue;
        final int first = int.parse(m.group(1)!);
        final int second = int.parse(
          separatorIsCaptured ? m.group(3)! : m.group(2)!,
        );
        final int rawYear = int.parse(
          separatorIsCaptured ? m.group(4)! : m.group(3)!,
        );
        final (int day, int month) = _orderParts(first, second, dayFirst);
        final int year = _fullYear(rawYear);

        // `15/9/1447` is a Hijri date spelled in digits, and it needs no era
        // marker to prove it: a four-digit year in the fourteen-hundreds
        // cannot be a Gregorian date this feature would accept, since the
        // ceiling is three years from today.
        final (int, int, int)? hijri =
            year >= _minHijriYear && year <= _maxHijriYear
            ? _toGregorian(year, month, day)
            : null;

        hits.add(
          _DateHit(
            start: m.start,
            end: m.end,
            year: hijri?.$1 ?? year,
            month: hijri?.$2 ?? month,
            day: hijri?.$3 ?? day,
          ),
        );
      }
    }

    for (final RegExpMatch m in _shortDate.allMatches(text)) {
      if (_claims(hits, m.start, m.end)) continue;
      final (int day, int month) = _orderParts(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        dayFirst,
      );
      hits.add(
        _DateHit(
          start: m.start,
          end: m.end,
          year: null,
          month: month,
          day: day,
          needsTime: true,
        ),
      );
    }
  }

  /// Resolves which number is the day.
  ///
  /// Whichever one cannot be a month settles it outright — `25/03` is the
  /// twenty-fifth in any region — and only a genuinely ambiguous pair falls
  /// through to the device's convention.
  static (int, int) _orderParts(int first, int second, bool dayFirst) {
    if (first > 12 && second <= 12) return (first, second);
    if (second > 12 && first <= 12) return (second, first);
    return dayFirst ? (first, second) : (second, first);
  }

  static int _fullYear(int raw) {
    if (raw >= 1000) return raw;
    // A two-digit year on a screenshot is this century unless it is very
    // clearly not; the cut-off only matters for dates we reject anyway.
    return raw < 70 ? 2000 + raw : 1900 + raw;
  }

  static void _findNamedDates(String text, List<_DateHit> hits) {
    for (final RegExpMatch m in _dayThenMonth.allMatches(text)) {
      _addNamed(hits, m, dayGroup: 1, monthGroup: 2, yearGroup: 3);
    }
    for (final RegExpMatch m in _monthThenDay.allMatches(text)) {
      if (_claims(hits, m.start, m.end)) continue;
      _addNamed(hits, m, dayGroup: 2, monthGroup: 1, yearGroup: 3);
    }
  }

  static void _addNamed(
    List<_DateHit> hits,
    RegExpMatch m, {
    required int dayGroup,
    required int monthGroup,
    required int yearGroup,
  }) {
    final int? month = _monthNumbers[_normalizeMonth(m.group(monthGroup)!)];
    if (month == null) return;
    final String? year = m.group(yearGroup);
    hits.add(
      _DateHit(
        start: m.start,
        end: m.end,
        year: year == null ? null : int.parse(year),
        month: month,
        day: int.parse(m.group(dayGroup)!),
      ),
    );
  }

  /// Every letter a month name is written in across the app's six languages,
  /// used to keep a name from matching inside a longer word.
  static const String _wordLetter = 'A-Za-zÀ-ɏ؀-ۿऀ-ॿ';

  /// The separator between a day number and its month: space, comma, or the
  /// Arabic comma, and never a newline — a day at the end of one line must not
  /// reach down and take the month heading off the next.
  static const String _daySeparator = '[ \t  ,،]{0,3}';

  static final RegExp _dayThenMonth = RegExp(
    '(?<![0-9])([0-9]{1,2})(?:st|nd|rd|th)?$_daySeparator'
    '($_monthAlternation)(?![$_wordLetter])'
    '(?:$_daySeparator([0-9]{4})(?![0-9]))?',
    caseSensitive: false,
  );

  static final RegExp _monthThenDay = RegExp(
    '(?<![$_wordLetter])($_monthAlternation)$_daySeparator'
    '([0-9]{1,2})(?:st|nd|rd|th)?(?![0-9])'
    '(?:$_daySeparator([0-9]{4})(?![0-9]))?',
    caseSensitive: false,
  );

  /// Month names in every language the app ships, plus the Levantine calendar
  /// — which is what Arabic screenshots from Jordan, Palestine, Syria, Lebanon
  /// and Iraq actually say. "أيار" is May there and matches nothing in a table
  /// built from "مايو".
  ///
  /// Written with single spaces and folded to single spaces before lookup, so
  /// "تشرين  الأول" off a two-column layout still resolves.
  static const Map<String, int> _monthNumbers = <String, int>{
    // English
    'jan': 1, 'january': 1, 'feb': 2, 'february': 2, 'mar': 3, 'march': 3,
    'apr': 4, 'april': 4, 'may': 5, 'jun': 6, 'june': 6, 'jul': 7, 'july': 7,
    'aug': 8, 'august': 8, 'sep': 9, 'sept': 9, 'september': 9, 'oct': 10,
    'october': 10, 'nov': 11, 'november': 11, 'dec': 12, 'december': 12,
    // Arabic — Gregorian names, used in the Gulf and Egypt
    'يناير': 1, 'فبراير': 2, 'مارس': 3, 'ابريل': 4, 'أبريل': 4, 'مايو': 5,
    'يونيو': 6, 'يونيه': 6, 'يوليو': 7, 'يوليه': 7, 'اغسطس': 8, 'أغسطس': 8,
    'سبتمبر': 9, 'اكتوبر': 10, 'أكتوبر': 10, 'نوفمبر': 11, 'ديسمبر': 12,
    // Arabic — Levantine names
    'كانون الثاني': 1, 'شباط': 2, 'اذار': 3, 'آذار': 3, 'نيسان': 4,
    'ايار': 5, 'أيار': 5, 'حزيران': 6, 'تموز': 7, 'اب': 8, 'آب': 8,
    'ايلول': 9, 'أيلول': 9, 'تشرين الاول': 10, 'تشرين الأول': 10,
    'تشرين الثاني': 11, 'كانون الاول': 12, 'كانون الأول': 12,
    // Urdu
    'جنوری': 1, 'فروری': 2, 'مارچ': 3, 'اپریل': 4, 'مئی': 5, 'جولائی': 7,
    'اگست': 8, 'ستمبر': 9, 'نومبر': 11, 'دسمبر': 12,
    // French
    'janvier': 1, 'février': 2, 'fevrier': 2, 'avril': 4, 'mai': 5,
    'juin': 6, 'juillet': 7, 'août': 8, 'aout': 8, 'septembre': 9,
    'octobre': 10, 'novembre': 11, 'décembre': 12, 'decembre': 12,
    // Spanish
    'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4, 'mayo': 5, 'junio': 6,
    'julio': 7, 'agosto': 8, 'septiembre': 9, 'setiembre': 9, 'octubre': 10,
    'noviembre': 11, 'diciembre': 12,
    // Hindi
    'जनवरी': 1, 'फरवरी': 2, 'फ़रवरी': 2, 'मार्च': 3, 'अप्रैल': 4, 'मई': 5,
    'जून': 6, 'जुलाई': 7, 'अगस्त': 8, 'सितंबर': 9, 'अक्टूबर': 10,
    'नवंबर': 11, 'दिसंबर': 12,
  };

  /// Longest first, so "september" is never matched as "sep" with a stray
  /// "tember" left behind, and "تشرين الثاني" beats nothing at all.
  static final String _monthAlternation =
      (_monthNumbers.keys.toList()
            ..sort((String a, String b) => b.length.compareTo(a.length)))
          .map((String name) => name.replaceAll(' ', '\\s+'))
          .join('|');

  static String _normalizeMonth(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  // -------------------------------------------------------------------
  // The Hijri calendar
  // -------------------------------------------------------------------

  /// Hijri dates are converted to Gregorian the moment they are read, so
  /// everything downstream — the past window, the three-year ceiling, the
  /// calendar link — keeps working on one kind of date and knows nothing
  /// about this.
  ///
  /// The conversion is Umm al-Qura, from the published table of lunar month
  /// lengths, not an arithmetic approximation. The distinction is the whole
  /// reason this took a dependency rather than thirty lines: the tabular
  /// Islamic calendar drifts from Umm al-Qura by a day or two, and a wedding
  /// entered on the wrong day is worse than one not entered at all. The
  /// table is what Saudi Arabia actually prints, which is what an invitation
  /// from the region actually says.
  ///
  /// The year is mandatory. A Hijri month name on its own is far too weak —
  /// `صفر` is also the word for zero, `رجب` is a given name — and a
  /// four-digit year in the fourteen-hundreds settles it beyond argument,
  /// since no Gregorian date this feature would ever accept has one.
  static void _findHijriDates(String text, List<_DateHit> hits) {
    for (final RegExpMatch m in _hijriNamedDate.allMatches(text)) {
      if (_claims(hits, m.start, m.end)) continue;
      final int? month = _hijriMonthNumbers[_normalizeMonth(m.group(2)!)];
      if (month == null) continue;

      final (int, int, int)? gregorian = _toGregorian(
        int.parse(m.group(3)!),
        month,
        int.parse(m.group(1)!),
      );
      if (gregorian == null) continue;

      hits.add(
        _DateHit(
          start: m.start,
          end: m.end,
          year: gregorian.$1,
          month: gregorian.$2,
          day: gregorian.$3,
        ),
      );
    }
  }

  /// `١٥ رمضان ١٤٤٧`, with an optional `من` before the month and an optional
  /// era marker after the year.
  static final RegExp _hijriNamedDate = RegExp(
    '(?<![0-9])([0-9]{1,2})$_daySeparator(?:من$_daySeparator)?'
    '($_hijriAlternation)(?![$_wordLetter])'
    '$_daySeparator([0-9]{4})(?![0-9])'
    '(?:$_daySeparator(?:هـ|هجري|ه\\.|AH))?',
    caseSensitive: false,
  );

  /// The twelve lunar months, in the spellings that actually appear on a
  /// printed card.
  ///
  /// The variants are not padding. Hamza is dropped as often as it is written
  /// (`ربيع الأول` / `ربيع الاول`), the fourth and sixth months each have two
  /// accepted names (`الثاني` and `الآخر`), and the last two are written both
  /// joined and separated. Any one of those missing is a whole class of
  /// invitation that silently does nothing.
  static const Map<String, int> _hijriMonthNumbers = <String, int>{
    'محرم': 1,
    'المحرم': 1,
    'muharram': 1,
    'صفر': 2,
    'safar': 2,
    'ربيع الاول': 3,
    'ربيع الأول': 3,
    'ربيع اول': 3,
    'ربيع1': 3,
    'rabi al-awwal': 3,
    'rabi i': 3,
    'ربيع الثاني': 4,
    'ربيع الآخر': 4,
    'ربيع الاخر': 4,
    'ربيع ثاني': 4,
    'rabi al-thani': 4,
    'rabi ii': 4,
    'جمادى الاولى': 5,
    'جمادى الأولى': 5,
    'جمادى الاول': 5,
    'جماد الاول': 5,
    'jumada al-awwal': 5,
    'jumada i': 5,
    'جمادى الثانية': 6,
    'جمادى الآخرة': 6,
    'جمادى الاخرة': 6,
    'جمادى الثاني': 6,
    'jumada al-thani': 6,
    'jumada ii': 6,
    'رجب': 7,
    'rajab': 7,
    'شعبان': 8,
    'shaaban': 8,
    'shaban': 8,
    'رمضان': 9,
    'ramadan': 9,
    'ramadhan': 9,
    'شوال': 10,
    'شوّال': 10,
    'shawwal': 10,
    'ذو القعدة': 11,
    'ذو القعده': 11,
    'ذي القعدة': 11,
    'ذوالقعدة': 11,
    'ذو القعدة الحرام': 11,
    'dhu al-qidah': 11,
    'ذو الحجة': 12,
    'ذو الحجه': 12,
    'ذي الحجة': 12,
    'ذوالحجة': 12,
    'ذو الحجة الحرام': 12,
    'dhu al-hijjah': 12,
  };

  static final String _hijriAlternation =
      (_hijriMonthNumbers.keys.toList()
            ..sort((String a, String b) => b.length.compareTo(a.length)))
          .map((String name) => name.replaceAll(' ', '\\s+'))
          .join('|');

  /// The span of Hijri years worth converting.
  ///
  /// Far wider than the three years this feature will actually accept,
  /// because the window check happens later and on Gregorian dates. The
  /// bounds exist only to keep an absurd year away from the lookup table,
  /// which throws rather than returning nothing when asked for a month it has
  /// no data for.
  static const int _minHijriYear = 1400;
  static const int _maxHijriYear = 1500;

  static (int, int, int)? _toGregorian(int year, int month, int day) {
    if (year < _minHijriYear || year > _maxHijriYear) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1) return null;

    try {
      final HijriCalendar calendar = HijriCalendar();
      // A lunar month is twenty-nine or thirty days, and asking for the
      // thirtieth of a twenty-nine-day month rolls silently into the next one
      // — the same failure `DateTime` has with the thirty-first of February,
      // and rejected here for the same reason.
      if (day > calendar.getDaysInMonth(year, month)) return null;

      final DateTime converted = calendar.hijriToGregorian(year, month, day);
      return (converted.year, converted.month, converted.day);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------
  // Times
  // -------------------------------------------------------------------

  /// `15:00`, `3:00 PM`, `٣:٠٠ م`.
  ///
  /// A colon and nothing else. `3.00` is a price far more often than it is
  /// three o'clock, and no clock on any screen renders with a full stop.
  ///
  /// Space around the colon is allowed for the same reason the date pattern
  /// allows it — decorative type recognises as `8 : 00`. The two-digit minute
  /// is what keeps that safe: it rejects the ratios and scores (`3 : 1`) that
  /// a looser minute would swallow.
  static final RegExp _clockTime = RegExp(
    '(?<![0-9:.])([0-9]{1,2})[ 	 ]*:[ 	 ]*([0-9]{2})(?![0-9])'
    '(?:[ \t ]*($_meridiem))?',
    caseSensitive: false,
  );

  /// `7 PM` — no minutes, so a marker is mandatory. Without one this is just
  /// a number.
  static final RegExp _hourTime = RegExp(
    '(?<![0-9:.])([0-9]{1,2})[ \t ]*($_meridiem)',
    caseSensitive: false,
  );

  /// Every alternative here ends in a lookahead, and both of them are load
  /// bearing.
  ///
  /// The Latin one keeps `15:00 amount` from reading as a morning. The Arabic
  /// one matters far more: `م` is one of the commonest letters in the
  /// language, so without it every word starting in meem turns the number
  /// before it into an afternoon.
  ///
  /// Longest alternative first — the engine takes the first that matches, and
  /// `ص` offered before `صباحاً` would claim the first letter of it.
  static const String _meridiem =
      r'a\.?m\.?(?![a-z])|p\.?m\.?(?![a-z])|'
      '(?:صباحاً|صباحًا|صباحا|مساءً|مساءا|مساء|ظهراً|ظهرا|ص|م)'
      '(?![؀-ۿ])';

  /// What sits between the two ends of a range. The word joins carry a
  /// lookahead so "3:00 today" does not read as a range starting with "to".
  static final RegExp _rangeJoin = RegExp(
    r'^[ \t ]*(?:[-–—]|(?:to|until|till|hasta|a|à)(?![a-z])'
    '|حتى|الى|إلى|لغاية)[ \t ]*',
    caseSensitive: false,
  );

  /// The clock time belonging to a date.
  ///
  /// Searched on the date's own line and the one after it, and nowhere else.
  /// A window measured in characters would reach across a whole itinerary and
  /// pair Tuesday's date with Thursday's departure time.
  static _TimeHit? _timeNear(
    String text,
    List<_Line> lines,
    int lineIndex,
    _DateHit date,
  ) {
    if (lineIndex < 0) return null;
    for (int i = lineIndex; i <= lineIndex + 1 && i < lines.length; i++) {
      final _Line line = lines[i];
      final _TimeHit? hit = _timeIn(text, line, date);
      if (hit != null) return hit;
    }
    return null;
  }

  static _TimeHit? _timeIn(String text, _Line line, _DateHit date) {
    for (final RegExp pattern in <RegExp>[_clockTime, _hourTime]) {
      final bool withMinutes = identical(pattern, _clockTime);
      for (final RegExpMatch m in pattern.allMatches(line.text)) {
        final int start = line.start + m.start;
        final int end = line.start + m.end;
        // The date's own digits are not its time. Without this "12/05" hands
        // its own "12" to the hour-only pattern.
        if (start < date.end && date.start < end) continue;

        final _Clock? clock = _clockOf(m, withMinutes);
        if (clock == null) continue;

        final (_Clock, int)? closing = _rangeEndAfter(line, m.end);
        return _TimeHit(
          start: start,
          end: closing == null ? end : line.start + closing.$2,
          hour: clock.hour,
          minute: clock.minute,
          endHour: closing?.$1.hour,
          endMinute: closing?.$1.minute,
        );
      }
    }
    return null;
  }

  /// Reads one match of either time pattern.
  ///
  /// The two patterns put the meridiem in different groups — third when
  /// minutes were captured, second when they weren't — which is the entire
  /// reason this takes a flag rather than reading a fixed index.
  static _Clock? _clockOf(Match m, bool withMinutes) {
    final int minute = withMinutes ? int.parse(m.group(2)!) : 0;
    if (minute > 59) return null;
    final int? hour = _hourOf(
      int.parse(m.group(1)!),
      withMinutes ? m.group(3) : m.group(2),
    );
    if (hour == null) return null;
    return _Clock(hour, minute);
  }

  /// The `- 5:00 PM` half of a range, if the line has one directly after the
  /// start time. [offset] is relative to the line, as [RegExpMatch.end] is.
  static (_Clock, int)? _rangeEndAfter(_Line line, int offset) {
    if (offset >= line.text.length) return null;

    final String tail = line.text.substring(offset);
    final RegExpMatch? join = _rangeJoin.firstMatch(tail);
    if (join == null) return null;

    final String rest = tail.substring(join.end);
    for (final RegExp pattern in <RegExp>[_clockTime, _hourTime]) {
      final Match? m = pattern.matchAsPrefix(rest);
      if (m == null) continue;
      final _Clock? clock = _clockOf(m, identical(pattern, _clockTime));
      if (clock == null) continue;
      return (clock, offset + join.end + m.end);
    }
    return null;
  }

  /// Folds a twelve-hour reading onto a twenty-four-hour one, and returns null
  /// for an hour that cannot be an hour.
  ///
  /// A bare `3:00` with no marker is left at three in the morning rather than
  /// promoted to the afternoon. Promoting it would be right most of the time
  /// and silently twelve hours wrong the rest, and a wrong time in somebody's
  /// calendar is the failure this whole feature has to avoid.
  static int? _hourOf(int raw, String? marker) {
    if (marker == null || marker.isEmpty) {
      return raw <= 23 ? raw : null;
    }
    if (raw < 1 || raw > 12) return null;

    final String tag = marker.toLowerCase().replaceAll('.', '');
    final bool afternoon =
        tag.startsWith('p') ||
        tag == 'م' ||
        tag.startsWith('مساء') ||
        tag.startsWith('ظهر');
    if (afternoon) return raw == 12 ? 12 : raw + 12;
    return raw == 12 ? 0 : raw;
  }

  // -------------------------------------------------------------------
  // Context: cues, titles, venues
  // -------------------------------------------------------------------

  /// Words that mean a date on this screen is a plan rather than a record.
  ///
  /// A trailing `*` is a deliberate stem, matched from the start of a word and
  /// allowed to run on — `invit*` has to reach invitation, invited and
  /// inviting, and `schedul*` both "schedule" and "scheduled". Everything else
  /// is matched as a whole word by [TextCues], which is what keeps `event` out
  /// of "eventually", `exam` out of "example", `session` out of "possession"
  /// and the Spanish `cita` out of "citación".
  static const List<String> _cues = <String>[
    'invit*',
    'rsvp',
    'meeting',
    'appointment',
    'event',
    'reserv*',
    'booking',
    'booked',
    'ceremony',
    'seminar',
    'webinar',
    'conference',
    'session',
    'interview',
    'wedding',
    'birthday',
    'deadline',
    'due date',
    'agenda',
    'schedul*',
    'starts at',
    'exam',
    'departure',
    'check-in',
    'boarding',
    'دعوة',
    'دعوه',
    'مدعو',
    'موعد',
    'اجتماع',
    'حجز',
    'محجوز',
    'مناسبة',
    'مناسبه',
    'حفل',
    'ندوة',
    'مؤتمر',
    'جلسة',
    'مقابلة',
    'زفاف',
    'عرس',
    'امتحان',
    'المغادرة',
    'الرحلة',
    'تسليم',
    'موعدك',
    'réunion',
    'rendez-vous',
    'invitation',
    'événement',
    'reunión',
    'cita',
    'invitación',
    'evento',
    'निमंत्रण',
    'बैठक',
    'कार्यक्रम',
  ];

  /// How far either side of the date a cue may sit. Wider than the time
  /// window on purpose — the word "Invitation" is usually a heading several
  /// lines above the date it belongs to.
  static const int _cueWindow = 160;

  static bool _hasCueNear(String haystack, int start, int end) =>
      TextCues.anyNear(haystack, start, end, _cueWindow, _cues);

  static final RegExp _venueLabel = RegExp(
    r'(?:location|venue|address|place|where|'
    r'المكان|الموقع|العنوان|مكان|lieu|adresse|lugar|dirección)'
    r'[ \t ]*[:：]{1}[ \t ]*(.{3,80})$',
    caseSensitive: false,
  );

  /// A venue, only when a line says outright that it is one.
  ///
  /// The colon is doing real work: "location services" and "address book" are
  /// not venues, and an unlabelled line near a date is anybody's guess.
  static String? _locationNear(List<_Line> lines, int lineIndex) {
    if (lineIndex < 0) return null;
    final int from = (lineIndex - 2).clamp(0, lines.length);
    final int to = (lineIndex + 3).clamp(0, lines.length);
    for (int i = from; i < to; i++) {
      final RegExpMatch? m = _venueLabel.firstMatch(lines[i].text.trim());
      if (m != null) return m.group(1)!.trim();
    }
    return null;
  }

  /// The line most likely to be what this event is called.
  ///
  /// Searched *above* the date first, because headings sit above their detail
  /// on every screen ever designed, and capped at four lines so a title is
  /// never dragged in from an unrelated card.
  ///
  /// The date's own line is the second choice rather than the first, and the
  /// order is what makes the difference between "Team sync" and "Meeting on
  /// 12/05/2026 at 3:00 PM" ending up in the calendar. It stays a choice at
  /// all because plenty of screens put the whole thing on one line.
  ///
  /// Falls back to the first usable line on the screen, then to nothing — at
  /// which point the UI supplies a translated placeholder, which is better
  /// than this layer inventing an English one.
  static int _titleLineFor(List<_Line> lines, int lineIndex) {
    if (lineIndex < 0) return -1;
    final int stop = (lineIndex - 4).clamp(0, lines.length);
    for (int i = lineIndex - 1; i >= stop; i--) {
      if (_isTitleish(lines[i].text)) return i;
    }
    if (_isTitleish(lines[lineIndex].text)) return lineIndex;
    for (int i = 0; i < lines.length; i++) {
      if (_isTitleish(lines[i].text)) return i;
    }
    return -1;
  }

  static final RegExp _letters = RegExp('[$_wordLetter]');

  static bool _isTitleish(String raw) {
    final String line = raw.trim();
    if (line.length < 3 || line.length > 60) return false;

    int letters = 0;
    for (final Match _ in _letters.allMatches(line)) {
      letters++;
      if (letters >= 4) break;
    }
    if (letters < 4) return false;

    // A line that is mostly digits is the date itself, or a price, or a
    // reference number — never a title.
    final int digits = line.replaceAll(RegExp('[^0-9]'), '').length;
    return digits * 2 < line.length;
  }

  /// Everything between the title and the date, so the calendar's notes field
  /// carries the detail the user could see and this parser could not.
  static String? _notesBetween(List<_Line> lines, int titleLine, int dateLine) {
    if (dateLine < 0) return null;
    final int from = titleLine < 0 ? dateLine : titleLine;
    final StringBuffer buffer = StringBuffer();
    for (int i = from; i <= dateLine && i < lines.length; i++) {
      final String line = lines[i].text.trim();
      if (line.isEmpty) continue;
      if (buffer.length + line.length > 400) break;
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(line);
    }
    final String notes = buffer.toString();
    return notes.isEmpty ? null : notes;
  }

  // -------------------------------------------------------------------
  // Lines and spans
  // -------------------------------------------------------------------

  static List<_Line> _linesOf(String text) {
    final List<_Line> lines = <_Line>[];
    int start = 0;
    while (start <= text.length) {
      final int newline = text.indexOf('\n', start);
      final int end = newline < 0 ? text.length : newline;
      lines.add(_Line(start, text.substring(start, end)));
      if (newline < 0) break;
      start = newline + 1;
    }
    return lines;
  }

  static int _lineIndexOf(List<_Line> lines, int offset) {
    for (int i = 0; i < lines.length; i++) {
      if (offset >= lines[i].start && offset <= lines[i].end) return i;
    }
    return -1;
  }

  /// A date inside a URL is a path segment. `example.com/2026/05/12/post` is a
  /// blog archive, not next Tuesday.
  static bool _sitsInsideUrl(String text, int offset) {
    int start = offset;
    while (start > 0 && !_isBreak(text.codeUnitAt(start - 1))) {
      start--;
    }
    int end = offset;
    while (end < text.length && !_isBreak(text.codeUnitAt(end))) {
      end++;
    }
    final String token = text.substring(start, end).toLowerCase();
    return token.contains('://') || token.startsWith('www.');
  }

  static bool _isBreak(int unit) =>
      unit == 0x20 ||
      unit == 0x09 ||
      unit == 0x0A ||
      unit == 0x0D ||
      unit == 0x00A0;

  static bool _claims(List<_DateHit> hits, int start, int end) {
    for (final _DateHit hit in hits) {
      if (start < hit.end && hit.start < end) return true;
    }
    return false;
  }

  static bool _overlapsFound(List<Extraction> found, int start, int end) {
    for (final Extraction e in found) {
      if (start < e.end && e.start < end) return true;
    }
    return false;
  }

  static int _maxOf(int a, int b) => a > b ? a : b;
}

class _Line {
  final int start;
  final String text;
  const _Line(this.start, this.text);

  int get end => start + text.length;
}

class _DateHit {
  final int start;
  final int end;

  /// Null when the screenshot never said which year, which is normal: an
  /// invitation says "Thursday 12 May" because everyone reading it knows.
  final int? year;
  final int month;
  final int day;

  /// True for the year-less numeric spelling only, which is weak enough that a
  /// clock time beside it is made mandatory.
  final bool needsTime;

  const _DateHit({
    required this.start,
    required this.end,
    required this.year,
    required this.month,
    required this.day,
    this.needsTime = false,
  });

  /// The calendar day this refers to, or null when it refers to none.
  ///
  /// A missing year resolves forward: the next occurrence at or after today,
  /// which is what "the twelfth of May" means to somebody reading it in
  /// December.
  DateTime? resolve(DateTime today) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    if (year != null) return _exact(year!, month, day);

    for (int candidate = today.year; candidate <= today.year + 1; candidate++) {
      final DateTime? resolved = _exact(candidate, month, day);
      if (resolved == null) continue;
      if (!resolved.isBefore(today)) return resolved;
    }
    return null;
  }

  /// Rejects the thirty-first of February instead of letting [DateTime] roll it
  /// quietly into March.
  static DateTime? _exact(int year, int month, int day) {
    final DateTime built = DateTime(year, month, day);
    if (built.year != year || built.month != month || built.day != day) {
      return null;
    }
    return built;
  }
}

class _Clock {
  final int hour;
  final int minute;
  const _Clock(this.hour, this.minute);
}

class _TimeHit {
  final int start;
  final int end;
  final int hour;
  final int minute;
  final int? endHour;
  final int? endMinute;

  const _TimeHit({
    required this.start,
    required this.end,
    required this.hour,
    required this.minute,
    this.endHour,
    this.endMinute,
  });
}
