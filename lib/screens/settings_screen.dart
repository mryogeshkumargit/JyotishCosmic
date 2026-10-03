import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
        setState(() => _modelsStatus = 'The provider returned no models; type the model id instead.');
        return;
      }
      await ref.read(settingsProvider.notifier).cacheModels(provider, models);
      if (!mounted) return;
      setState(() => _modelsStatus = '${models.length} models loaded from $provider');
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
            Tab(icon: Icon(Icons.smart_toy), text: 'AI'),
            Tab(icon: Icon(Icons.cloud_sync), text: 'Sync'),
            Tab(icon: Icon(Icons.info), text: 'About'),
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
        _sectionTitle('Chart Style'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('style$_selectedStyle'),
          initialValue: _selectedStyle,
          items: ['North', 'South', 'East'].map((e) => DropdownMenuItem(value: e, child: Text('$e Indian Chart'))).toList(),
          onChanged: (v) => setState(() => _selectedStyle = v!),
        ),
        const SizedBox(height: 32),
        _sectionTitle('Colour Theme'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
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
    final scheme = Theme.of(context).colorScheme;
    final live = ref.watch(settingsProvider.select((st) => st.modelCache[_selectedLLM]?.length ?? 0));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
          isExpanded: true,
          key: ValueKey('llm$_selectedLLM'),
          initialValue: _selectedLLM,
          decoration: const InputDecoration(labelText: 'LLM Provider'),
          items: LlmProviders.endpoints.keys
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e == 'Custom' ? 'Custom (OpenAI-compatible, e.g. Ollama)' : e, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: _onLLMChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureKey,
          decoration: InputDecoration(
            labelText: _selectedLLM == 'Custom' ? 'API Key (optional)' : 'API Key',
            helperText: 'Stored encrypted on this device only',
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
            labelText: 'Model',
            helperText: live > 0 ? '$live models available • tap the list icon to choose' : 'Tap the list icon to choose, or type any model id',
            helperMaxLines: 2,
            suffixIcon: IconButton(
              tooltip: 'Choose model',
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
            label: const Text('Load latest models from provider'),
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
          decoration: const InputDecoration(labelText: 'Interpreter Language'),
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
        ElevatedButton(onPressed: _saveAiConfig, child: const Text('Save')),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isTesting ? null : _testConnection,
          child: _isTesting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Test Connection'),
        ),
        const SizedBox(height: 32),
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
            'zodiac and Lahiri ayanamsa. Profiles are stored in a local database and are uploaded only if you turn on '
            'Cloud Sync. City data © GeoNames (CC BY 4.0).',
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
      error = 'Please enter a valid email address';
    } else if (_password.text.length < 6) {
      error = 'Password must be at least 6 characters';
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
          child: const Text(
            'Cloud Sync is optional. The app works fully offline; when you sign in, your profiles and saved '
            'interpretations are backed up to the server below and kept in sync across your devices.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
        if (sync.loading)
          const Center(child: CircularProgressIndicator())
        else if (sync.signedIn) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_done, color: scheme.secondary, size: 36),
            title: Text('Signed in as ${sync.email ?? ''}'),
            subtitle: Text(sync.serverUrl),
          ),
          const SizedBox(height: 8),
          Text(
            sync.busy
                ? 'Syncing...'
                : sync.lastSync == null
                    ? 'Not synced yet'
                    : 'Last sync: ${_fmt(sync.lastSync!)} (${sync.lastResult ?? ''})',
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
                  label: const Text('Sync now'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: sync.busy ? null : () => ref.read(syncProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Signing out keeps all profiles on this device.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ] else ...[
          TextField(
            controller: _server,
            decoration: const InputDecoration(labelText: 'Sync server', prefixIcon: Icon(Icons.dns)),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
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
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                child: OutlinedButton(
                  onPressed: sync.busy ? null : () => _auth(true),
                  child: const Text('Create Account'),
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
                child: Text('${widget.provider} models', style: Theme.of(context).textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  widget.live
                      ? 'Loaded from your ${widget.provider} account, newest first.'
                      : 'Suggested models. Use "Load latest models from provider" to see every model on your account.',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: false,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search or type a model id'),
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
                        title: Text('Use "$custom"', overflow: TextOverflow.ellipsis),
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
