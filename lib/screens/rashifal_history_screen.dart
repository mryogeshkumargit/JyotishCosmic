import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import '../core/l10n.dart';
import '../providers/profile_provider.dart';
import '../providers/rashifal_provider.dart';
import '../services/rashifal_repository.dart';
import '../widgets/analysis_widgets.dart';
import 'daily_rashifal_screen.dart';

/// Every saved daily Rashifal, newest first, paged from the database.
class RashifalHistoryScreen extends ConsumerStatefulWidget {
  const RashifalHistoryScreen({super.key});

  @override
  ConsumerState<RashifalHistoryScreen> createState() => _RashifalHistoryScreenState();
}

class _RashifalHistoryScreenState extends ConsumerState<RashifalHistoryScreen> {
  static const int _pageSize = 30;
  final List<RashifalSummary> _items = [];
  final ScrollController _scroll = ScrollController();
  int? _profileId;
  bool _favourites = false;
  bool _loading = false;
  bool _hasMore = true;
  int _total = 0;
  StreamSubscription<void>? _changes;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _more();
    });
    _changes = ref.read(rashifalRepositoryProvider).changes().listen((_) {
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 300), _reload);
    });
    _reload();
  }

  @override
  void dispose() {
    _changes?.cancel();
    _reloadDebounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final repo = ref.read(rashifalRepositoryProvider);
    final keep = _items.length < _pageSize ? _pageSize : _items.length;
    final page = await repo.page(profileId: _profileId, favouritesOnly: _favourites, limit: keep);
    final total = await repo.count(profileId: _profileId, favouritesOnly: _favourites);
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(page);
      _total = total;
      _hasMore = page.length < total;
    });
  }

  Future<void> _more() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final page = await ref.read(rashifalRepositoryProvider).page(profileId: _profileId, favouritesOnly: _favourites, limit: _pageSize, offset: _items.length);
    if (!mounted) return;
    setState(() {
      _items.addAll(page);
      _hasMore = page.length == _pageSize;
      _loading = false;
    });
  }

  Future<bool> _confirmDelete(RashifalSummary s) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Delete this Rashifal?', 'यह राशिफल हटाएँ?')),
          content: Text('${s.profileName} · ${_dateLabel(s.dateKey)}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel', 'रद्द करें'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Delete', 'हटाएँ'))),
          ],
        ),
      ) ==
      true;

  static String _dateLabel(String key) {
    final d = DateTime.tryParse(key);
    return d == null ? key : '${L10n.weekday(d.weekday)}, ${d.day} ${L10n.month(d.month)} ${d.year}';
  }

  static String _shortDate(String key) {
    final d = DateTime.tryParse(key);
    return d == null ? key : '${d.day} ${L10n.month(d.month)} ${d.year}';
  }

  static String _weekday(String key) {
    final d = DateTime.tryParse(key);
    return d == null ? '' : L10n.weekday(d.weekday);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profileListProvider).value ?? const <Profile>[];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Saved Rashifals', 'सहेजे गए राशिफल'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _profileId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: tr('Kundali', 'कुंडली'), isDense: true),
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text(tr('All', 'सभी'))),
                      for (final p in profiles)
                        DropdownMenuItem<int?>(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _profileId = v;
                        _items.clear();
                      });
                      _reload();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(tr('Starred', 'तारांकित')),
                  avatar: const Icon(Icons.star, size: 16),
                  selected: _favourites,
                  onSelected: (v) {
                    setState(() {
                      _favourites = v;
                      _items.clear();
                    });
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(tr('$_total saved', '$_total सहेजे गए'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        tr('No saved Rashifal yet. Every day you open is saved here automatically.', 'अभी कोई राशिफल सहेजा नहीं गया। जो भी दिन आप खोलते हैं, वह यहाँ अपने आप सहेजा जाता है।'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final s = _items[i];
                      final color = ratingColor(context, s.rating);
                      return Dismissible(
                        key: ValueKey(s.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: scheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: scheme.onError),
                        ),
                        confirmDismiss: (_) => _confirmDelete(s),
                        onDismissed: (_) {
                          setState(() => _items.removeAt(i));
                          ref.read(rashifalRepositoryProvider).delete(s.id);
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.18),
                            child: Text(
                              '${s.score}',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _shortDate(s.dateKey),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (s.hasAi) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.auto_awesome, size: 16)),
                              const SizedBox(width: 4),
                              Pill(s.rating.label, color),
                            ],
                          ),
                          subtitle: Text('${_weekday(s.dateKey)} · ${s.profileName}${s.lang == 'hi' ? ' · हिन्दी' : ''}\n${s.headline}', maxLines: 3, overflow: TextOverflow.ellipsis),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: Icon(s.favourite ? Icons.star : Icons.star_border, color: s.favourite ? Colors.amber : null),
                            tooltip: tr('Star', 'तारांकित करें'),
                            onPressed: () => ref.read(rashifalRepositoryProvider).setFavourite(s.id, !s.favourite),
                          ),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DailyRashifalScreen(reportId: s.id))),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
