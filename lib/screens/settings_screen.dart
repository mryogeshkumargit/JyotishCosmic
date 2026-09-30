import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/settings_provider.dart';
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

  // About / updater
  String _version = '';
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;
  double? _downloadProgress;

  static const _languages = ['English', 'Hindi', 'Sanskrit', 'Marathi', 'Bengali', 'Tamil', 'Telugu', 'Gujarati', 'Spanish'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _modelController.text = LlmProviders.models[newValue]!.first;
    });
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI configuration saved securely on this device')));
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AiService.testConnection(_formState());
      messenger.showSnackBar(const SnackBar(content: Text('Connection successful!'), backgroundColor: Colors.green));
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
      messenger.showSnackBar(const SnackBar(content: Text('You are on the latest version.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update available'),
        content: Text('Version ${updateData['tag']} is available. Download and install it now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Install')),
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
      messenger.showSnackBar(const SnackBar(content: Text('Update failed. Please check your internet connection.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: 'Style'),
            Tab(icon: Icon(Icons.smart_toy), text: 'AI Config'),
            Tab(icon: Icon(Icons.info), text: 'About'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStyleTab(), _buildAIConfigTab(), _buildAboutTab()],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold));

  Widget _buildStyleTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Chart Style'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('style$_selectedStyle'),
          initialValue: _selectedStyle,
          items: ['North', 'South', 'East'].map((e) => DropdownMenuItem(value: e, child: Text('$e Indian Chart'))).toList(),
          onChanged: (v) => setState(() => _selectedStyle = v!),
        ),
        const SizedBox(height: 32),
        _sectionTitle('Colour Theme'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('theme$_selectedTheme'),
          initialValue: _selectedTheme,
          items: ['Cosmic', 'Dark', 'Light'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedTheme = v!),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await ref.read(settingsProvider.notifier).updateAppearance(_selectedStyle, _selectedTheme);
            messenger.showSnackBar(const SnackBar(content: Text('Appearance saved')));
          },
          child: const Text('Save Appearance'),
        )
      ],
    );
  }

  Widget _buildAIConfigTab() {
    final suggestions = LlmProviders.models[_selectedLLM] ?? const <String>[];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'All charts are calculated offline. The AI features are optional: only when you ask for an '
            'interpretation is the chart data sent to the provider below, using your own API key.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('llm$_selectedLLM'),
          initialValue: _selectedLLM,
          decoration: const InputDecoration(labelText: 'LLM Provider'),
          items: LlmProviders.endpoints.keys
              .map((e) => DropdownMenuItem(value: e, child: Text(e == 'Custom' ? 'Custom (OpenAI-compatible, e.g. Ollama)' : e)))
              .toList(),
          onChanged: _onLLMChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _modelController,
          decoration: const InputDecoration(labelText: 'Model', helperText: 'Pick a suggestion or type any model name'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: suggestions
              .map((m) => ActionChip(label: Text(m), onPressed: () => setState(() => _modelController.text = m)))
              .toList(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('lang$_selectedLanguage'),
          initialValue: _selectedLanguage,
          decoration: const InputDecoration(labelText: 'Interpreter Language'),
          items: _languages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedLanguage = v!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _endpointController,
          decoration: const InputDecoration(labelText: 'API Endpoint'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureKey,
          decoration: InputDecoration(
            labelText: _selectedLLM == 'Custom' ? 'API Key (optional)' : 'API Key (stored encrypted)',
            prefixIcon: const Icon(Icons.security),
            suffixIcon: IconButton(
              icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureKey = !_obscureKey),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isTesting ? null : _testConnection,
                child: _isTesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test Connection'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: ElevatedButton(onPressed: _saveAiConfig, child: const Text('Save'))),
          ],
        ),
        const SizedBox(height: 48),
        _buildApiGuide(),
      ],
    );
  }

  Widget _buildApiGuide() {
    return ExpansionTile(
      title: Text('How to get an API Key',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        _buildGuideSection('OpenAI (ChatGPT)', '1. Go to platform.openai.com\n2. Create an account and add a payment method.\n3. Go to API Keys and click "Create new secret key".\n4. Copy the key and paste it here.'),
        _buildGuideSection('Anthropic (Claude)', '1. Go to console.anthropic.com\n2. Sign up and add billing details.\n3. Open "API Keys" and create a key.\n4. Paste it here.'),
        _buildGuideSection('Gemini (Google)', '1. Go to aistudio.google.com\n2. Sign in with your Google account.\n3. Click "Get API key" and create one.\n4. Paste it here.'),
        _buildGuideSection('DeepSeek', '1. Go to platform.deepseek.com\n2. Create an account.\n3. Create a key in the API Keys section.'),
        _buildGuideSection('Grok (xAI)', '1. Go to console.x.ai\n2. Sign in and open the API Keys section to generate a key.'),
        _buildGuideSection('Custom / Local (Ollama, LM Studio)', 'Run an OpenAI-compatible server on your network, then enter its /v1/chat/completions URL and model name. No key is needed for most local servers.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Your API key is encrypted and stored only on this device. It is sent only to the AI provider you configure.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
        Text(_version.isEmpty ? '' : 'Version $_version',
            textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16)),
        const SizedBox(height: 32),
        _card([
          Text('Updates', style: TextStyle(color: scheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isDownloading && _downloadProgress != null) ...[
            LinearProgressIndicator(value: _downloadProgress),
            const SizedBox(height: 8),
            Text('Downloading: ${(_downloadProgress! * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCheckingUpdate || _version.isEmpty ? null : _checkAndInstallUpdate,
                icon: _isCheckingUpdate
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_download),
                label: const Text('Check for Updates (GitHub)'),
              ),
            ),
        ]),
        const SizedBox(height: 24),
        _card([
          Text('Created by', style: TextStyle(color: scheme.secondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Astro Yogesh', style: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            'Charts are computed on your device with the Swiss Ephemeris (Astrodienst AG, AGPL-3.0) using the sidereal '
            'zodiac and Lahiri ayanamsa. Profiles are stored only in a local database. City data © GeoNames (CC BY 4.0).',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ]),
      ],
    );
  }
}
