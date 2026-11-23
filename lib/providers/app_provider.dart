/// Main app state provider: theme, selected model,
  settings, gateway status.
  library app_provider;

  import 'dart:json';
  import 'package:flutter/material.dart';
  import
  'package:shared_preferences/shared_preferences.dart';
  import 'package:flutter_secure_storage/flutter_secure_sto
  rage.dart';
  import '../core/constants/app_constants.dart';
  import '../theme/app_theme.dart';

  /// Secure storage instance.
  final FlutterSecureStorage _secureStorage = const
  FlutterSecureStorage(                                        aOptions: AndroidOptions(encryptedSharedPreferences:
  true),                                                     );

  /// App-wide state managed by Provider.                    class AppProvider extends ChangeNotifier {
    // Theme                                                   AppThemeData _themeData = const AppThemeData();
    AppThemeData get themeData => _themeData;              
    // Selected model                                          String _selectedModel = 'auto';
    String get selectedModel => _selectedModel;            
    // Gateway
    String _gatewayBaseUrl = kDefaultGatewayBaseUrl;
    String get gatewayBaseUrl => _gatewayBaseUrl;          
    GatewayStatus _gatewayStatus = GatewayStatus.unknown;      GatewayStatus get gatewayStatus => _gatewayStatus;
                                                               // API key (masked for UI)
    String? _apiKey;                                           String? get apiKey => _apiKey;
    String get maskedApiKey {
      if (_apiKey == null || _apiKey!.isEmpty) return '';        if (_apiKey!.length <= 8) return '********';
      return '${_apiKey!.substring(0,                        4)}****${_apiKey!.substring(_apiKey!.length - 4)}';
    }

    // Font size multiplier                                    double _fontSize = 1.0;
    double get fontSize => _fontSize;                      
    // Haptics                                                 bool _hapticsEnabled = true;
    bool get hapticsEnabled => _hapticsEnabled;

    // Loading states                                          bool _isLoadingTheme = true;
    bool get isLoadingTheme => _isLoadingTheme;            
    bool _isTestingConnection = false;                         bool get isTestingConnection => _isTestingConnection;
                                                               /// Initialize all persisted settings.
    Future<void> initialize() async {
      final prefs = await SharedPreferences.getInstance();
                                                                 // Theme
      final themeModeIndex = prefs.getInt(kPrefThemeMode)    ?? 0;
      final presetIndex =
  prefs.getInt(kPrefColorThemeIndex) ?? 0;
      final customColorsJson =                               prefs.getString(kPrefCustomColors);
      ColorThemePreset? customPreset;                            if (customColorsJson != null) {
        try {
          customPreset =
  ColorThemePreset.fromJson(jsonDecode(customColorsJson));         } catch (_) {}
      }                                                          _themeData = AppThemeData(
        themeMode: AppThemeMode.values[themeModeIndex],
        presetIndex: presetIndex,
        customPreset: customPreset,                              );
                                                                 // Model
      _selectedModel = prefs.getString(kPrefSelectedModel)   ?? 'auto';

      // Gateway URL                                             _gatewayBaseUrl =
  prefs.getString(kPrefGatewayBaseUrl) ??                    kDefaultGatewayBaseUrl;

      // Font size
      _fontSize = prefs.getDouble(kPrefFontSize) ?? 1.0;
                                                                 // Haptics
      _hapticsEnabled = prefs.getBool(kPrefHapticsEnabled)   ?? true;

      // API key (secure)
      _apiKey = await _secureStorage.read(key:
  kSecureApiKey);
                                                                 _isLoadingTheme = false;
      notifyListeners();                                       }
                                                               // ─── Theme ───

    Future<void> setThemeMode(AppThemeMode mode) async {
      final prefs = await SharedPreferences.getInstance();       await prefs.setInt(kPrefThemeMode, mode.index);
      _themeData = AppThemeData(                                   themeMode: mode,
        presetIndex: _themeData.presetIndex,
        customPreset: _themeData.customPreset,
      );                                                         notifyListeners();
    }                                                      
    Future<void> setPresetIndex(int index) async {               final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kPrefColorThemeIndex, index);
      _themeData = AppThemeData(
        themeMode: _themeData.themeMode,                           presetIndex: index,
        customPreset: null,
      );
      notifyListeners();
    }                                                      
    Future<void> setCustomPreset(ColorThemePreset preset)    async {
      final prefs = await SharedPreferences.getInstance();       await prefs.setString(kPrefCustomColors,
  jsonEncode(preset.toJson()));                                  _themeData = AppThemeData(
        themeMode: _themeData.themeMode,
        presetIndex: -1,
        customPreset: preset,                                    );
      notifyListeners();                                       }
                                                               // ─── Model ───

    Future<void> setSelectedModel(String model) async {          final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefSelectedModel, model);
      _selectedModel = model;
      notifyListeners();
    }

    // ─── Gateway URL ───                                 
    Future<void> setGatewayBaseUrl(String url) async {           final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefGatewayBaseUrl, url);
      _gatewayBaseUrl = url;
      notifyListeners();                                       }

    // ─── API Key ───

    Future<void> setApiKey(String? key) async {                  if (key == null || key.isEmpty) {
        await _secureStorage.delete(key: kSecureApiKey);           _apiKey = null;
      } else {                                                     await _secureStorage.write(key: kSecureApiKey,
  value: key);
        _apiKey = key;
      }                                                          notifyListeners();
    }

    // ─── Font size ───                                   
    Future<void> setFontSize(double size) async {                final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(kPrefFontSize, size.clamp(0.8,
  1.5));
      _fontSize = size.clamp(0.8, 1.5);
      notifyListeners();                                       }

    // ─── Haptics ───                                     
    Future<void> setHapticsEnabled(bool enabled) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kPrefHapticsEnabled, enabled);         _hapticsEnabled = enabled;
      notifyListeners();
    }
                                                               // ─── Gateway status ───
                                                               void setGatewayStatus(GatewayStatus status) {
      _gatewayStatus = status;
      notifyListeners();
    }
  }                                                        
  /// Gateway connection status.                             enum GatewayStatus { unknown, starting, connected,
  offline, error }

  /// Gateway status extension for UI.                         String get label {
      switch (this) {
        case GatewayStatus.unknown:
          return 'Checking...';
        case GatewayStatus.starting:
          return 'Starting...';
        case GatewayStatus.connected:                                return 'Connected';
        case GatewayStatus.offline:                                  return 'Offline';
        case GatewayStatus.error:                                    return 'Error';
      }
    }

    Color get color {
      switch (this) {                                              case GatewayStatus.unknown:
          return Colors.grey;
        case GatewayStatus.starting:
          return Colors.orange;                                    case GatewayStatus.connected:
          return Colors.green;
        case GatewayStatus.offline:
          return Colors.red;
        case GatewayStatus.error:                                    return Colors.red;
      }                                                        }

    IconData get icon {
      switch (this) {
        case GatewayStatus.unknown:
          return Icons.help_outline;
        case GatewayStatus.starting:
          return Icons.hourglass_top;
        case GatewayStatus.connected:                                return Icons.wifi;
        case GatewayStatus.offline:                                  return Icons.wifi_off;
        case GatewayStatus.error:
          return Icons.error_outline;                            }
    }                                                        }
