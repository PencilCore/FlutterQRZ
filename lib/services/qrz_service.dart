import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/callsign_data.dart';

class QrzSession {
  final String sessionKey;
  final String expires;

  QrzSession({required this.sessionKey, required this.expires});
}

class QrzService {
  static const String baseUrl = 'https://xmldata.qrz.com/xml/current/';

  String? _sessionKey;
  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  /// Login to QRZ API with credentials
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = '$baseUrl?username=$username;password=$password';
    try {
      final response = await http.get(Uri.parse(url));
      final document = xml.XmlDocument.parse(response.body);

      final sessionKeyElements = document.findAllElements('Key');
      if (sessionKeyElements.isNotEmpty) {
        _sessionKey = sessionKeyElements.first.innerText;
        _loggedIn = true;

        final expiresElements = document.findAllElements('Expiration');
        final expires =
            expiresElements.isNotEmpty ? expiresElements.first.innerText : '';

        return {
          'success': true,
          'message': '登录成功',
          'sessionKey': _sessionKey,
          'expires': expires,
        };
      }

      // Check for errors
      final errorElements = document.findAllElements('Error');
      if (errorElements.isNotEmpty) {
        final errorMessage =
            errorElements.first.innerText;
        return {'success': false, 'message': errorMessage};
      }

      return {'success': false, 'message': '未知错误'};
    } catch (e) {
      return {'success': false, 'message': '连接错误: $e'};
    }
  }

  /// Lookup callsign information
  Future<Map<String, dynamic>> lookupCallsign(String callsign) async {
    if (!_loggedIn || _sessionKey == null) {
      return {'success': false, 'message': '请先登录', 'data': null};
    }

    final url = '$baseUrl?s=$_sessionKey;callsign=${callsign.toUpperCase()}';
    try {
      final response = await http.get(Uri.parse(url));
      final document = xml.XmlDocument.parse(response.body);

      // Check for errors first
      final errorElements = document.findAllElements('Error');
      if (errorElements.isNotEmpty) {
        final errorCode = document.findAllElements('Code');
        final code = errorCode.isNotEmpty ? errorCode.first.innerText : '';
        if (code == 'NotFound' || code == 'NotAuthorized') {
          return {
            'success': false,
            'message': '呼号 $callsign 未找到',
            'data': null,
          };
        }
        return {
          'success': false,
          'message': errorElements.first.innerText,
          'data': null,
        };
      }

      // Parse callsign data
      final callsignElements = document.findAllElements('Callsign');
      if (callsignElements.isNotEmpty) {
        final element = callsignElements.first;
        final Map<String, String> data = {};

        // Extract all child elements
        for (final child in element.childElements) {
          final tag = child.name.local;
          final value = child.innerText;
          if (value.isNotEmpty) {
            data[tag] = value;
          }
        }

        return {
          'success': true,
          'data': CallsignData.fromMap(data),
        };
      }

      return {'success': false, 'message': '未找到呼号数据', 'data': null};
    } catch (e) {
      return {'success': false, 'message': '查询错误: $e', 'data': null};
    }
  }

  /// Logout from QRZ API
  void logout() {
    _sessionKey = null;
    _loggedIn = false;
  }
}
