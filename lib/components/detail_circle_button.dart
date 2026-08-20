import 'package:flutter/material.dart';

class DetailCircleButton extends StatelessWidget {
  const DetailCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  const DetailCircleButton.back({super.key, required this.onTap})
    : icon = Icons.arrow_back;

  final IconData icon;
  final VoidCallback onTap;

  static const _background = Color(0xFFF8F7F0);
  static const _border = Color(0xFFEEEAD9);
  static const _foreground = Color(0xFF382F00);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _background,
          shape: BoxShape.circle,
          border: Border.all(color: _border),
        ),
        child: Icon(icon, size: 18, color: _foreground),
      ),
    );
  }
}
