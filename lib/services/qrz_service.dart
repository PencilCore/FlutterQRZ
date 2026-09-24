import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/callsign_data.dart';

/// QRZ.com XML API 客户端
///
/// - 会话过期自动续期（QRZ session 约 1 小时有效）
/// - 返回结构统一为 Map，避免上层处理异常
class QrzService {
  static const String baseUrl = 'https://xmldata.qrz.com/xml/current/';

  String? _sessionKey;
  bool _loggedIn = false;

  /// 保存凭据用于会话过期后自动重登
  String? _username;
  String? _password;

  /// 会话过期时间（QRZ 返回的字符串）
  String _expires = '';

  bool get isLoggedIn => _loggedIn;
  String get sessionExpires => _expires;
  String? get username => _username;

  /// 记录凭据（登录成功后调用，用于后续自动续期）
  void rememberCredentials(String username, String password) {
    _username = username;
    _password = password;
  }

  // ── 登录 ───────────────────────────────────────────────────

  /// 使用凭据登录 QRZ
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final uri = Uri.parse(
        '$baseUrl?username=${Uri.encodeComponent(username)}'
        ';password=${Uri.encodeComponent(password)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      final doc = xml.XmlDocument.parse(response.body);

      // 会话信息在 <Session> 节点下
      final keys = doc.findAllElements('Key');
      if (keys.isNotEmpty && keys.first.innerText.trim().isNotEmpty) {
        _sessionKey = keys.first.innerText.trim();
        _loggedIn = true;

        final exp = doc.findAllElements('Expiration');
        _expires = exp.isNotEmpty ? exp.first.innerText : '';

        final subExp = doc.findAllElements('SubExp');
        final subExpText = subExp.isNotEmpty ? subExp.first.innerText : '';

        // 记住凭据，供会话过期时自动重登
        _username = username;
        _password = password;

        return {
          'success': true,
          'message': '登录成功',
          'sessionKey': _sessionKey,
          'expires': _expires,
          'subExp': subExpText,
        };
      }

      // 错误节点：<Error>文本</Error>，有时带 <Code> 和 <Message>
      final err = doc.findAllElements('Error');
      if (err.isNotEmpty) {
        final code = doc.findAllElements('Code');
        final codeText = code.isNotEmpty ? code.first.innerText : '';
        final msg = doc.findAllElements('Message');
        final msgText = msg.isNotEmpty ? msg.first.innerText : '';
        return {
          'success': false,
          'message': _describeLoginError(err.first.innerText, codeText, msgText),
        };
      }

      return {'success': false, 'message': '登录失败：QRZ 返回了无法识别的响应'};
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e)};
    }
  }

  /// 把 QRZ 的英文登录错误翻译成中文提示
  static String _describeLoginError(String error, String code, String message) {
    final e = error.toLowerCase();
    if (e.contains('invalid username') || e.contains('password')) {
      return '用户名或密码错误，请检查后重试。';
    }
    if (e.contains('not found')) {
      return '账号不存在。';
    }
    if (e.contains('subscription')) {
      return '该账号的 QRZ 订阅已过期，XML 数据服务需要有效订阅。';
    }
    if (e.contains('exceeded') || e.contains('too many')) {
      return '请求过于频繁，请稍后再试。';
    }
    if (e.contains('session')) {
      return '会话已失效，请重新登录。';
    }
    final detail = [
      if (code.isNotEmpty) code,
      if (message.isNotEmpty) message,
      if (error.isNotEmpty) error,
    ].join(' - ');
    return '登录失败：$detail';
  }

  // ── 会话管理 ───────────────────────────────────────────────

  /// 判断错误文本是否表示会话失效
  static bool _isSessionError(String text) {
    final t = text.toLowerCase();
    return t.contains('session timeout') ||
        t.contains('session does not exist') ||
        t.contains('invalid session') ||
        t.contains('please login') ||
        t.contains('not logged in');
  }

  /// 尝试用已保存的凭据静默重新登录
  Future<bool> _renewSession() async {
    final u = _username;
    final p = _password;
    if (u == null || p == null) return false;
    final result = await login(u, p);
    return result['success'] == true;
  }

  // ── 呼号查询 ───────────────────────────────────────────────

  /// 查询呼号完整信息
  ///
  /// 会话过期时会自动重新登录并重试一次。
  Future<Map<String, dynamic>> lookupCallsign(String callsign) async {
    if (!_loggedIn || _sessionKey == null) {
      return {'success': false, 'message': '请先登录 QRZ.com', 'data': null};
    }

    var result = await _doLookup(callsign);

    // 会话失效 → 自动续期并重试
    if (result['sessionExpired'] == true) {
      final renewed = await _renewSession();
      if (renewed) {
        result = await _doLookup(callsign);
      } else {
        return {
          'success': false,
          'message': '登录会话已过期，请重新登录。',
          'data': null,
          'needLogin': true,
        };
      }
    }

    return result;
  }

  /// 实际执行一次查询
  Future<Map<String, dynamic>> _doLookup(String callsign) async {
    final query = callsign.trim().toUpperCase();
    final uri = Uri.parse('$baseUrl?s=$_sessionKey;callsign=$query');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      final doc = xml.XmlDocument.parse(response.body);

      // 错误处理
      final err = doc.findAllElements('Error');
      if (err.isNotEmpty) {
        final text = err.first.innerText;
        final codeEl = doc.findAllElements('Code');
        final code = codeEl.isNotEmpty ? codeEl.first.innerText : '';

        if (_isSessionError(text)) {
          return {'success': false, 'message': '会话过期', 'sessionExpired': true};
        }
        if (code == 'NotFound' || text.toLowerCase().contains('not found')) {
          return {
            'success': false,
            'message': '未找到呼号 $query 的记录',
            'data': null,
            'notFound': true,
          };
        }
        return {'success': false, 'message': text, 'data': null};
      }

      // 解析呼号数据
      final records = doc.findAllElements('Callsign');
      if (records.isNotEmpty) {
        final element = records.first;
        final Map<String, String> map = {};
        for (final child in element.childElements) {
          final tag = child.name.local;
          final value = child.innerText.trim();
          if (value.isNotEmpty) map[tag] = value;
        }
        final data = CallsignData.fromMap(map);
        if (data.isEmpty) {
          return {'success': false, 'message': '返回数据为空', 'data': null};
        }
        return {'success': true, 'data': data};
      }

      return {'success': false, 'message': '未找到呼号数据', 'data': null};
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e), 'data': null};
    }
  }

  // ── 错误信息（不泄露密码） ─────────────────────────────────

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Failed host lookup') ||
        msg.contains('No address associated')) {
      return '无法解析 QRZ.com 域名，请检查网络连接后重试。';
    }
    if (msg.contains('TimeoutException') ||
        msg.contains('timed out') ||
        msg.contains('timeout')) {
      return '连接 QRZ.com 超时，请检查网络后重试。';
    }
    if (msg.contains('SocketException')) {
      return '网络连接失败，请检查网络后重试。';
    }
    if (msg.contains('HandshakeException') || msg.contains('Certificate')) {
      return '安全连接失败（证书校验不通过）。';
    }
    if (msg.contains('FormatException') || msg.contains('XmlParserException')) {
      return 'QRZ 返回的数据格式异常。';
    }
    return '连接 QRZ.com 失败，请稍后重试。';
  }

  // ── 登出 ───────────────────────────────────────────────────

  void logout() {
    _sessionKey = null;
    _loggedIn = false;
    _expires = '';
    // 保留 _username/_password 以便上层决定是否清除
  }

  /// 彻底清除包括凭据在内的所有状态
  void logoutAndForget() {
    logout();
    _username = null;
    _password = null;
  }
}
