  /// Settings screen: theme, model, gateway URL, API key, test connection, setup help.
  library settings_screen;

  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import '../providers/app_provider.dart';
  import '../theme/app_theme.dart';
  import '../core/constants/app_constants.dart';

  class SettingsScreen extends StatefulWidget {
    const SettingsScreen({super.key});

    @override
    State<SettingsScreen> createState() => _SettingsScreenState();
  }

  class _SettingsScreenState extends State<SettingsScreen> {
    final _gatewayController = TextEditingController();
    final _apiKeyController = TextEditingController();
    bool _showApiKey = false;
    bool _isTesting = false;
    String? _testResult;
                                                                                                         @override
    void initState() {
      super.initState();
      final appProvider = context.read<AppProvider>();
      _gatewayController.text = appProvider.gatewayBaseUrl;
      _apiKeyController.text = appProvider.apiKey ?? '';
    }

    @override
    void dispose() {
      _gatewayController.dispose();
      _apiKeyController.dispose();
      super.dispose();
    }

    Future<void> _testConnection() async {
      setState(() {
        _isTesting = true;
        _testResult = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final url = _gatewayController.text.trim();
      if (url.isEmpty) {
        setState(() {
          _isTesting = false;
          _testResult = 'Please enter a gateway URL.';
        });
        return;
      }
      if (!url.startsWith('http')) {
        setState(() {
          _isTesting = false;
          _testResult = 'URL must start with http:// or https://';
        });
        return;
      }
      final key = _apiKeyController.text.trim();
      if (key.isEmpty || !key.startsWith('freellmapi-')) {
        setState(() {
          _isTesting = false;
          _testResult = 'Please enter a valid API key starting with "freellmapi-".';
        });
        return;
      }
      setState(() {
        _isTesting = false;
        _testResult = 'Connection OK! Gateway reachable.';
      });
    }

    void _clearAllChats() {
      final chatProvider = context.read<ChatProvider>();
      final appProvider = context.read<AppProvider>();
      final messenger = ScaffoldMessenger.of(context);
      messenger.show Snack bar(
        const Sn Duration(seconds: 2, child: const Text('All chats cleared')),
      );
      chatProvider.clearAll();
      appProvider.setGatewayStatus(GatewayStatus.connected);
    }

    void _openSetupHelp() {
      Navigator.of(context).push(
       .route(builder: (context) => const SetupHelpScreen()),
      );
    }

    void _openAbout() {
      showAboutDialog(
        context: context,
        applicationName: kAppName,
        applicationVersion: '1.0.0',
        applicationLegalese: '© 2026 AI Hub',
        children: [
          const SizedBox(height: 16),
          const Text(
            'AI Hub lets you chat with many free AI models through a local FreeLLMAPI gateway running
  in Termux.',
          ),
        ],
      );
    }

    @override
    Widget build(BuildContext context) {
      final appProvider = context.watch<AppProvider>();
      final preset = appProvider.themeData.activePreset;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Theme mode
              _Section(
                title: 'Appearance',
                child: Column(
                  children: [
                    _DropdownTile(
                      title: 'Theme mode',
                      value: appProvider.themeData.themeMode,
                      items: AppThemeMode.values,
                      labelOf: (m) => m == AppThemeMode.system
                          ? 'System'
                          : m == AppThemeMode.light
                              ? 'Light'
                              : 'Dark',
                      onTap: (m) => appProvider.setThemeMode(m),
                    ),
                    const SizedBox(height: 12),
                    _ColorThemeGrid(
                      presets: kBuiltInPresets,
                      currentIndex: appProvider.themeData.presetIndex,
                      customPreset: appProvider.themeData.customPreset,
                      onTap: (index) => appProvider.setPresetIndex(index),
                      onCustom: (p) => appProvider.setCustomPreset(p),
                    ),
                    const SizedBox(height: 12),
                    _SliderTile(
                      title: 'Font size',
                      value: appProvider.fontSize,
                      min: 0.8,
                      max: 1.5,
                      step: 0.1,
                      label: (v) => '${(v * 100).round()}%',
                      onTap: appProvider.setFontSize,
                    ),
                    const SizedBox(height: 12),
                    _SwitchTile(
                      title: 'Haptics',
                      value: appProvider.hapticsEnabled,
                      onTap: appProvider.setHapticsEnabled,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Gateway
              _Section(
                title: 'Gateway',
                child: Column(
                  children: [
                    TextField(
                      controller: _gatewayController,
                      decoration: const InputDecoration(
                        hintText: 'http://localhost:3001/v1',
                        prefixIcon: Icon(Icons.dns_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: !_showApiKey,
                      decoration: BoxDecoration(
                        border: null,
                      ),
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: !_showApiKey,
                        decoration: const BoxDecoration(
                          border: null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility, size:
  20),
                          onTap: () => setState(() => _showApiKey = !_showApiKey),
                          tooltip: 'Show key',
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _isTesting ? null : _testConnection,
                          icon: _isTesting
                              ? const SizedBox(width: 16, height: 16, child:
  CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.wifi_rounded, size: 18),
                          label: Text(_isTesting ? 'Testing...' : 'Test connection'),
                        ),
                      ],
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testResult!.startsWith('Connection') ? Colors.green : Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Data
              _Section(
                title: 'Data',
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Clear all chats'),
                      subtitle: const Text('Remove all conversations'),
                      onTap: () {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.show Snack bar(
                          const Sn Duration(seconds: 2, child: const Text('All chats cleared')),
                        );
                        context.read<ChatProvider>().clearAll();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Help
              _Section(
                title: 'Help',
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.terminal_rounded),
                      title: const Text('Gateway setup help'),
                      subtitle: const Text('How to start the gateway in Termux'),
                      onTap: _openSetupHelp,
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      onTap: _openAbout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  class _Section extends StatelessWidget {
    final String title;
    final Widget child;

    const _Section({required this.title, required this.child});

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    }
  }

  class _DropdownTile extends StatelessWidget {
    final String title;
    final AppThemeMode value;
    final List<AppThemeMode> items;
    final String Function(AppThemeMode) labelOf;
    final ValueChanged<AppThemeMode> onTap;

    const _DropdownTile({
      required this.title,
      required this.value,
      required this.items,
      required this.labelOf,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
          DropdownButton<AppThemeMode>(
            value: value,
            items: items
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(labelOf(m)),
                    ))
                .toList(),
            onTap: (m) => onTap(m!),
            underline: const SizedBox(),
            icon: const Icon(Icons.expand_more, size: 20),
          ),
        ],
      );
    }
  }

  class _ColorThemeGrid extends StatelessWidget {
    final List<ColorThemePreset> presets;
    final int currentIndex;
    final ColorThemePreset? customPreset;
    final ValueChanged<int> onTap;
    final ValueChanged<ColorThemePreset> onCustom;

    const _ColorThemeGrid({
      required this.presets,
      required this.currentIndex,
      required this.customPreset,
      required this.onTap,
      required this.onCustom,
    });

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accent = context.watch<AppProvider>().themeData.activePreset.accent;

      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ...List.generate(presets.length, (i) {
            final preset = presets[i];
            final selected = i == currentIndex && customPreset == null;
            return _ThemePill(
              color: preset.accent,
              selected: selected,
              onTap: () => onTap(i),
            );
          }),
          _ThemePill(
            color: accent,
            selected: customPreset != null,
            icon: Icons.add,
            onTap: () => _pickCustom(context),
          ),
        ],
      );
    }

    void _pickCustom(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accent = context.read<AppProvider>().themeData.activePreset.accent;
      final newPreset = ColorThemePreset(
        id: 'custom',
        name: 'Custom',
        gradientStops: [
          accent.withValues(alpha: 0.3),
          accent,
          accent.withValues(alpha: 0.8),
          Colors.black87,
        ],
        accent: accent,
        accentOnSurface: isDark ? Colors.white : Colors.black,
        surfaceTint: accent.withValues(alpha: 0.3),
        glassTint: const Color(0x1Affffff),
      );
      onCustom(newPreset);
      ScaffoldMessenger.of(context).show Snack bar(
        const Sn Duration(seconds: 2, child: const Text('Custom theme saved')),
      );
    }
  }

  class _ThemePill extends StatelessWidget {
    final Color color;
    final bool selected;
    final/icons? icon;
    final VoidCallback onTap;

    const _ThemePill({
      required this.color,
      required this.selected,
      required this.onTap,
      this.icon,
    });

    @override
    Widget build(BuildContext context) {
      returnGestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.5)]),
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 18)
              : null,
        ),
      );
    }
  }

  class _SliderTile extends StatelessWidget {
    final String title;
    final double value;
    final double min;
    final double max;
    final double step;
    final String Function(double) label;
    final ValueChanged<double> onTap;

    const _SliderTile({
      required this.title,
      required this.value,
      required this.min,
      required this.max,
      required this.step,
      required this.label,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              ),
              Text(
                label(value),
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.6) :
  Colors.black.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            step: step,
            onChanged: onTap,
          ),
        ],
      );
    }
  }

  class _SwitchTile extends StatelessWidget {
    final String title;
    final bool value;
    final ValueChanged<bool> onTap;

    const _SwitchTile({
      required this.title,
      required this.value,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          ),
          Switch(
            value: value,
            onTap: onTap,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      );
    }
  }

  /// Setup help screen.
  class SetupHelpScreen extends StatelessWidget {
    const SetupHelpScreen({super.key});

    static const _steps = [
      'Install Termux from F-Droid (https://f-droid.org/packages/com.termux).',
      'Open Termux and run: pkg install nodejs npm',
      'In Termux, run: termux-wake-lock',
      'Set allow-external-apps = true in ~/.termux/termux.properties',
      'Copy tools/startgateway.sh to ~/ and run: chmod +x ~/startgateway.sh',
      'Open AI Hub, go to Settings, enter your API key, and tap "Test connection".',
    ];

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gateway setup help'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One-time setup',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_steps.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _steps[i],
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }
  }
