/// QRZ.com XML API 呼号完整数据模型
///
/// 字段严格对照官方规范 <https://www.qrz.com/docs/xml/current_spec.html>
/// 覆盖 <Callsign> 节点全部字段，未识别的字段保留在 [raw]。
class CallsignData {
  // ── 标识 ──────────────────────────────────────────────
  final String call; // 呼号
  final String xref; // 交叉引用：发起本次查询的呼号
  final String aliases; // 该记录对应的其他呼号
  final String serial; // QRZ 数据库序列号

  // ── 姓名 ──────────────────────────────────────────────
  final String fname; // 名
  final String name; // 姓
  final String nickname; // 昵称
  final String nameFmt; // 格式化姓名（含昵称）

  // ── 地址 ──────────────────────────────────────────────
  final String attn; // 收件人
  final String addr1; // 地址行 1
  final String addr2; // 地址行 2（城市）
  final String state; // 州 / 省
  final String zip; // 邮编
  final String country; // 国家
  final String county; // 县 / 区
  final String fips; // FIPS 县代码
  final String msa; // 都市服务区（USPS）
  final String areaCode; // 电话区号

  // ── DXCC ──────────────────────────────────────────────
  final String dxcc; // DXCC 实体编号
  final String ccode; // 邮寄地址国家的 DXCC 代码
  final String land; // 呼号所属 DXCC 国家
  final String cqZone; // CQ 区
  final String ituZone; // ITU 区

  // ── 位置 ──────────────────────────────────────────────
  final String lat; // 纬度
  final String lon; // 经度
  final String grid; // Maidenhead 网格
  final String geoloc; // 经纬度来源
  final String timeZone; // 时区
  final String gmtOffset; // GMT 偏移
  final String dst; // 是否使用夏令时

  // ── 执照（美国） ──────────────────────────────────────
  final String efdate; // 执照生效日期
  final String expdate; // 执照到期日期
  final String pCall; // 原呼号
  final String class_; // 执照等级
  final String codes; // 执照类型代码

  // ── QSL ───────────────────────────────────────────────
  final String qslvia; // QSL 转交路径
  final String qslmgr; // QSL 管理员
  final String mqsl; // 是否收纸质 QSL
  final String eqsl; // 是否收 eQSL
  final String lotw; // 是否使用 Logbook of the World
  final String iota; // IOTA 编号

  // ── 联系方式 ──────────────────────────────────────────
  final String email; // 邮箱
  final String url; // 个人主页

  // ── 其他 ──────────────────────────────────────────────
  final String born; // 出生年份
  final String user; // QRZ 用户名
  final String trustee; // 监护人呼号
  final String sk; // Silent Key（1 = 已故）
  final String uViews; // QRZ 页面浏览数（即页面上的 Lookups）
  final String bio; // 简介（长度/日期 或 正文）
  final String biodate; // 简介最后更新日期
  final String image; // 主图 URL
  final String imageinfo; // 图片 高:宽:字节
  final String modifydate; // 记录最后修改时间

  /// 原始返回，保留全部字段
  final Map<String, String> raw;

  CallsignData({
    this.call = '',
    this.xref = '',
    this.aliases = '',
    this.serial = '',
    this.fname = '',
    this.name = '',
    this.nickname = '',
    this.nameFmt = '',
    this.attn = '',
    this.addr1 = '',
    this.addr2 = '',
    this.state = '',
    this.zip = '',
    this.country = '',
    this.county = '',
    this.fips = '',
    this.msa = '',
    this.areaCode = '',
    this.dxcc = '',
    this.ccode = '',
    this.land = '',
    this.cqZone = '',
    this.ituZone = '',
    this.lat = '',
    this.lon = '',
    this.grid = '',
    this.geoloc = '',
    this.timeZone = '',
    this.gmtOffset = '',
    this.dst = '',
    this.efdate = '',
    this.expdate = '',
    this.pCall = '',
    this.class_ = '',
    this.codes = '',
    this.qslvia = '',
    this.qslmgr = '',
    this.mqsl = '',
    this.eqsl = '',
    this.lotw = '',
    this.iota = '',
    this.email = '',
    this.url = '',
    this.born = '',
    this.user = '',
    this.trustee = '',
    this.sk = '',
    this.uViews = '',
    this.bio = '',
    this.biodate = '',
    this.image = '',
    this.imageinfo = '',
    this.modifydate = '',
    Map<String, String>? raw,
  }) : raw = raw ?? const {};

  /// 已映射的 XML 标签名（用于挑出未知字段）
  static const Set<String> _mappedTags = {
    'call', 'xref', 'aliases', 'serial',
    'fname', 'name', 'nickname', 'name_fmt',
    'attn', 'addr1', 'addr2', 'state', 'zip', 'country', 'county', 'fips',
    'MSA', 'AreaCode',
    'dxcc', 'ccode', 'land', 'cqzone', 'ituzone',
    'lat', 'lon', 'grid', 'geoloc', 'TimeZone', 'GMTOffset', 'DST',
    'efdate', 'expdate', 'p_call', 'class', 'codes',
    'qslvia', 'qslmgr', 'mqsl', 'eqsl', 'lotw', 'iota',
    'email', 'url',
    'born', 'user', 'trustee', 'sk', 'u_views', 'bio', 'biodate',
    'image', 'imageinfo', 'moddate',
    // 兼容旧版 / 别名写法
    'timezone', 'dst', 'eqslqsl', 'modifydate', 'class_',
  };

  /// 取第一个非空值（兼容不同版本字段名）
  static String _pick(Map<String, String> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  factory CallsignData.fromMap(Map<String, String> map) {
    return CallsignData(
      call: _pick(map, ['call']),
      xref: _pick(map, ['xref']),
      aliases: _pick(map, ['aliases']),
      serial: _pick(map, ['serial']),
      fname: _pick(map, ['fname']),
      name: _pick(map, ['name']),
      nickname: _pick(map, ['nickname']),
      nameFmt: _pick(map, ['name_fmt']),
      attn: _pick(map, ['attn']),
      addr1: _pick(map, ['addr1']),
      addr2: _pick(map, ['addr2']),
      state: _pick(map, ['state']),
      zip: _pick(map, ['zip']),
      country: _pick(map, ['country']),
      county: _pick(map, ['county']),
      fips: _pick(map, ['fips']),
      msa: _pick(map, ['MSA', 'msa']),
      areaCode: _pick(map, ['AreaCode', 'areacode']),
      dxcc: _pick(map, ['dxcc']),
      ccode: _pick(map, ['ccode']),
      land: _pick(map, ['land']),
      cqZone: _pick(map, ['cqzone', 'cqZone']),
      ituZone: _pick(map, ['ituzone', 'ituZone']),
      lat: _pick(map, ['lat']),
      lon: _pick(map, ['lon']),
      grid: _pick(map, ['grid']),
      geoloc: _pick(map, ['geoloc']),
      timeZone: _pick(map, ['TimeZone', 'timezone']),
      gmtOffset: _pick(map, ['GMTOffset', 'gmtoffset']),
      dst: _pick(map, ['DST', 'dst']),
      efdate: _pick(map, ['efdate']),
      expdate: _pick(map, ['expdate']),
      pCall: _pick(map, ['p_call', 'pcall']),
      class_: _pick(map, ['class', 'class_']),
      codes: _pick(map, ['codes']),
      qslvia: _pick(map, ['qslvia']),
      qslmgr: _pick(map, ['qslmgr']),
      mqsl: _pick(map, ['mqsl']),
      eqsl: _pick(map, ['eqsl', 'eqslqsl']),
      lotw: _pick(map, ['lotw']),
      iota: _pick(map, ['iota']),
      email: _pick(map, ['email']),
      url: _pick(map, ['url']),
      born: _pick(map, ['born']),
      user: _pick(map, ['user']),
      trustee: _pick(map, ['trustee']),
      sk: _pick(map, ['sk']),
      uViews: _pick(map, ['u_views', 'uviews']),
      bio: _pick(map, ['bio']),
      biodate: _pick(map, ['biodate']),
      image: _pick(map, ['image']),
      imageinfo: _pick(map, ['imageinfo']),
      modifydate: _pick(map, ['moddate', 'modifydate']),
      raw: map,
    );
  }

  // ── 派生属性 ──────────────────────────────────────────

  String get fullName {
    if (fname.isNotEmpty && name.isNotEmpty) return '$fname $name';
    return name.isNotEmpty ? name : fname;
  }

  /// 显示用姓名：优先 QRZ 的格式化姓名
  String get displayName {
    if (nameFmt.isNotEmpty) return nameFmt;
    if (fullName.isNotEmpty) return fullName;
    return nickname;
  }

  bool get isSilentKey => sk == '1' || sk.toUpperCase() == 'Y';

  bool get hasPhoto => image.startsWith('http');

  bool get hasCoordinates => lat.isNotEmpty && lon.isNotEmpty;

  String get coordinateText => hasCoordinates ? '$lat, $lon' : '';

  String? get mapUrl => hasCoordinates
      ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lon'
      : null;

  String get location {
    final parts = [addr2, state, country].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  String get fullAddress {
    final parts = [
      if (attn.isNotEmpty) attn,
      if (addr1.isNotEmpty) addr1,
      if (addr2.isNotEmpty) addr2,
      if (county.isNotEmpty) '$county County',
      if (state.isNotEmpty) state,
      if (zip.isNotEmpty) zip,
      if (country.isNotEmpty) country,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join('\n');
  }

  /// QSL 方式标签
  List<String> get qslMethods {
    final methods = <String>[];
    if (_isYes(lotw)) methods.add('LotW');
    if (_isYes(eqsl)) methods.add('eQSL');
    if (_isYes(mqsl)) methods.add('纸质 QSL');
    return methods;
  }

  /// QRZ 页面浏览数（页面上的 Lookups）
  String get lookupsText {
    final n = int.tryParse(uViews);
    if (n == null) return uViews;
    if (n < 1000) return '$n';
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }

  /// `<bio>` 有时是「字节数/日期」而非正文
  bool get bioIsMetadata => RegExp(r'^\d+\s*/\s*\d{4}-\d{2}-\d{2}$').hasMatch(bio);

  String get bioSizeText {
    final m = RegExp(r'^(\d+)\s*/\s*(\d{4}-\d{2}-\d{2})$').firstMatch(bio);
    if (m == null) return '';
    return '${m.group(1)} 字节';
  }

  /// 图片尺寸信息 高:宽:字节 → 可读文本
  String get imageInfoText {
    if (imageinfo.isEmpty) return '';
    final parts = imageinfo.split(':');
    if (parts.length < 3) return imageinfo;
    final h = int.tryParse(parts[0]);
    final w = int.tryParse(parts[1]);
    final b = int.tryParse(parts[2]);
    if (h == null || w == null || b == null) return imageinfo;
    return '$w × $h 像素 · ${(b / 1024).toStringAsFixed(1)} KB';
  }

  /// 未识别的额外字段
  Map<String, String> get extraFields {
    final extra = <String, String>{};
    raw.forEach((key, value) {
      if (!_mappedTags.contains(key) && value.isNotEmpty) extra[key] = value;
    });
    return extra;
  }

  bool get isEmpty => call.isEmpty && name.isEmpty && fname.isEmpty;

  static bool _isYes(String v) {
    final t = v.toUpperCase();
    return t == 'Y' || t == '1';
  }

  static String _yesNo(String v) {
    final t = v.toUpperCase();
    if (t == 'Y' || t == '1') return '是';
    if (t == 'N' || t == '0') return '否';
    return v;
  }

  String get eqslText => _yesNo(eqsl);
  String get mqslText => _yesNo(mqsl);
  String get lotwText => _yesNo(lotw);
  String get dstText => _yesNo(dst);

  /// 导出为纯文本
  String toPlainText() {
    final b = StringBuffer();
    void add(String label, String value) {
      if (value.isNotEmpty) b.writeln('$label: $value');
    }

    add('呼号', call);
    add('姓名', displayName);
    add('昵称', nickname);
    add('曾用呼号', aliases);
    add('原呼号', pCall);
    add('执照等级', class_);
    add('生效日期', efdate);
    add('到期日期', expdate);
    add('地址', fullAddress.replaceAll('\n', ', '));
    add('FIPS', fips);
    add('国家', country);
    add('DXCC 实体', dxcc);
    add('CQ 区', cqZone);
    add('ITU 区', ituZone);
    add('网格', grid);
    add('坐标', coordinateText);
    add('时区', timeZone);
    add('GMT 偏移', gmtOffset);
    add('QSL Via', qslvia);
    add('QSL 管理员', qslmgr);
    add('LotW', lotw);
    add('eQSL', eqslText);
    add('纸质 QSL', mqslText);
    add('IOTA', iota);
    add('邮箱', email);
    add('主页', url);
    add('出生年', born);
    add('监护人', trustee);
    add('Lookups', lookupsText);
    add('更新时间', modifydate);
    if (isSilentKey) b.writeln('状态: Silent Key（已故）');
    if (bio.isNotEmpty && !bioIsMetadata) add('简介', bio);
    return b.toString().trim();
  }
}
