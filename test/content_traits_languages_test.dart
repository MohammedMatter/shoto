import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/content_traits.dart';

/// The app ships in six languages, and until this file existed the detection
/// behind the library's content filters was only ever exercised in two of
/// them. Running the same four realistic screenshots through every language
/// found one outright bug and two whole-language gaps:
///
/// * an Arabic phone number could never satisfy the cue test, because the
///   match is cut from digit-normalised text and was being looked up in the
///   raw string — `٠٥٩٩١٢٣٤٥٦` and `0599123456` share no characters;
/// * the verification-code cues held English and Arabic only, so a Spanish,
///   Hindi or Urdu one-time password was never a code;
/// * the bare-domain TLD list had no `es`, `fr`, `in` or `pk`, so a plain
///   domain was invisible in four of the six.
///
/// None of these are visible in English, which is exactly why the table is
/// here rather than a handful of hand-picked cases.
void main() {
  const Map<String, Map<ContentTrait, String>> byLanguage =
      <String, Map<ContentTrait, String>>{
        'English': <ContentTrait, String>{
          ContentTrait.code: 'Your verification code is 481920',
          ContentTrait.contact: 'Mobile 0599123456',
          ContentTrait.event: 'Meeting on 12/05/2027 at 3:00 PM',
          ContentTrait.link: 'visit example.com today',
        },
        'Arabic': <ContentTrait, String>{
          ContentTrait.code: 'رمز التحقق الخاص بك هو ٤٨١٩٢٠',
          ContentTrait.contact: 'جوال ٠٥٩٩١٢٣٤٥٦',
          ContentTrait.event: 'موعد الاجتماع ١٢/٠٥/٢٠٢٧ الساعة ٣:٠٠',
          ContentTrait.link: 'زوروا example.com اليوم',
        },
        'Spanish': <ContentTrait, String>{
          ContentTrait.code: 'Su código de verificación es 481920',
          ContentTrait.contact: 'Teléfono 0599123456',
          ContentTrait.event: 'Reunión el 12/05/2027 a las 15:00',
          ContentTrait.link: 'visita ejemplo.es hoy',
        },
        'French': <ContentTrait, String>{
          ContentTrait.code: 'Votre code de vérification est 481920',
          ContentTrait.contact: 'Téléphone 0599123456',
          ContentTrait.event: 'Réunion le 12/05/2027 à 15:00',
          ContentTrait.link: 'visitez exemple.fr maintenant',
        },
        'Hindi': <ContentTrait, String>{
          ContentTrait.code: 'आपका सत्यापन कोड 481920 है',
          ContentTrait.contact: 'मोबाइल 0599123456',
          ContentTrait.event: 'बैठक 12/05/2027 को 3:00 बजे',
          ContentTrait.link: 'देखें udaharan.in आज',
        },
        'Urdu': <ContentTrait, String>{
          ContentTrait.code: 'آپ کا تصدیقی کوڈ 481920 ہے',
          ContentTrait.contact: 'فون 0599123456',
          ContentTrait.event: 'ملاقات 12/05/2027 کو 3:00 بجے',
          ContentTrait.link: 'دیکھیں misal.pk آج',
        },
      };

  byLanguage.forEach((String language, Map<ContentTrait, String> samples) {
    group(language, () {
      samples.forEach((ContentTrait trait, String text) {
        test('finds ${trait.name}', () {
          expect(ContentTraits.of(text), contains(trait));
        });
      });
    });
  });

  group('digit systems', () {
    // The bug this file was written for. Arabic-Indic and Persian/Urdu digits
    // are different code points again, and both have to survive the round trip
    // through normalisation and back into the cue lookup.
    test('Arabic-Indic digits reach the cue test', () {
      expect(
        ContentTraits.of('هاتف ٠٥٩٩١٢٣٤٥٦'),
        contains(ContentTrait.contact),
      );
    });

    test('Persian and Urdu digits reach it too', () {
      expect(
        ContentTraits.of('فون ۰۵۹۹۱۲۳۴۵۶'),
        contains(ContentTrait.contact),
      );
    });

    test('an uncued Arabic-Indic run is still rejected', () {
      // The fix must not turn into "any Arabic number is a phone".
      expect(
        ContentTraits.of('رقم الطلب ٥٥٥١٢٣٤'),
        isNot(contains(ContentTrait.contact)),
      );
    });
  });
}
