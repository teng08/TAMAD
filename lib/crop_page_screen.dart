import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'document_services.dart';

enum _CropDrag { topLeft, topRight, bottomLeft, bottomRight, move }

class CropPageScreen extends StatefulWidget {
  const CropPageScreen({required this.pagePath, super.key});

  final String pagePath;

  @override
  State<CropPageScreen> createState() => _CropPageScreenState();
}

class _CropPageScreenState extends State<CropPageScreen> {
  static const _minimumSpan = 0.05;
  Rect _bounds = const Rect.fromLTRB(0.06, 0.06, 0.94, 0.94);
  Size? _imageSize;
  String? _error;
  _CropDrag? _drag;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    try {
      final bytes = await File(widget.pagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();
      codec.dispose();
      if (mounted) setState(() => _imageSize = size);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'This page could not be opened for cropping.');
      }
    }
  }

  void _startDrag(Offset point, Size size) {
    final crop = Rect.fromLTRB(
      _bounds.left * size.width,
      _bounds.top * size.height,
      _bounds.right * size.width,
      _bounds.bottom * size.height,
    );
    final corners = <_CropDrag, Offset>{
      _CropDrag.topLeft: crop.topLeft,
      _CropDrag.topRight: crop.topRight,
      _CropDrag.bottomLeft: crop.bottomLeft,
      _CropDrag.bottomRight: crop.bottomRight,
    };
    final closest = corners.entries.reduce(
      (a, b) =>
          (a.value - point).distance <= (b.value - point).distance ? a : b,
    );
    _drag = crop.contains(point) && (closest.value - point).distance > 32
        ? _CropDrag.move
        : closest.key;
  }

  void _updateDrag(DragUpdateDetails details, Size size) {
    final drag = _drag;
    if (drag == null) return;
    final x = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
    final y = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
    final current = _bounds;
    setState(() {
      _bounds = switch (drag) {
        _CropDrag.topLeft => Rect.fromLTRB(
          math.min(x, current.right - _minimumSpan),
          math.min(y, current.bottom - _minimumSpan),
          current.right,
          current.bottom,
        ),
        _CropDrag.topRight => Rect.fromLTRB(
          current.left,
          math.min(y, current.bottom - _minimumSpan),
          math.max(x, current.left + _minimumSpan),
          current.bottom,
        ),
        _CropDrag.bottomLeft => Rect.fromLTRB(
          math.min(x, current.right - _minimumSpan),
          current.top,
          current.right,
          math.max(y, current.top + _minimumSpan),
        ),
        _CropDrag.bottomRight => Rect.fromLTRB(
          current.left,
          current.top,
          math.max(x, current.left + _minimumSpan),
          math.max(y, current.top + _minimumSpan),
        ),
        _CropDrag.move => _moveCrop(
          current,
          details.delta.dx / size.width,
          details.delta.dy / size.height,
        ),
      };
    });
  }

  Rect _moveCrop(Rect current, double dx, double dy) {
    final left = (current.left + dx).clamp(0.0, 1.0 - current.width);
    final top = (current.top + dy).clamp(0.0, 1.0 - current.height);
    return Rect.fromLTWH(left, top, current.width, current.height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop page')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text('Drag the corners to choose the part to keep.'),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _error != null
                    ? Center(child: Text(_error!))
                    : _imageSize == null
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final imageSize = _imageSize!;
                          final ratio = imageSize.width / imageSize.height;
                          final width = math.min(
                            constraints.maxWidth,
                            constraints.maxHeight * ratio,
                          );
                          final size = Size(width, width / ratio);
                          return Center(
                            child: SizedBox(
                              width: size.width,
                              height: size.height,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) =>
                                    _startDrag(details.localPosition, size),
                                onPanUpdate: (details) =>
                                    _updateDrag(details, size),
                                onPanEnd: (_) => _drag = null,
                                onPanCancel: () => _drag = null,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(widget.pagePath),
                                      fit: BoxFit.fill,
                                    ),
                                    CustomPaint(
                                      painter: _CropOverlayPainter(_bounds),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            TextButton.icon(
              onPressed: _imageSize == null
                  ? null
                  : () => setState(
                      () => _bounds = const Rect.fromLTRB(0, 0, 1, 1),
                    ),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Select full page'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _imageSize == null
                ? null
                : () => Navigator.of(context).pop(
                    CropBounds(
                      _bounds.left,
                      _bounds.top,
                      _bounds.right,
                      _bounds.bottom,
                    ),
                  ),
            icon: const Icon(Icons.crop_rounded),
            label: const Text('Save crop'),
          ),
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter(this.bounds);

  final Rect bounds;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      bounds.left * size.width,
      bounds.top * size.height,
      bounds.right * size.width,
      bounds.bottom * size.height,
    );
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.48);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, rect.top), shade);
    canvas.drawRect(
      Rect.fromLTRB(0, rect.bottom, size.width, size.height),
      shade,
    );
    canvas.drawRect(Rect.fromLTRB(0, rect.top, rect.left, rect.bottom), shade);
    canvas.drawRect(
      Rect.fromLTRB(rect.right, rect.top, size.width, rect.bottom),
      shade,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final point in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(point, 8, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        8,
        Paint()
          ..color = Colors.teal.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.bounds != bounds;
}
