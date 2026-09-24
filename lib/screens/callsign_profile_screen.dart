import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/callsign_data.dart';
import '../services/extra_sources_service.dart';
import '../services/user_location_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/geo_widgets.dart';

/// 呼号完整资料页
///
/// 包含：地图预览、距离/方位、时间与灰线、网格互转、
/// QRZ 全部字段分区展示、原始数据表。
class CallsignProfileScreen extends StatefulWidget {
  final CallsignData data;

  const CallsignProfileScreen({super.key, required this.data});

  @override
  State<CallsignProfileScreen> createState() => _CallsignProfileScreenState();
}

class _CallsignProfileScreenState extends State<CallsignProfileScreen> {
  final _locService = UserLocationService();
  final _extra = ExtraSourcesService();
  ({double lat, double lon, String grid})? _myLoc;
  bool _loadingLoc = true;

  // 外部数据源
  FccRecord? _fcc;
  List<DmrRecord> _dmr = [];
  List<PskReport>? _psk;
  List<ParkRecord>? _parks;
  bool _loadingExtras = true;
  bool _loadingPsk = false;
  bool _loadingParks = false;

  CallsignData get data => widget.data;

  @override
  void initState() {
    super.initState();
    _loadMyLocation();
    _loadBasicExtras();
  }

  /// 加载体积小的数据源：FCC 执照、DMR 身份
  Future<void> _loadBasicExtras() async {
    final call = data.call;
    if (call.isEmpty) {
      if (mounted) setState(() => _loadingExtras = false);
      return;
    }

    final results = await Future.wait([
      _extra.lookupFcc(call),
      _extra.lookupDmr(call),
    ]);

    if (!mounted) return;
    setState(() {
      _fcc = results[0] as FccRecord?;
      _dmr = results[1] as List<DmrRecord>;
      _loadingExtras = false;
    });
  }

  /// PSK Reporter：谁最近听到过这个呼号（按需加载，响应较大）
  Future<void> _loadPskReports() async {
    if (_loadingPsk) return;
    setState(() => _loadingPsk = true);
    final reports = await _extra.lookupPskReports(data.call);
    if (!mounted) return;
    setState(() {
      _psk = reports;
      _loadingPsk = false;
    });
  }

  /// POTA：目标呼号所在国离他最近的公园（按需加载）
  Future<void> _loadNearbyParks() async {
    if (_loadingParks || !_hasTarget) return;
    setState(() => _loadingParks = true);
    final parks = await _extra.nearbyParks(
      data.call,
      _targetLat!,
      _targetLon!,
    );
    if (!mounted) return;
    setState(() {
      _parks = parks;
      _loadingParks = false;
    });
  }

  Future<void> _loadMyLocation() async {
    final loc = await _locService.load();
    if (mounted) {
      setState(() {
        _myLoc = loc;
        _loadingLoc = false;
      });
    }
  }

  // ── 派生数据 ───────────────────────────────────────────────

  double? get _targetLat => double.tryParse(data.lat);
  double? get _targetLon => double.tryParse(data.lon);
  bool get _hasTarget =>
      _targetLat != null &&
      _targetLon != null &&
      _targetLat!.abs() <= 90 &&
      _targetLon!.abs() <= 180;

  double? get _distanceKm {
    if (!_hasTarget || _myLoc == null) return null;
    return GeoUtils.distanceKm(
        _myLoc!.lat, _myLoc!.lon, _targetLat!, _targetLon!);
  }

  double? get _bearing {
    if (!_hasTarget || _myLoc == null) return null;
    return GeoUtils.bearingDeg(
        _myLoc!.lat, _myLoc!.lon, _targetLat!, _targetLon!);
  }

  /// 目标呼号的当地时间（用 QRZ 返回的 GMT 偏移）
  double? get _gmtOffset {
    final off = double.tryParse(data.gmtOffset);
    return off;
  }

  String get _targetLocalTime {
    final off = _gmtOffset;
    if (off == null) return '';
    final now = DateTime.now().toUtc().add(Duration(minutes: (off * 60).round()));
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(data.call),
        actions: [
          IconButton(
            tooltip: '复制全部资料',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copyAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isNarrow ? 14 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme, isNarrow),
            const SizedBox(height: 12),
            _buildQuickActions(colorScheme),

            // 地图
            if (_hasTarget) ...[
              const SizedBox(height: 14),
              _buildMapCard(colorScheme),
            ],

            // 距离与方位
            if (_hasTarget) ...[
              const SizedBox(height: 14),
              _buildDistanceCard(colorScheme, isNarrow),
            ],

            // 时间与太阳
            if (_hasTarget) ...[
              const SizedBox(height: 14),
              _buildSunCard(colorScheme),
            ],

            // 网格
            if (_hasTarget || data.grid.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildGridCard(colorScheme),
            ],

            const SizedBox(height: 4),

            _buildSection(colorScheme, '基本信息', Icons.badge_outlined, [
              ('呼号', data.call),
              ('姓名', data.displayName),
              ('名', data.fname),
              ('姓', data.name),
              ('昵称', data.nickname),
              ('曾用呼号', data.aliases),
              ('原呼号', data.pCall),
              ('出生年份', data.born),
              ('QRZ 用户名', data.user),
              ('监护人呼号', data.trustee),
              ('数据库序列号', data.serial),
              ('本次查询呼号', data.xref),
            ]),

            _buildSection(colorScheme, '执照信息', Icons.assignment_ind_outlined, [
              ('执照等级', data.class_),
              ('生效日期', data.efdate),
              ('到期日期', data.expdate),
              ('执照代码', data.codes),
            ]),

            if (data.isSilentKey || data.sk.isNotEmpty)
              _buildSection(colorScheme, '状态', Icons.info_outline, [
                if (data.isSilentKey) ('Silent Key', '是（执照持有人已故）'),
                if (data.sk.isNotEmpty && !data.isSilentKey) ('SK 标记', data.sk),
              ]),

            _buildSection(colorScheme, '地址信息', Icons.location_on_outlined, [
              ('收件人', data.attn),
              ('地址 1', data.addr1),
              ('地址 2', data.addr2),
              ('县 / 区', data.county),
              ('州 / 省', data.state),
              ('邮编', data.zip),
              ('国家', data.country),
              ('FIPS 代码', data.fips),
              ('都市服务区', data.msa),
              ('电话区号', data.areaCode),
            ]),

            _buildSection(colorScheme, 'DXCC / 分区', Icons.public_outlined, [
              ('DXCC 实体编号', data.dxcc),
              ('邮寄国 DXCC 码', data.ccode),
              ('所属地区', data.land),
              ('CQ 区', data.cqZone),
              ('ITU 区', data.ituZone),
            ]),

            _buildSection(colorScheme, '坐标位置', Icons.map_outlined, [
              ('纬度', data.lat),
              ('经度', data.lon),
              ('网格定位', data.grid),
              ('位置来源', _geolocLabel(data.geoloc)),
              ('时区', data.timeZone),
              ('GMT 偏移', data.gmtOffset.isEmpty ? '' : '${data.gmtOffset} 小时'),
              ('当前当地时间', _targetLocalTime),
              ('夏令时', data.dstText),
            ]),

            _buildSection(colorScheme, 'QSL 信息', Icons.mail_outline, [
              ('QSL Via', data.qslvia),
              ('QSL 管理员', data.qslmgr),
              ('纸质 QSL', data.mqslText),
              ('eQSL', data.eqslText),
              ('LotW', data.lotwText),
              ('IOTA 编号', data.iota),
            ]),

            _buildSection(colorScheme, 'QRZ 记录', Icons.insights_outlined, [
              ('页面浏览数', data.uViews.isEmpty
                  ? ''
                  : '${data.lookupsText} 次'),
              ('记录最后修改', data.modifydate),
              ('简介更新日期', data.biodate),
              ('简介长度', data.bioSizeText),
            ]),

            _buildSection(colorScheme, '联系方式', Icons.alternate_email, [
              ('电子邮箱', data.email),
              ('个人主页', data.url),
            ]),

            if (data.image.isNotEmpty || data.imageinfo.isNotEmpty)
              _buildSection(colorScheme, '照片信息', Icons.image_outlined, [
                ('图片尺寸', data.imageInfoText),
                ('图片地址', data.image),
              ]),

            if (data.bio.isNotEmpty) _buildBio(colorScheme),

            // ── 外部数据源 ──
            if (_loadingExtras)
              _card(
                colorScheme,
                title: '外部数据源',
                icon: Icons.cloud_download_outlined,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('正在查询 FCC 执照与 DMR 身份…',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            if (_fcc != null) _buildFccCard(colorScheme),
            if (_dmr.isNotEmpty) _buildDmrCard(colorScheme),
            _buildPskCard(colorScheme),
            if (_hasTarget) _buildParksCard(colorScheme),

            // 原始数据：QRZ 返回的全部字段
            if (data.raw.isNotEmpty) _buildRawData(colorScheme),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── 顶部资料卡 ─────────────────────────────────────────────

  Widget _buildHeader(ColorScheme colorScheme, bool isNarrow) {
    final avatarSize = isNarrow ? 84.0 : 104.0;

    final avatar = data.hasPhoto
        ? GestureDetector(
            onTap: () => _showPhotoDialog(),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    data.image,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildInitials(colorScheme, avatarSize),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.zoom_in,
                        size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        : _buildInitials(colorScheme, avatarSize);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              data.call,
              style: TextStyle(
                fontSize: isNarrow ? 26 : 30,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            if (data.isSilentKey) _tag('SK 已故', Colors.grey),
            if (data.class_.isNotEmpty) _tag(data.class_, Colors.purple),
            ...data.qslMethods.map((m) => _tag(m, Colors.teal)),
          ],
        ),
        if (data.displayName.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(data.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        ],
        if (data.nickname.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('（${data.nickname}）',
              style: TextStyle(
                  fontSize: 13, color: colorScheme.onSurface.withOpacity(0.6))),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (data.location.isNotEmpty)
              _iconText(Icons.place_outlined, data.location, colorScheme),
            if (data.grid.isNotEmpty)
              _iconText(Icons.grid_on_outlined, '网格 ${data.grid}', colorScheme),
            if (data.born.isNotEmpty)
              _iconText(Icons.cake_outlined, '${data.born} 年生', colorScheme),
            if (data.uViews.isNotEmpty)
              _iconText(Icons.visibility_outlined,
                  'Lookups ${data.lookupsText}', colorScheme),
          ],
        ),
      ],
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isNarrow ? 16 : 22),
        child: isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [avatar, const SizedBox(height: 14), info],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 20),
                  Expanded(child: info),
                ],
              ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
              fontSize: 13.5, color: colorScheme.onSurface.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildInitials(ColorScheme colorScheme, double size) {
    final text = data.call.isNotEmpty
        ? data.call.substring(0, data.call.length > 4 ? 4 : data.call.length)
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _showPhotoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.network(
                data.image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('图片加载失败'),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.imageinfo.isNotEmpty
                          ? data.imageinfo
                          : '${data.call} 的照片',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 快捷操作 ───────────────────────────────────────────────

  Widget _buildQuickActions(ColorScheme colorScheme) {
    final actions = <Widget>[];

    if (data.mapUrl != null) {
      actions.add(_actionButton(Icons.map, '地图', () => _launch(data.mapUrl!)));
    }
    if (data.url.isNotEmpty) {
      actions.add(_actionButton(
          Icons.language, '主页', () => _launch(_normalizeUrl(data.url))));
    }
    if (data.call.isNotEmpty) {
      actions.add(_actionButton(Icons.open_in_new, 'QRZ 页面',
          () => _launch('https://www.qrz.com/db/${data.call}')));
    }
    if (data.email.isNotEmpty) {
      actions.add(
          _actionButton(Icons.email_outlined, '发邮件', () => _launch('mailto:${data.email}')));
    }
    actions.add(_actionButton(Icons.copy_all_outlined, '复制全部', _copyAll));
    actions.add(_actionButton(
        Icons.share_outlined, '分享文本', _shareAsText));

    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: data.toPlainText()));
    if (!mounted) return;
    _snack('已复制全部资料');
  }

  Future<void> _shareAsText() async {
    await Clipboard.setData(
      ClipboardData(text: '${data.call}\n${data.toPlainText()}'),
    );
    if (!mounted) return;
    _snack('已复制到剪贴板，可粘贴分享');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      ),
    );
  }

  Future<void> _launch(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack('无法打开链接');
    } catch (_) {
      if (mounted) _snack('无法打开链接');
    }
  }

  String _normalizeUrl(String url) =>
      url.startsWith('http') ? url : 'https://$url';

  // ── 地图卡片 ───────────────────────────────────────────────

  Widget _buildMapCard(ColorScheme colorScheme) {
    return _card(
      colorScheme,
      title: '位置地图',
      icon: Icons.public,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaticMapPreview(
            lat: _targetLat!,
            lon: _targetLon!,
            onTap: () => _launch(data.mapUrl!),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${data.coordinateText}   网格 ${data.grid}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _launch(data.mapUrl!),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('打开地图', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 距离与方位 ─────────────────────────────────────────────

  Widget _buildDistanceCard(ColorScheme colorScheme, bool isNarrow) {
    if (_loadingLoc) {
      return _card(
        colorScheme,
        title: '距离与方位',
        icon: Icons.explore_outlined,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_myLoc == null) {
      return _card(
        colorScheme,
        title: '距离与方位',
        icon: Icons.explore_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置你自己的位置后，即可计算与该呼号的大圆距离、方位角和推荐波段。',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _promptMyLocation,
              icon: const Icon(Icons.my_location, size: 17),
              label: const Text('设置我的位置'),
            ),
          ],
        ),
      );
    }

    final dist = _distanceKm!;
    final brg = _bearing!;
    final lp = GeoUtils.longPathBearing(brg);
    final bands = GeoUtils.suggestedBands(dist);

    final compass = BearingCompass(
      bearing: brg,
      bearingLabel: GeoUtils.bearingToCompass(brg),
      distanceKm: dist,
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kvRow(colorScheme, '大圆距离',
            dist < 1000 ? '${dist.toStringAsFixed(1)} km' : '${(dist / 1000).toStringAsFixed(2)} 千km'),
        _kvRow(colorScheme, '英里', '${(dist * 0.621371).toStringAsFixed(1)} mi'),
        _kvRow(colorScheme, '短路径方位',
            '${brg.round()}° ${GeoUtils.bearingToCompassEn(brg)}（${GeoUtils.bearingToCompass(brg)}）'),
        _kvRow(colorScheme, '长路径方位',
            '${lp.round()}° ${GeoUtils.bearingToCompassEn(lp)}（${GeoUtils.bearingToCompass(lp)}）'),
        _kvRow(colorScheme, '推荐波段', bands.join(' · ')),
        _kvRow(colorScheme, '我的位置',
            '${_myLoc!.lat.toStringAsFixed(3)}, ${_myLoc!.lon.toStringAsFixed(3)}'),
      ],
    );

    return _card(
      colorScheme,
      title: '距离与方位',
      icon: Icons.explore_outlined,
      trailing: TextButton(
        onPressed: _promptMyLocation,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: const Text('修改位置', style: TextStyle(fontSize: 12)),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: compass),
                const SizedBox(height: 14),
                details,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                compass,
                const SizedBox(width: 18),
                Expanded(child: details),
              ],
            ),
    );
  }

  // ── 太阳 / 灰线 ────────────────────────────────────────────

  Widget _buildSunCard(ColorScheme colorScheme) {
    final off = _gmtOffset;
    final now = DateTime.now().toUtc();
    final t = GeoUtils.sunTimes(_targetLat!, _targetLon!, now);
    final tzName = data.timeZone.isNotEmpty
        ? data.timeZone
        : 'UTC${off == null ? '' : (off >= 0 ? '+' : '')}${off ?? ''}';

    double? toLocal(double? utc) =>
        utc == null ? null : GeoUtils.toOffsetHour(utc, off ?? 0);

    final rows = <(String, String)>[
      if (off != null) ('当地时间', '$_targetLocalTime（$tzName）'),
      ('当前 UTC', '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'),
      if (!t.isPolarDay) ...[
        ('日出', GeoUtils.formatHour(toLocal(t.sunriseUtc))),
        ('日落', GeoUtils.formatHour(toLocal(t.sunsetUtc))),
        ('灰线（晨）', GeoUtils.formatHour(toLocal(t.civilDawnUtc))),
        ('灰线（昏）', GeoUtils.formatHour(toLocal(t.civilDuskUtc))),
      ] else
        ('日照情况', '当前日期为极昼 / 极夜'),
    ];

    return _card(
      colorScheme,
      title: '时间与灰线',
      icon: Icons.wb_twilight,
      child: Column(
        children: [
          ...rows.map((r) => _kvRow(colorScheme, r.$1, r.$2)),
          const SizedBox(height: 4),
          Text(
            '时间为该呼号所在地当地时间（灰线 = 太阳位于地平线下 6°）',
            style: TextStyle(
              fontSize: 11.5,
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── 网格信息 ───────────────────────────────────────────────

  Widget _buildGridCard(ColorScheme colorScheme) {
    final grid = data.grid.isNotEmpty
        ? data.grid
        : (_hasTarget ? GeoUtils.latLonToGrid(_targetLat!, _targetLon!) : '');

    final center = grid.isEmpty ? null : GeoUtils.gridToLatLon(grid);

    final rows = <(String, String)>[
      ('Maidenhead', grid),
      if (center != null)
        ('网格中心', '${center.lat.toStringAsFixed(4)}, ${center.lon.toStringAsFixed(4)}'),
      ('字段（大区）', grid.length >= 2 ? grid.substring(0, 2) : ''),
      ('方格', grid.length >= 4 ? grid.substring(2, 4) : ''),
      if (grid.length >= 6) ('子方格', grid.substring(4, 6)),
      if (grid.length >= 8) ('延伸方格', grid.substring(6, 8)),
      if (_hasTarget) ('由坐标反算', GeoUtils.latLonToGrid(_targetLat!, _targetLon!, precision: 8)),
    ];

    return _card(
      colorScheme,
      title: '网格定位',
      icon: Icons.grid_on_outlined,
      child: Column(
        children: rows
            .where((r) => r.$2.isNotEmpty)
            .map((r) => _kvRow(colorScheme, r.$1, r.$2))
            .toList(),
      ),
    );
  }

  // ── 原始数据 ───────────────────────────────────────────────

  Widget _buildRawData(ColorScheme colorScheme) {
    final entries = data.raw.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return _card(
      colorScheme,
      title: 'QRZ 原始返回 (${entries.length} 个字段)',
      icon: Icons.data_object,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...entries.map((e) {
            final value = e.value.length > 200
                ? '${e.value.substring(0, 200)}…'
                : e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        color: colorScheme.primary.withOpacity(0.85),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final text = entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n');
              await Clipboard.setData(ClipboardData(text: text));
              if (!mounted) return;
              _snack('已复制原始数据');
            },
            icon: const Icon(Icons.copy, size: 15),
            label: const Text('复制原始数据', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── 我的位置输入 ───────────────────────────────────────────

  Future<void> _promptMyLocation() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置我的位置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '用于计算与目标呼号的距离和方位。\n支持以下格式：',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
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
                labelText: '我的位置',
                hintText: '例如 PM01AA 或 31.23, 121.47',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (_myLoc != null)
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
      setState(() => _myLoc = null);
      _snack('已清除我的位置');
      return;
    }

    final parsed = UserLocationService.parseInput(result);
    if (parsed == null) {
      if (!mounted) return;
      _snack('格式无法识别，请输入网格（PM01AA）或经纬度（31.23, 121.47）');
      return;
    }

    await _locService.save(parsed.lat, parsed.lon, result);
    if (!mounted) return;
    setState(() {
      _myLoc = (
        lat: parsed.lat,
        lon: parsed.lon,
        grid: GeoUtils.latLonToGrid(parsed.lat, parsed.lon),
      );
    });
    _snack('已保存我的位置：${GeoUtils.latLonToGrid(parsed.lat, parsed.lon)}');
  }

  // ── 外部数据源卡片 ─────────────────────────────────────────

  /// 美国 FCC 执照数据（hamdb.org）
  Widget _buildFccCard(ColorScheme colorScheme) {
    final f = _fcc!;
    if (f.isEmpty) return const SizedBox.shrink();

    return _card(
      colorScheme,
      title: '美国 FCC 执照数据',
      icon: Icons.gavel_outlined,
      trailing: _sourceTag('hamdb.org', colorScheme),
      child: Column(
        children: [
          _kvRow(colorScheme, '执照状态', f.statusLabel),
          _kvRow(colorScheme, '执照等级', f.licenseClass),
          _kvRow(colorScheme, '有效期至', f.expires),
          _kvRow(colorScheme, '姓名', f.fullName),
          _kvRow(colorScheme, '网格', f.grid),
          _kvRow(colorScheme, '坐标', [f.lat, f.lon].where((s) => s.isNotEmpty).join(', ')),
          _kvRow(colorScheme, '地址',
              [f.addr1, f.addr2, f.state, f.zip].where((s) => s.isNotEmpty).join(', ')),
          _kvRow(colorScheme, '国家', f.country),
          _kvRow(colorScheme, '监护人', f.trustee),
        ],
      ),
    );
  }

  /// DMR 数字电台身份（radioid.net）
  Widget _buildDmrCard(ColorScheme colorScheme) {
    return _card(
      colorScheme,
      title: 'DMR 数字电台身份',
      icon: Icons.router_outlined,
      trailing: _sourceTag('radioid.net', colorScheme),
      child: Column(
        children: _dmr.map((d) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DMR ID ${d.id}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.callsign,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '复制 DMR ID',
                      icon: const Icon(Icons.copy, size: 14),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: d.id));
                        if (!mounted) return;
                        _snack('已复制 DMR ID：${d.id}');
                      },
                    ),
                  ],
                ),
                if (d.fullName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('姓名：${d.fullName}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                if (d.city.isNotEmpty || d.country.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [d.city, d.state, d.country]
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// PSK Reporter 接收报告
  Widget _buildPskCard(ColorScheme colorScheme) {
    return _card(
      colorScheme,
      title: '信号接收报告',
      icon: Icons.wifi_tethering,
      trailing: _sourceTag('PSK Reporter', colorScheme),
      child: Builder(
        builder: (ctx) {
          if (_loadingPsk) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          if (_psk == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '查询最近 24 小时内，世界上有谁接收到过 ${data.call} 的信号'
                  '（含频率、模式、信噪比）。',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: _loadPskReports,
                  icon: const Icon(Icons.search, size: 17),
                  label: const Text('查询接收报告'),
                ),
              ],
            );
          }

          if (_psk!.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近 24 小时内没有接收到 ${data.call} 的信号报告。',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _loadPskReports,
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('重新查询', style: TextStyle(fontSize: 12)),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '最近 24 小时共 ${_psk!.length} 条报告',
                style: TextStyle(
                  fontSize: 12.5,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              ..._psk!.map((r) => _buildPskRow(r, colorScheme)),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _loadPskReports,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('刷新', style: TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPskRow(PskReport r, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              r.receiverCallsign,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (r.band.isNotEmpty) r.band,
                    if (r.frequencyMHz.isNotEmpty) '${r.frequencyMHz} MHz',
                    if (r.mode.isNotEmpty) r.mode,
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12.5),
                ),
                Text(
                  [
                    if (r.receiverLocator.isNotEmpty) '网格 ${r.receiverLocator}',
                    if (r.receiverDXCC.isNotEmpty) r.receiverDXCC,
                    if (r.receiverRegion.isNotEmpty) r.receiverRegion,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${r.snr} dB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: r.snr >= 0
                      ? Colors.green.shade600
                      : Colors.orange.shade700,
                ),
              ),
              Text(
                r.agoText,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// POTA 附近公园
  Widget _buildParksCard(ColorScheme colorScheme) {
    return _card(
      colorScheme,
      title: '附近 POTA 公园',
      icon: Icons.park_outlined,
      trailing: _sourceTag('POTA', colorScheme),
      child: Builder(
        builder: (ctx) {
          if (_loadingParks) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          if (_parks == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '查找离 ${data.call} 最近的「公园通联计划」（POTA）公园，'
                  '适合做户外电台活动。',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: _loadNearbyParks,
                  icon: const Icon(Icons.travel_explore, size: 17),
                  label: const Text('查找附近公园'),
                ),
              ],
            );
          }

          if (_parks!.isEmpty) {
            return Text(
              '该呼号所在国家暂无 POTA 公园数据。',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._parks!.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            p.reference,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (p.grid.isNotEmpty || p.locationDesc.isNotEmpty)
                                Text(
                                  [
                                    if (p.grid.isNotEmpty) '网格 ${p.grid}',
                                    if (p.locationDesc.isNotEmpty) p.locationDesc,
                                  ].join(' · '),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          p.distanceText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 4),
              Text(
                '距离按 ${data.call} 的坐标计算',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 数据来源小标签
  Widget _sourceTag(String name, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  // ── 通用组件 ───────────────────────────────────────────────

  Widget _card(
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 17, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ColorScheme colorScheme,
    String title,
    IconData icon,
    List<(String, String)> rows,
  ) {
    final visible = rows.where((r) => r.$2.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return _card(
      colorScheme,
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visible.map((r) => _buildRow(r.$1, r.$2, colorScheme)).toList(),
      ),
    );
  }

  Widget _buildRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            tooltip: '复制',
            icon: const Icon(Icons.copy, size: 14),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!mounted) return;
              _snack('已复制：$value');
            },
          ),
        ],
      ),
    );
  }

  /// 无复制按钮的紧凑键值行
  Widget _kvRow(ColorScheme colorScheme, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio(ColorScheme colorScheme) {
    return _card(
      colorScheme,
      title: '个人简介',
      icon: Icons.article_outlined,
      child: SelectableText(
        data.bio,
        style: const TextStyle(fontSize: 13.5, height: 1.55),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  static String _geolocLabel(String v) {
    switch (v.toLowerCase()) {
      case 'user':
        return '用户提供';
      case 'grid':
        return '由网格推算';
      case 'callbook':
        return '来自 Callbook';
      default:
        return v;
    }
  }
}
