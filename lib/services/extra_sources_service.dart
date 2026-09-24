import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../utils/geo_utils.dart';

/// ── 外部数据源聚合 ────────────────────────────────────────────
///
/// 全部为公开、免费、无需密钥的接口：
/// - hamdb.org   美国 FCC 执照数据
/// - radioid.net DMR 数字电台身份库
/// - PSK Reporter 信号接收报告
/// - POTA        国家公园通联计划
class ExtraSourcesService {
  static const Duration _timeout = Duration(seconds: 20);
  static const Map<String, String> _headers = {
    'User-Agent': 'QRZShell/1.1 (Flutter; amateur radio client)',
    'Accept': '*/*',
  };

  // ── 1. hamdb.org：美国 FCC 执照数据 ─────────────────────────

  /// 仅美系呼号（W/K/N/A 开头）有数据
  static bool isUsCallsign(String call) {
    final c = call.trim().toUpperCase();
    if (c.isEmpty) return false;
    final first = c[0];
    return first == 'W' ||
        first == 'K' ||
        first == 'N' ||
        first == 'A' ||
        RegExp(r'^[KWN][A-Z]?[0-9]').hasMatch(c);
  }

  Future<FccRecord?> lookupFcc(String callsign) async {
    if (!isUsCallsign(callsign)) return null;
    try {
      final uri = Uri.parse(
        'https://api.hamdb.org/v1/${callsign.trim().toUpperCase()}/json/QRZShell',
      );
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return null;

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final root = body['hamdb'] as Map<String, dynamic>?;
      final cs = root?['callsign'] as Map<String, dynamic>?;
      if (cs == null) return null;

      String v(String key) {
        final val = cs[key];
        if (val == null) return '';
        final s = val.toString();
        return s == 'NOT_FOUND' ? '' : s;
      }

      final record = FccRecord(
        call: v('call'),
        status: v('status'),
        licenseClass: v('class'),
        expires: v('expires'),
        grid: v('grid'),
        lat: v('lat'),
        lon: v('lon'),
        name: v('name'),
        fname: v('fname'),
        addr1: v('addr1'),
        addr2: v('addr2'),
        state: v('state'),
        zip: v('zip'),
        country: v('country'),
        trustee: v('trustee'),
      );
      return record.isEmpty ? null : record;
    } catch (_) {
      return null;
    }
  }

  // ── 2. radioid.net：DMR 身份 ───────────────────────────────

  Future<List<DmrRecord>> lookupDmr(String callsign) async {
    try {
      final uri = Uri.parse(
        'https://radioid.net/api/dmr/user/?callsign=${callsign.trim().toUpperCase()}',
      );
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return [];

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = body['results'] as List?;
      if (results == null) return [];

      return results.map((e) {
        final m = e as Map<String, dynamic>;
        String s(String k) => (m[k] ?? '').toString();
        return DmrRecord(
          id: s('id'),
          callsign: s('callsign'),
          fname: s('fname'),
          surname: s('surname'),
          city: s('city'),
          state: s('state'),
          country: s('country'),
        );
      }).where((r) => r.callsign.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 3. PSK Reporter：接收报告 ──────────────────────────────

  /// 查询最近 [hours] 小时内，接收过该呼号的报告
  Future<List<PskReport>> lookupPskReports(
    String callsign, {
    int hours = 24,
    int max = 30,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final start = now - hours * 3600;
      final uri = Uri.parse(
        'https://retrieve.pskreporter.info/query'
        '?senderCallsign=${callsign.trim().toUpperCase()}'
        '&flowStartSeconds=$start'
        '&noactive=1',
      );
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return [];

      final doc = xml.XmlDocument.parse(resp.body);
      final reports = <PskReport>[];
      for (final el in doc.findAllElements('receptionReport')) {
        String a(String name) => el.getAttribute(name) ?? '';
        reports.add(PskReport(
          receiverCallsign: a('receiverCallsign'),
          receiverLocator: a('receiverLocator'),
          receiverDXCC: a('receiverDXCC'),
          receiverRegion: a('receiverRegion'),
          frequencyHz: int.tryParse(a('frequency')) ?? 0,
          snr: int.tryParse(a('sNR')) ?? 0,
          mode: a('mode'),
          flowStartSeconds: int.tryParse(a('flowStartSeconds')) ?? 0,
        ));
      }
      reports.sort(
        (a, b) => b.flowStartSeconds.compareTo(a.flowStartSeconds),
      );
      return reports.take(max).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 4. POTA：附近国家公园 ──────────────────────────────────

  /// 呼号前缀 → ISO 国家代码（用于拉取该国公园列表）
  /// 按前缀长度优先匹配，避免冲突
  static const List<(String, String)> _prefixToCountry = [
    // 中国
    ('BY', 'CN'), ('BD', 'CN'), ('BG', 'CN'), ('BH', 'CN'), ('BI', 'CN'),
    ('BJ', 'CN'), ('BL', 'CN'), ('BM', 'CN'), ('BN', 'CN'), ('BO', 'CN'),
    ('BP', 'CN'), ('BQ', 'CN'), ('BR', 'CN'), ('BS', 'CN'), ('BT', 'CN'),
    ('BU', 'CN'), ('BV', 'CN'), ('BW', 'CN'), ('BX', 'CN'),
    // 日本
    ('JA', 'JP'), ('JE', 'JP'), ('JF', 'JP'), ('JG', 'JP'), ('JH', 'JP'),
    ('JI', 'JP'), ('JJ', 'JP'), ('JK', 'JP'), ('JL', 'JP'), ('JM', 'JP'),
    ('JN', 'JP'), ('JO', 'JP'), ('JP', 'JP'), ('JQ', 'JP'), ('JR', 'JP'),
    ('JS', 'JP'),
    // 德国
    ('DA', 'DE'), ('DB', 'DE'), ('DC', 'DE'), ('DD', 'DE'), ('DF', 'DE'),
    ('DG', 'DE'), ('DH', 'DE'), ('DJ', 'DE'), ('DK', 'DE'), ('DL', 'DE'),
    ('DM', 'DE'), ('DO', 'DE'), ('DP', 'DE'), ('DQ', 'DE'), ('DR', 'DE'),
    // 美国
    ('K', 'US'), ('W', 'US'), ('N', 'US'), ('A', 'US'),
    // 加拿大
    ('VA', 'CA'), ('VB', 'CA'), ('VC', 'CA'), ('VD', 'CA'), ('VE', 'CA'),
    ('VF', 'CA'), ('VG', 'CA'), ('VH', 'CA'), ('VI', 'CA'), ('VJ', 'CA'),
    ('VM', 'CA'), ('VN', 'CA'), ('VO', 'CA'), ('VX', 'CA'), ('VY', 'CA'),
    ('CY', 'CA'), ('CZ', 'CA'),
    // 澳大利亚
    ('VK', 'AU'), ('VL', 'AU'), ('VZ', 'AU'),
    // 英国
    ('G', 'GB'), ('M', 'GB'), ('VP', 'GB'), ('VQ', 'GB'), ('VS', 'GB'),
    ('2', 'GB'),
    // 印度
    ('VT', 'IN'), ('VU', 'IN'), ('VV', 'IN'), ('VW', 'IN'),
    // 其他常见
    ('F', 'FR'), ('I', 'IT'), ('E', 'ES'), ('R', 'RU'), ('U', 'RU'),
    ('S', 'SE'), ('O', 'FI'), ('L', 'PL'), ('H', 'HU'), ('P', 'NL'),
    ('T', 'TR'), ('Y', 'UA'), ('Z', 'UA'), ('C', 'CA'), ('D', 'DE'),
    ('J', 'JP'), ('B', 'CN'), ('V', 'CA'),
  ];

  static String? countryFromCallsign(String call) {
    final c = call.trim().toUpperCase();
    if (c.isEmpty) return null;
    String? best;
    var bestLen = 0;
    for (final entry in _prefixToCountry) {
      if (entry.$1.length > bestLen && c.startsWith(entry.$1)) {
        best = entry.$2;
        bestLen = entry.$1.length;
      }
    }
    return best;
  }

  Future<List<ParkRecord>> nearbyParks(
    String callsign,
    double lat,
    double lon, {
    int max = 8,
  }) async {
    final country = countryFromCallsign(callsign);
    if (country == null) return [];

    try {
      final uri = Uri.parse('https://api.pota.app/program/parks/$country');
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return [];

      final list = jsonDecode(resp.body) as List;
      final parks = <ParkRecord>[];
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final plat = (m['latitude'] as num?)?.toDouble();
        final plon = (m['longitude'] as num?)?.toDouble();
        if (plat == null || plon == null) continue;
        parks.add(ParkRecord(
          reference: (m['reference'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          grid: (m['grid'] ?? '').toString(),
          locationDesc: (m['locationDesc'] ?? '').toString(),
          latitude: plat,
          longitude: plon,
          distanceKm: GeoUtils.distanceKm(lat, lon, plat, plon),
        ));
      }
      parks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return parks.take(max).toList();
    } catch (_) {
      return [];
    }
  }
}

// ── 数据结构 ─────────────────────────────────────────────────

/// 美国 FCC 执照记录（来自 hamdb.org）
class FccRecord {
  final String call;
  final String status;
  final String licenseClass;
  final String expires;
  final String grid;
  final String lat;
  final String lon;
  final String name;
  final String fname;
  final String addr1;
  final String addr2;
  final String state;
  final String zip;
  final String country;
  final String trustee;

  const FccRecord({
    this.call = '',
    this.status = '',
    this.licenseClass = '',
    this.expires = '',
    this.grid = '',
    this.lat = '',
    this.lon = '',
    this.name = '',
    this.fname = '',
    this.addr1 = '',
    this.addr2 = '',
    this.state = '',
    this.zip = '',
    this.country = '',
    this.trustee = '',
  });

  bool get isEmpty =>
      call.isEmpty && licenseClass.isEmpty && expires.isEmpty && name.isEmpty;

  /// 执照状态码 → 中文
  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'A':
        return '有效（Active）';
      case 'E':
        return '已过期（Expired）';
      case 'C':
        return '已取消（Cancelled）';
      case 'T':
        return '已终止（Terminated）';
      case 'W':
        return '等待中（Pending）';
      default:
        return status;
    }
  }

  String get fullName {
    if (fname.isNotEmpty && name.isNotEmpty) return '$fname $name';
    return name.isNotEmpty ? name : fname;
  }
}

/// DMR 数字电台身份（来自 radioid.net）
class DmrRecord {
  final String id;
  final String callsign;
  final String fname;
  final String surname;
  final String city;
  final String state;
  final String country;

  const DmrRecord({
    this.id = '',
    this.callsign = '',
    this.fname = '',
    this.surname = '',
    this.city = '',
    this.state = '',
    this.country = '',
  });

  String get fullName =>
      [fname, surname].where((s) => s.isNotEmpty).join(' ');
}

/// 信号接收报告（来自 PSK Reporter）
class PskReport {
  final String receiverCallsign;
  final String receiverLocator;
  final String receiverDXCC;
  final String receiverRegion;
  final int frequencyHz;
  final int snr;
  final String mode;
  final int flowStartSeconds;

  const PskReport({
    this.receiverCallsign = '',
    this.receiverLocator = '',
    this.receiverDXCC = '',
    this.receiverRegion = '',
    this.frequencyHz = 0,
    this.snr = 0,
    this.mode = '',
    this.flowStartSeconds = 0,
  });

  /// 频率 → MHz，并推断波段
  String get frequencyMHz =>
      frequencyHz > 0 ? (frequencyHz / 1000000).toStringAsFixed(4) : '';

  String get band {
    final mhz = frequencyHz / 1000000;
    if (mhz >= 1.8 && mhz < 2) return '160m';
    if (mhz >= 3.5 && mhz < 4) return '80m';
    if (mhz >= 5 && mhz < 5.5) return '60m';
    if (mhz >= 7 && mhz < 7.3) return '40m';
    if (mhz >= 10.1 && mhz < 10.15) return '30m';
    if (mhz >= 14 && mhz < 14.35) return '20m';
    if (mhz >= 18 && mhz < 18.2) return '17m';
    if (mhz >= 21 && mhz < 21.45) return '15m';
    if (mhz >= 24.8 && mhz < 25) return '12m';
    if (mhz >= 28 && mhz < 29.7) return '10m';
    if (mhz >= 50 && mhz < 54) return '6m';
    if (mhz >= 144 && mhz < 148) return '2m';
    if (mhz >= 430 && mhz < 450) return '70cm';
    return '';
  }

  /// 时间差描述
  String get agoText {
    if (flowStartSeconds == 0) return '';
    final t = DateTime.fromMillisecondsSinceEpoch(flowStartSeconds * 1000);
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }
}

/// POTA 公园（来自 api.pota.app）
class ParkRecord {
  final String reference;
  final String name;
  final String grid;
  final String locationDesc;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const ParkRecord({
    this.reference = '',
    this.name = '',
    this.grid = '',
    this.locationDesc = '',
    this.latitude = 0,
    this.longitude = 0,
    this.distanceKm = 0,
  });

  String get distanceText => distanceKm < 1000
      ? '${distanceKm.round()} km'
      : '${(distanceKm / 1000).toStringAsFixed(1)} 千km';
}
