import 'package:flutter/material.dart';

/// Color Picker Component
/// 
/// A reusable color picker widget with:
/// - Material Design dialog
/// - Color history tracking
/// - Preset brand colors
/// - Real-time preview
class ColorPicker extends StatefulWidget {
  /// Currently selected color
  final Color initialColor;

  /// Callback when color changes
  final Function(Color) onColorChanged;

  /// Optional label for the picker
  final String? label;

  /// Optional description/hint text
  final String? description;

  /// Show color code input field
  final bool showColorCode;

  /// Enable color history tracking
  final bool enableHistory;

  /// Preset colors to display
  final List<Color>? presetColors;

  /// Custom width for the picker button
  final double buttonWidth;

  /// Custom height for the picker button
  final double buttonHeight;

  /// Show as filled or outlined button
  final bool filled;

  const ColorPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.label,
    this.description,
    this.showColorCode = true,
    this.enableHistory = true,
    this.presetColors,
    this.buttonWidth = 80,
    this.buttonHeight = 50,
    this.filled = true,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _selectedColor;
  late List<Color> _colorHistory;

  /// Default brand colors for AuraSphere
  static const List<Color> _defaultBrandColors = [
    Color(0xFF3A86FF), // Primary blue
    Color(0xFF8338EC), // Purple
    Color(0xFFFF006E), // Pink
    Color(0xFFFB5607), // Orange
    Color(0xFFFFBE0B), // Yellow
    Color(0xFF06FFA5), // Mint
    Color(0xFF1F77F2), // Dark blue
    Color(0xFF333333), // Dark gray
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Black
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _colorHistory = widget.enableHistory ? [widget.initialColor] : [];
  }

  /// Add color to history (max 10 colors)
  void _addToHistory(Color color) {
    if (!widget.enableHistory) return;

    if (!_colorHistory.contains(color)) {
      _colorHistory.add(color);
      if (_colorHistory.length > 10) {
        _colorHistory.removeAt(0);
      }
    }
  }

  /// Open color picker dialog
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.label ?? 'Pick a color'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPresetColors(),
                _buildColorCode(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addToHistory(_selectedColor);
                widget.onColorChanged(_selectedColor);
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  /// Build color preview box
  Widget _buildColorPreview() {
    return Container(
      width: widget.buttonWidth,
      height: widget.buttonHeight,
      decoration: BoxDecoration(
        color: _selectedColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showColorPicker,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Icon(
              Icons.palette,
              color: _selectedColor.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Build preset colors grid
  Widget _buildPresetColors() {
    final colors = widget.presetColors ?? _defaultBrandColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Brand Colors',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors
              .map(
                (color) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    _addToHistory(color);
                    widget.onColorChanged(color);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.black
                            : Colors.grey.shade300,
                        width: _selectedColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  /// Build color code display
  Widget _buildColorCode() {
    if (!widget.showColorCode) return const SizedBox.shrink();

    final hexColor = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Color Code',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            hexColor,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (widget.label != null) const SizedBox(height: 8),
        if (widget.description != null)
          Text(
            widget.description!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        if (widget.description != null) const SizedBox(height: 8),
        _buildColorPreview(),
      ],
    );
  }
}
