import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // Settings cards
          _buildSettingsSection(
            context,
            title: '外观',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.dark_mode_outlined,
                title: '深色模式',
                subtitle: '切换深色/浅色主题',
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    // Toggle theme
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            title: '数据',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.storage_outlined,
                title: '清除缓存',
                subtitle: '清除本地缓存数据',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Clear cache
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.download_outlined,
                title: '导出数据',
                subtitle: '导出通联日志和设置',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Export data
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            title: '关于',
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: '版本信息',
                subtitle: 'v1.0.0 (Flutter ${_getFlutterVersion()})',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'QRZ Shell',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(
                      Icons.radio,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    children: const [
                      Text(
                        'QRZ Shell 是 QRZ.com 的第三方客户端壳，'
                        '支持 Windows 和 Android 平台。',
                      ),
                    ],
                  );
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.help_outline,
                title: '帮助与反馈',
                subtitle: '获取帮助或提交反馈',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Open help
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFlutterVersion() {
    return '3.x';
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withOpacity(0.3),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
