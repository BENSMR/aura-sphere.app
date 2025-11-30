import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Watermark Painter Component
/// 
/// Custom painter for rendering watermarks with:
/// - Diagonal text watermarks
/// - Customizable opacity and angle
/// - Font and size control
/// - Color customization
/// - Real-time preview
/// - PDF-ready rendering
class WatermarkPainter extends CustomPainter {
  /// Text to display as watermark
  final String text;

  /// Color of the watermark
  final Color color;

  /// Opacity (0-1)
  final double opacity;

  /// Font size
  final double fontSize;

  /// Rotation angle in degrees
  final double angle;

  /// Font style (normal, italic, etc.)
  final FontStyle fontStyle;

  /// Font weight
  final FontWeight fontWeight;

  /// Background color (optional)
  final Color? backgroundColor;

  /// Stroke width for outlined text
  final double strokeWidth;

  /// Use stroke instead of fill
  final bool useStroke;

  WatermarkPainter({
    required this.text,
    this.color = const Color(0xFFCCCCCC),
    this.opacity = 0.3,
    this.fontSize = 48,
    this.angle = -45,
    this.fontStyle = FontStyle.normal,
    this.fontWeight = FontWeight.normal,
    this.backgroundColor,
    this.strokeWidth = 0,
    this.useStroke = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background if provided
    if (backgroundColor != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor!,
      );
    }

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withOpacity(opacity),
          fontSize: fontSize,
          fontStyle: fontStyle,
          fontWeight: fontWeight,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Calculate center position
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Save canvas state
    canvas.save();

    // Translate to center and rotate
    canvas.translate(centerX, centerY);
    canvas.rotate((angle * math.pi) / 180);

    // Draw text
    if (useStroke && strokeWidth > 0) {
      _drawTextStroke(canvas, textPainter, strokeWidth);
    } else {
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
    }

    // Restore canvas state
    canvas.restore();
  }

  /// Draw text with stroke effect
  void _drawTextStroke(Canvas canvas, TextPainter textPainter, double width) {
    // Create stroked version
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.angle != angle ||
        oldDelegate.fontStyle != fontStyle ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.useStroke != useStroke;
  }
}

/// Watermark Preview Widget
/// 
/// Display a live preview of watermark with customization options
class WatermarkPreview extends StatefulWidget {
  /// Initial watermark text
  final String initialText;

  /// Callback when watermark settings change
  final Function(String, Color, double, double) onWatermarkChanged;

  /// Optional label
  final String? label;

  const WatermarkPreview({
    super.key,
    required this.initialText,
    required this.onWatermarkChanged,
    this.label,
  });

  @override
  State<WatermarkPreview> createState() => _WatermarkPreviewState();
}

class _WatermarkPreviewState extends State<WatermarkPreview> {
  late TextEditingController _textController;
  late Color _watermarkColor;
  late double _opacity;
  late double _fontSize;
  late double _angle;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _watermarkColor = const Color(0xFFCCCCCC);
    _opacity = 0.3;
    _fontSize = 48;
    _angle = -45;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Notify parent of changes
  void _notifyChanges() {
    widget.onWatermarkChanged(
      _textController.text,
      _watermarkColor,
      _opacity,
      _angle,
    );
  }

  /// Build text input field
  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: 'Watermark Text',
        hintText: 'Enter watermark text',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.text_fields),
        suffixIcon: _textController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _textController.clear();
                  setState(() {});
                  _notifyChanges();
                },
              )
            : null,
      ),
      onChanged: (value) {
        setState(() {});
        _notifyChanges();
      },
      maxLength: 50,
    );
  }

  /// Build opacity slider
  Widget _buildOpacitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Opacity',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${(_opacity * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _opacity,
          onChanged: (value) {
            setState(() => _opacity = value);
            _notifyChanges();
          },
          min: 0.1,
          max: 1.0,
          divisions: 9,
        ),
      ],
    );
  }

  /// Build font size slider
  Widget _buildFontSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Font Size',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${_fontSize.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _fontSize,
          onChanged: (value) {
            setState(() => _fontSize = value);
            _notifyChanges();
          },
          min: 20,
          max: 80,
          divisions: 12,
        ),
      ],
    );
  }

  /// Build angle slider
  Widget _buildAngleSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Angle',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${_angle.toStringAsFixed(0)}°',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _angle,
          onChanged: (value) {
            setState(() => _angle = value);
            _notifyChanges();
          },
          min: -90,
          max: 90,
          divisions: 18,
        ),
      ],
    );
  }

  /// Build color picker button
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Pick Watermark Color'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Simple color palette
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          const Color(0xFF000000),
                          const Color(0xFF808080),
                          const Color(0xFFCCCCCC),
                          const Color(0xFFFFFFFF),
                          const Color(0xFF3A86FF),
                          const Color(0xFF8338EC),
                          const Color(0xFFFF006E),
                          const Color(0xFFFB5607),
                        ]
                            .map(
                              (color) => GestureDetector(
                                onTap: () {
                                  setState(() => _watermarkColor = color);
                                  _notifyChanges();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _watermarkColor == color
                                          ? Colors.black
                                          : Colors.grey.shade300,
                                      width:
                                          _watermarkColor == color ? 3 : 1,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _watermarkColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.palette, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Build preview canvas
  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: CustomPaint(
        painter: WatermarkPainter(
          text: _textController.text.isEmpty ? widget.initialText : _textController.text,
          color: _watermarkColor,
          opacity: _opacity,
          fontSize: _fontSize,
          angle: _angle,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (widget.label != null) const SizedBox(height: 16),
        const Text(
          'Preview',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        _buildPreview(),
        const SizedBox(height: 24),
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextInput(),
        const SizedBox(height: 24),
        _buildColorPicker(),
        const SizedBox(height: 24),
        _buildOpacitySlider(),
        const SizedBox(height: 24),
        _buildFontSizeSlider(),
        const SizedBox(height: 24),
        _buildAngleSlider(),
      ],
    );
  }
}
