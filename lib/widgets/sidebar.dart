import 'package:flutter/material.dart';

enum SidebarItem {
  dashboard,
  login,
  callsignLookup,
  qrLog,
  settings,
}

class AppSidebar extends StatelessWidget {
  final SidebarItem selectedItem;
  final Function(SidebarItem) onItemSelected;
  final bool isLoggedIn;
  final String? currentUser;

  const AppSidebar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
    this.isLoggedIn = false,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo / App title
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.radio,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'QRZ Shell',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 8),

          // User info card if logged in
          if (isLoggedIn && currentUser != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      currentUser![0].toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '已登录',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNavItem(
                  context,
                  item: SidebarItem.dashboard,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: '仪表盘',
                ),
                _buildNavItem(
                  context,
                  item: SidebarItem.callsignLookup,
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  label: '呼号查询',
                ),
                _buildNavItem(
                  context,
                  item: SidebarItem.qrLog,
                  icon: Icons.list_alt_outlined,
                  activeIcon: Icons.list_alt,
                  label: '通联日志',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '账户',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildNavItem(
                  context,
                  item: SidebarItem.login,
                  icon: isLoggedIn
                      ? Icons.logout_outlined
                      : Icons.login_outlined,
                  activeIcon:
                      isLoggedIn ? Icons.logout : Icons.login,
                  label: isLoggedIn ? '退出登录' : '登录',
                ),
                _buildNavItem(
                  context,
                  item: SidebarItem.settings,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: '设置',
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required SidebarItem item,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedItem == item;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onItemSelected(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                if (item == SidebarItem.login && isLoggedIn)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
