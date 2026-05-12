import 'package:flutter/material.dart';

/// Widget hiển thị một công cụ trong grid
class ToolItemWidget extends StatelessWidget {
  /// Khởi tạo [ToolItemWidget]
  const ToolItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  /// Icon hiển thị
  final IconData icon;

  /// Nhãn hiển thị bên dưới icon
  final String label;

  /// Màu sắc của công cụ
  final Color color;

  /// Hàm xử lý khi nhấn
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}