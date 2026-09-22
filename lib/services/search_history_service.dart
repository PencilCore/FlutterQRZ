import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/callsign_data.dart';

/// 搜索历史记录条目
class SearchHistoryItem {
  final String callsign;
  final String name;
  final String country;
  final DateTime searchTime;

  SearchHistoryItem({
    required this.callsign,
    this.name = '',
    this.country = '',
    required this.searchTime,
  });

  Map<String, dynamic> toJson() => {
        'callsign': callsign,
        'name': name,
        'country': country,
        'searchTime': searchTime.toIso8601String(),
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      callsign: json['callsign'] ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      searchTime: DateTime.parse(json['searchTime']),
    );
  }

  /// 从 CallsignData 创建历史条目
  factory SearchHistoryItem.fromCallsignData(CallsignData data) {
    return SearchHistoryItem(
      callsign: data.callsign,
      name: data.fullName,
      country: data.country,
      searchTime: DateTime.now(),
    );
  }
}

class SearchHistoryService {
  static const String _key = 'qrz_search_history';
  static const int _maxHistory = 50;

  /// 加载搜索历史
  Future<List<SearchHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => SearchHistoryItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存搜索历史
  Future<void> saveHistory(List<SearchHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((e) => e.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  /// 添加一条搜索记录（自动去重，新的在前面）
  Future<List<SearchHistoryItem>> addEntry(
    List<SearchHistoryItem> history,
    CallsignData data,
  ) async {
    // 移除已有的同一呼号记录
    history.removeWhere(
        (item) => item.callsign.toUpperCase() == data.callsign.toUpperCase());
    // 在最前面插入新记录
    history.insert(0, SearchHistoryItem.fromCallsignData(data));
    // 限制最大数量
    if (history.length > _maxHistory) {
      history = history.sublist(0, _maxHistory);
    }
    await saveHistory(history);
    return history;
  }

  /// 删除一条历史记录
  Future<List<SearchHistoryItem>> removeEntry(
    List<SearchHistoryItem> history,
    String callsign,
  ) async {
    history.removeWhere(
        (item) => item.callsign.toUpperCase() == callsign.toUpperCase());
    await saveHistory(history);
    return history;
  }

  /// 清空所有历史
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
