import 'package:flutter/material.dart';

/// Text field that keeps focus across parent rebuilds while syncing external
/// document updates (e.g. Accept AI suggestion).
class BuilderBoundField extends StatefulWidget {
  const BuilderBoundField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<BuilderBoundField> createState() => _BuilderBoundFieldState();
}

class _BuilderBoundFieldState extends State<BuilderBoundField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant BuilderBoundField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: widget.maxLines > 1,
      ),
    );
  }
}
