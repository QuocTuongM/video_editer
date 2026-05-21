import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Card nền kính tối dùng thống nhất cho toàn bộ giao diện.
class AppGlassCard extends StatelessWidget {
  /// Khởi tạo [AppGlassCard].
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 28,
    this.gradient,
    this.onTap,
  });

  /// Nội dung bên trong card.
  final Widget child;

  /// Padding bên trong card.
  final EdgeInsetsGeometry padding;

  /// Margin bên ngoài card.
  final EdgeInsetsGeometry? margin;

  /// Bo góc card.
  final double borderRadius;

  /// Gradient nền tuỳ chọn.
  final Gradient? gradient;

  /// Callback khi nhấn card.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSoft.withValues(alpha: 0.76),
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}