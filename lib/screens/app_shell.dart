 /// App shell: main scaffold with drawer, animated glass
  background, status pill.
  library app_shell;                                            
  import 'dart:async';                                            import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:intl/intl.dart';
  import '../providers/app_provider.dart';
  import '../providers/chat_provider.dart';
  import '../theme/app_theme.dart';
  import '../core/constants/app_constants.dart';
  import 'chat_screen.dart';
  import 'settings_screen.dart';

  /// Main app shell: contains drawer, background, status pill.
  class AppShell extends StatefulWidget {
    const AppShell({super.key});

    @override
    State<AppShell> createState() => _AppShellState();
  }

  class _AppShellState extends State<AppShell> {
    int _selectedIndex = 0;
    late Timer _healthTimer;
    bool _drawerOpen = false;

    @override
    void initState() {
      super.initState();
      _startGatewayCheck();
    }

    @override
    void dispose() {
      _healthTimer.cancel();
      super.dispose();
    }

    void _startGatewayCheck() {
      // Poll gateway health every 2 seconds.
      _healthTimer = Timer.periodic(kGatewayPollInterval, (_)
  async {
        final appProvider = context.read<AppProvider>();
        // Placeholder: real check implemented in Phase 8.
        // For now keep status unknown until Phase 8.
        if (appProvider.gatewayStatus == GatewayStatus.unknown)
  {
          appProvider.setGatewayStatus(GatewayStatus.connected);
        }
      });
    }

    void _toggleDrawer() {
      setState(() => _drawerOpen = !_drawerOpen);
    }

    void _openChatScreen() {
      setState(() => _selectedIndex = 0);
      Navigator.of(context).pop();
    }

    void _openSettingsScreen() {
      setState(() => _selectedIndex = 1);
      Navigator.of(context).pop();
    }

    Widget _buildDrawer(BuildContext context) {
      final appProvider = context.watch<AppProvider>();
      final isDark = Theme.of(context).brightness ==
  Brightness.dark;
      final preset = appProvider.themeData.activePreset;

      return Drawer(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          margin: const EdgeInsets.all(16),
          blur: 25,
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                kAppName,
                style: TextStyle(
                  color: preset.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Free AI Chat',
                style: TextStyle(
                  color: (isDark ? Colors.white :
  Colors.black).withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const Divider(height: 32),
              _DrawerItem(
                icon: Icons.chat_bubble_outline,
                title: 'Chats',
                selected: _selectedIndex == 0,
                onTap: _openChatScreen,
              ),
              _DrawerItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                selected: _selectedIndex == 1,
                onTap: _openSettingsScreen,
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.info_outline, size:
  20),
                title: const Text('Version 1.0.0'),
                contentPadding: const
  EdgeInsets.symmetric(horizontal: 16),
              ),
            ],
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      final appProvider = context.watch<AppProvider>();
      final preset = appProvider.themeData.activePreset;

      return Scaffold(
        body: Stack(
          children: [
            AnimatedGradientBackground(
              themeData: appProvider.themeData,
              child: SafeArea(
                child: _selectedIndex == 0 ? const ChatScreen()
  : const SettingsScreen(),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: StatusPill(
                text: appProvider.gatewayStatus.label,
                color: appProvider.gatewayStatus.color,
                icon: appProvider.gatewayStatus.icon,
              ),
            ),
          ],
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleDrawer,
          backgroundColor: preset.accent,
          foregroundColor: preset.accentOnSurface,
          child: const Icon(Icons.menu),
        ),
      );
    }
  }

  /// Drawer item widget.
  class _DrawerItem extends StatelessWidget {
    final IconData icon;
    final String title;
    final bool selected;
    final VoidCallback onTap;

    const _DrawerItem({
      required this.icon,
      required this.title,
      required this.selected,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      final preset =
  context.watch<AppProvider>().themeData.activePreset;
      final isDark = Theme.of(context).brightness ==
  Brightness.dark;

      return ListTile(
        leading: Icon(icon, color: selected ? preset.accent :
  null, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? preset.accent : (isDark ?
  Colors.white : Colors.black),
            fontWeight: selected ? FontWeight.w600 :
  FontWeight.normal,
          ),
        ),
        selected: selected,
        selectedTileColor: preset.accent.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius:
  BorderRadius.circular(12)),
        onTap: onTap,
      );
    }
  }
