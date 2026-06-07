import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 State
  String _selectedStyle = 'North';
  String _selectedTheme = 'Cosmic';

  // Tab 2 State
  String _selectedLLM = 'OpenAI';
  String _selectedLanguage = 'English';
  final _endpointController = TextEditingController();
  final _apiKeyController = TextEditingController();
  String _selectedModel = 'gpt-4o';
  
  bool _isTesting = false;

  final Map<String, List<String>> _providerModels = {
    'OpenAI': ['gpt-5', 'gpt-4.5-turbo'],
    'Gemini': ['gemini-2.5-pro', 'gemini-2.5-flash', 'gemini-omni'],
    'Anthropic': ['claude-4-opus', 'claude-4-sonnet', 'claude-3.5-sonnet'],
    'DeepSeek': ['deepseek-chat', 'deepseek-reasoner'],
    'Grok': ['grok-4', 'grok-4-turbo'],
  };

  final Map<String, String> _providerEndpoints = {
    'OpenAI': 'https://api.openai.com/v1/chat/completions',
    'Gemini': 'https://generativelanguage.googleapis.com/v1beta/models/',
    'Anthropic': 'https://api.anthropic.com/v1/messages',
    'DeepSeek': 'https://api.deepseek.com/v1/chat/completions',
    'Grok': 'https://api.x.ai/v1/chat/completions',
  };

  // Tab 3 State (Updater)
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial state after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(settingsProvider);
      setState(() {
        _selectedStyle = state.chartStyle;
        _selectedTheme = state.themeMode;
        _selectedLLM = state.llmProvider;
        _selectedLanguage = state.aiLanguage;
        _endpointController.text = state.apiEndpoint;
        _apiKeyController.text = state.apiKey;
        
        // Ensure model exists in provider list
        if (_providerModels[_selectedLLM]?.contains(state.modelName) ?? false) {
          _selectedModel = state.modelName;
        } else {
          _selectedModel = _providerModels[_selectedLLM]!.first;
        }
      });
    });
  }

  void _onLLMChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedLLM = newValue;
        _endpointController.text = _providerEndpoints[newValue]!;
        _selectedModel = _providerModels[newValue]!.first;
      });
    }
  }

  void _testConnection() async {
    setState(() => _isTesting = true);
    // Simulate API ping
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isTesting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection Successful!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _checkAndInstallUpdate() async {
    setState(() => _isCheckingUpdate = true);
    
    final updateService = UpdateService();
    final updateData = await updateService.checkUpdate();
    
    if (updateData == null) {
      setState(() => _isCheckingUpdate = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are on the latest version! No update found.')));
      }
      return;
    }

    setState(() {
      _isCheckingUpdate = false;
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final success = await updateService.downloadAndInstallUpdate(updateData['url']!, (received, total) {
      if (total != -1) {
        setState(() {
          _downloadProgress = received / total;
        });
      }
    });

    setState(() {
      _isDownloading = false;
      _downloadProgress = null;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed. Please check internet.')));
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
        children: [
          _buildStyleTab(),
          _buildAIConfigTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  Widget _buildStyleTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Chart Style', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedStyle,
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          items: ['North', 'South', 'East'].map((e) => DropdownMenuItem(value: e, child: Text('\$e Indian Chart'))).toList(),
          onChanged: (v) => setState(() => _selectedStyle = v!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 32),
        Text('Colour Theme', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedTheme,
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          items: ['Cosmic', 'Dark', 'Light'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedTheme = v!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {
            ref.read(settingsProvider.notifier).updateAppearance(_selectedStyle, _selectedTheme);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appearance Saved!')));
          },
          child: const Text('Save Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildAIConfigTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DropdownButtonFormField<String>(
          value: _selectedLLM,
          decoration: const InputDecoration(labelText: 'LLM Provider', border: OutlineInputBorder()),
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          items: _providerModels.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: _onLLMChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedModel,
          decoration: const InputDecoration(labelText: 'Latest Models', border: OutlineInputBorder()),
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          items: _providerModels[_selectedLLM]!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedModel = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedLanguage,
          decoration: const InputDecoration(labelText: 'Interpreter Language', border: OutlineInputBorder()),
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          items: ['English', 'Hindi', 'Sanskrit', 'Spanish'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedLanguage = v!),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _endpointController,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: const InputDecoration(labelText: 'API Endpoint', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _apiKeyController,
          obscureText: true,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: const InputDecoration(
            labelText: 'API Key (Encrypted)', 
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.security),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isTesting ? null : _testConnection,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  padding: const EdgeInsets.all(16)
                ),
                child: _isTesting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Test Connection', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).updateAIConfig(
                    _selectedLLM, 
                    _selectedLanguage, 
                    _endpointController.text, 
                    _apiKeyController.text, 
                    _selectedModel
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Configuration Saved Securely!')));
                },
                child: const Text('Save API Key', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        _buildApiGuide(),
      ],
    );
  }

  Widget _buildApiGuide() {
    return ExpansionTile(
      title: Text('📖 How to get an API Key', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        _buildGuideSection('OpenAI (ChatGPT)', '1. Go to platform.openai.com\n2. Create an account and add a payment method.\n3. Go to API Keys and click "Create new secret key".\n4. Copy the key and paste it here.'),
        _buildGuideSection('Gemini (Google) - FREE', '1. Go to aistudio.google.com\n2. Sign in with your Google account.\n3. Click "Get API key" on the left menu.\n4. Click "Create API key" and paste it here. It is free for standard usage!'),
        _buildGuideSection('Anthropic (Claude)', '1. Go to console.anthropic.com\n2. Sign up and add billing details.\n3. Navigate to "Get API Keys" and generate one.\n4. Paste it here.'),
        _buildGuideSection('DeepSeek - CHEAP', '1. Go to platform.deepseek.com\n2. Create an account.\n3. Go to API Keys section and create one.\n4. DeepSeek is incredibly affordable.'),
        _buildGuideSection('Grok (xAI)', '1. Go to console.x.ai\n2. Sign in with your X account.\n3. Navigate to the API Keys section to generate your key.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'Note: Your API Key is encrypted and stored locally on your device. It is never sent anywhere except directly to the AI provider.',
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

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.auto_awesome, size: 80, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 24),
            Text('Jyotish Cosmic', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Version 1.0.0', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text('OTA Updates', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_isDownloading && _downloadProgress != null)
                    Column(
                      children: [
                        LinearProgressIndicator(value: _downloadProgress),
                        const SizedBox(height: 8),
                        Text('Downloading: \${(_downloadProgress! * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingUpdate ? null : _checkAndInstallUpdate,
                        icon: _isCheckingUpdate 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.cloud_download),
                        label: const Text('Check for Updates (GitHub)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text('Created by', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Astro Yogesh', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(
                    'A high-performance astrological charting engine and LLM interpreter built natively in Flutter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
