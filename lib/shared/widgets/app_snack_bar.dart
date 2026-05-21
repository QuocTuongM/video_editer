import 'package:flutter/material.dart';

/// Loại thông báo SnackBar.
enum SnackBarType { success, error, warning, info }

/// Helper hiển thị SnackBar đẹp thống nhất toàn app.
class AppSnackBar {
  AppSnackBar._();

  /// Hiển thị thông báo thành công.
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      _show(context, message, SnackBarType.success, duration);

  /// Hiển thị thông báo lỗi.
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) =>
      _show(context, message, SnackBarType.error, duration);

  /// Hiển thị thông báo cảnh báo.
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      _show(context, message, SnackBarType.warning, duration);

  /// Hiển thị thông báo thông tin.
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) =>
      _show(context, message, SnackBarType.info, duration);

  static void _show(
    BuildContext context,
    String message,
    SnackBarType type,
    Duration duration,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: _SnackBarContent(message: message, type: type),
        ),
      );
  }
}

class _SnackBarContent extends StatelessWidget {
  const _SnackBarContent({
    required this.message,
    required this.type,
  });

  final String message;
  final SnackBarType type;

  @override
  Widget build(BuildContext context) {
    final config = _config(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: config.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: config.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SnackConfig _config(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackConfig(
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF4ADE80),
          iconBgColor: const Color(0xFF4ADE80).withValues(alpha: 0.15),
          bgColor: const Color(0xFF0F2318),
          borderColor: const Color(0xFF4ADE80).withValues(alpha: 0.3),
          textColor: const Color(0xFFDCFCE7),
        );
      case SnackBarType.error:
        return _SnackConfig(
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFF87171),
          iconBgColor: const Color(0xFFF87171).withValues(alpha: 0.15),
          bgColor: const Color(0xFF1F0A0A),
          borderColor: const Color(0xFFF87171).withValues(alpha: 0.3),
          textColor: const Color(0xFFFEE2E2),
        );
      case SnackBarType.warning:
        return _SnackConfig(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFFBBF24),
          iconBgColor: const Color(0xFFFBBF24).withValues(alpha: 0.15),
          bgColor: const Color(0xFF1F1506),
          borderColor: const Color(0xFFFBBF24).withValues(alpha: 0.3),
          textColor: const Color(0xFFFEF3C7),
        );
      case SnackBarType.info:
        return _SnackConfig(
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFF60A5FA),
          iconBgColor: const Color(0xFF60A5FA).withValues(alpha: 0.15),
          bgColor: const Color(0xFF0A1628),
          borderColor: const Color(0xFF60A5FA).withValues(alpha: 0.3),
          textColor: const Color(0xFFDBEAFE),
        );
    }
  }
}

class _SnackConfig {
  const _SnackConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
}