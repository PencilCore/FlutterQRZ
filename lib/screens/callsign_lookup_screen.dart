import 'package:flutter/material.dart';
import '../services/qrz_service.dart';
import '../models/callsign_data.dart';

class CallsignLookupScreen extends StatefulWidget {
  final QrzService qrzService;

  const CallsignLookupScreen({
    super.key,
    required this.qrzService,
  });

  @override
  State<CallsignLookupScreen> createState() => _CallsignLookupScreenState();
}

class _CallsignLookupScreenState extends State<CallsignLookupScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  CallsignData? _result;
  String? _errorMessage;
  List<String> _recentSearches = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _lookupCallsign() async {
    final callsign = _searchController.text.trim();
    if (callsign.isEmpty) {
      setState(() {
        _errorMessage = '请输入呼号';
      });
      return;
    }

    if (!widget.qrzService.isLoggedIn) {
      setState(() {
        _errorMessage = '请先登录 QRZ.com';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    final result = await widget.qrzService.lookupCallsign(callsign);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      setState(() {
        _result = result['data'];
      });
      // Add to recent searches
      if (!_recentSearches.contains(callsign.toUpperCase())) {
        _recentSearches.insert(0, callsign.toUpperCase());
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.sublist(0, 10);
        }
      }
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '呼号查询',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入业余无线电呼号进行查询',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),

          // Search bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '输入呼号 (例如: BI4BVC)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _lookupCallsign(),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _lookupCallsign,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: const Text('查询'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recent searches
          if (_recentSearches.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '最近查询:',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                ..._recentSearches.take(5).map((cs) => ActionChip(
                      label: Text(
                        cs,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        _searchController.text = cs;
                        _lookupCallsign();
                      },
                      visualDensity: VisualDensity.compact,
                    )),
              ],
            ),

          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Results
          if (_result != null)
            Expanded(
              child: _buildResultCard(colorScheme),
            ),

          if (_result == null && _errorMessage == null && !_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.radio_outlined,
                      size: 64,
                      color: colorScheme.onSurface.withOpacity(0.15),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '输入呼号开始查询',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with callsign
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _result!.callsign,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result!.fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (_result!.class_.isNotEmpty)
                        Text(
                          '执照等级: ${_result!.class_}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Info grid
            _buildInfoSection('基本信息', [
              if (_result!.country.isNotEmpty) ('国家', _result!.country),
              if (_result!.state.isNotEmpty) ('州/省', _result!.state),
              if (_result!.county.isNotEmpty) ('县/区', _result!.county),
              if (_result!.grid.isNotEmpty) ('网格', _result!.grid),
              if (_result!.born.isNotEmpty) ('出生年', _result!.born),
            ], colorScheme),

            const SizedBox(height: 16),

            _buildInfoSection('地址信息', [
              if (_result!.addr1.isNotEmpty) ('地址1', _result!.addr1),
              if (_result!.addr2.isNotEmpty) ('地址2', _result!.addr2),
              if (_result!.zip.isNotEmpty) ('邮编', _result!.zip),
            ], colorScheme),

            const SizedBox(height: 16),

            _buildInfoSection('QSL 信息', [
              if (_result!.qslVia.isNotEmpty) ('QSL Via', _result!.qslVia),
              if (_result!.eqsl.isNotEmpty) ('eQSL', _result!.eqsl),
              if (_result!.mgr.isNotEmpty) ('Manager', _result!.mgr),
            ], colorScheme),

            const SizedBox(height: 16),

            _buildInfoSection('坐标', [
              if (_result!.lat.isNotEmpty) ('纬度', _result!.lat),
              if (_result!.lon.isNotEmpty) ('经度', _result!.lon),
            ], colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<(String, String)> items,
    ColorScheme colorScheme,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    item.$1,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
