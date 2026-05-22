import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/local_video_repository.dart';

/// Hiển thị dialog progress khi upload video/ảnh lên Firebase.
///
/// Ví dụ dùng:
/// ```dart
/// await UploadProgressDialog.uploadVideo(
///   context: context,
///   sourcePath: filePath,
///   type: 'edited',
///   title: 'Video của tôi',
///   originalFileName: 'video.mp4',
/// );
/// ```
class UploadProgressDialog extends StatefulWidget {
  const UploadProgressDialog._({
    required this.uploadFuture,
    required this.fileName,
  });

  final Future<String> Function(void Function(double) onProgress) uploadFuture;
  final String fileName;

  /// Upload video và hiển thị dialog progress.
  static Future<String?> uploadVideo({
    required BuildContext context,
    required String sourcePath,
    required String type,
    required String title,
    required String originalFileName,
    int? durationMs,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UploadProgressDialog._(
        fileName: originalFileName,
        uploadFuture: (onProgress) => LocalVideoRepository().saveVideo(
          sourcePath: sourcePath,
          type: type,
          title: title,
          originalFileName: originalFileName,
          durationMs: durationMs,
          onProgress: onProgress,
        ),
      ),
    );
  }

  /// Upload ảnh và hiển thị dialog progress.
  static Future<String?> uploadImage({
    required BuildContext context,
    required Uint8List bytes,
    required String title,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UploadProgressDialog._(
        fileName: title,
        uploadFuture: (onProgress) => LocalVideoRepository().saveImage(
          bytes: bytes,
          title: title,
          onProgress: onProgress,
        ),
      ),
    );
  }

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  double _progress = 0;
  bool _isDone = false;
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    try {
      final docId = await widget.uploadFuture((p) {
        if (mounted) setState(() => _progress = p);
      });
      if (!mounted) return;
      setState(() => _isDone = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, docId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isDone || _hasError,
      child: Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasError
                      ? AppTheme.danger.withValues(alpha: 0.1)
                      : _isDone
                          ? Colors.green.withValues(alpha: 0.1)
                          : AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _hasError
                    ? const Icon(Icons.error_outline,
                        color: AppTheme.danger, size: 32)
                    : _isDone
                        ? const Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 32)
                        : const Icon(Icons.cloud_upload_outlined,
                            color: AppTheme.primaryBlue, size: 32),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                _hasError
                    ? 'Upload thất bại'
                    : _isDone
                        ? 'Đã lưu thành công!'
                        : 'Đang tải lên...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // File name
              Text(
                widget.fileName,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              if (_hasError) ...[
                // Error message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _errorMsg,
                    style: const TextStyle(
                      color: AppTheme.danger,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text('Đóng'),
                ),
              ] else ...[
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _isDone ? 1.0 : _progress,
                    backgroundColor: AppTheme.surfaceHigh,
                    color: _isDone ? Colors.green : AppTheme.primaryBlue,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),

                // Percent + label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isDone
                          ? 'Hoàn thành ✅'
                          : _progress < 0.01
                              ? 'Đang chuẩn bị...'
                              : 'Đang upload lên Firebase...',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(_isDone ? 1.0 : _progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isDone ? Colors.green : AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}