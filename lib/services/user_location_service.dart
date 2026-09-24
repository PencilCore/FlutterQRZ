import 'package:shared_preferences/shared_preferences.dart';
import '../utils/geo_utils.dart';

/// 保存用户自己的位置，用于计算与目标呼号的距离 / 方位
class UserLocationService {
  static const String _keyLat = 'my_lat';
  static const String _keyLon = 'my_lon';
  static const String _keyGrid = 'my_grid';
  static const String _keyRaw = 'my_location_raw';

  /// 读取已保存的位置；未设置时返回 null
  Future<({double lat, double lon, String grid})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLat);
    final lon = prefs.getDouble(_keyLon);
    if (lat == null || lon == null) return null;
    return (lat: lat, lon: lon, grid: prefs.getString(_keyGrid) ?? '');
  }

  /// 已保存的原始输入文本
  Future<String> loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRaw) ?? '';
  }

  /// 保存位置（纬经度 + 由之推算的网格）
  Future<void> save(double lat, double lon, String raw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, lat);
    await prefs.setDouble(_keyLon, lon);
    await prefs.setString(_keyGrid, GeoUtils.latLonToGrid(lat, lon));
    await prefs.setString(_keyRaw, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLat);
    await prefs.remove(_keyLon);
    await prefs.remove(_keyGrid);
    await prefs.remove(_keyRaw);
  }

  /// 解析用户输入，支持三种格式：
  /// - Maidenhead 网格：`PM01AA`、`PM01`
  /// - 十进制度：`31.2304, 121.4737` 或 `31.2304 121.4737`
  /// - 带方向后缀：`31.2304N 121.4737E`
  ///
  /// 返回 null 表示无法解析。
  static ({double lat, double lon})? parseInput(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    // 1) 网格定位
    if (RegExp(r'^[A-Ra-r]{2}[0-9]{2}([A-Xa-x]{2})?([0-9]{2})?$')
        .hasMatch(text)) {
      final c = GeoUtils.gridToLatLon(text);
      if (c != null) return (lat: c.lat, lon: c.lon);
    }

    // 2) 经纬度：允许 N/S/E/W 后缀，逗号或空格分隔
    final normalized = text
        .toUpperCase()
        .replaceAll('，', ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final parts = normalized.contains(',')
        ? normalized.split(',').map((s) => s.trim()).toList()
        : normalized.split(' ').where((s) => s.isNotEmpty).toList();

    if (parts.length < 2) return null;

    double? parseCoord(String s, {required bool isLat}) {
      s = s.trim();
      double sign = 1;
      if (s.endsWith('S') || s.endsWith('W')) {
        sign = -1;
        s = s.substring(0, s.length - 1);
      } else if (s.endsWith('N') || s.endsWith('E')) {
        s = s.substring(0, s.length - 1);
      }
      final v = double.tryParse(s.trim());
      if (v == null) return null;
      final limit = isLat ? 90.0 : 180.0;
      if (v.abs() > limit) return null;
      return v * sign;
    }

    final lat = parseCoord(parts[0], isLat: true);
    final lon = parseCoord(parts[1], isLat: false);
    if (lat == null || lon == null) return null;
    return (lat: lat, lon: lon);
  }

  /// 生成说明文本
  static String describeInput(String raw) {
    final parsed = parseInput(raw);
    if (parsed == null) return '无法识别';
    final grid = GeoUtils.latLonToGrid(parsed.lat, parsed.lon);
    return '${parsed.lat.toStringAsFixed(4)}, ${parsed.lon.toStringAsFixed(4)}'
        ' · 网格 $grid';
  }
}
