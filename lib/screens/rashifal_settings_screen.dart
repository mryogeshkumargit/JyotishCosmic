import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database.dart';
import '../core/l10n.dart';
import '../core/rashifal/rashifal_models.dart';
import '../providers/profile_provider.dart';
import '../providers/rashifal_provider.dart';
import '../providers/settings_provider.dart';
import '../services/rashifal_notifications.dart';
import '../widgets/city_autocomplete.dart';

/// Settings of the morning Rashifal notification.
class RashifalSettingsScreen extends ConsumerStatefulWidget {
  const RashifalSettingsScreen({super.key});

  @override
  ConsumerState<RashifalSettingsScreen> createState() => _RashifalSettingsScreenState();
}

class _RashifalSettingsScreenState extends ConsumerState<RashifalSettingsScreen> {
  bool? _permission;
  bool? _exact;
  int? _pending;
  int? _saved;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final permission = await RashifalNotifications.notificationsEnabled();
    final exact = await RashifalNotifications.canScheduleExact();
    final pending = (await RashifalNotifications.pending()).length;
    final saved = await ref.read(rashifalRepositoryProvider).count();
    if (mounted) {
      setState(() {
        _permission = permission;
        _exact = exact;
        _pending = pending;
        _saved = saved;
      });
    }
  }

  RashifalPrefs get _prefs => ref.read(settingsProvider).rashifal;

  Future<void> _update(RashifalPrefs p) async {
    await ref.read(settingsProvider.notifier).updateRashifal(p);
    setState(() => _busy = true);
    try {
      if (p.enabled && RashifalNotifications.supported && !(_permission ?? false)) {
        _permission = await RashifalNotifications.requestPermission();
      }
      await ref.read(rashifalSchedulerProvider).run(force: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _refreshStatus();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _prefs.hour, minute: _prefs.minute),
    );
    if (t != null) _update(_prefs.copyWith(hour: t.hour, minute: t.minute));
  }

  Future<void> _test(List<Profile> profiles) async {
    final messenger = ScaffoldMessenger.of(context);
    final profile = RashifalNotifications.profileFor(_prefs, profiles);
    if (profile == null) {
      messenger.showSnackBar(SnackBar(content: Text(tr('Please create a profile first.', 'कृपया पहले एक प्रोफ़ाइल बनाएँ।'))));
      return;
    }
    if (!RashifalNotifications.supported) {
      messenger.showSnackBar(SnackBar(content: Text(tr('Notifications are available on Android and iOS.', 'सूचनाएँ Android और iOS पर उपलब्ध हैं।'))));
      return;
    }
    if (!await RashifalNotifications.requestPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(tr('Notifications are blocked for this app. Allow them in the phone settings.', 'इस ऐप की सूचनाएँ बंद हैं। फ़ोन की सेटिंग्स में अनुमति दें।'))));
      return;
    }
    final now = DateTime.now();
    final (l1, l2) = await ref.read(rashifalServiceProvider).notificationLines(profile, now, _prefs);
    await RashifalNotifications.showNow(PlannedNotification(now, RashifalPayload(profile.id, dateKeyOf(now)), '${tr('Daily Rashifal', 'दैनिक राशिफल')} · ${profile.name}', '$l1\n$l2'));
    _refreshStatus();
  }

  Future<void> _deleteOld() async {
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('Delete saved Rashifals', 'सहेजे गए राशिफल हटाएँ')),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 90), child: Text(tr('Older than 3 months (starred are kept)', '3 महीने से पुराने (तारांकित रखे जाएँगे)'))),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 365), child: Text(tr('Older than 1 year (starred are kept)', '1 वर्ष से पुराने (तारांकित रखे जाएँगे)'))),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, -1), child: Text(tr('All saved Rashifals', 'सभी सहेजे गए राशिफल'))),
        ],
      ),
    );
    if (choice == null) return;
    final repo = ref.read(rashifalRepositoryProvider);
    final n = choice < 0 ? await repo.deleteAll() : await repo.deleteOlderThan(dateKeyOf(DateTime.now().subtract(Duration(days: choice))));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('$n deleted', '$n हटाए गए'))));
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(settingsProvider.select((s) => s.rashifal));
    final aiReady = ref.watch(settingsProvider.select((s) => s.apiKey.trim().isNotEmpty || s.llmProvider == 'Custom'));
    final profiles = ref.watch(profileListProvider).value ?? const <Profile>[];
    final scheme = Theme.of(context).colorScheme;
    final profile = RashifalNotifications.profileFor(prefs, profiles);
    final time = TimeOfDay(hour: prefs.hour, minute: prefs.minute).format(context);
    Widget title(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        t,
        style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(tr('Daily Rashifal notification', 'दैनिक राशिफल सूचना'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(tr('Morning notification', 'सुबह की सूचना')),
            subtitle: Text(tr('A two-line Rashifal every morning; tap it for the full day.', 'हर सुबह दो पंक्तियों का राशिफल; पूरा दिन देखने के लिए टैप करें।')),
            value: prefs.enabled,
            onChanged: (v) => _update(prefs.copyWith(enabled: v)),
          ),
          ListTile(
            enabled: prefs.enabled,
            leading: const Icon(Icons.schedule),
            title: Text(tr('Time', 'समय')),
            trailing: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            onTap: _pickTime,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (int d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(L10n.weekday(d).substring(0, L10n.hi ? L10n.weekday(d).length - 3 : 3)),
                    selected: prefs.weekdays.contains(d),
                    onSelected: !prefs.enabled
                        ? null
                        : (v) {
                            final days = {...prefs.weekdays};
                            v ? days.add(d) : days.remove(d);
                            _update(prefs.copyWith(weekdays: days));
                          },
                  ),
              ],
            ),
          ),
          title(tr('Kundali', 'कुंडली')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: profiles.isEmpty
                ? Text(tr('Create a profile first.', 'पहले एक प्रोफ़ाइल बनाएँ।'))
                : DropdownButtonFormField<int>(
                    key: ValueKey('nprofile-${profile?.id}'),
                    initialValue: profile?.id,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: tr('Kundali used for the notification', 'सूचना के लिए कुंडली')),
                    items: [
                      for (final p in profiles)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => _update(prefs.copyWith(profileId: v)),
                  ),
          ),
          title(tr('Place for Panchang & muhurat', 'पंचांग और मुहूर्त का स्थान')),
          SwitchListTile(
            title: Text(tr('Use the birth place', 'जन्म स्थान का उपयोग करें')),
            subtitle: Text(prefs.hasPlace ? prefs.placeName! : (profile?.pob ?? '—')),
            value: !prefs.hasPlace,
            onChanged: (v) {
              if (v) _update(prefs.copyWith(clearPlace: true));
              if (!v && profile != null) _update(prefs.copyWith(placeName: profile.pob, lat: profile.lat, lon: profile.lon, tzName: profile.tzName));
            },
          ),
          if (prefs.hasPlace)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CityAutocomplete(
                initialText: prefs.placeName,
                onSelected: (loc) => _update(prefs.copyWith(placeName: loc.displayName, lat: loc.lat, lon: loc.lon, tzName: loc.tzName)),
              ),
            ),
          title('AI'),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome),
            title: Text(tr('AI analysis when today\'s Rashifal is opened', 'आज का राशिफल खुलने पर AI विश्लेषण')),
            subtitle: Text(
              aiReady
                  ? tr('Uses your AI provider once per day and Kundali; the result is saved.', 'प्रति दिन और कुंडली एक बार आपके AI प्रदाता का उपयोग; परिणाम सहेजा जाता है।')
                  : tr('Set up an AI provider and API key in Settings > AI to enable this.', 'इसे चालू करने के लिए सेटिंग्स > AI में AI प्रदाता और API कुंजी सेट करें।'),
            ),
            value: prefs.autoAi,
            onChanged: (v) => _update(prefs.copyWith(autoAi: v)),
          ),
          title(tr('Status', 'स्थिति')),
          if (!RashifalNotifications.supported)
            ListTile(leading: const Icon(Icons.info_outline), title: Text(tr('Notifications are available on Android and iOS.', 'सूचनाएँ Android और iOS पर उपलब्ध हैं।')))
          else ...[
            ListTile(
              leading: Icon(_permission == true ? Icons.check_circle : Icons.error_outline, color: _permission == true ? Colors.green : scheme.error),
              title: Text(_permission == true ? tr('Notifications allowed', 'सूचनाओं की अनुमति है') : tr('Notifications not allowed', 'सूचनाओं की अनुमति नहीं है')),
              trailing: _permission == true
                  ? null
                  : TextButton(
                      onPressed: () async {
                        await RashifalNotifications.requestPermission();
                        _refreshStatus();
                      },
                      child: Text(tr('Allow', 'अनुमति दें')),
                    ),
            ),
            ListTile(
              leading: Icon(_exact == true ? Icons.alarm_on : Icons.alarm, color: _exact == true ? Colors.green : scheme.onSurfaceVariant),
              title: Text(_exact == true ? tr('Exact timing on', 'सटीक समय चालू') : tr('Approximate timing', 'अनुमानित समय')),
              subtitle: _exact == true ? null : Text(tr('Android may deliver a few minutes late to save battery.', 'बैटरी बचाने के लिए Android कुछ मिनट देर से दे सकता है।')),
              trailing: _exact == true
                  ? null
                  : TextButton(
                      onPressed: () async {
                        await RashifalNotifications.requestExact();
                        await ref.read(rashifalSchedulerProvider).run(force: true);
                        _refreshStatus();
                      },
                      child: Text(tr('Allow exact', 'सटीक करें')),
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: Text(tr('${_pending ?? 0} upcoming notifications scheduled', '${_pending ?? 0} आगामी सूचनाएँ निर्धारित')),
              subtitle: Text(
                tr(
                  'Prepared ${RashifalNotifications.horizonDays} days ahead on the device and refreshed every time the app opens.',
                  'डिवाइस पर ${RashifalNotifications.horizonDays} दिन पहले तैयार और हर बार ऐप खुलने पर ताज़ा।',
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(onPressed: () => _test(profiles), icon: const Icon(Icons.send), label: Text(tr('Send a test notification now', 'अभी एक परीक्षण सूचना भेजें'))),
          ),
          title(tr('Storage', 'संग्रह')),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(tr('${_saved ?? 0} saved daily Rashifals', '${_saved ?? 0} सहेजे गए दैनिक राशिफल')),
            subtitle: Text(tr('Every day you open is saved with its full analysis.', 'आपके द्वारा खोला गया हर दिन पूरे विश्लेषण के साथ सहेजा जाता है।')),
            trailing: TextButton(onPressed: (_saved ?? 0) == 0 ? null : _deleteOld, child: Text(tr('Clean up', 'साफ़ करें'))),
          ),
        ],
      ),
    );
  }
}
