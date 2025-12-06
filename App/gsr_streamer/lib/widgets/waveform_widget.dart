import 'package:flutter/material.dart';
import '../models/waveform_data.dart';
import '../services/waveform_manager.dart';

/// Widget for displaying real-time waveforms
class WaveformWidget extends StatefulWidget {
  final WaveformManager waveformManager;
  final WaveformType type;
  final double height;
  final bool showStats;
  final bool showGrid;

  const WaveformWidget({
    super.key,
    required this.waveformManager,
    required this.type,
    this.height = 200,
    this.showStats = true,
    this.showGrid = true,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget> {
  @override
  Widget build(BuildContext context) {
    final stats = widget.waveformManager.getStats(widget.type);
    final hasData = widget.waveformManager.hasData(widget.type);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(stats),
            const SizedBox(height: 12),
            if (hasData) ...[
              SizedBox(
                height: widget.height,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: WaveformPainter(
                    waveformManager: widget.waveformManager,
                    type: widget.type,
                    showGrid: widget.showGrid,
                  ),
                ),
              ),
              if (widget.showStats) ...[
                const SizedBox(height: 12),
                _buildStats(stats),
              ],
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WaveformStats stats) {
    final color = Color(widget.type.colorValue);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              widget.type.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.type.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stats.formattedCurrent,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (stats.pointCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${stats.pointCount} pts',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStats(WaveformStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Min', stats.formattedMin, Colors.blue),
        _buildStatItem('Avg', stats.formattedAvg, Colors.green),
        _buildStatItem('Max', stats.formattedMax, Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No ${widget.type.displayName} data yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Data will appear once readings start',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final WaveformManager waveformManager;
  final WaveformType type;
  final bool showGrid;

  WaveformPainter({
    required this.waveformManager,
    required this.type,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = waveformManager.getPoints(type);
    if (points.isEmpty) return;

    // Draw grid
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw waveform
    _drawWaveform(canvas, size, points);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertical lines
    for (int i = 0; i <= 6; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawWaveform(Canvas canvas, Size size, List<WaveformPoint> points) {
    if (points.length < 2) return;

    final normalizedValues = waveformManager.getNormalizedValues(type);
    if (normalizedValues.isEmpty) return;

    final waveformPaint = Paint()
      ..color = Color(type.colorValue)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Color(type.colorValue).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Calculate x positions
    final xStep = size.width / (normalizedValues.length - 1);

    // Start paths
    final firstY = size.height * (1 - normalizedValues[0]);
    path.moveTo(0, firstY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, firstY);

    // Draw waveform line and fill
    for (int i = 0; i < normalizedValues.length; i++) {
      final x = i * xStep;
      final y = size.height * (1 - normalizedValues[i]);

      if (i == 0) continue;

      // Smooth curve using quadratic bezier
      final prevX = (i - 1) * xStep;
      final prevY = size.height * (1 - normalizedValues[i - 1]);
      final cpX = (prevX + x) / 2;

      path.quadraticBezierTo(cpX, prevY, x, y);
      fillPath.quadraticBezierTo(cpX, prevY, x, y);
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill first, then line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, waveformPaint);

    // Draw current value indicator
    _drawCurrentIndicator(canvas, size, normalizedValues.last);
  }

  void _drawCurrentIndicator(Canvas canvas, Size size, double normalizedValue) {
    final y = size.height * (1 - normalizedValue);

    // Draw horizontal line
    final linePaint = Paint()
      ..color = Color(type.colorValue).withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      linePaint,
    );

    // Draw circle at current point
    final circlePaint = Paint()
      ..color = Color(type.colorValue)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width, y),
      4,
      circlePaint,
    );

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(size.width, y),
      4,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) => true;
}

/// Multi-waveform display widget
class MultiWaveformWidget extends StatelessWidget {
  final WaveformManager waveformManager;
  final List<WaveformType> types;

  const MultiWaveformWidget({
    super.key,
    required this.waveformManager,
    this.types = const [
      WaveformType.heartRate,
      WaveformType.gsr,
      WaveformType.temperature,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: types
          .map((type) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: WaveformWidget(
                  waveformManager: waveformManager,
                  type: type,
                  height: 150,
                ),
              ))
          .toList(),
    );
  }
}

/// Compact waveform preview (for overview)
class CompactWaveformWidget extends StatelessWidget {
  final WaveformManager waveformManager;
  final WaveformType type;

  const CompactWaveformWidget({
    super.key,
    required this.waveformManager,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final stats = waveformManager.getStats(type);
    final color = Color(type.colorValue);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                type.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: Size.infinite,
              painter: WaveformPainter(
                waveformManager: waveformManager,
                type: type,
                showGrid: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stats.formattedCurrent,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
