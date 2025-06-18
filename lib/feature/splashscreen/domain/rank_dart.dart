import 'package:flutter/material.dart';

class RankData {
  final String rank;
  final String title;
  final String subtitle;
  final String description;
  final String analogy;
  final int basePrice;
  final int maxPrice;
  final Color color;
  final IconData icon;

  RankData({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.analogy,
    required this.basePrice,
    required this.maxPrice,
    required this.color,
    required this.icon,
  });
}
