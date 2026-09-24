import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 静态地图预览：用 OSM 瓦片拼出目标位置周边，无需任何原生插件。
///
/// 瓦片加载失败时自动降级为占位块，不影响整体页面。
class StaticMapPreview extends StatefulWidget {
  final double lat;
  final double lon;
  final double height;
  final int zoom;
  final VoidCallback? onTap;

  const StaticMapPreview({
    super.key,
    required this.lat,
    required this.lon,
    this.height = 190,
    this.zoom = 9,
    this.onTap,
  });

  @override
  State<StaticMapPreview> createState() => _StaticMapPreviewState();
}

class _StaticMapPreviewState extends State<StaticMapPreview> {
  static const int _tileSize = 256;

  /// 经度 → 瓦片 X（含小数）
  double _tileX(double lon, int z) => (lon + 180.0) / 360.0 * (1 << z);

  /// 纬度 → 瓦片 Y（含小数）
  double _tileY(double lat, int z) {
    final rad = lat * math.pi / 180.0;
    return (1 -
            math.log(math.tan(rad) + 1 / math.cos(rad)) / math.pi) /
        2 *
        (1 << z);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final z = widget.zoom;
    final tx = _tileX(widget.lon, z);
    final ty = _tileY(widget.lat, z);

    final cx = tx.floor();
    final cy = ty.floor();
    final fx = tx - cx;
    final fy = ty - cy;

    // 画布尺寸：单块瓦片大小，居中显示目标点
    const canvasW = 320.0;
    const canvasH = 190.0;

    // 目标点在 3×3 网格中的像素位置
    final pointPx = ((1 + fx) * _tileSize, (1 + fy) * _tileSize);
    final originX = canvasW / 2 - pointPx.$1;
    final originY = canvasH / 2 - pointPx.$2;

    final tiles = <Widget>[];
    for (var j = 0; j < 3; j++) {
      for (var i = 0; i < 3; i++) {
        final x = (cx - 1 + i) % (1 << z);
        final y = cy - 1 + j;
        if (y < 0 || y >= (1 << z)) continue;

        final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
        tiles.add(
          Positioned(
            left: originX + i * _tileSize * 1.0,
            top: originY + j * _tileSize * 1.0,
            width: _tileSize.toDouble(),
            height: _tileSize.toDouble(),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Container(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
              ),
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: widget.height,
          width: double.infinity,
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              ...tiles,
              // 目标点标记
              const Center(
                child: _MapMarker(),
              ),
              // 右下角来源标注
              Positioned(
                right: 6,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '© OpenStreetMap',
                    style: TextStyle(fontSize: 9, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 方位罗盘：显示从“我的位置”看目标呼号的方向
class BearingCompass extends StatelessWidget {
  final double bearing;
  final String bearingLabel;
  final double? distanceKm;
  final double size;

  const BearingCompass({
    super.key,
    required this.bearing,
    required this.bearingLabel,
    this.distanceKm,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassPainter(
          bearing: bearing,
          primary: colorScheme.primary,
          outline: colorScheme.outlineVariant,
          onSurface: colorScheme.onSurface,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${bearing.round()}°',
                style: TextStyle(
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                bearingLabel,
                style: TextStyle(
                  fontSize: size * 0.11,
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              if (distanceKm != null)
                Text(
                  distanceKm! < 1000
                      ? '${distanceKm!.round()} km'
                      : '${(distanceKm! / 1000).toStringAsFixed(1)}k km',
                  style: TextStyle(
                    fontSize: size * 0.09,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double bearing;
  final Color primary;
  final Color outline;
  final Color onSurface;

  _CompassPainter({
    required this.bearing,
    required this.primary,
    required this.outline,
    required this.onSurface,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // 外圈
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = outline.withOpacity(0.7);
    canvas.drawCircle(center, radius, ring);

    // 刻度
    final tick = Paint()
      ..strokeWidth = 1
      ..color = outline;
    for (var i = 0; i < 36; i++) {
      final a = i * 10 * math.pi / 180.0;
      final isMajor = i % 9 == 0;
      final r1 = radius - (isMajor ? 9 : 4);
      canvas.drawLine(
        center + Offset(math.sin(a) * r1, -math.cos(a) * r1),
        center + Offset(math.sin(a) * radius, -math.cos(a) * radius),
        tick,
      );
    }

    // 方位指针
    final a = bearing * math.pi / 180.0;
    final tip = center + Offset(math.sin(a) * (radius - 14), -math.cos(a) * (radius - 14));
    final head = Paint()..color = primary;
    final shaft = Paint()
      ..color = primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, shaft);

    // 箭头
    final path = Path();
    final leftA = a - 0.35;
    final rightA = a + 0.35;
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      center.dx + math.sin(leftA) * (radius - 24),
      center.dy - math.cos(leftA) * (radius - 24),
    );
    path.lineTo(
      center.dx + math.sin(rightA) * (radius - 24),
      center.dy - math.cos(rightA) * (radius - 24),
    );
    path.close();
    canvas.drawPath(path, head);

    // 中心点
    canvas.drawCircle(center, 3, Paint()..color = primary);

    // 方位字母
    const labels = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    labels.forEach((label, deg) {
      final ang = deg * math.pi / 180.0;
      final pos = center +
          Offset(math.sin(ang) * (radius - 2), -math.cos(ang) * (radius - 2));
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: label == 'N' ? primary : onSurface.withOpacity(0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      Offset offset;
      switch (label) {
        case 'N':
          offset = Offset(pos.dx - tp.width / 2, pos.dy - tp.height * 0.15);
          break;
        case 'S':
          offset = Offset(pos.dx - tp.width / 2, pos.dy - tp.height * 0.85);
          break;
        case 'E':
          offset = Offset(pos.dx - tp.width * 1.05, pos.dy - tp.height / 2);
          break;
        default:
          offset = Offset(pos.dx - tp.width * -0.05, pos.dy - tp.height / 2);
      }
      tp.paint(canvas, offset);
    });
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.bearing != bearing ||
      old.primary != primary ||
      old.outline != outline;
}
