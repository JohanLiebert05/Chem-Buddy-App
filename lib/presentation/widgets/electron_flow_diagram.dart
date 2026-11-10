import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

/// Displays the authored SVG and traces its electron arrows in SVG coordinates.
class ElectronFlowDiagram extends StatefulWidget {
  const ElectronFlowDiagram({
    super.key,
    required this.svg,
    required this.label,
    this.showFlow = true,
  });

  final String svg;
  final String label;
  final bool showFlow;

  static Color arrowColor(int index) => const [
    Color(0xFF005C9E),
    Color(0xFFA52752),
    Color(0xFF087254),
    Color(0xFF6942A1),
  ][index % 4];

  @override
  State<ElectronFlowDiagram> createState() => _ElectronFlowDiagramState();
}

class _ElectronFlowDiagramState extends State<ElectronFlowDiagram>
    with SingleTickerProviderStateMixin {
  late final _trace = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late _Diagram _diagram = _Diagram.parse(widget.svg);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _play();
  }

  @override
  void didUpdateWidget(ElectronFlowDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.svg != oldWidget.svg) _diagram = _Diagram.parse(widget.svg);
    if (widget.svg != oldWidget.svg || widget.showFlow != oldWidget.showFlow) {
      _play();
    }
  }

  void _play() {
    if (!widget.showFlow ||
        _diagram.arrows.isEmpty ||
        MediaQuery.disableAnimationsOf(context)) {
      _trace.stop();
      _trace.value = 1;
    } else {
      _trace.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: widget.label,
    child: SizedBox.expand(
      child: CustomPaint(
        foregroundPainter: _FlowPainter(
          _diagram,
          _trace,
          visible: widget.showFlow,
        ),
        child: SvgPicture.string(
          _diagram.background,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _Diagram {
  const _Diagram(this.background, this.viewBox, this.arrows);

  factory _Diagram.parse(String svg) {
    final document = XmlDocument.parse(svg);
    final root = document.rootElement;
    final values = (root.getAttribute('viewBox') ?? '0 0 820 360')
        .trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.parse)
        .toList();
    final viewBox = Rect.fromLTWH(values[0], values[1], values[2], values[3]);
    final paths = <({ui.PathMetric metric, bool singleElectron})>[];
    final group = root.descendants
        .whereType<XmlElement>()
        .where((element) => element.getAttribute('id') == 'electron-arrows')
        .firstOrNull;
    if (group != null) {
      for (final element in group.findAllElements('path')) {
        final target = _PathSink();
        writeSvgPathDataToPath(element.getAttribute('d'), target);
        final metric = target.path.computeMetrics().firstOrNull;
        if (metric == null || metric.length == 0) continue;
        final marker = element.getAttribute('marker-end') ?? '';
        paths.add((
          metric: metric,
          singleElectron: marker.contains('fishhook') || marker.contains('1e'),
        ));
      }
      group.parent!.children.remove(group);
    }
    for (final marker in root.findAllElements('marker').toList()) {
      // Electron arrowheads are painted explicitly. Other SVG definitions stay.
      if (marker.getAttribute('id') case 'electron-arrow' || 'fishhook') {
        marker.parent!.children.remove(marker);
      }
    }
    return _Diagram(document.toXmlString(), viewBox, paths);
  }

  final String background;
  final Rect viewBox;
  final List<({ui.PathMetric metric, bool singleElectron})> arrows;
}

class _PathSink implements PathProxy {
  final path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(this.diagram, this.trace, {required this.visible})
    : super(repaint: trace);

  final _Diagram diagram;
  final Animation<double> trace;
  final bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible || diagram.arrows.isEmpty || size.isEmpty) return;
    final box = diagram.viewBox;
    final fitted = applyBoxFit(BoxFit.contain, box.size, size).destination;
    final scale = fitted.width / box.width;
    final frame = Alignment.center.inscribe(fitted, Offset.zero & size);
    canvas.save();
    canvas.translate(frame.left, frame.top);
    canvas.scale(scale);
    canvas.translate(-box.left, -box.top);

    final progress = Curves.easeInOutCubic.transform(trace.value);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = (1.65 / scale).clamp(2.6, 5.0);
    for (final (index, arrow) in diagram.arrows.indexed) {
      final distance = arrow.metric.length * progress;
      if (distance < 1) continue;
      pen.color = ElectronFlowDiagram.arrowColor(index);
      canvas.drawPath(arrow.metric.extractPath(0, distance), pen);

      final tip = arrow.metric.getTangentForOffset(distance)!;
      final axis = tip.vector;
      final normal = Offset(-axis.dy, axis.dx);
      final length = (8 / scale).clamp(10.0, 20.0);
      final rear = tip.position - axis * length;
      final barb = normal * (length * .44);
      final head = Path()
        ..moveTo((rear + barb).dx, (rear + barb).dy)
        ..lineTo(tip.position.dx, tip.position.dy);
      if (!arrow.singleElectron) {
        head.lineTo((rear - barb).dx, (rear - barb).dy);
      }
      canvas.drawPath(head, pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) =>
      oldDelegate.visible != visible || oldDelegate.diagram != diagram;
}
