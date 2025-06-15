import 'package:flutter/material.dart';

class TextFieldWidget extends StatefulWidget {
  final String hint;
  final int maxLines;
  final void Function(String)? onchange;
  final TextEditingController controller;
  final bool isPassword; // New property to indicate if it's a password field
  final TextInputType keyboardType;

  const TextFieldWidget({
    super.key,
    required this.hint,
    required this.onchange,
    required this.controller,
    this.isPassword = false, // Default to false
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  // State to manage the visibility of the text, specific to this widget
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    // Initialize _obscureText based on the isPassword property
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    // Define consistent border styles using theme colors
    OutlineInputBorder defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        width: 1.0,
      ), // Themed border color
    );

    OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 2.0,
      ),
    );

    return TextField(
      onChanged: widget.onchange,
      controller: widget.controller,
      obscureText: _obscureText, // Use the internal state for obscuring text
      keyboardType: widget.keyboardType,
      cursorColor: Theme.of(context).colorScheme.primary,
      maxLines: widget.maxLines,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
      ), // Text input color
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ), // Themed hint color
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surface, // Use theme surface for fill color
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
        border: defaultBorder,
        enabledBorder: defaultBorder,
        focusedBorder: focusedBorder,
        suffixIcon:
            widget
                .isPassword // Only show suffix icon if it's a password field
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6), // Themed icon color
                ),
                onPressed: () {
                  // Toggle the visibility state
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null, // No suffix icon for non-password fields
      ),
    );
  }
}
