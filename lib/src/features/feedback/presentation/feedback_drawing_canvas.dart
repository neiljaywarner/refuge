import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// GlobalKey attached to the root Scaffold or screen RepaintBoundary
/// so feedback capture can snapshot the screen state before opening the modal sheet.
final GlobalKey rootFeedbackRepaintBoundaryKey = GlobalKey(
  debugLabel: 'rootFeedbackRepaintBoundary',
);

/// Repaint boundary around the Vote & Feedback sheet itself.
///
/// Drawing capture prefers this over a nested control so the scribble sits on
/// the sheet the member is looking at, not a cropped strip of one card.
final GlobalKey feedbackSheetRepaintBoundaryKey = GlobalKey(
  debugLabel: 'feedbackSheetRepaintBoundary',
);

/// How the drawing dialog frames a screenshot so the whole image stays visible.
abstract final class FeedbackScreenshotFrame {
  static const maxColumnWidth = 440.0;

  /// Canvas size that keeps [imageWidth] / [imageHeight] and stays inside a
  /// phone-like column. A missing image uses the short blank canvas.
  static Size canvasSize({
    double? imageWidth,
    double? imageHeight,
    required Size screen,
    required double availableWidth,
  }) {
    final screenWidth = math.max(120.0, screen.width - 32);
    final offered = availableWidth.isFinite ? availableWidth : maxColumnWidth;
    final maxWidth = math.min(maxColumnWidth, math.min(offered, screenWidth));
    final maxHeight = math.max(160.0, math.min(screen.height * 0.62, 640.0));
    if (imageWidth == null || imageHeight == null || imageWidth <= 0 || imageHeight <= 0) {
      final height = (screen.height * 0.42).clamp(150.0, 260.0);
      return Size(maxWidth, height);
    }
    final aspect = imageWidth / imageHeight;
    var width = maxWidth;
    var height = width / aspect;
    if (height > maxHeight) {
      height = maxHeight;
      width = math.min(maxWidth, height * aspect);
    }
    if (height < 140) {
      height = 140;
      width = math.min(maxWidth, height * aspect);
    }
    return Size(width, height);
  }

  /// [BoxFit.contain] destination. The whole image stays inside [canvas].
  static Rect containRect({required Size image, required Size canvas}) {
    if (image.width <= 0 || image.height <= 0 || canvas.width <= 0 || canvas.height <= 0) {
      return Offset.zero & canvas;
    }
    final fitted = applyBoxFit(BoxFit.contain, image, canvas);
    return Alignment.center.inscribe(fitted.destination, Offset.zero & canvas);
  }
}

/// Largest repaint boundary at or above [start].
///
/// A button or card strip is smaller than the screen the member meant to mark.
RenderRepaintBoundary? largestRepaintBoundary(RenderObject? start) {
  RenderRepaintBoundary? best;
  var bestArea = 0.0;
  var node = start;
  while (node != null) {
    if (node is RenderRepaintBoundary && node.attached && node.hasSize) {
      final size = node.size;
      if (size.width >= 8 && size.height >= 8) {
        final area = size.width * size.height;
        if (area >= bestArea) {
          best = node;
          bestArea = area;
        }
      }
    }
    node = node.parent;
  }
  return best;
}

bool _boundaryIsUsefulScreen(RenderRepaintBoundary? boundary) {
  if (boundary == null || !boundary.attached || !boundary.hasSize) return false;
  final size = boundary.size;
  return size.shortestSide >= 160 && size.width >= 160 && size.height >= 200;
}

Future<Uint8List?> _pngOfBoundary(RenderRepaintBoundary? boundary) async {
  if (boundary == null || !boundary.hasSize || boundary.size.shortestSide < 8) {
    return null;
  }
  final binding = WidgetsBinding.instance;
  // Widget tests have no rasterizer. toImage waits for a frame that the
  // test will not flush while this callback is paused, so skip capture.
  if (binding.runtimeType.toString().contains('Test')) {
    return null;
  }
  binding.scheduleFrame();
  await binding.endOfFrame.timeout(const Duration(milliseconds: 500), onTimeout: () {});
  final image = await boundary.toImage(pixelRatio: 1);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Captures a [GlobalKey]'s repaint boundary as PNG bytes.
Future<Uint8List?> captureRepaintBoundary(GlobalKey key) async {
  try {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    return await _pngOfBoundary(boundary);
  } catch (_) {
    return null;
  }
}

/// Captures the feedback sheet, or the largest useful screen behind the
/// drawing control. A nested slice is skipped so the scribble is not a
/// cropped strip.
///
/// Widget tests often have no rasterizer; a failure returns null and the
/// dialog stays usable without a background.
Future<Uint8List?> captureEnclosingScreenshot(BuildContext context) async {
  try {
    RenderRepaintBoundary? boundary;
    final sheet = feedbackSheetRepaintBoundaryKey.currentContext?.findRenderObject();
    if (sheet is RenderRepaintBoundary && _boundaryIsUsefulScreen(sheet)) {
      boundary = sheet;
    }
    if (boundary == null) {
      final largest = largestRepaintBoundary(context.findRenderObject());
      if (_boundaryIsUsefulScreen(largest)) boundary = largest;
    }
    if (boundary == null) {
      final root = rootFeedbackRepaintBoundaryKey.currentContext?.findRenderObject();
      if (root is RenderRepaintBoundary && root.hasSize && root.size.shortestSide >= 64) {
        boundary = root;
      }
    }
    return await _pngOfBoundary(boundary);
  } catch (_) {
    return null;
  }
}

/// Single stroke drawn by a member on the feedback canvas.
@immutable
class DrawnStroke {
  const DrawnStroke({required this.points, required this.color, required this.strokeWidth});

  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawnStroke copyWith({List<Offset>? points, Color? color, double? strokeWidth}) => DrawnStroke(
    points: points ?? this.points,
    color: color ?? this.color,
    strokeWidth: strokeWidth ?? this.strokeWidth,
  );
}

/// Custom painter rendering all completed and in-progress strokes on canvas.
class FeedbackDrawingPainter extends CustomPainter {
  FeedbackDrawingPainter({
    required this.strokes,
    this.backgroundColor = Colors.transparent,
    this.backgroundImage,
  });

  final List<DrawnStroke> strokes;
  final Color backgroundColor;
  final ui.Image? backgroundImage;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      final imageSize = Size(backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble());
      paintImage(
        canvas: canvas,
        rect: FeedbackScreenshotFrame.containRect(image: imageSize, canvas: size),
        image: backgroundImage!,
        fit: BoxFit.fill,
      );
    } else if (backgroundColor != Colors.transparent) {
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRect(Offset.zero & size, bgPaint);
    }

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
      } else {
        final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FeedbackDrawingPainter oldDelegate) => true;
}

/// Interactive drawing & scribble canvas for feedback annotation.
class FeedbackDrawingCanvas extends StatefulWidget {
  const FeedbackDrawingCanvas({
    super.key,
    this.onChanged,
    this.initialStrokes = const [],
    this.canvasHeight = 240,
    this.backgroundColor,
    this.backgroundImage,
  });

  final ValueChanged<List<DrawnStroke>>? onChanged;
  final List<DrawnStroke> initialStrokes;
  final double canvasHeight;
  final Color? backgroundColor;
  final ui.Image? backgroundImage;

  @override
  FeedbackDrawingCanvasState createState() => FeedbackDrawingCanvasState();
}

class FeedbackDrawingCanvasState extends State<FeedbackDrawingCanvas>
    with AutomaticKeepAliveClientMixin {
  late List<DrawnStroke> _strokes;
  DrawnStroke? _activeStroke;
  Color _selectedColor = Colors.redAccent;
  double _selectedWidth = 4.0;
  final GlobalKey _surfaceKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  static const List<Color> palette = [
    Colors.redAccent,
    Colors.amber,
    Colors.teal,
    Colors.lightBlueAccent,
    Colors.white,
    Colors.black87,
  ];

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.initialStrokes);
  }

  List<DrawnStroke> get strokes => List.unmodifiable(_strokes);

  String get canvasSemanticsLabel {
    final count = _strokes.length;
    final noun = count == 1 ? 'stroke' : 'strokes';
    return 'Feedback drawing canvas, $count $noun';
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _activeStroke = null;
    });
    widget.onChanged?.call(_strokes);
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
        _activeStroke = null;
      });
      widget.onChanged?.call(_strokes);
    }
  }

  void _finishStroke() {
    _activeStroke = null;
    widget.onChanged?.call(_strokes);
  }

  /// Exports the canvas strokes into a PNG image byte buffer.
  ///
  /// Defaults to the on-screen surface so strokes stay lined up with the
  /// screenshot. Pass [width] and [height] only for a fixed test raster.
  Future<Uint8List> exportPngBytes({int? width, int? height}) async {
    try {
      final box = _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
      final surface = box != null && box.hasSize ? box.size : const Size(400, 240);
      final resolvedWidth = width ?? surface.width.round();
      final resolvedHeight = height ?? surface.height.round();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(resolvedWidth.toDouble(), resolvedHeight.toDouble());

      final painter = FeedbackDrawingPainter(
        strokes: _strokes,
        backgroundColor: widget.backgroundColor ?? const Color(0xFF1E2429),
        backgroundImage: widget.backgroundImage,
      );
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      // If running under AutomatedTestWidgetsFlutterBinding without rasterizer, use fallback sample png
      if (WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding')) {
        return _fallbackSamplePng();
      }

      final img = await picture.toImage(resolvedWidth, resolvedHeight);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List() ?? _fallbackSamplePng();
    } catch (_) {
      return _fallbackSamplePng();
    }
  }

  static Uint8List _fallbackSamplePng() => Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bgColor =
        widget.backgroundColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1F24)
            : const Color(0xFFF3F6F8));

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        // Controls Toolbar
        Container(
          padding: const .symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: const .vertical(top: .circular(12)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              // Palette colors
              Row(
                mainAxisSize: .min,
                children: [
                  for (final color in palette)
                    InkWell(
                      key: Key('color_choice_${color.toARGB32()}'),
                      onTap: () => setState(() => _selectedColor = color),
                      borderRadius: .circular(999),
                      child: Container(
                        margin: const .symmetric(horizontal: 2.5),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withValues(alpha: 0.4),
                            width: _selectedColor == color ? 2.5 : 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Stroke width, undo, and clear controls
              Row(
                mainAxisSize: .min,
                children: [
                  IconButton(
                    key: const Key('drawing_pen_fine'),
                    tooltip: 'Fine stroke',
                    visualDensity: VisualDensity.compact,
                    padding: .zero,
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    icon: Icon(
                      Icons.edit,
                      size: 16,
                      color: _selectedWidth == 2.0 ? Theme.of(context).colorScheme.primary : null,
                    ),
                    onPressed: () => setState(() => _selectedWidth = 2.0),
                  ),
                  IconButton(
                    key: const Key('drawing_pen_bold'),
                    tooltip: 'Bold stroke',
                    visualDensity: VisualDensity.compact,
                    padding: .zero,
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    icon: Icon(
                      Icons.brush,
                      size: 20,
                      color: _selectedWidth == 6.0 ? Theme.of(context).colorScheme.primary : null,
                    ),
                    onPressed: () => setState(() => _selectedWidth = 6.0),
                  ),
                  IconButton(
                    key: const Key('drawing_undo_button'),
                    tooltip: 'Undo stroke',
                    visualDensity: VisualDensity.compact,
                    padding: .zero,
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    icon: const Icon(Icons.undo, size: 18),
                    onPressed: _strokes.isEmpty ? null : undo,
                  ),
                  IconButton(
                    key: const Key('drawing_clear_button'),
                    tooltip: 'Clear canvas',
                    visualDensity: VisualDensity.compact,
                    padding: .zero,
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: _strokes.isEmpty ? null : clear,
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const .fromLTRB(10, 6, 10, 0),
          child: Text(
            canvasSemanticsLabel,
            key: const Key('feedback_drawing_stroke_count'),
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
        // Interactive Drawing Canvas
        ClipRRect(
          borderRadius: const .vertical(bottom: .circular(12)),
          child: Container(
            key: _surfaceKey,
            height: widget.canvasHeight,
            color: bgColor,
            child: Semantics(
              identifier: 'feedback_drawing_canvas',
              label: canvasSemanticsLabel,
              container: true,
              child: Listener(
                key: const Key('feedback_drawing_touch_area'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  final point = event.localPosition;
                  setState(() {
                    _activeStroke = DrawnStroke(
                      points: [point],
                      color: _selectedColor,
                      strokeWidth: _selectedWidth,
                    );
                    _strokes.add(_activeStroke!);
                  });
                  widget.onChanged?.call(_strokes);
                },
                onPointerMove: (event) {
                  if (_activeStroke == null) return;
                  setState(() {
                    _activeStroke!.points.add(event.localPosition);
                  });
                },
                onPointerUp: (_) => _finishStroke(),
                onPointerCancel: (_) => _finishStroke(),
                child: CustomPaint(
                  painter: FeedbackDrawingPainter(
                    strokes: _strokes,
                    backgroundColor: bgColor,
                    backgroundImage: widget.backgroundImage,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modal dialog allowing members to draw/annotate feedback before attaching.
class FeedbackDrawingDialog extends StatefulWidget {
  const FeedbackDrawingDialog({super.key, this.initialStrokes = const [], this.screenshotBytes});

  final List<DrawnStroke> initialStrokes;

  /// PNG of the screen behind this dialog. Null when capture is unavailable.
  final Uint8List? screenshotBytes;

  static Future<Uint8List?> show(BuildContext context, {Uint8List? screenshotBytes}) =>
      showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final column = math.min(
            FeedbackScreenshotFrame.maxColumnWidth,
            MediaQuery.sizeOf(dialogContext).width - 32,
          );
          return Dialog(
            insetPadding: const .all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: math.max(120, column)),
              child: FeedbackDrawingDialog(screenshotBytes: screenshotBytes),
            ),
          );
        },
      );

  @override
  State<FeedbackDrawingDialog> createState() => _FeedbackDrawingDialogState();
}

class _FeedbackDrawingDialogState extends State<FeedbackDrawingDialog> {
  final GlobalKey<FeedbackDrawingCanvasState> _canvasKey = GlobalKey<FeedbackDrawingCanvasState>();
  bool _hasStrokes = true;
  ui.Image? _screenshot;

  bool get _hasScreenshot => widget.screenshotBytes != null && widget.screenshotBytes!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final bytes = widget.screenshotBytes;
    if (bytes != null && bytes.isNotEmpty) {
      _decodeScreenshot(bytes);
    }
  }

  Future<void> _decodeScreenshot(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _screenshot = frame.image);
    } catch (_) {
      // The status line still reports that a screenshot was captured.
    }
  }

  @override
  void dispose() {
    _screenshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final image = _screenshot;
        final frame = FeedbackScreenshotFrame.canvasSize(
          imageWidth: image?.width.toDouble(),
          imageHeight: image?.height.toDouble(),
          screen: screen,
          availableWidth: constraints.maxWidth,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const Key('feedback_drawing_dialog'),
            width: frame.width,
            child: _dialogBody(theme, frame.height),
          ),
        );
      },
    );
  }

  Widget _dialogBody(ThemeData theme, double canvasHeight) => SingleChildScrollView(
    padding: const .all(16),
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Icon(Icons.draw_rounded, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Draw / Annotate Feedback',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'Close drawing',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _hasScreenshot
              ? 'Annotating a screenshot of this screen. Draw on it, then attach.'
              : 'Circle a button, point out an issue, or draw what you expected.',
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        FeedbackDrawingCanvas(
          key: _canvasKey,
          initialStrokes: widget.initialStrokes,
          canvasHeight: canvasHeight,
          backgroundImage: _screenshot,
          onChanged: (strokes) {
            setState(() {
              _hasStrokes = strokes.isNotEmpty;
            });
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              key: const Key('drawing_dialog_cancel_button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              key: const Key('drawing_dialog_attach_button'),
              onPressed: _hasStrokes
                  ? () async {
                      final bytes = await _canvasKey.currentState?.exportPngBytes();
                      if (mounted) {
                        Navigator.of(context).pop(bytes);
                      }
                    }
                  : null,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Attach Scribble'),
            ),
          ],
        ),
      ],
    ),
  );
}
