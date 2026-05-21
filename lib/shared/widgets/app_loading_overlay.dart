import 'package:flutter/material.dart';

/// Overlay loading toàn màn hình dùng chung.
///
/// Dùng qua [AppLoadingOverlay.show] và [AppLoadingOverlay.hide].
class AppLoadingOverlay {
  AppLoadingOverlay._();

  static OverlayEntry? _entry;

  /// Hiện loading overlay với [message] tuỳ chọn.
  static void show(
    BuildContext context, {
    String message = 'Đang xử lý...',
  }) {
    hide(); // Đảm bảo không có overlay cũ
    _entry = OverlayEntry(
      builder: (_) => _LoadingOverlayWidget(message: message),
    );
    Overlay.of(context).insert(_entry!);
  }

  /// Ẩn loading overlay.
  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _LoadingOverlayWidget extends StatelessWidget {
  const _LoadingOverlayWidget({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 28,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2F80FF),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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

/// Widget bọc nội dung với loading state tích hợp.
///
/// Dùng khi muốn block tương tác trong 1 phần màn hình.
class AppLoadingWrapper extends StatelessWidget {
  /// Khởi tạo [AppLoadingWrapper].
  const AppLoadingWrapper({
    super.key,
    required this.isLoading,
    required this.child,
    this.message = 'Đang xử lý...',
  });

  /// Có đang loading không.
  final bool isLoading;

  /// Widget con bên trong.
  final Widget child;

  /// Thông báo hiện khi loading.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2F80FF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}