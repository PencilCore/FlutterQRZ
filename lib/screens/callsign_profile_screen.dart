import 'package:flutter/material.dart';
import '../models/callsign_data.dart';

class CallsignProfileScreen extends StatelessWidget {
  final CallsignData data;
  final VoidCallback? onBack;

  const CallsignProfileScreen({
    super.key,
    required this.data,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                    tooltip: '返回搜索',
                  ),
                if (onBack != null) const SizedBox(width: 4),
                Text(
                  '个人主页',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // Profile header card
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: _buildProfileHeader(colorScheme, textTheme),
          ),

          const SizedBox(height: 20),

          // Info cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - personal info
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildInfoCard(
                        context,
                        title: '基本信息',
                        icon: Icons.person_outline,
                        children: [
                          if (data.class_.isNotEmpty)
                            _buildInfoRow('执照等级', data.class_),
                          if (data.born.isNotEmpty)
                            _buildInfoRow('出生年份', data.born),
                          if (data.grid.isNotEmpty)
                            _buildInfoRow('网格定位', data.grid),
                          if (data.land.isNotEmpty)
                            _buildInfoRow('所属地区', data.land),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        title: 'QSL 信息',
                        icon: Icons.mail_outline,
                        children: [
                          if (data.qslVia.isNotEmpty)
                            _buildInfoRow('QSL Via', data.qslVia),
                          if (data.eqsl.isNotEmpty)
                            _buildInfoRow('eQSL', data.eqsl),
                          if (data.mgr.isNotEmpty)
                            _buildInfoRow('Manager', data.mgr),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right column - address & location
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildInfoCard(
                        context,
                        title: '地址信息',
                        icon: Icons.location_on_outlined,
                        children: [
                          if (data.addr1.isNotEmpty)
                            _buildInfoRow('地址', data.addr1),
                          if (data.addr2.isNotEmpty)
                            _buildInfoRow('城市', data.addr2),
                          if (data.state.isNotEmpty)
                            _buildInfoRow('州/省', data.state),
                          if (data.zip.isNotEmpty)
                            _buildInfoRow('邮编', data.zip),
                          if (data.country.isNotEmpty)
                            _buildInfoRow('国家', data.country),
                          if (data.county.isNotEmpty)
                            _buildInfoRow('县/区', data.county),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        title: '坐标位置',
                        icon: Icons.map_outlined,
                        children: [
                          if (data.lat.isNotEmpty)
                            _buildInfoRow('纬度', data.lat),
                          if (data.lon.isNotEmpty)
                            _buildInfoRow('经度', data.lon),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Map placeholder
          if (data.lat.isNotEmpty && data.lon.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '地图位置',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 32,
                                color: colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${data.lat}, ${data.lon}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '坐标位置',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          children: [
            // Avatar with callsign
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  data.callsign.isNotEmpty
                      ? data.callsign.substring(
                          0,
                          data.callsign.length > 4
                              ? 4
                              : data.callsign.length,
                        )
                      : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 24),

            // Name and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Callsign badge + full name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.callsign,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (data.fullName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      data.fullName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Quick info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (data.country.isNotEmpty)
                        _buildChip(
                          icon: Icons.flag_outlined,
                          label: data.country,
                          colorScheme: colorScheme,
                        ),
                      if (data.state.isNotEmpty)
                        _buildChip(
                          icon: Icons.location_city_outlined,
                          label: data.state,
                          colorScheme: colorScheme,
                        ),
                      if (data.grid.isNotEmpty)
                        _buildChip(
                          icon: Icons.grid_on_outlined,
                          label: data.grid,
                          colorScheme: colorScheme,
                        ),
                      if (data.class_.isNotEmpty)
                        _buildChip(
                          icon: Icons.school_outlined,
                          label: data.class_,
                          colorScheme: colorScheme,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (children.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
