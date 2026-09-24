import 'package:flutter/material.dart';
import '../services/search_history_service.dart';
import '../services/user_location_service.dart';
import '../utils/geo_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _locService = UserLocationService();
  final _historyService = SearchHistoryService();

  String _myLocationText = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = await _locService.load();
    final raw = await _locService.loadRaw();
    if (!mounted) return;
    setState(() {
      _myLocationText = loc == null
          ? ''
          : (raw.isNotEmpty
              ? raw
              : '${loc.lat.toStringAsFixed(4)}, ${loc.lon.toStringAsFixed(4)}');
      _loading = false;
    });
  }

  Future<void> _editMyLocation() async {
    final controller = TextEditingController(text: _myLocationText);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('我的位置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '用于计算与目标呼号的距离和方位角。',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text(
              '· Maidenhead 网格：PM01AA\n'
              '· 经纬度：31.2304, 121.4737\n'
              '· 带方向：31.2304N 121.4737E',
              style: TextStyle(fontSize: 12.5, height: 1.6),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '位置',
                hintText: '例如 PM01AA 或 31.23, 121.47',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (_myLocationText.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('__clear__'),
              child: const Text('清除'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == '__clear__') {
      await _locService.clear();
      if (!mounted) return;
      setState(() => _myLocationText = '');
      _snack('已清除我的位置');
      return;
    }

    final parsed = UserLocationService.parseInput(result);
    if (parsed == null) {
      _snack('格式无法识别，请输入网格（PM01AA）或经纬度（31.23, 121.47）');
      return;
    }

    await _locService.save(parsed.lat, parsed.lon, result);
    await _loadLocation();
    if (!mounted) return;
    _snack('已保存：${GeoUtils.latLonToGrid(parsed.lat, parsed.lon)}');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    if (!mounted) return;
    _snack('已清除搜索历史');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isNarrow ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置',
            style: TextStyle(
              fontSize: isNarrow ? 22 : 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),

          _buildSection(
            title: '我的位置',
            children: [
              _buildTile(
                icon: Icons.my_location,
                title: '坐标 / 网格',
                subtitle: _loading
                    ? '读取中…'
                    : (_myLocationText.isEmpty
                        ? '未设置 · 点击设置后可计算距离和方位'
                        : _myLocationText),
                onTap: _editMyLocation,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: '数据',
            children: [
              _buildTile(
                icon: Icons.history,
                title: '清除搜索历史',
                subtitle: '删除本地保存的呼号查询记录',
                onTap: _clearHistory,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            title: '关于',
            children: [
              _buildTile(
                icon: Icons.info_outline,
                title: '版本信息',
                subtitle: 'v1.1.0 · 第三方 QRZ.com 客户端',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'QRZ Shell',
                  applicationVersion: '1.1.0',
                  applicationIcon: Icon(
                    Icons.radio,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  children: const [
                    Text(
                      'QRZ Shell 是 QRZ.com 的第三方客户端，'
                      '数据来自 QRZ.com XML API。\n\n'
                      '呼号资料版权归 QRZ.com 及其贡献者所有。',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, size: 21),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.55),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
