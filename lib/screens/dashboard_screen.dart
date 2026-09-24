import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final bool isLoggedIn;
  final String? currentUser;

  const DashboardScreen({
    super.key,
    this.isLoggedIn = false,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 700 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Text(
            isLoggedIn
                ? '欢迎, $currentUser'
                : '欢迎使用 QRZ Shell',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedIn
                ? '您已成功登录 QRZ.com，可以使用所有功能。'
                : '请先登录您的 QRZ.com 账户以使用完整功能。',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Quick actions grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                final int cols = w < 560 ? 1 : (w < 900 ? 2 : 3);
                final double ratio = w < 560 ? 3.4 : 2.2;
                return GridView.count(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: ratio,
                  children: [
                _buildFeatureCard(
                  context,
                  icon: Icons.search,
                  title: '呼号查询',
                  subtitle: '查询业余无线电呼号详细信息',
                  color: Colors.blue,
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.list_alt,
                  title: '通联日志',
                  subtitle: '管理您的通联记录',
                  color: Colors.green,
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.location_on,
                  title: '地图模式',
                  subtitle: '查看呼号地理位置',
                  color: Colors.orange,
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.bookmark,
                  title: '收藏夹',
                  subtitle: '管理收藏的呼号',
                  color: Colors.purple,
                ),
                  ],
                );
              },
            ),
          ),

          // Info bar at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QRZ Shell 是 QRZ.com 的第三方客户端壳，支持 Windows 和 Android 平台。',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to the corresponding feature
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
