/// Single source of truth for app-wide constants.
  /// Change the app name here and it updates everywhere.
  library app_constants;

  /// The app name — change this one constant to rename the
  app everywhere.
  const String kAppName = 'AI Hub';

  /// Default gateway base URL (OpenAI-compatible API
  endpoint root).
  const String kDefaultGatewayBaseUrl =
  'http://localhost:3001/v1';

  /// Health check endpoint (any response = gateway is
  running).
  'http://localhost:3001/';

  /// Model used when no selection exists (auto mode).
  const String kDefaultModel = 'auto';

  /// Termux package name for RUN_COMMAND intent.
  const String kTermuxPackage = 'com.termux';

  /// Termux RUN_COMMAND service action.
  const String kTermuxRunCommandAction =
  'com.termux.RUN_COMMAND';

  /// Termux RUN_COMMAND service class.
  const String kTermuxRunCommandService =
  'com.termux.app.RunCommandService';

  /// SharedPreferences keys.
  const String kPrefSelectedModel = 'selected_model';
  const String kPrefThemeMode = 'theme_mode';
  const String kPrefColorThemeIndex = 'color_theme_index';
  const String kPrefCustomColors = 'custom_colors';
  const String kPrefFontSize = 'font_size';
  const String kPrefHapticsEnabled = 'haptics_enabled';
  const String kPrefGatewayBaseUrl = 'gateway_base_url';

  /// FlutterSecureStorage keys.
  const String kSecureApiKey = 'api_key';

  /// Database.
  const String kDbName = 'ai_hub.db';
  const int kDbVersion = 1;

  /// Chat limits.
  const int kMaxMessageLength = 100000;
  const int kDefaultMaxTokens = 4096;

  /// Animation durations.
  const Duration kShortAnim = Duration(milliseconds: 150);
  const Duration kMediumAnim = Duration(milliseconds: 300);
  const Duration kLongAnim = Duration(milliseconds: 500);

  /// Polling intervals.
  const Duration kGatewayPollInterval = Duration(seconds:
  2);
  const Duration kGatewayMaxWait = Duration(seconds: 40);
