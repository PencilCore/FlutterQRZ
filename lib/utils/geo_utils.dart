import 'dart:math' as math;

/// 业余无线电常用的地理 / 天文计算
///
/// 全部为纯计算，无需任何原生插件。
class GeoUtils {
  static const double _earthRadiusKm = 6371.0088;

  // ── Maidenhead 网格 ────────────────────────────────────────

  /// 经纬度 → Maidenhead 网格定位
  ///
  /// [precision] 4 = 字段+方格 (PM01)，6 = 加子方格 (PM01AA)，8 = 延伸方格
  static String latLonToGrid(double lat, double lon,
      {int precision = 6}) {
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return '';

    double lng = lon + 180.0;
    double la = lat + 90.0;
    final sb = StringBuffer();

    // 字段：20° 经 × 10° 纬，A-R
    int a = (lng / 20).floor();
    int b = (la / 10).floor();
    sb.writeCharCode(65 + a);
    sb.writeCharCode(65 + b);
    lng -= a * 20;
    la -= b * 10;

    // 方格：2° 经 × 1° 纬，0-9
    a = (lng / 2).floor();
    b = la.floor();
    sb.write(a);
    sb.write(b);
    lng -= a * 2;
    la -= b * 1;

    if (precision <= 4) return sb.toString();

    // 子方格：5′ 经 × 2.5′ 纬，a-x
    a = (lng * 12).floor();
    b = (la * 24).floor();
    sb.writeCharCode(97 + a);
    sb.writeCharCode(97 + b);
    lng -= a / 12;
    la -= b / 24;

    if (precision <= 6) return sb.toString().toUpperCase();

    // 延伸方格：0.5′ 经 × 0.25′ 纬，0-9
    a = (lng * 120).floor();
    b = (la * 240).floor();
    sb.write(a);
    sb.write(b);

    return sb.toString().toUpperCase();
  }

  /// Maidenhead 网格 → 经纬度（返回该网格中心点）
  static ({double lat, double lon})? gridToLatLon(String grid) {
    final g = grid.trim().toUpperCase();
    if (g.length < 4) return null;

    // 只接受合法字符
    if (g.codeUnitAt(0) < 65 || g.codeUnitAt(0) > 82) return null;
    if (g.codeUnitAt(1) < 65 || g.codeUnitAt(1) > 82) return null;
    final s1 = int.tryParse(g[2]);
    final s2 = int.tryParse(g[3]);
    if (s1 == null || s2 == null) return null;

    double lon = (g.codeUnitAt(0) - 65) * 20.0 - 180.0;
    double lat = (g.codeUnitAt(1) - 65) * 10.0 - 90.0;
    double cellLon = 20.0;
    double cellLat = 10.0;

    lon += s1 * 2.0;
    lat += s2 * 1.0;
    cellLon = 2.0;
    cellLat = 1.0;

    if (g.length >= 6) {
      final c1 = g.codeUnitAt(4);
      final c2 = g.codeUnitAt(5);
      if (c1 < 65 || c1 > 88 || c2 < 65 || c2 > 88) return null;
      lon += (c1 - 65) * (2.0 / 24.0);
      lat += (c2 - 65) * (1.0 / 24.0);
      cellLon = 2.0 / 24.0;
      cellLat = 1.0 / 24.0;
    }

    if (g.length >= 8) {
      final d1 = int.tryParse(g[6]);
      final d2 = int.tryParse(g[7]);
      if (d1 == null || d2 == null) return null;
      lon += d1 * (2.0 / 240.0);
      lat += d2 * (1.0 / 240.0);
      cellLon = 2.0 / 240.0;
      cellLat = 1.0 / 240.0;
    }

    // 返回中心
    return (lat: lat + cellLat / 2, lon: lon + cellLon / 2);
  }

  // ── 大圆距离 / 方位 ────────────────────────────────────────

  /// 两点大圆距离（公里）
  static double distanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final rLat1 = _rad(lat1);
    final rLat2 = _rad(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rLat1) *
            math.cos(rLat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// 从点 1 指向点 2 的初始方位角（度，0=正北，顺时针）
  static double bearingDeg(
      double lat1, double lon1, double lat2, double lon2) {
    final rLat1 = _rad(lat1);
    final rLat2 = _rad(lat2);
    final dLon = _rad(lon2 - lon1);

    final y = math.sin(dLon) * math.cos(rLat2);
    final x = math.cos(rLat1) * math.sin(rLat2) -
        math.sin(rLat1) * math.cos(rLat2) * math.cos(dLon);
    final deg = _deg(math.atan2(y, x));
    return (deg + 360) % 360;
  }

  /// 方位角 → 中文方位（16 方位）
  static String bearingToCompass(double bearing) {
    const names = [
      '北', '北北东', '东北', '东北东',
      '东', '东南东', '东南', '南南东',
      '南', '南南西', '西南', '西南西',
      '西', '西北西', '西北', '北北西',
    ];
    final idx = (((bearing + 11.25) % 360) / 22.5).floor() % 16;
    return names[idx];
  }

  /// 方位角 → 英文缩写
  static String bearingToCompassEn(double bearing) {
    const names = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final idx = (((bearing + 11.25) % 360) / 22.5).floor() % 16;
    return names[idx];
  }

  /// 长路径方位角（大圆反方向）
  static double longPathBearing(double bearing) => (bearing + 180) % 360;

  /// 地球另一侧（对跖点）距离
  static double antipodeDistanceKm() => math.pi * _earthRadiusKm;

  // ── 太阳 / 灰线 ────────────────────────────────────────────

  /// 日出 / 日落 / 民用晨昏蒙影时间（返回 UTC 小时数，字段为 null 表示极昼极夜）
  static SunTimes sunTimes(double lat, double lon, DateTime dateUtc) {
    final n = _dayOfYear(dateUtc).toDouble();
    final lngHour = lon / 15.0;

    // 日出使用近似时刻 t=6，日落 t=18
    final riseRaw = _sunEvent(n, lngHour, lat, 6.0, 90.833, true);
    final setRaw = _sunEvent(n, lngHour, lat, 18.0, 90.833, false);

    // 民用晨昏蒙影（灰线）：太阳在地平线下 6°
    final dawnRaw = _sunEvent(n, lngHour, lat, 5.0, 96.0, true);
    final duskRaw = _sunEvent(n, lngHour, lat, 19.0, 96.0, false);

    return SunTimes(
      sunriseUtc: riseRaw,
      sunsetUtc: setRaw,
      civilDawnUtc: dawnRaw,
      civilDuskUtc: duskRaw,
    );
  }

  static double? _sunEvent(double n, double lngHour, double lat, double t0,
      double zenith, bool rising) {
    final t = n + ((t0 - lngHour) / 24.0);
    final m = (0.9856 * t) - 3.289;

    var l = m +
        (1.916 * math.sin(_rad(m))) +
        (0.020 * math.sin(_rad(2 * m))) +
        282.634;
    l = (l + 360) % 360;

    var ra = _deg(math.atan(0.91764 * math.tan(_rad(l))));
    ra = (ra + 360) % 360;
    final lQuad = (l / 90).floor() * 90.0;
    final raQuad = (ra / 90).floor() * 90.0;
    ra = (ra + (lQuad - raQuad)) / 15.0;

    final sinDec = 0.39782 * math.sin(_rad(l));
    final cosDec = math.cos(math.asin(sinDec));

    final cosH = (math.cos(_rad(zenith)) - (sinDec * math.sin(_rad(lat)))) /
        (cosDec * math.cos(_rad(lat)));

    if (cosH > 1 || cosH < -1) return null; // 极昼 / 极夜

    var h = rising
        ? 360 - _deg(math.acos(cosH))
        : _deg(math.acos(cosH));
    h = h / 15.0;

    final localMeanTime = h + ra - (0.06571 * t) - 6.622;
    var ut = localMeanTime - lngHour;
    ut = (ut + 24) % 24;
    return ut;
  }

  /// UTC 小时数 → 指定时区偏移的小时数
  static double toOffsetHour(double utcHour, double gmtOffset) {
    return (utcHour + gmtOffset + 24) % 24;
  }

  /// 小时数 → HH:MM
  static String formatHour(double? hour) {
    if (hour == null) return '—';
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    final hh = (m == 60 ? h + 1 : h) % 24;
    final mm = m == 60 ? 0 : m;
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  /// Maidenhead 网格覆盖的粗略范围（用于展示）
  static String gridCenterText(String grid) {
    final c = gridToLatLon(grid);
    if (c == null) return '';
    return '${c.lat.toStringAsFixed(4)}, ${c.lon.toStringAsFixed(4)}';
  }

  // ── 波段建议 ───────────────────────────────────────────────

  /// 根据距离给出常用波段建议
  static List<String> suggestedBands(double distanceKm) {
    if (distanceKm < 30) {
      return ['160m', '80m', '2m', '70cm'];
    } else if (distanceKm < 300) {
      return ['80m', '40m', '2m'];
    } else if (distanceKm < 1500) {
      return ['40m', '30m', '20m'];
    } else if (distanceKm < 5000) {
      return ['20m', '17m', '15m'];
    } else if (distanceKm < 12000) {
      return ['15m', '12m', '10m'];
    }
    return ['10m', '6m'];
  }

  // ── 内部工具 ───────────────────────────────────────────────

  static double _rad(double d) => d * math.pi / 180.0;
  static double _deg(double r) => r * 180.0 / math.pi;

  static int _dayOfYear(DateTime date) {
    final start = DateTime.utc(date.year, 1, 1);
    final d = DateTime.utc(date.year, date.month, date.day);
    return d.difference(start).inDays + 1;
  }
}

/// 日出日落结果（UTC 小时数，null 表示极昼/极夜）
class SunTimes {
  final double? sunriseUtc;
  final double? sunsetUtc;
  final double? civilDawnUtc;
  final double? civilDuskUtc;

  const SunTimes({
    this.sunriseUtc,
    this.sunsetUtc,
    this.civilDawnUtc,
    this.civilDuskUtc,
  });

  bool get isPolarDay => sunriseUtc == null && sunsetUtc == null;
}
