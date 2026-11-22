import 'dart:convert';

import '../../providers/settings_provider.dart';
import '../../services/ai_service.dart';
import '../l10n.dart';
import 'rashifal_engine.dart';
import 'rashifal_models.dart';

/// AI interpretation of a computed daily Rashifal.
///
/// The AI receives every factor the engine calculated (Panchang, Moon,
/// Gochar with Ashtakavarga, aspects, Dasha, Sade Sati, yogas, doshas, D9 and
/// D10, scores and time windows) plus the full natal chart, and rewrites the
/// text of each section as strict JSON. Scores, ratings, tables and time
/// windows stay the engine's, so the report never contradicts the numbers.
class RashifalAi {
  static const List<String> areaKeys = ['overall', 'family', 'marriage', 'health', 'career', 'mind', 'finance', 'social'];
  static const List<String> outlookKeys = ['muhurat', 'travel', 'financeDecisions', 'unexpected'];
  static const List<String> remedyKeys = ['mantra', 'upay', 'donation', 'colour'];
  static const List<String> analysisKeys = ['date', 'panchang', 'moonSign', 'moonTransit', 'gochar', 'drishti', 'nakshatra', 'dasha', 'strength', 'energy'];

  static String buildPrompt(RashifalNatal natal, RashifalComputation c, String language) {
    String keys(List<String> k, String v) => '{${k.map((e) => '"$e": $v').join(', ')}}';
    return '''
Write today's personalised daily Rashifal (Vedic horoscope) for ${natal.name}.

Use ONLY the calculated data below (Swiss Ephemeris, sidereal). Consider together the natal chart, current Gochar from the Moon and the Lagna, Chandra Bala and Tara Bala, the Panchang (tithi, vara, nakshatra, yoga, karana), the running Maha/Antar/Pratyantar Dasha, Ashtakavarga bindus, Sade Sati, yogas, doshas, conjunctions, aspects and the divisional charts (D9, D10). Do not recalculate positions.

=== NATAL CHART ===
${natal.summary}

=== TODAY ===
${c.aiContext}

=== OUTPUT ===
Reply with ONE JSON object and nothing else (no Markdown, no code fences). Write all text in $language, in the second person ("you"), warm and practical. Each "text" is 2-4 sentences that name the concrete astrological reasons (planet, house, nakshatra, dasha) and give practical advice. Keep the ratings implied by ENGINE SCORES (good / average / bad); do not invent scores or times — use the time windows given. Be balanced and avoid fear-inducing language.

Schema:
{
  "summary": "4-6 sentence overview of the whole day",
  "headline": "one short line",
  "notification": ["line 1, max 80 characters: how the day is and its main theme", "line 2, max 80 characters: one practical tip with a time or colour"],
  "areas": ${keys(areaKeys, '{"text": "..."}')},
  "outlook": ${keys(outlookKeys, '{"text": "..."}')},
  "remedies": ${keys(remedyKeys, '{"text": "..."}')},
  "dosDonts": {"dos": ["4-6 short items"], "donts": ["4-6 short items"]},
  "analysis": ${keys(analysisKeys, '"2-4 sentence interpretation"')}
}
Area keys: overall = how the day will be and why; family; marriage = married life and relationships; health = health and well-being; career = work life; mind = mental peace; finance = financial matters; social = social relations. Outlook keys: muhurat = auspicious times; travel; financeDecisions; unexpected = unexpected events. Remedy keys: mantra (include the mantra text), upay, donation, colour.''';
  }

  /// Extracts the JSON object from a model answer (tolerates code fences and prose).
  static Map<String, dynamic>? parseJson(String text) {
    var s = text.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(s);
    if (fence != null) s = fence.group(1)!.trim();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final v = jsonDecode(s.substring(start, end + 1));
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  static String? _str(Object? v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (v is Map) return _str(v['text']);
    return null;
  }

  static List<String> _list(Object? v) => v is List
      ? [
          for (final e in v)
            if (e is String && e.trim().isNotEmpty) e.trim(),
        ].take(8).toList()
      : const [];

  /// Applies the AI texts to [r]; sections the AI left out keep the engine text.
  static DailyRashifalReport merge(DailyRashifalReport r, Map<String, dynamic> j, {String? model}) {
    Map<String, dynamic> obj(String k) => j[k] is Map ? Map<String, dynamic>.from(j[k] as Map) : const {};
    List<RashifalSection> apply(List<RashifalSection> list, Map<String, dynamic> m) => [for (final s in list) _str(m[s.key]) == null ? s : s.copyWith(text: _str(m[s.key]))];

    final dd = obj('dosDonts');
    final remedies = [
      for (final s in apply(r.remedies, obj('remedies')))
        s.key == 'dosDonts' ? s.copyWith(items: _list(dd['dos']).isEmpty ? null : _list(dd['dos']), items2: _list(dd['donts']).isEmpty ? null : _list(dd['donts'])) : s,
    ];
    final analysis = obj('analysis');
    final notif = _list(j['notification']);
    String? line(int i) => notif.length > i && notif[i].length <= 140 ? notif[i] : null;
    return r.copyWith(
      headline: _str(j['headline']),
      notificationLine1: line(0),
      notificationLine2: line(1),
      areas: apply(r.areas, obj('areas')),
      outlook: apply(r.outlook, obj('outlook')),
      remedies: remedies,
      analysis: [for (final a in r.analysis) _str(analysis[a.key]) == null ? a : a.copyWith(summary: _str(analysis[a.key]))],
      aiSummary: _str(j['summary']),
      aiModel: model,
      aiGeneratedAt: DateTime.now(),
    );
  }

  /// Asks the configured AI provider; retries once if the answer is not valid JSON.
  /// Returns the merged report and the raw answer.
  static Future<(DailyRashifalReport, String)> enrich(SettingsState config, RashifalNatal natal, RashifalComputation c, {void Function(int charsReceived)? onProgress}) async {
    final prompt = buildPrompt(natal, c, config.aiLanguage);
    final messages = [ChatMessage.user(prompt)];
    var answer = await AiService.chat(config, messages, onPartial: (t) => onProgress?.call(t.length));
    var json = parseJson(answer);
    if (json == null) {
      answer = await AiService.chat(config, [
        ...messages,
        ChatMessage.assistant(answer),
        const ChatMessage.user('That was not valid JSON. Return only the JSON object described above, with no other text.'),
      ], onPartial: (t) => onProgress?.call(t.length));
      json = parseJson(answer);
    }
    if (json == null) {
      throw AiException(
        tr('The AI answer could not be read (invalid JSON). Please try again or choose another model.', 'AI का उत्तर पढ़ा नहीं जा सका (अमान्य JSON)। फिर से कोशिश करें या कोई दूसरा मॉडल चुनें।'),
      );
    }
    return (merge(c.report, json, model: '${config.llmProvider} · ${config.modelName}'), answer);
  }
}
