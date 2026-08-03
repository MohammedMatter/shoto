/// Turns what a vision model saw into words a person would actually type.
///
/// The on-device model emits English nouns like `Cat`, `Ice cream`, `Skyline`
/// — a fixed vocabulary it was trained on. That is not what anybody searches
/// for. They type "قطة", or "حيوان", or "kitten", and expect the picture of a
/// cat. This maps between the two.
///
/// Three ideas do all the work:
///
/// 1. **A raw label is always searchable as itself.** Everything below is
///    *additional*. If a label is missing from these tables — or the model is
///    updated and starts emitting a name nobody here predicted — searching
///    its English word still finds it. A gap costs Arabic support for one
///    label; it never costs the feature. That also means over-listing is
///    free: a label written here that the model never emits simply never
///    matches anything, so the tables can be generous.
/// 2. **Synonyms carry the Arabic.** One label, several everyday words, in
///    both languages.
/// 3. **Groups carry the general question.** The model never says "animal";
///    it says `Cat`. Somebody looking for "صورة حيوان" is asking a broader
///    question than any single label answers, so groups bridge the two.
///
/// Pure Dart on purpose — no Flutter imports — so all of it is unit-testable
/// without a widget tree, the same split used by [PerceptualHash] and
/// [ScrollStitcher].
class VisualVocabulary {
  /// Below this, a query matches so much that the results are noise. Two
  /// characters is enough for "قط" to find a cat.
  static const int minimumQueryLength = 2;

  /// Labels that describe the *medium*, not the subject.
  ///
  /// This list is the difference between the feature working and the feature
  /// looking broken, and it was found by reading the real database rather
  /// than by reasoning: almost every row in a live library was
  /// `["Screenshot"]`, `["Mobile phone","Screenshot"]`, or
  /// `["Product","Screenshot","Mobile phone","Web page"]`.
  ///
  /// The reason is structural. The model describes the whole frame, and the
  /// whole frame is a phone screen — so a screenshot *of a dog* scores
  /// "Screenshot" around 0.9 and "Dog" far lower, because the dog occupies a
  /// fraction of the picture. Keeping these labels does active harm twice
  /// over: they crowd out the real subject under any confidence threshold,
  /// and they make "shows something" match every screenshot in the library,
  /// which is the same as matching nothing.
  ///
  /// Dropped at both ends — never stored, and filtered again when reading, so
  /// libraries indexed before this existed are cleaned up on the way out.
  static const Set<String> mediumLabels = {
    'Screenshot',
    'Mobile phone',
    'Smartphone',
    'Telephone',
    'Portable communications device',
    'Communication Device',
    'Gadget',
    'Electronic device',
    'Display device',
    'Screen',
    'Technology',
    'Software',
    'Web page',
    'Website',
    'Multimedia',
    'Font',
    'Text',
    'Line',
    'Parallel',
    'Rectangle',
    'Circle',
    'Number',
    'Icon',
    'Logo',
    'Brand',
    'Material property',
    'Colorfulness',
    'Azure',
    'Product',
    'Paper',
    'Document',
  };

  /// Whether [label] says something about what a picture is *of*.
  static bool isMeaningful(String label) => !mediumLabels.contains(label);

  /// [labels] with the medium-describing ones removed.
  static List<String> meaningful(Iterable<String> labels) => [
    for (final String label in labels)
      if (isMeaningful(label)) label,
  ];

  /// Everyday words for a single label, in both languages.
  ///
  /// Arabic is written naturally here — [normalize] is applied to these and
  /// to the query alike, so spelling "قطة" with a ta marbuta still matches
  /// somebody who typed "قطه".
  static const Map<String, List<String>> synonyms = {
    'Cat': ['قطة', 'قطط', 'بسة', 'هرة', 'kitten'],
    'Dog': ['كلب', 'كلاب', 'جرو', 'puppy'],
    // Labels the live model actually emitted on this user's library that had
    // no everyday word attached — so the evidence was there and unreachable.
    'Snout': ['وجه حيوان', 'خطم'],
    'Whiskers': ['شوارب'],
    'Fur': ['فرو', 'فراء'],
    'Bird': ['طير', 'طيور', 'عصفور'],
    'Fish': ['سمك', 'سمكة', 'أسماك'],
    'Horse': ['حصان', 'خيل', 'أحصنة'],
    'Butterfly': ['فراشة', 'فراشات'],
    'Insect': ['حشرة', 'حشرات'],
    'Rabbit': ['أرنب', 'أرانب'],
    'Lion': ['أسد', 'سبع'],
    'Tiger': ['نمر'],
    'Elephant': ['فيل'],
    'Monkey': ['قرد'],
    'Bear': ['دب'],
    'Snake': ['ثعبان', 'حية', 'أفعى'],
    'Turtle': ['سلحفاة'],
    'Sheep': ['خروف', 'غنم'],
    'Cattle': ['بقرة', 'بقر', 'ثور', 'cow'],
    'Chicken': ['دجاجة', 'دجاج', 'فروج'],
    'Duck': ['بطة', 'بط'],
    'Camel': ['جمل', 'ناقة'],
    'Pet': ['حيوان أليف', 'أليف', 'pets'],

    'Food': ['أكل', 'طعام', 'وجبة'],
    'Dessert': ['حلى', 'حلويات', 'تحلية'],
    'Cake': ['كيك', 'كيكة', 'قالب حلى', 'تورتة'],
    'Bread': ['خبز', 'عيش'],
    'Fruit': ['فاكهة', 'فواكه'],
    'Vegetable': ['خضار', 'خضروات'],
    'Ice cream': ['بوظة', 'آيس كريم', 'جيلاتي'],
    'Pizza': ['بيتزا'],
    'Hamburger': ['برجر', 'برغر', 'burger'],
    'Sandwich': ['ساندويش', 'شطيرة'],
    'Rice': ['رز', 'أرز'],
    'Meat': ['لحم', 'لحمة'],
    'Soup': ['شوربة', 'حساء'],
    'Salad': ['سلطة'],
    'Coffee': ['قهوة', 'كوفي', 'اسبريسو'],
    'Tea': ['شاي'],
    'Drink': ['مشروب', 'عصير', 'juice'],
    'Cooking': ['طبخ', 'وصفة', 'recipe'],
    'Restaurant': ['مطعم'],

    'Person': ['شخص', 'انسان', 'ناس'],
    'Selfie': ['سيلفي', 'صورة شخصية'],
    'Smile': ['ابتسامة', 'ضحكة'],
    'Baby': ['طفل', 'بيبي', 'رضيع'],
    'Child': ['طفل', 'أطفال', 'ولد'],
    'Crowd': ['زحمة', 'حشد', 'جمهور'],
    'Wedding': ['عرس', 'زفاف', 'فرح'],
    'Hairstyle': ['تسريحة', 'شعر', 'قصة شعر'],
    'Nail': ['أظافر', 'مناكير'],
    'Tattoo': ['وشم', 'تاتو'],

    'Sky': ['سماء', 'سما'],
    'Cloud': ['غيم', 'غيوم', 'سحاب'],
    'Sunset': ['غروب'],
    'Sunrise': ['شروق'],
    'Beach': ['شاطئ', 'بحر', 'رملة'],
    'Mountain': ['جبل', 'جبال'],
    'Snow': ['ثلج', 'تلج'],
    'Waterfall': ['شلال'],
    'Lake': ['بحيرة'],
    'River': ['نهر'],
    'Forest': ['غابة', 'غابات'],
    'Desert': ['صحراء'],
    'Tree': ['شجرة', 'شجر'],
    'Flower': ['وردة', 'ورد', 'زهرة', 'زهور'],
    'Plant': ['نبتة', 'نبات', 'زرع'],
    'Grass': ['عشب', 'حشيش'],
    'Garden': ['حديقة', 'جنينة'],
    'Rain': ['مطر', 'شتاء'],
    'Rainbow': ['قوس قزح'],
    'Moon': ['قمر'],
    'Night': ['ليل', 'مسا'],
    'Landscape': ['منظر', 'مناظر', 'طبيعة خلابة'],

    'Car': ['سيارة', 'سيارات', 'عربية'],
    'Bicycle': ['بسكليت', 'دراجة', 'bike'],
    'Motorcycle': ['موتور', 'دراجة نارية'],
    'Boat': ['قارب', 'مركب'],
    'Airplane': ['طيارة', 'طائرة', 'plane'],
    'Train': ['قطار'],
    'Bus': ['باص', 'حافلة'],
    'Truck': ['شاحنة', 'تريلا'],
    'Road': ['شارع', 'طريق'],

    'Building': ['مبنى', 'بناية', 'عمارة'],
    'House': ['بيت', 'منزل', 'دار'],
    'Skyscraper': ['ناطحة سحاب', 'برج'],
    'Bridge': ['جسر'],
    'Mosque': ['مسجد', 'جامع'],
    'Church': ['كنيسة'],
    'City': ['مدينة'],
    'Room': ['غرفة', 'أوضة'],
    'Kitchen': ['مطبخ'],
    'Furniture': ['أثاث', 'موبيليا'],
    'Interior design': ['ديكور', 'تصميم داخلي'],

    'Sports': ['رياضة'],
    'Football': ['كرة قدم', 'فوتبول', 'soccer'],
    'Basketball': ['كرة سلة'],
    'Swimming': ['سباحة'],
    'Gym': ['جيم', 'نادي', 'تمرين'],
    'Running': ['ركض', 'جري'],

    'Music': ['موسيقى', 'أغنية', 'أغاني'],
    'Guitar': ['جيتار'],
    'Piano': ['بيانو'],
    'Concert': ['حفلة', 'كونسرت'],
    'Dance': ['رقص', 'رقصة'],

    'Laptop': ['لابتوب', 'حاسوب محمول'],
    'Computer': ['كمبيوتر', 'حاسوب', 'pc'],
    'Mobile phone': ['موبايل', 'جوال', 'تلفون', 'phone'],
    'Keyboard': ['كيبورد', 'لوحة مفاتيح'],
    'Camera': ['كاميرا'],
    'Watch': ['ساعة'],
    'Television': ['تلفزيون', 'شاشة', 'tv'],

    'Book': ['كتاب', 'كتب'],
    'Newspaper': ['جريدة', 'صحيفة'],
    'Handwriting': ['خط يد', 'كتابة يدوية'],
    'Map': ['خريطة'],
    'Menu': ['منيو', 'قائمة طعام'],
    'Poster': ['بوستر', 'ملصق'],
    'Calendar': ['تقويم', 'روزنامة'],

    'Painting': ['لوحة', 'رسمة', 'رسم زيتي'],
    'Drawing': ['رسم', 'رسمة', 'اسكتش'],
    'Comics': ['كوميك', 'قصة مصورة'],
    'Cartoon': ['كرتون', 'رسوم متحركة'],
    'Anime': ['أنمي', 'انمي'],
    'Art': ['فن'],

    'Shopping': ['تسوق', 'شوبينغ'],
    'Clothing': ['ملابس', 'لبس'],
    'Dress': ['فستان'],
    'Shoe': ['حذاء', 'جزمة', 'كندرة'],
    'Bag': ['شنطة', 'حقيبة'],
    'Jewellery': ['مجوهرات', 'ذهب', 'jewelry'],
    'Sunglasses': ['نظارة شمس', 'نظارات'],

    'Party': ['حفلة', 'سهرة'],
    'Birthday': ['عيد ميلاد', 'ميلاد'],
    'Gift': ['هدية', 'هدايا'],
    'Balloon': ['بالون', 'بالونات'],
    'Fireworks': ['ألعاب نارية'],

    'Game': ['لعبة', 'ألعاب'],
    'Video game': ['لعبة فيديو', 'قيمنق', 'gaming'],
    'Toy': ['لعبة أطفال', 'دمية'],
  };

  /// Broad everyday categories, each pointing at the specific labels a model
  /// would actually emit for them.
  ///
  /// This is the part that answers "حيوان" with a picture of a cat. Listing a
  /// label the model never produces is harmless, so these lean generous.
  static const List<VisualGroup> groups = [
    VisualGroup(
      terms: ['animal', 'حيوان', 'حيوانات', 'حياة برية', 'wildlife'],
      labels: [
        'Cat',
        'Dog',
        // The model reaches for these when it can see an animal but is not
        // sure which one — which on a cropped screenshot is often. Leaving
        // them out meant the most common evidence of an animal did not count
        // as evidence of an animal.
        'Pet',
        'Snout',
        'Whiskers',
        'Fur',
        'Puppy',
        'Kitten',
        'Bird',
        'Fish',
        'Horse',
        'Butterfly',
        'Insect',
        'Spider',
        'Turtle',
        'Rabbit',
        'Bear',
        'Lion',
        'Tiger',
        'Elephant',
        'Monkey',
        'Cattle',
        'Sheep',
        'Goat',
        'Chicken',
        'Duck',
        'Penguin',
        'Owl',
        'Snake',
        'Frog',
        'Shark',
        'Whale',
        'Dolphin',
        'Squirrel',
        'Deer',
        'Fox',
        'Wolf',
        'Mouse',
        'Pig',
        'Camel',
        'Dinosaur',
        'Zoo',
        'Pet',
        'Wildlife',
        'Feather',
        'Fur',
        'Snout',
        'Whiskers',
        'Paw',
      ],
    ),
    VisualGroup(
      terms: ['food', 'أكل', 'طعام', 'مأكولات', 'وجبة'],
      labels: [
        'Food',
        'Dessert',
        'Cake',
        'Bread',
        'Fruit',
        'Vegetable',
        'Ice cream',
        'Pizza',
        'Hamburger',
        'Sandwich',
        'Pasta',
        'Rice',
        'Soup',
        'Salad',
        'Meat',
        'Seafood',
        'Cheese',
        'Chocolate',
        'Cookie',
        'Candy',
        'Breakfast',
        'Lunch',
        'Dinner',
        'Barbecue',
        'Sushi',
        'Noodle',
        'Egg',
        'Honey',
        'Cooking',
        'Baking',
        'Restaurant',
        'Cuisine',
        'Dish',
        'Recipe',
        'Tableware',
        'Plate',
      ],
    ),
    VisualGroup(
      terms: ['drink', 'مشروب', 'مشروبات', 'شراب'],
      labels: [
        'Drink',
        'Coffee',
        'Tea',
        'Juice',
        'Wine',
        'Beer',
        'Cocktail',
        'Water',
        'Milk',
        'Bottle',
        'Cup',
        'Mug',
        'Smoothie',
      ],
    ),
    VisualGroup(
      terms: ['person', 'people', 'شخص', 'ناس', 'أشخاص', 'انسان', 'وجه'],
      labels: [
        'Person',
        'Selfie',
        'Smile',
        'Face',
        'Hair',
        'Baby',
        'Child',
        'Crowd',
        'Wedding',
        'Bride',
        'Groom',
        'Portrait',
        'Beard',
        'Eyelash',
        'Nail',
        'Tattoo',
        'Hairstyle',
        'Chin',
        'Forehead',
        'Eyebrow',
        'Lip',
        'Neck',
        'Shoulder',
      ],
    ),
    VisualGroup(
      terms: ['nature', 'طبيعة', 'منظر طبيعي', 'outdoors', 'خارجي'],
      labels: [
        'Sky',
        'Cloud',
        'Sunset',
        'Sunrise',
        'Beach',
        'Mountain',
        'Snow',
        'Waterfall',
        'Lake',
        'River',
        'Sea',
        'Ocean',
        'Forest',
        'Desert',
        'Tree',
        'Plant',
        'Flower',
        'Leaf',
        'Grass',
        'Garden',
        'Rock',
        'Island',
        'Rain',
        'Rainbow',
        'Star',
        'Moon',
        'Night',
        'Landscape',
        'Sand',
        'Wave',
        'Horizon',
        'Sunlight',
        'Field',
        'Valley',
      ],
    ),
    VisualGroup(
      terms: ['vehicle', 'مركبة', 'مواصلات', 'سيارات', 'transport'],
      labels: [
        'Car',
        'Vehicle',
        'Bicycle',
        'Motorcycle',
        'Boat',
        'Airplane',
        'Train',
        'Bus',
        'Truck',
        'Ship',
        'Helicopter',
        'Traffic',
        'Road',
        'Wheel',
        'Tire',
        'Automotive',
        'Windshield',
        'Bumper',
      ],
    ),
    VisualGroup(
      terms: ['building', 'مبنى', 'مباني', 'عمارة', 'architecture'],
      labels: [
        'Building',
        'Skyscraper',
        'House',
        'Bridge',
        'Temple',
        'Castle',
        'Church',
        'Mosque',
        'Tower',
        'City',
        'Street',
        'Architecture',
        'Window',
        'Door',
        'Stairs',
        'Roof',
        'Wall',
        'Facade',
        'Skyline',
      ],
    ),
    VisualGroup(
      terms: ['home', 'بيت', 'منزل', 'داخلي', 'interior', 'ديكور'],
      labels: [
        'Room',
        'Kitchen',
        'Bathroom',
        'Bedroom',
        'Furniture',
        'Interior design',
        'Table',
        'Chair',
        'Bed',
        'Sofa',
        'Lamp',
        'Curtain',
        'Shelf',
        'Cabinet',
        'Floor',
        'Mirror',
      ],
    ),
    VisualGroup(
      terms: ['sport', 'رياضة', 'رياضي', 'fitness', 'تمرين'],
      labels: [
        'Sports',
        'Football',
        'Soccer',
        'Basketball',
        'Baseball',
        'Tennis',
        'Swimming',
        'Surfing',
        'Skiing',
        'Cycling',
        'Running',
        'Gym',
        'Yoga',
        'Boxing',
        'Golf',
        'Volleyball',
        'Skateboard',
        'Fitness',
        'Stadium',
        'Ball',
        'Athlete',
      ],
    ),
    VisualGroup(
      terms: ['music', 'موسيقى', 'أغاني', 'حفلة موسيقية'],
      labels: [
        'Music',
        'Guitar',
        'Piano',
        'Drum',
        'Concert',
        'Singing',
        'Microphone',
        'Violin',
        'Dance',
        'Performance',
        'Stage',
        'Musician',
        'Speaker',
      ],
    ),
    VisualGroup(
      terms: ['tech', 'تقنية', 'الكترونيات', 'أجهزة', 'device'],
      labels: [
        'Laptop',
        'Computer',
        'Mobile phone',
        'Keyboard',
        'Camera',
        'Watch',
        'Television',
        'Headphones',
        'Robot',
        'Technology',
        'Gadget',
        'Screen',
        'Monitor',
        'Charger',
        'Cable',
      ],
    ),
    VisualGroup(
      terms: ['document', 'مستند', 'ورق', 'وثيقة', 'paper'],
      labels: [
        'Book',
        'Newspaper',
        'Paper',
        'Document',
        'Text',
        'Handwriting',
        'Map',
        'Menu',
        'Poster',
        'Receipt',
        'Calendar',
        'Whiteboard',
        'Magazine',
        'Envelope',
        'Note',
      ],
    ),
    VisualGroup(
      terms: ['art', 'فن', 'رسم', 'تصميم', 'design'],
      labels: [
        'Painting',
        'Drawing',
        'Sketch',
        'Comics',
        'Cartoon',
        'Anime',
        'Illustration',
        'Art',
        'Graffiti',
        'Sculpture',
        'Design',
        'Pattern',
        'Colorfulness',
        'Font',
        'Logo',
      ],
    ),
    VisualGroup(
      terms: ['shopping', 'تسوق', 'ملابس', 'موضة', 'fashion'],
      labels: [
        'Shopping',
        'Clothing',
        'Dress',
        'Shoe',
        'Bag',
        'Handbag',
        'Jewellery',
        'Sunglasses',
        'Hat',
        'Suit',
        'Shirt',
        'Jeans',
        'Store',
        'Market',
        'Fashion',
        'Sleeve',
        'Textile',
        'Boutique',
      ],
    ),
    VisualGroup(
      terms: ['celebration', 'مناسبة', 'احتفال', 'عيد', 'حفلة'],
      labels: [
        'Party',
        'Birthday',
        'Wedding',
        'Gift',
        'Balloon',
        'Cake',
        'Fireworks',
        'Christmas',
        'Celebration',
        'Candle',
        'Decoration',
        'Event',
        'Ceremony',
      ],
    ),
    VisualGroup(
      terms: ['game', 'لعبة', 'ألعاب', 'قيمنق', 'gaming'],
      labels: [
        'Game',
        'Video game',
        'Toy',
        'Doll',
        'Chess',
        'Card',
        'Puzzle',
        'Playing',
        'Controller',
        'Console',
      ],
    ),
  ];

  /// Every word that should find a screenshot carrying [labels], normalized.
  ///
  /// The label itself always comes first — see the class doc on why nothing
  /// here is allowed to be the *only* way to reach a picture.
  static Set<String> searchTermsFor(Iterable<String> labels) {
    final Set<String> terms = {};

    // Filtered here as well as at extraction time, so a library indexed
    // before [mediumLabels] existed stops answering "shows a phone" for every
    // screenshot in it without needing a re-scan.
    for (final String label in meaningful(labels)) {
      terms.add(normalize(label));

      for (final String synonym in synonyms[label] ?? const []) {
        terms.add(normalize(synonym));
      }
      for (final VisualGroup group in groups) {
        if (!group.labels.contains(label)) continue;
        for (final String term in group.terms) {
          terms.add(normalize(term));
        }
      }
    }

    terms.remove('');
    return terms;
  }

  /// Whether a screenshot carrying [labels] should surface for [query].
  ///
  /// Matching is by prefix in **both** directions: a term that starts with
  /// the query catches "قط" → "قطة" (still typing), and a query that starts
  /// with a term catches "cats" → "Cat" (a plural the tables don't list).
  /// Plain substring matching was rejected — it makes "at" return every cat
  /// in the library, and a search that answers questions nobody asked is
  /// worse than one that misses.
  static bool matches(Iterable<String> labels, String query) {
    final String needle = normalize(query);
    if (needle.length < minimumQueryLength) return false;

    return searchTermsFor(
      labels,
    ).any((term) => term.startsWith(needle) || needle.startsWith(term));
  }

  /// Whether a screenshot carrying [labels] is *of* [subject] — the stricter
  /// question a filing rule asks.
  ///
  /// [matches] is right for the search box and wrong here, and the difference
  /// is who sees the result. A search matches by prefix in both directions so
  /// that half-typed words find things; the cost is that `category` starts
  /// with `cat`, so it also returns every cat in the library. In a search that
  /// is a stray row you scroll past. In a rule it is a photo moved into the
  /// wrong folder, weeks later, with nothing on screen explaining why.
  ///
  /// So this asks for equality, with the one difference that genuinely leaves
  /// the word the same word — an English plural, folded on both sides, so a
  /// rule written `cats` still matches the model's `Cat`. Everything else the
  /// user does not have to guess at: the builder offers the exact labels their
  /// own library produced.
  static bool describes(Iterable<String> labels, String subject) {
    final String needle = normalize(subject);
    if (needle.length < minimumQueryLength) return false;

    final String folded = _foldPlural(needle);
    return searchTermsFor(labels).any((term) => _foldPlural(term) == folded);
  }

  /// Drops an English plural ending, and only when enough word is left for
  /// the result to still be a word — `es` off `bus` would leave `b`.
  static String _foldPlural(String term) {
    if (term.length > 4 && term.endsWith('es')) {
      return term.substring(0, term.length - 2);
    }
    if (term.length > 3 && term.endsWith('s')) {
      return term.substring(0, term.length - 1);
    }
    return term;
  }

  /// The labels on a screenshot that actually caused [query] to match, so the
  /// UI can show *why* a picture came back. A visual match is a guess, and a
  /// guess the user can see is one they can judge — which is the whole
  /// difference between this and the auto-filing that got deleted.
  static List<String> matchingLabels(Iterable<String> labels, String query) {
    final String needle = normalize(query);
    if (needle.length < minimumQueryLength) return const [];

    return [
      for (final String label in labels)
        if (matches([label], needle)) label,
    ];
  }

  /// Folds away the spelling differences that make Arabic text miss.
  ///
  /// Somebody typing "قطه" and a table entry reading "قطة" are the same
  /// word, and neither side is wrong. Every Arabic feature in this app has
  /// needed this pass — the classifier once shipped a bug purely because ta
  /// marbuta was left out of it — so it runs on the query and on every stored
  /// term alike, and no table here has to be spelled defensively.
  static String normalize(String input) {
    final StringBuffer buffer = StringBuffer();

    for (final int rune in input.toLowerCase().runes) {
      // Harakat (fatha..sukun) and tatweel carry no meaning when searching.
      if (rune >= 0x064B && rune <= 0x0652) continue;
      if (rune == 0x0640) continue;

      buffer.writeCharCode(switch (rune) {
        0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627, // أ إ آ ٱ → ا
        0x0649 => 0x064A, // ى → ي
        0x0629 => 0x0647, // ة → ه
        _ => rune,
      });
    }

    return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// A broad category and the specific model labels that belong to it.
class VisualGroup {
  final List<String> terms;
  final List<String> labels;

  const VisualGroup({required this.terms, required this.labels});
}
