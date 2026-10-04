import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/calc_config.dart';
import '../core/ephemeris.dart';
import '../core/l10n.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../services/ai_service.dart';
import '../services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Appearance
  String _selectedStyle = 'North';
  String _selectedTheme = 'Cosmic';

  // AI config
  String _selectedLLM = 'OpenAI';
  String _selectedLanguage = 'English';
  final _endpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _isTesting = false;
  bool _obscureKey = true;
  bool _loadingModels = false;
  String? _modelsStatus;

  // About / updater
  String _version = '';
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;
  double? _downloadProgress;

  static const _languages = ['English', 'Hindi', 'Sanskrit', 'Marathi', 'Bengali', 'Tamil', 'Telugu', 'Gujarati', 'Spanish'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitial();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    }).catchError((_) {});
  }

  Future<void> _loadInitial() async {
    // Wait for persisted settings so the form never overwrites them with defaults.
    await ref.read(settingsProvider.notifier).loaded;
    if (!mounted) return;
    final state = ref.read(settingsProvider);
    setState(() {
      _selectedStyle = state.chartStyle;
      _selectedTheme = state.themeMode;
      _selectedLLM = LlmProviders.endpoints.containsKey(state.llmProvider) ? state.llmProvider : 'OpenAI';
      _selectedLanguage = _languages.contains(state.aiLanguage) ? state.aiLanguage : 'English';
      _endpointController.text = state.apiEndpoint;
      _apiKeyController.text = state.apiKey;
      _modelController.text = state.modelName;
    });
    if (state.apiKey.isNotEmpty && !state.modelCache.containsKey(_selectedLLM)) {
      _loadModels(quiet: true);
    }
  }

  /// Loads the models available to this account from the provider.
  Future<void> _loadModels({bool quiet = false}) async {
    final provider = _selectedLLM;
    setState(() {
      _loadingModels = true;
      _modelsStatus = null;
    });
    try {
      final models = await AiService.listModels(_formState());
      if (!mounted || provider != _selectedLLM) return;
      if (models.isEmpty) {
        setState(() => _modelsStatus = tr('The provider returned no models; type the model id instead.', 'प्रदाता ने कोई मॉडल नहीं दिया; मॉडल id स्वयं लिखें।'));
        return;
      }
      await ref.read(settingsProvider.notifier).cacheModels(provider, models);
      if (!mounted) return;
      setState(() => _modelsStatus = tr('${models.length} models loaded from $provider', '$provider से ${models.length} मॉडल लोड हुए'));
    } catch (e) {
      if (mounted && !quiet) setState(() => _modelsStatus = '$e');
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _pickModel() async {
    final settings = ref.read(settingsProvider);
    final provider = _selectedLLM;
    final models = settings.modelsFor(provider);
    final live = settings.modelCache[provider]?.isNotEmpty ?? false;
    final current = _modelController.text.trim();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ModelPickerSheet(provider: provider, models: models, current: current, live: live),
    );
    if (chosen != null && mounted) setState(() => _modelController.text = chosen);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _endpointController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _onLLMChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      _selectedLLM = newValue;
      _endpointController.text = LlmProviders.endpoints[newValue]!;
      _modelController.text = ref.read(settingsProvider).modelsFor(newValue).first;
      _modelsStatus = null;
    });
    if (_apiKeyController.text.trim().isNotEmpty || newValue == 'Custom') _loadModels(quiet: true);
  }

  SettingsState _formState() => ref.read(settingsProvider).copyWith(
        llmProvider: _selectedLLM,
        aiLanguage: _selectedLanguage,
        apiEndpoint: _endpointController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        modelName: _modelController.text.trim(),
      );

  Future<void> _saveAiConfig() async {
    final s = _formState();
    await ref.read(settingsProvider.notifier).updateAIConfig(s.llmProvider, s.aiLanguage, s.apiEndpoint, s.apiKey, s.modelName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('AI configuration saved securely on this device', 'AI सेटिंग्स इस डिवाइस पर सुरक्षित रूप से सहेजी गईं'))));
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AiService.testConnection(_formState());
      messenger.showSnackBar(SnackBar(content: Text(tr('Connection successful!', 'कनेक्शन सफल!')), backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _checkAndInstallUpdate() async {
    setState(() => _isCheckingUpdate = true);
    final messenger = ScaffoldMessenger.of(context);
    final updateService = UpdateService();
    final updateData = await updateService.checkUpdate(_version);
    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    if (updateData == null) {
      messenger.showSnackBar(SnackBar(content: Text(tr('You are on the latest version.', 'आप नवीनतम संस्करण पर हैं।'))));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Update available', 'अपडेट उपलब्ध')),
        content: Text(tr('Version ${updateData['tag']} is available. Download and install it now?', 'संस्करण ${updateData['tag']} उपलब्ध है। अभी डाउनलोड और इंस्टॉल करें?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Later', 'बाद में'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Install', 'इंस्टॉल करें'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final success = await updateService.downloadAndInstallUpdate(updateData['url']!, (received, total) {
      if (total > 0 && mounted) setState(() => _downloadProgress = received / total);
    });

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _downloadProgress = null;
    });
    if (!success) {
      messenger.showSnackBar(SnackBar(content: Text(tr('Update failed. Please check your internet connection.', 'अपडेट विफल। कृपया इंटरनेट कनेक्शन जाँचें।'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Settings', 'सेटिंग्स')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: [
            Tab(icon: const Icon(Icons.palette), text: tr('Style', 'शैली')),
            const Tab(icon: Icon(Icons.smart_toy), text: 'AI'),
            Tab(icon: const Icon(Icons.cloud_sync), text: tr('Sync', 'सिंक')),
            Tab(icon: const Icon(Icons.info), text: tr('About', 'परिचय')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStyleTab(), _buildAIConfigTab(), const _CloudSyncTab(), _buildAboutTab()],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold));

  Widget _buildStyleTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Language / भाषा'),
        const SizedBox(height: 16),
        Consumer(builder: (context, ref, _) {
          final lang = ref.watch(settingsProvider.select((s) => s.appLanguage));
          return SegmentedButton<String>(
            segments: [for (final e in L10n.languages.entries) ButtonSegment(value: e.key, label: Text(e.value))],
            selected: {lang},
            onSelectionChanged: (v) async {
              await ref.read(settingsProvider.notifier).updateLanguage(v.first);
              if (mounted) setState(() => _selectedLanguage = this.ref.read(settingsProvider).aiLanguage);
            },
          );
        }),
        const SizedBox(height: 32),
        _sectionTitle(tr('Chart Style', 'कुंडली शैली')),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('style$_selectedStyle'),
          initialValue: _selectedStyle,
          items: ['North', 'South', 'East'].map((e) => DropdownMenuItem(value: e, child: Text(tr('$e Indian Chart', const {'North': 'उत्तर भारतीय कुंडली', 'South': 'दक्षिण भारतीय कुंडली', 'East': 'पूर्व भारतीय कुंडली'}[e]!)))).toList(),
          onChanged: (v) => setState(() => _selectedStyle = v!),
        ),
        const SizedBox(height: 32),
        _sectionTitle(tr('Colour Theme', 'रंग थीम')),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('theme$_selectedTheme'),
          initialValue: _selectedTheme,
          items: ['Cosmic', 'Dark', 'Light'].map((e) => DropdownMenuItem(value: e, child: Text(tr(e, const {'Cosmic': 'कॉस्मिक', 'Dark': 'गहरा', 'Light': 'हल्का'}[e]!)))).toList(),
          onChanged: (v) => setState(() => _selectedTheme = v!),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await ref.read(settingsProvider.notifier).updateAppearance(_selectedStyle, _selectedTheme);
            messenger.showSnackBar(SnackBar(content: Text(tr('Appearance saved', 'रूप-रंग सहेजा गया'))));
          },
          child: Text(tr('Save Appearance', 'रूप-रंग सहेजें')),
        ),
        const SizedBox(height: 40),
        _sectionTitle(tr('Calculation Conventions', 'गणना पद्धतियाँ')),
        const SizedBox(height: 8),
        Text(tr('Where Jyotisha traditions differ, choose the rule used by Conjunctions, Strength and Synthesis. Every report states the rule it used.', 'जहाँ ज्योतिष परंपराएँ भिन्न हैं, वहाँ युति, बल और संश्लेषण में प्रयुक्त नियम चुनें। हर रिपोर्ट अपना प्रयुक्त नियम बताती है।'),
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Consumer(builder: (context, ref, _) {
          final calc = ref.watch(settingsProvider.select((s) => s.calc));
          final notifier = ref.read(settingsProvider.notifier);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('ay${calc.ayanamsa}'),
                initialValue: calc.ayanamsa,
                decoration: InputDecoration(labelText: tr('Ayanamsa', 'अयनांश'), helperText: tr('Applies to charts opened after the change', 'बदलाव के बाद खोली गई कुंडलियों पर लागू')),
                items: [
                  for (final e in Ephemeris.ayanamsaModes.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value.$2, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => notifier.updateCalc(calc.copyWith(ayanamsa: v)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<bool>(
                isExpanded: true,
                key: ValueKey('tn${calc.trueNode}'),
                initialValue: calc.trueNode,
                decoration: InputDecoration(labelText: tr('Rahu/Ketu node', 'राहु/केतु पात')),
                items: [
                  DropdownMenuItem(value: false, child: Text(tr('Mean node', 'मध्यम पात'))),
                  DropdownMenuItem(value: true, child: Text(tr('True (osculating) node', 'स्पष्ट (वास्तविक) पात'))),
                ],
                onChanged: (v) => notifier.updateCalc(calc.copyWith(trueNode: v)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                isExpanded: true,
                key: ValueKey('dy${calc.dashaYearDays}'),
                initialValue: calc.dashaYearDays,
                decoration: InputDecoration(labelText: tr('Daśā year length', 'दशा वर्ष की लंबाई')),
                items: [
                  DropdownMenuItem(value: 365.25, child: Text(tr('365.25 days (Julian year)', '365.25 दिन (जूलियन वर्ष)'))),
                  DropdownMenuItem(value: 365.2425, child: Text(tr('365.2425 days (Gregorian year)', '365.2425 दिन (ग्रेगोरियन वर्ष)'))),
                ],
                onChanged: (v) => notifier.updateCalc(calc.copyWith(dashaYearDays: v)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                isExpanded: true,
                key: ValueKey('ck${calc.karakaScheme}'),
                initialValue: calc.karakaScheme,
                decoration: InputDecoration(labelText: tr('Jaimini Chara Karakas', 'जैमिनी चर कारक')),
                items: [
                  DropdownMenuItem(value: 8, child: Text(tr('8 karakas (with Rahu)', '8 कारक (राहु सहित)'))),
                  DropdownMenuItem(value: 7, child: Text(tr('7 karakas (Sun to Saturn)', '7 कारक (सूर्य से शनि)'))),
                ],
                onChanged: (v) => notifier.updateCalc(calc.copyWith(karakaScheme: v)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                isExpanded: true,
                key: ValueKey('to${calc.transitOrb}'),
                initialValue: const [1.0, 2.0, 3.0].contains(calc.transitOrb) ? calc.transitOrb : 2.0,
                decoration: InputDecoration(labelText: tr('Transit trigger orb', 'गोचर संकेत सीमा')),
                items: [
                  DropdownMenuItem(value: 1.0, child: Text(tr('1° (tight)', '1° (सख़्त)'))),
                  DropdownMenuItem(value: 2.0, child: Text(tr('2° (default)', '2° (डिफ़ॉल्ट)'))),
                  DropdownMenuItem(value: 3.0, child: Text(tr('3° (wide)', '3° (विस्तृत)'))),
                ],
                onChanged: (v) => notifier.updateCalc(calc.copyWith(transitOrb: v)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NodeAspectRule>(
                isExpanded: true,
                key: ValueKey('na${calc.nodeAspects}'),
                initialValue: calc.nodeAspects,
                decoration: InputDecoration(labelText: tr('Rahu/Ketu aspects', 'राहु/केतु की दृष्टि')),
                items: [
                  for (final v in NodeAspectRule.values)
                    DropdownMenuItem(value: v, child: Text(calc.copyWith(nodeAspects: v).nodeAspectLabel, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => notifier.updateCalc(calc.copyWith(nodeAspects: v)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WarRule>(
                isExpanded: true,
                key: ValueKey('war${calc.warRule}'),
                initialValue: calc.warRule,
                decoration: InputDecoration(labelText: tr('Planetary war (Graha Yuddha) winner', 'ग्रह युद्ध में विजेता')),
                items: [
                  for (final v in WarRule.values)
                    DropdownMenuItem(value: v, child: Text(calc.copyWith(warRule: v).warRuleLabel, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => notifier.updateCalc(calc.copyWith(warRule: v)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<double>(
                isExpanded: true,
                key: ValueKey('orb${calc.closeConjunctionOrb}'),
                initialValue: const [3.0, 5.0, 8.0, 10.0].contains(calc.closeConjunctionOrb) ? calc.closeConjunctionOrb : 5.0,
                decoration: InputDecoration(labelText: tr('Close conjunction within', 'निकट युति की सीमा')),
                items: [for (final v in const [3.0, 5.0, 8.0, 10.0]) DropdownMenuItem(value: v, child: Text('${v.toStringAsFixed(0)}°'))],
                onChanged: (v) => notifier.updateCalc(calc.copyWith(closeConjunctionOrb: v)),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAIConfigTab() {
    final scheme = Theme.of(context).colorScheme;
    final live = ref.watch(settingsProvider.select((st) => st.modelCache[_selectedLLM]?.length ?? 0));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            tr('All charts are calculated offline. The AI features are optional: only when you ask for an '
                'interpretation is the chart data sent to the provider below, using your own API key.',
                'सभी कुंडलियाँ ऑफ़लाइन गणना होती हैं। AI सुविधाएँ वैकल्पिक हैं: केवल जब आप विश्लेषण माँगते हैं, तभी कुंडली का डेटा आपकी अपनी API key से नीचे दिए प्रदाता को भेजा जाता है।'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('llm$_selectedLLM'),
          initialValue: _selectedLLM,
          decoration: InputDecoration(labelText: tr('LLM Provider', 'AI प्रदाता')),
          items: LlmProviders.endpoints.keys
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e == 'Custom' ? tr('Custom (OpenAI-compatible, e.g. Ollama)', 'कस्टम (OpenAI-संगत, जैसे Ollama)') : e, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: _onLLMChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureKey,
          decoration: InputDecoration(
            labelText: _selectedLLM == 'Custom' ? tr('API Key (optional)', 'API Key (वैकल्पिक)') : 'API Key',
            helperText: tr('Stored encrypted on this device only', 'केवल इस डिवाइस पर एन्क्रिप्ट करके रखी गई'),
            prefixIcon: const Icon(Icons.security),
            suffixIcon: IconButton(
              icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _modelController,
          decoration: InputDecoration(
            labelText: tr('Model', 'मॉडल'),
            helperText: live > 0
                ? tr('$live models available • tap the list icon to choose', '$live मॉडल उपलब्ध • चुनने के लिए सूची आइकन दबाएँ')
                : tr('Tap the list icon to choose, or type any model id', 'चुनने के लिए सूची आइकन दबाएँ, या कोई भी मॉडल id लिखें'),
            helperMaxLines: 2,
            suffixIcon: IconButton(
              tooltip: tr('Choose model', 'मॉडल चुनें'),
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: _pickModel,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _loadingModels ? null : () => _loadModels(),
            icon: _loadingModels
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 18),
            label: Text(tr('Load latest models from provider', 'प्रदाता से नवीनतम मॉडल लोड करें')),
          ),
        ),
        if (_modelsStatus != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_modelsStatus!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('lang$_selectedLanguage'),
          initialValue: _selectedLanguage,
          decoration: InputDecoration(labelText: tr('Interpreter Language', 'AI उत्तर की भाषा')),
          items: _languages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedLanguage = v!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _endpointController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'API Endpoint'),
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _saveAiConfig, child: Text(tr('Save', 'सहेजें'))),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isTesting ? null : _testConnection,
          child: _isTesting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(tr('Test Connection', 'कनेक्शन जाँचें')),
        ),
        const SizedBox(height: 32),
        _buildApiGuide(),
      ],
    );
  }

  Widget _buildApiGuide() {
    return ExpansionTile(
      title: Text(tr('How to get an API Key', 'API Key कैसे प्राप्त करें'),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        _buildGuideSection('OpenAI (ChatGPT)', tr('1. Go to platform.openai.com\n2. Create an account and add a payment method.\n3. Go to API Keys and click "Create new secret key".\n4. Copy the key and paste it here.', '1. platform.openai.com पर जाएँ\n2. खाता बनाएँ और भुगतान विधि जोड़ें।\n3. API Keys में जाकर "Create new secret key" दबाएँ।\n4. key कॉपी करके यहाँ चिपकाएँ।')),
        _buildGuideSection('Anthropic (Claude)', tr('1. Go to console.anthropic.com\n2. Sign up and add billing details.\n3. Open "API Keys" and create a key.\n4. Paste it here.', '1. console.anthropic.com पर जाएँ\n2. साइन अप करके बिलिंग जानकारी जोड़ें।\n3. "API Keys" खोलकर key बनाएँ।\n4. यहाँ चिपकाएँ।')),
        _buildGuideSection('Gemini (Google)', tr('1. Go to aistudio.google.com\n2. Sign in with your Google account.\n3. Click "Get API key" and create one.\n4. Paste it here.', '1. aistudio.google.com पर जाएँ\n2. अपने Google खाते से साइन इन करें।\n3. "Get API key" दबाकर key बनाएँ।\n4. यहाँ चिपकाएँ।')),
        _buildGuideSection('DeepSeek', tr('1. Go to platform.deepseek.com\n2. Create an account.\n3. Create a key in the API Keys section.', '1. platform.deepseek.com पर जाएँ\n2. खाता बनाएँ।\n3. API Keys भाग में key बनाएँ।')),
        _buildGuideSection('Grok (xAI)', tr('1. Go to console.x.ai\n2. Sign in and open the API Keys section to generate a key.', '1. console.x.ai पर जाएँ\n2. साइन इन करके API Keys भाग में key बनाएँ।')),
        _buildGuideSection(tr('Custom / Local (Ollama, LM Studio)', 'कस्टम / स्थानीय (Ollama, LM Studio)'), tr('Run an OpenAI-compatible server on your network, then enter its /v1/chat/completions URL and model name. No key is needed for most local servers.', 'अपने नेटवर्क पर OpenAI-संगत सर्वर चलाएँ, फिर उसका /v1/chat/completions URL और मॉडल नाम लिखें। अधिकांश स्थानीय सर्वरों के लिए key की ज़रूरत नहीं।')),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            tr('Your API key is encrypted and stored only on this device. It is sent only to the AI provider you configure.',
                'आपकी API key एन्क्रिप्ट करके केवल इस डिवाइस पर रखी जाती है। यह केवल आपके चुने AI प्रदाता को भेजी जाती है।'),
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)),
        ),
        child: Column(children: children),
      );

  Widget _buildAboutTab() {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Icon(Icons.auto_awesome, size: 80, color: scheme.secondary),
        const SizedBox(height: 24),
        Text('Jyotish Cosmic',
            textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurface, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_version.isEmpty ? '' : '${tr('Version', 'संस्करण')} $_version',
            textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16)),
        const SizedBox(height: 32),
        _card([
          Text(tr('Updates', 'अपडेट'), style: TextStyle(color: scheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isDownloading && _downloadProgress != null) ...[
            LinearProgressIndicator(value: _downloadProgress),
            const SizedBox(height: 8),
            Text('${tr('Downloading', 'डाउनलोड हो रहा है')}: ${(_downloadProgress! * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCheckingUpdate || _version.isEmpty ? null : _checkAndInstallUpdate,
                icon: _isCheckingUpdate
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_download),
                label: Text(tr('Check for Updates (GitHub)', 'अपडेट जाँचें (GitHub)')),
              ),
            ),
        ]),
        const SizedBox(height: 24),
        _card([
          Text(tr('Created by', 'निर्माता'), style: TextStyle(color: scheme.secondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Astro Yogesh', style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            tr('Charts are computed on your device with the Swiss Ephemeris (Astrodienst AG, AGPL-3.0) using the sidereal '
                'zodiac and Lahiri ayanamsa. Profiles are stored in a local database and are uploaded only if you turn on '
                'Cloud Sync. City data © GeoNames (CC BY 4.0).',
                'कुंडलियाँ आपके डिवाइस पर स्विस एफ़ेमेरिस (Astrodienst AG, AGPL-3.0) से निरयन राशिचक्र और लाहिरी अयनांश के साथ गणना होती हैं। '
                    'प्रोफ़ाइल स्थानीय डेटाबेस में रहती हैं और केवल क्लाउड सिंक चालू करने पर ही अपलोड होती हैं। शहर डेटा © GeoNames (CC BY 4.0)।'),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ]),
      ],
    );
  }
}

/// Optional cloud backup/sync of profiles across devices.
class _CloudSyncTab extends ConsumerStatefulWidget {
  const _CloudSyncTab();

  @override
  ConsumerState<_CloudSyncTab> createState() => _CloudSyncTabState();
}

class _CloudSyncTabState extends ConsumerState<_CloudSyncTab> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _server = TextEditingController();
  bool _serverLoaded = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _email.text.trim();
    String? error;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      error = tr('Please enter a valid email address', 'कृपया सही ईमेल पता लिखें');
    } else if (_password.text.length < 6) {
      error = tr('Password must be at least 6 characters', 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए');
    }
    if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return error == null;
  }

  Future<void> _auth(bool create) async {
    if (!_validate()) return;
    final notifier = ref.read(syncProvider.notifier);
    await notifier.setServerUrl(_server.text);
    final ok = create
        ? await notifier.register(_email.text, _password.text)
        : await notifier.signIn(_email.text, _password.text);
    if (ok) _password.clear();
  }

  String _fmt(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncProvider);
    final scheme = Theme.of(context).colorScheme;
    if (!_serverLoaded && !sync.loading) {
      _server.text = sync.serverUrl;
      _serverLoaded = true;
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            tr('Cloud Sync is optional. The app works fully offline; when you sign in, your profiles and saved '
                'interpretations are backed up to the server below and kept in sync across your devices.',
                'क्लाउड सिंक वैकल्पिक है। ऐप पूरी तरह ऑफ़लाइन चलता है; साइन इन करने पर आपकी प्रोफ़ाइल और सहेजे गए विश्लेषण नीचे दिए सर्वर पर बैकअप होते हैं और आपके सभी डिवाइसों में सिंक रहते हैं।'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
        if (sync.loading)
          const Center(child: CircularProgressIndicator())
        else if (sync.signedIn) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_done, color: scheme.secondary, size: 36),
            title: Text('${tr('Signed in as', 'साइन इन')}: ${sync.email ?? ''}'),
            subtitle: Text(sync.serverUrl),
          ),
          const SizedBox(height: 8),
          Text(
            sync.busy
                ? tr('Syncing...', 'सिंक हो रहा है...')
                : sync.lastSync == null
                    ? tr('Not synced yet', 'अभी सिंक नहीं हुआ')
                    : '${tr('Last sync', 'पिछला सिंक')}: ${_fmt(sync.lastSync!)} (${sync.lastResult ?? ''})',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (sync.error != null) ...[
            const SizedBox(height: 8),
            Text(sync.error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: sync.busy ? null : () => ref.read(syncProvider.notifier).syncNow(),
                  icon: sync.busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                  label: Text(tr('Sync now', 'अभी सिंक करें')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: sync.busy ? null : () => ref.read(syncProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(tr('Sign out', 'साइन आउट')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tr('Signing out keeps all profiles on this device.', 'साइन आउट करने पर सभी प्रोफ़ाइल इस डिवाइस पर बनी रहती हैं।'),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ] else ...[
          TextField(
            controller: _server,
            decoration: InputDecoration(labelText: tr('Sync server', 'सिंक सर्वर'), prefixIcon: const Icon(Icons.dns)),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            decoration: InputDecoration(labelText: tr('Email', 'ईमेल'), prefixIcon: const Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: tr('Password', 'पासवर्ड'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            autofillHints: const [AutofillHints.password],
          ),
          if (sync.error != null) ...[
            const SizedBox(height: 12),
            Text(sync.error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                child: ElevatedButton(
                  onPressed: sync.busy ? null : () => _auth(false),
                  child: sync.busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(tr('Sign In', 'साइन इन')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                child: OutlinedButton(
                  onPressed: sync.busy ? null : () => _auth(true),
                  child: Text(tr('Create Account', 'खाता बनाएँ')),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Searchable list of the provider's models.
class _ModelPickerSheet extends StatefulWidget {
  final String provider;
  final List<String> models;
  final String current;
  final bool live;

  const _ModelPickerSheet({required this.provider, required this.models, required this.current, required this.live});

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _query.toLowerCase();
    final filtered = widget.models.where((m) => m.toLowerCase().contains(q)).toList();
    final custom = _query.trim();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(tr('${widget.provider} models', '${widget.provider} मॉडल'), style: Theme.of(context).textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  widget.live
                      ? tr('Loaded from your ${widget.provider} account, newest first.', 'आपके ${widget.provider} खाते से लोड, नवीनतम पहले।')
                      : tr('Suggested models. Use "Load latest models from provider" to see every model on your account.', 'सुझाए गए मॉडल। अपने खाते के सभी मॉडल देखने के लिए "प्रदाता से नवीनतम मॉडल लोड करें" दबाएँ।'),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: false,
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr('Search or type a model id', 'खोजें या मॉडल id लिखें')),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    if (custom.isNotEmpty && !widget.models.contains(custom))
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text(tr('Use "$custom"', '"$custom" उपयोग करें'), overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(context, custom),
                      ),
                    for (final m in filtered)
                      ListTile(
                        title: Text(m, overflow: TextOverflow.ellipsis),
                        trailing: m == widget.current ? Icon(Icons.check, color: scheme.primary) : null,
                        onTap: () => Navigator.pop(context, m),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
