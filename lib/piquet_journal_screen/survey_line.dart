import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pickquet/model.dart';

/// Station position: x — восток, y — север, z — высота (метры).
class StationPoint {
  final double x;
  final double y;
  final double z;

  const StationPoint(this.x, this.y, this.z);

  StationPoint operator +(StationPoint other) =>
      StationPoint(x + other.x, y + other.y, z + other.z);

  StationPoint operator -() => StationPoint(-x, -y, -z);
}

/// Therion anonymous stations ("-" / ".") mark splay shots.
bool _isSplayStation(String name) => name == '-' || name == '.';

StationPoint _legVector(MeasurementModel m) {
  final double azimuth = m.compass.toDouble() * math.pi / 180;
  final double clino = m.angle.toDouble() * math.pi / 180;
  final double distance = m.distance.toDouble();
  final double horizontal = distance * math.cos(clino);
  return StationPoint(
    horizontal * math.sin(azimuth),
    horizontal * math.cos(azimuth),
    distance * math.sin(clino),
  );
}

class SurveyLine {
  final Map<String, StationPoint> stations;
  final List<(String, String)> legs;
  final List<(StationPoint, StationPoint)> splays;
  final String? entrance;

  /// Number of disconnected parts of the survey. Every part starts at the
  /// origin, so more than one means pieces are drawn on top of each other.
  final int components;

  const SurveyLine({
    required this.stations,
    required this.legs,
    required this.splays,
    required this.entrance,
    required this.components,
  });

  /// Lays out stations by walking the leg graph breadth-first from the first
  /// station. On loops the first computed position wins; the closing leg is
  /// still drawn between the fixed positions, so misclosure stays visible.
  factory SurveyLine.fromMeasurements(List<MeasurementModel> measurements) {
    final Map<String, List<(String, StationPoint)>> graph = {};
    final List<String> order = [];
    final List<(String, String)> legs = [];
    final List<(String, StationPoint)> splayShots = [];

    void addStation(String name) {
      if (!graph.containsKey(name)) {
        graph[name] = [];
        order.add(name);
      }
    }

    for (final m in measurements) {
      final bool fromSplay = _isSplayStation(m.from);
      final bool toSplay = _isSplayStation(m.to);
      if (fromSplay && toSplay) continue;
      final StationPoint vector = _legVector(m);
      if (toSplay) {
        addStation(m.from);
        splayShots.add((m.from, vector));
      } else if (fromSplay) {
        addStation(m.to);
        splayShots.add((m.to, -vector));
      } else {
        addStation(m.from);
        addStation(m.to);
        graph[m.from]!.add((m.to, vector));
        graph[m.to]!.add((m.from, -vector));
        legs.add((m.from, m.to));
      }
    }

    final Map<String, StationPoint> stations = {};
    int components = 0;
    for (final start in order) {
      if (stations.containsKey(start)) continue;
      components++;
      stations[start] = const StationPoint(0, 0, 0);
      final Queue<String> queue = Queue.of([start]);
      while (queue.isNotEmpty) {
        final String current = queue.removeFirst();
        for (final (next, vector) in graph[current]!) {
          if (stations.containsKey(next)) continue;
          stations[next] = stations[current]! + vector;
          queue.add(next);
        }
      }
    }

    return SurveyLine(
      stations: stations,
      legs: legs,
      splays: [
        for (final (station, vector) in splayShots)
          (stations[station]!, stations[station]! + vector),
      ],
      entrance: order.isEmpty ? null : order.first,
      components: components,
    );
  }

  double get totalLength => legs.fold(0.0, (sum, leg) {
        final a = stations[leg.$1]!;
        final b = stations[leg.$2]!;
        final dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z;
        return sum + math.sqrt(dx * dx + dy * dy + dz * dz);
      });

  Rect get bounds {
    final Iterable<StationPoint> points = [
      ...stations.values,
      for (final (a, b) in splays) ...[a, b],
    ];
    if (points.isEmpty) return Rect.zero;
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final p in points) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class SurveyLineView extends StatelessWidget {
  const SurveyLineView({super.key, required this.measurements});

  final List<MeasurementModel> measurements;

  @override
  Widget build(BuildContext context) {
    final SurveyLine line = SurveyLine.fromMeasurements(measurements);
    if (line.legs.isEmpty) {
      return const Center(child: Text('Нет ходов для отображения'));
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    final double depth = line.stations.values
        .map((p) => p.z)
        .fold<double>(0, (lo, z) => math.min(lo, z));
    final double height = line.stations.values
        .map((p) => p.z)
        .fold<double>(0, (hi, z) => math.max(hi, z));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text('Длина: ${line.totalLength.toStringAsFixed(1)} м'),
              Text('Пикетов: ${line.stations.length}'),
              Text('Перепад: ${(height - depth).toStringAsFixed(1)} м'),
            ],
          ),
        ),
        if (line.components > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Несвязанных участков: ${line.components} — '
              'каждый начинается из одной точки',
              style: TextStyle(color: colors.error),
            ),
          ),
        Expanded(
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) => InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.2,
                maxScale: 40,
                child: CustomPaint(
                  size: constraints.biggest,
                  painter: _SurveyLinePainter(line: line, colors: colors),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurveyLinePainter extends CustomPainter {
  _SurveyLinePainter({required this.line, required this.colors});

  final SurveyLine line;
  final ColorScheme colors;

  static const double _padding = 40;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = line.bounds;
    final double spanX = math.max(bounds.width, 1);
    final double spanY = math.max(bounds.height, 1);
    final double scale = math.min(
      (size.width - 2 * _padding) / spanX,
      (size.height - 2 * _padding) / spanY,
    );
    final Offset center = size.center(Offset.zero);

    // North is up: screen y grows downwards, so flip the y axis.
    Offset toScreen(StationPoint p) => Offset(
          center.dx + (p.x - bounds.center.dx) * scale,
          center.dy - (p.y - bounds.center.dy) * scale,
        );

    final Paint splayPaint = Paint()
      ..color = colors.outline
      ..strokeWidth = 0.6;
    for (final (a, b) in line.splays) {
      canvas.drawLine(toScreen(a), toScreen(b), splayPaint);
    }

    final Paint legPaint = Paint()
      ..color = colors.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in line.legs) {
      canvas.drawLine(toScreen(line.stations[from]!),
          toScreen(line.stations[to]!), legPaint);
    }

    final Paint stationPaint = Paint()..color = colors.onSurface;
    final Paint entrancePaint = Paint()..color = Colors.green.shade700;
    for (final MapEntry(key: name, value: point) in line.stations.entries) {
      final Offset position = toScreen(point);
      final bool isEntrance = name == line.entrance;
      canvas.drawCircle(position, isEntrance ? 5 : 3,
          isEntrance ? entrancePaint : stationPaint);
      _drawText(canvas, name, position + const Offset(5, -14),
          TextStyle(color: colors.onSurface, fontSize: 11));
    }

    _drawScaleBar(canvas, size, scale);
    _drawNorthArrow(canvas, size);
  }

  void _drawScaleBar(Canvas canvas, Size size, double scale) {
    final double meters = _niceLength(size.width / 4 / scale);
    final double length = meters * scale;
    final Offset start = Offset(_padding, size.height - 16);
    final Offset end = start + Offset(length, 0);
    final Paint paint = Paint()
      ..color = colors.onSurface
      ..strokeWidth = 2;
    canvas.drawLine(start, end, paint);
    canvas.drawLine(start, start - const Offset(0, 6), paint);
    canvas.drawLine(end, end - const Offset(0, 6), paint);
    final String label = meters >= 1
        ? '${meters.toStringAsFixed(0)} м'
        : '${(meters * 100).toStringAsFixed(0)} см';
    _drawText(canvas, label, start + const Offset(0, -22),
        TextStyle(color: colors.onSurface, fontSize: 12));
  }

  void _drawNorthArrow(Canvas canvas, Size size) {
    final Offset tip = Offset(size.width - 24, 12);
    final Path arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 7, tip.dy + 20)
      ..lineTo(tip.dx, tip.dy + 15)
      ..lineTo(tip.dx + 7, tip.dy + 20)
      ..close();
    canvas.drawPath(arrow, Paint()..color = colors.onSurface);
    _drawText(canvas, 'С', tip + const Offset(-5, 22),
        TextStyle(color: colors.onSurface, fontSize: 12));
  }

  /// Rounds down to 1, 2 or 5 × 10ⁿ.
  static double _niceLength(double raw) {
    final double magnitude =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final double fraction = raw / magnitude;
    final double nice = fraction >= 5
        ? 5
        : fraction >= 2
            ? 2
            : 1;
    return nice * magnitude;
  }

  void _drawText(Canvas canvas, String text, Offset at, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_SurveyLinePainter oldDelegate) =>
      oldDelegate.line != line || oldDelegate.colors != colors;
}
