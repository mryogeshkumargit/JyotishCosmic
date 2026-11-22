import '../l10n.dart';

/// Overall quality of a day or of one life area.
enum DayRating {
  good,
  average,
  bad;

  static DayRating fromScore(int score) => score >= 62 ? good : (score >= 42 ? average : bad);

  static DayRating parse(String? s) => DayRating.values.firstWhere((r) => r.name == s, orElse: () => average);

  String get label => switch (this) {
    good => tr('Good', 'शुभ'),
    average => tr('Average', 'मध्यम'),
    bad => tr('Challenging', 'चुनौतीपूर्ण'),
  };
}

/// One titled block of the daily report (a life area, an outlook item or a remedy).
class RashifalSection {
  /// Stable id ('family', 'travel', 'mantra'...), also used as the AI JSON key.
  final String key;
  final String title;
  final String text;

  /// 0-100, for scored sections (life areas, travel, finance, unexpected events).
  final int? score;
  final DayRating? rating;

  /// The astrological reasons behind [text] ("Moon transits your 11th house…").
  final List<String> factors;

  /// Bulleted items (Do's, or the mantra's transliteration and count...).
  final List<String> items;

  /// Second list, used for Don'ts.
  final List<String> items2;

  /// Small named values (colour hex, mantra in Devanagari, direction...).
  final Map<String, String> extra;

  const RashifalSection({
    required this.key,
    required this.title,
    required this.text,
    this.score,
    this.rating,
    this.factors = const [],
    this.items = const [],
    this.items2 = const [],
    this.extra = const {},
  });

  RashifalSection copyWith({String? text, List<String>? items, List<String>? items2}) =>
      RashifalSection(key: key, title: title, text: text ?? this.text, score: score, rating: rating, factors: factors, items: items ?? this.items, items2: items2 ?? this.items2, extra: extra);

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'text': text,
    if (score != null) 'score': score,
    if (rating != null) 'rating': rating!.name,
    if (factors.isNotEmpty) 'factors': factors,
    if (items.isNotEmpty) 'items': items,
    if (items2.isNotEmpty) 'items2': items2,
    if (extra.isNotEmpty) 'extra': extra,
  };

  factory RashifalSection.fromJson(Map<String, dynamic> j) => RashifalSection(
    key: j['key'] as String? ?? '',
    title: j['title'] as String? ?? '',
    text: j['text'] as String? ?? '',
    score: (j['score'] as num?)?.toInt(),
    rating: j['rating'] == null ? null : DayRating.parse(j['rating'] as String?),
    factors: _strings(j['factors']),
    items: _strings(j['items']),
    items2: _strings(j['items2']),
    extra: {for (final e in ((j['extra'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
  );
}

/// A time window of the day (muhurat, choghadiya, Rahu Kaal...).
class TimeSlot {
  final String name;
  final String start;
  final String end;

  /// 'good', 'neutral' or 'avoid'.
  final String quality;
  final String note;

  const TimeSlot(this.name, this.start, this.end, this.quality, [this.note = '']);

  String get range => '$start – $end';

  Map<String, dynamic> toJson() => {'name': name, 'start': start, 'end': end, 'quality': quality, if (note.isNotEmpty) 'note': note};

  factory TimeSlot.fromJson(Map<String, dynamic> j) =>
      TimeSlot(j['name'] as String? ?? '', j['start'] as String? ?? '', j['end'] as String? ?? '', j['quality'] as String? ?? 'neutral', j['note'] as String? ?? '');
}

/// One block of the "daily planetary and astrological analysis".
class AnalysisBlock {
  final String key;
  final String title;
  final String summary;
  final List<String> points;

  /// Optional table: first row is the header.
  final List<List<String>> table;

  const AnalysisBlock({required this.key, required this.title, required this.summary, this.points = const [], this.table = const []});

  AnalysisBlock copyWith({String? summary}) => AnalysisBlock(key: key, title: title, summary: summary ?? this.summary, points: points, table: table);

  Map<String, dynamic> toJson() => {'key': key, 'title': title, 'summary': summary, if (points.isNotEmpty) 'points': points, if (table.isNotEmpty) 'table': table};

  factory AnalysisBlock.fromJson(Map<String, dynamic> j) => AnalysisBlock(
    key: j['key'] as String? ?? '',
    title: j['title'] as String? ?? '',
    summary: j['summary'] as String? ?? '',
    points: _strings(j['points']),
    table: [for (final r in (j['table'] as List? ?? const [])) _strings(r)],
  );
}

/// The complete daily Rashifal of one Kundali for one date.
///
/// It is produced on the device by `RashifalEngine` (every astrological
/// factor, a score and plain-language text for each section) and optionally
/// rewritten by the AI from the same data (`RashifalAi`). The whole report
/// is stored as JSON in the database, so a saved day reopens exactly as it
/// was generated, even after the chart conventions or the app change.
class DailyRashifalReport {
  static const int formatVersion = 1;

  final int profileId;
  final String profileName;

  /// Local calendar date, `yyyy-MM-dd`.
  final String dateKey;
  final String lang;
  final String placeName;

  /// 0-100.
  final int score;
  final DayRating rating;
  final String headline;
  final List<String> dayReasons;

  /// The two notification lines.
  final String notificationLine1;
  final String notificationLine2;

  /// family, marriage, health, career, mind, finance, social.
  final List<RashifalSection> areas;

  /// muhurat, travel, financeDecisions, unexpected.
  final List<RashifalSection> outlook;

  /// mantra, upay, donation, colour, dosDonts.
  final List<RashifalSection> remedies;

  final List<TimeSlot> timeSlots;

  /// The ten analysis blocks plus supporting factors.
  final List<AnalysisBlock> analysis;

  /// AI-written overview of the day (null when the AI was not used).
  final String? aiSummary;
  final String? aiModel;
  final DateTime generatedAt;
  final DateTime? aiGeneratedAt;

  const DailyRashifalReport({
    required this.profileId,
    required this.profileName,
    required this.dateKey,
    required this.lang,
    required this.placeName,
    required this.score,
    required this.rating,
    required this.headline,
    required this.dayReasons,
    required this.notificationLine1,
    required this.notificationLine2,
    required this.areas,
    required this.outlook,
    required this.remedies,
    required this.timeSlots,
    required this.analysis,
    required this.generatedAt,
    this.aiSummary,
    this.aiModel,
    this.aiGeneratedAt,
  });

  bool get hasAi => aiGeneratedAt != null;

  DateTime get date => DateTime.parse(dateKey);

  RashifalSection? section(String key) {
    for (final s in [...areas, ...outlook, ...remedies]) {
      if (s.key == key) return s;
    }
    return null;
  }

  DailyRashifalReport copyWith({
    String? headline,
    List<String>? dayReasons,
    String? notificationLine1,
    String? notificationLine2,
    List<RashifalSection>? areas,
    List<RashifalSection>? outlook,
    List<RashifalSection>? remedies,
    List<AnalysisBlock>? analysis,
    String? aiSummary,
    String? aiModel,
    DateTime? aiGeneratedAt,
  }) => DailyRashifalReport(
    profileId: profileId,
    profileName: profileName,
    dateKey: dateKey,
    lang: lang,
    placeName: placeName,
    score: score,
    rating: rating,
    headline: headline ?? this.headline,
    dayReasons: dayReasons ?? this.dayReasons,
    notificationLine1: notificationLine1 ?? this.notificationLine1,
    notificationLine2: notificationLine2 ?? this.notificationLine2,
    areas: areas ?? this.areas,
    outlook: outlook ?? this.outlook,
    remedies: remedies ?? this.remedies,
    timeSlots: timeSlots,
    analysis: analysis ?? this.analysis,
    generatedAt: generatedAt,
    aiSummary: aiSummary ?? this.aiSummary,
    aiModel: aiModel ?? this.aiModel,
    aiGeneratedAt: aiGeneratedAt ?? this.aiGeneratedAt,
  );

  Map<String, dynamic> toJson() => {
    'v': formatVersion,
    'profileId': profileId,
    'profileName': profileName,
    'date': dateKey,
    'lang': lang,
    'place': placeName,
    'score': score,
    'rating': rating.name,
    'headline': headline,
    'reasons': dayReasons,
    'notif': [notificationLine1, notificationLine2],
    'areas': [for (final s in areas) s.toJson()],
    'outlook': [for (final s in outlook) s.toJson()],
    'remedies': [for (final s in remedies) s.toJson()],
    'slots': [for (final s in timeSlots) s.toJson()],
    'analysis': [for (final a in analysis) a.toJson()],
    'generatedAt': generatedAt.toIso8601String(),
    if (aiSummary != null) 'aiSummary': aiSummary,
    if (aiModel != null) 'aiModel': aiModel,
    if (aiGeneratedAt != null) 'aiGeneratedAt': aiGeneratedAt!.toIso8601String(),
  };

  factory DailyRashifalReport.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) => [
      for (final e in (j[k] as List? ?? const []))
        if (e is Map) f(Map<String, dynamic>.from(e)),
    ];
    final notif = _strings(j['notif']);
    return DailyRashifalReport(
      profileId: (j['profileId'] as num?)?.toInt() ?? 0,
      profileName: j['profileName'] as String? ?? '',
      dateKey: j['date'] as String? ?? '',
      lang: j['lang'] as String? ?? 'en',
      placeName: j['place'] as String? ?? '',
      score: (j['score'] as num?)?.toInt() ?? 50,
      rating: DayRating.parse(j['rating'] as String?),
      headline: j['headline'] as String? ?? '',
      dayReasons: _strings(j['reasons']),
      notificationLine1: notif.isNotEmpty ? notif[0] : '',
      notificationLine2: notif.length > 1 ? notif[1] : '',
      areas: list('areas', RashifalSection.fromJson),
      outlook: list('outlook', RashifalSection.fromJson),
      remedies: list('remedies', RashifalSection.fromJson),
      timeSlots: list('slots', TimeSlot.fromJson),
      analysis: list('analysis', AnalysisBlock.fromJson),
      generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? '') ?? DateTime.now(),
      aiSummary: j['aiSummary'] as String?,
      aiModel: j['aiModel'] as String?,
      aiGeneratedAt: DateTime.tryParse(j['aiGeneratedAt'] as String? ?? ''),
    );
  }
}

/// `yyyy-MM-dd` of a local calendar date.
String dateKeyOf(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<String> _strings(Object? v) => v is List
    ? [
        for (final e in v)
          if (e != null) '$e',
      ]
    : const [];
