import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  // Appearance
  final String chartStyle; // 'North' or 'South'
  final String themeMode; // 'Cosmic', 'Dark', 'Light'
  
  // AI Config
  final String llmProvider;
  final String aiLanguage;
  final String apiEndpoint;
  final String apiKey;
  final String modelName;

  // Update Config
  final String updateServerIp;

  SettingsState({
    this.chartStyle = 'North',
    this.themeMode = 'Cosmic',
    this.llmProvider = 'OpenAI',
    this.aiLanguage = 'English',
    this.apiEndpoint = 'https://api.openai.com/v1/chat/completions',
    this.apiKey = '',
    this.modelName = 'gpt-5',
    this.updateServerIp = '192.168.1.100',
  });

  SettingsState copyWith({
    String? chartStyle,
    String? themeMode,
    String? llmProvider,
    String? aiLanguage,
    String? apiEndpoint,
    String? apiKey,
    String? modelName,
    String? updateServerIp,
  }) {
    return SettingsState(
      chartStyle: chartStyle ?? this.chartStyle,
      themeMode: themeMode ?? this.themeMode,
      llmProvider: llmProvider ?? this.llmProvider,
      aiLanguage: aiLanguage ?? this.aiLanguage,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      updateServerIp: updateServerIp ?? this.updateServerIp,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  final _storage = const FlutterSecureStorage();

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState();
  }

  Future<void> _loadSettings() async {
    final style = await _storage.read(key: 'chartStyle');
    final theme = await _storage.read(key: 'themeMode');
    final llm = await _storage.read(key: 'llmProvider');
    final lang = await _storage.read(key: 'aiLanguage');
    final endpoint = await _storage.read(key: 'apiEndpoint');
    final key = await _storage.read(key: 'apiKey');
    final model = await _storage.read(key: 'modelName');
    final updateIp = await _storage.read(key: 'updateServerIp');

    state = state.copyWith(
      chartStyle: style,
      themeMode: theme,
      llmProvider: llm,
      aiLanguage: lang,
      apiEndpoint: endpoint,
      apiKey: key,
      modelName: model,
      updateServerIp: updateIp,
    );
  }

  Future<void> updateAppearance(String style, String theme) async {
    await _storage.write(key: 'chartStyle', value: style);
    await _storage.write(key: 'themeMode', value: theme);
    state = state.copyWith(chartStyle: style, themeMode: theme);
  }

  Future<void> updateAIConfig(String llm, String lang, String endpoint, String key, String model) async {
    await _storage.write(key: 'llmProvider', value: llm);
    await _storage.write(key: 'aiLanguage', value: lang);
    await _storage.write(key: 'apiEndpoint', value: endpoint);
    await _storage.write(key: 'apiKey', value: key);
    await _storage.write(key: 'modelName', value: model);
    
    state = state.copyWith(
      llmProvider: llm,
      aiLanguage: lang,
      apiEndpoint: endpoint,
      apiKey: key,
      modelName: model,
    );
  }

  Future<void> updateServerIp(String ip) async {
    await _storage.write(key: 'updateServerIp', value: ip);
    state = state.copyWith(updateServerIp: ip);
  }
}
