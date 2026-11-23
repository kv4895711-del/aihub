 /// App entry point: loads settings then shows the app shell.
  library main;

  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';

  import 'providers/app_provider.dart';
  import 'providers/chat_provider.dart';
  import 'screens/app_shell.dart';
  import 'theme/app_theme.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    final appProvider = AppProvider();
    await appProvider.initialize();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appProvider),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: AiHubApp(appProvider: appProvider),
      ),
    );
  }

  /// Root widget: animated gradient background + glass theme.
  class AiHubApp extends StatelessWidget {
    final AppProvider appProvider;

    const AiHubApp({super.key, required this.appProvider});

    @override
    Widget build(BuildContext context) {
      return Consumer<AppProvider>(
        builder: (context, provider, _) {
          final themeData = provider.themeData;
          return MaterialApp(
            title: kAppName,
            theme: buildAppTheme(themeData),
            themeMode: themeData.themeMode == AppThemeMode.system
                ? ThemeMode.system
                : themeData.themeMode == AppThemeMode.light
                    ? ThemeMode.light
                    : ThemeMode.dark,
            debugShowCheckedModeBanner: false,
            home: const AppShell(),
          );
        },
      );
    }
  }
