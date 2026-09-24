import 'package:flutter/material.dart';
import 'services/qrz_service.dart';
import 'services/credential_storage.dart';
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
  final CredentialStorage _credentialStorage = CredentialStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SidebarItem _selectedItem = SidebarItem.dashboard;
  bool _isLoggedIn = false;
  String _currentUser = '';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  /// 启动时尝试自动登录（使用保存的凭据）
  Future<void> _tryAutoLogin() async {
    try {
      final wasLoggedIn = await _credentialStorage.wasLoggedIn();
      if (wasLoggedIn) {
        final username = await _credentialStorage.getUsername();
        final password = await _credentialStorage.getPassword();
        if (username != null && password != null && password.isNotEmpty) {
          final result = await _qrzService.login(username, password);
          if (result['success'] == true && mounted) {
            setState(() {
              _isLoggedIn = true;
              _currentUser = username;
            });
          }
        }
      }
    } catch (e) {
      // Auto-login failed silently, user can login manually
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

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
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radio, size: 64, color: Color(0xFF1565C0)),
              SizedBox(height: 24),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在连接 QRZ.com...'),
            ],
          ),
        ),
      );
    }

    final bool isNarrow = MediaQuery.of(context).size.width < 700;
    final Widget sidebar = AppSidebar(
      selectedItem: _selectedItem,
      onItemSelected: (item) {
        setState(() {
          _selectedItem = item;
        });
        if (isNarrow) {
          _scaffoldKey.currentState?.closeDrawer();
        }
      },
      isLoggedIn: _isLoggedIn,
      currentUser: _currentUser.isNotEmpty ? _currentUser : null,
    );

    if (isNarrow) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('QRZ Shell'),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: '菜单',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          width: 240,
          child: sidebar,
        ),
        body: _buildCurrentScreen(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          sidebar,
          Expanded(
            child: _buildCurrentScreen(),
          ),
        ],
      ),
    );
  }
}
