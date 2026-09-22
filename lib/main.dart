import 'package:flutter/material.dart';
import 'services/qrz_service.dart';
import 'widgets/sidebar.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/callsign_lookup_screen.dart';
import 'screens/qr_log_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRZ Shell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final QrzService _qrzService = QrzService();
  SidebarItem _selectedItem = SidebarItem.dashboard;
  bool _isLoggedIn = false;
  String _currentUser = '';

  Widget _buildCurrentScreen() {
    switch (_selectedItem) {
      case SidebarItem.dashboard:
        return DashboardScreen(
          isLoggedIn: _isLoggedIn,
          currentUser: _currentUser.isNotEmpty ? _currentUser : null,
        );
      case SidebarItem.login:
        return LoginScreen(
          qrzService: _qrzService,
          onLoginChanged: (loggedIn, username) {
            setState(() {
              _isLoggedIn = loggedIn;
              _currentUser = username;
            });
          },
        );
      case SidebarItem.callsignLookup:
        return CallsignLookupScreen(qrzService: _qrzService);
      case SidebarItem.qrLog:
        return const QrLogScreen();
      case SidebarItem.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedItem: _selectedItem,
            onItemSelected: (item) {
              setState(() {
                _selectedItem = item;
              });
            },
            isLoggedIn: _isLoggedIn,
            currentUser: _currentUser.isNotEmpty ? _currentUser : null,
          ),
          Expanded(
            child: _buildCurrentScreen(),
          ),
        ],
      ),
    );
  }
}

