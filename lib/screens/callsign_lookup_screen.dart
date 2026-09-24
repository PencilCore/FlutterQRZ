import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/qrz_service.dart';
import '../services/search_history_service.dart';
import '../models/callsign_data.dart';
import 'callsign_profile_screen.dart';

/// 呼号查询页：搜索 + 历史记录 + 结果预览
class CallsignLookupScreen extends StatefulWidget {
  final QrzService qrzService;

  const CallsignLookupScreen({super.key, required this.qrzService});

  @override
  State<CallsignLookupScreen> createState() => _CallsignLookupScreenState();
}

class _CallsignLookupScreenState extends State<CallsignLookupScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _historyService = SearchHistoryService();

  bool _isLoading = false;
  CallsignData? _result;
  String? _errorMessage;
  bool _needLogin = false;
  List<SearchHistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final items = await _historyService.loadHistory();
    if (mounted) setState(() => _history = items);
  }

  Future<void> _lookupCallsign([String? rawCallsign]) async {
    final callsign = (rawCallsign ?? _searchController.text).trim().toUpperCase();
    if (callsign.isEmpty) {
      setState(() {
        _errorMessage = '请输入呼号';
        _needLogin = false;
      });
      return;
    }

    if (!widget.qrzService.isLoggedIn) {
      setState(() {
        _errorMessage = '请先登录 QRZ.com';
        _needLogin = true;
      });
      return;
    }

    // 收起键盘
    _focusNode.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _needLogin = false;
      _result = null;
    });

    final result = await widget.qrzService.lookupCallsign(callsign);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as CallsignData;
      setState(() {
        _isLoading = false;
        _result = data;
        _searchController.text = data.call;
      });
      // 记录历史
      final updated = await _historyService.addEntry(_history, data);
      if (mounted) setState(() => _history = updated);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'] as String? ?? '查询失败';
        _needLogin = result['needLogin'] == true;
      });
    }
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    if (mounted) setState(() => _history = []);
  }

  Future<void> _removeHistoryItem(String callsign) async {
    final updated = await _historyService.removeEntry(_history, callsign);
    if (mounted) setState(() => _history = updated);
  }

  void _openProfile(CallsignData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallsignProfileScreen(data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 700;

    return Padding(
      padding: EdgeInsets.all(isNarrow ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '呼号查询',
            style: TextStyle(
              fontSize: isNarrow ? 22 : 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '输入业余无线电呼号，查询完整资料',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),

          // 搜索栏
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _lookupCallsign(),
                  decoration: InputDecoration(
                    hintText: isNarrow ? '呼号，如 BI4BVC' : '输入呼号 (例如: BI4BVC)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _result = null);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : () => _lookupCallsign(),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('查询'),
                ),
              ),
            ],
          ),

          // 历史记录
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.history,
                  size: 14,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  '最近查询',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearHistory,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('清空', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 0,
              children: _history
                  .take(8)
                  .map(
                    (item) => InputChip(
                      label: Text(
                        item.callsign,
                        style: const TextStyle(fontSize: 12),
                      ),
                      avatar: item.country.isNotEmpty
                          ? null
                          : const Icon(Icons.radio, size: 14),
                      onPressed: () {
                        _searchController.text = item.callsign;
                        _lookupCallsign(item.callsign);
                      },
                      onDeleted: () => _removeHistoryItem(item.callsign),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 12),

          // 错误提示
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _needLogin
                    ? colorScheme.primaryContainer.withOpacity(0.4)
                    : Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _needLogin
                      ? colorScheme.primary.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _needLogin ? Icons.lock_outline : Icons.warning_amber_outlined,
                    color: _needLogin ? colorScheme.primary : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _needLogin
                            ? colorScheme.onSurface
                            : Colors.orange.shade800,
                      ),
                    ),
                  ),
                  if (_needLogin)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.login, size: 18),
                    ),
                ],
              ),
            ),

          // 结果预览
          if (_result != null)
            Expanded(child: _buildResultCard(_result!, colorScheme)),

          // 空状态
          if (_result == null && _errorMessage == null && !_isLoading)
            Expanded(child: _buildEmptyState(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radio_outlined,
            size: 56,
            color: colorScheme.onSurface.withOpacity(0.15),
          ),
          const SizedBox(height: 14),
          Text(
            '输入呼号开始查询',
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '可查询姓名、地址、网格、QSL 方式、照片等完整资料',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(CallsignData data, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openProfile(data),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头像 / 照片
                    _buildAvatar(data, colorScheme),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                data.call,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (data.isSilentKey)
                                _buildTag('SK', Colors.grey, colorScheme),
                              if (data.class_.isNotEmpty)
                                _buildTag(data.class_, Colors.purple, colorScheme),
                            ],
                          ),
                          if (data.displayName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              data.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (data.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 13,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    data.location,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),

                // 快速标签
                if (data.qslMethods.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...data.qslMethods.map(
                        (m) => _buildTag(m, Colors.teal, colorScheme),
                      ),
                      if (data.grid.isNotEmpty)
                        _buildTag('网格 ${data.grid}', Colors.indigo, colorScheme),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Text(
                      '点击查看完整资料',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: data.toPlainText()),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已复制全部资料'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('复制', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(CallsignData data, ColorScheme colorScheme) {
    if (data.hasPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          data.image,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(data, colorScheme),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _buildInitials(data, colorScheme);
          },
        ),
      );
    }
    return _buildInitials(data, colorScheme);
  }

  Widget _buildInitials(CallsignData data, ColorScheme colorScheme) {
    final text = data.call.isNotEmpty
        ? data.call.substring(0, data.call.length > 4 ? 4 : data.call.length)
        : '?';
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
