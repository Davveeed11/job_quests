import 'package:flutter/material.dart';

/// Helper Widget for Category Cards (for explore categories)
class CategoryCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final int jobCount; // Added jobCount parameter

  const CategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.jobCount, // jobCount is now required
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
    // This SnackBar is for demonstration. In a real app, this would likely
    // trigger navigation to a category-specific job listing page.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exploring ${widget.name} jobs')));
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Card(
          elevation: 7,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          color: Theme.of(
            context,
          ).colorScheme.surface, // Use theme surface color
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              // Changed from Row to Column
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center content vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center content horizontally
              children: [
                Icon(
                  widget.icon,
                  size: 40, // Increased icon size for prominence
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 14), // Increased spacing
                Text(
                  widget.name,
                  textAlign: TextAlign.center, // Center align text
                  style: TextStyle(
                    fontSize: 16, // Slightly increased font size
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.jobCount} jobs available', // Display job count
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
