import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/content_traits.dart';

/// The app ships in seven languages, and until this file existed the detection
/// behind the library's content filters was only ever exercised in one of
/// them. Running the same four realistic screenshots through every language is
/// what found the whole-language gaps — a verification-code cue list holding
/// only English, a bare-domain TLD list with no `es` or `fr` — none of which
/// are visible in English, which is exactly why this is a table rather than a
/// handful of hand-picked cases.
///
/// **Every language here is one the recogniser can actually read.** The table
/// used to include Arabic, Hindi and Urdu and they passed, because a test
/// hands `ContentTraits` a string directly. On a phone nothing ever handed it
/// one: `TextRecognitionScript.latin` cannot produce those characters, so the
/// rows were green over a feature that did not exist. That gap is the reason
/// the shipped language set changed — see
/// `docs/decisions/shipped-languages.md`. Adding a language to
/// [AppLanguage] means adding a row here, and it means checking the model can
/// read it first.
void main() {
  const Map<String, Map<ContentTrait, String>> byLanguage =
      <String, Map<ContentTrait, String>>{
        'English': <ContentTrait, String>{
          ContentTrait.code: 'Your verification code is 481920',
          ContentTrait.contact: 'Mobile 0599123456',
          ContentTrait.event: 'Meeting on 12/05/2027 at 3:00 PM',
          ContentTrait.link: 'visit example.com today',
        },
        'German': <ContentTrait, String>{
          ContentTrait.code: 'Ihr Bestätigungscode lautet 481920',
          ContentTrait.contact: 'Telefon 0599123456',
          ContentTrait.event: 'Termin am 12/05/2027 um 15:00',
          ContentTrait.link: 'besuchen Sie beispiel.de heute',
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
        'Italian': <ContentTrait, String>{
          ContentTrait.code: 'Il tuo codice di verifica è 481920',
          ContentTrait.contact: 'Cellulare 0599123456',
          ContentTrait.event: 'Riunione il 12/05/2027 alle 15:00',
          ContentTrait.link: 'visita esempio.it oggi',
        },
        'Portuguese': <ContentTrait, String>{
          ContentTrait.code: 'O seu código de verificação é 481920',
          ContentTrait.contact: 'Telemóvel 0599123456',
          ContentTrait.event: 'Reunião em 12/05/2027 às 15:00',
          ContentTrait.link: 'visite exemplo.pt hoje',
        },
        'Dutch': <ContentTrait, String>{
          ContentTrait.code: 'Je verificatiecode is 481920',
          ContentTrait.contact: 'Telefoonnummer 0599123456',
          ContentTrait.event: 'Afspraak op 12/05/2027 om 15:00',
          ContentTrait.link: 'bezoek voorbeeld.nl vandaag',
        },
      };

  /// The clock the event samples are measured against. Every one of them is
  /// dated 12/05/2027, which is only in the future because of this line — and
  /// `dayFirst` because that date is ambiguous, so without it the answer
  /// depends on the region the test happens to run in.
  final DateTime today = DateTime(2026, 3, 1);

  Set<ContentTrait> traitsOf(String text) =>
      ContentTraits.of(text, now: today, dayFirst: true);

  byLanguage.forEach((String language, Map<ContentTrait, String> samples) {
    group(language, () {
      samples.forEach((ContentTrait trait, String text) {
        test('finds ${trait.name}', () {
          expect(traitsOf(text), contains(trait));
        });
      });
    });
  });

  group('a cue is required, in every language', () {
    /// The other half of the contract, and the half a cue list makes easy to
    /// break: adding words until everything matches. A bare run of digits with
    /// no word vouching for it is a reference number, whatever language the
    /// rest of the screen is in.
    const List<String> uncued = <String>[
      'Bestellnummer 5551234',
      'Numero ordine 5551234',
      'Número do pedido 5551234',
      'Bestelnummer 5551234',
      'Order 5551234',
    ];

    for (final String text in uncued) {
      test('"$text" is not a contact', () {
        expect(traitsOf(text), isNot(contains(ContentTrait.contact)));
      });
    }
  });
}
