import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pro_video_editor_example/features/auth/pages/auth_page.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/local_video_repository.dart';
import '../../../shared/widgets/app_loading_overlay.dart';
import '../../../shared/widgets/app_snack_bar.dart';

/// Trang upload video lên Firebase (dành cho nền tảng Web).
class UploadVideoPage extends StatefulWidget {
  /// Khởi tạo [UploadVideoPage].
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final _repo = LocalVideoRepository();

  PlatformFile? _pickedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.single);
  }

  Future<void> _upload() async {
    final file = _pickedFile;
    if (file == null) return;

    final user = AuthService().currentUser;
    if (user == null) {
      if (!mounted) return;
      AppSnackBar.warning(context, 'Bạn cần đăng nhập trước.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.1;
    });

    try {
      final title = file.name.split('.').first;
      await _repo.savePlatformFileVideo(
        file: file,
        type: 'original',
        title: title,
      );

      setState(() => _uploadProgress = 1.0);

      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Upload thành công! Video đã lưu vào Dự án.',
      );
      setState(() {
        _pickedFile = null;
        _uploadProgress = 0;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Upload thất bại: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: const Text('Tải video lên')),
          body: AppLoadingWrapper(
            isLoading: _isUploading,
            message: 'Đang tải lên... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Chọn video từ máy để lưu vào Firebase Storage.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: _isUploading ? null : _pickVideo,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: _pickedFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 56,
                                    color: Colors.blue.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Nhấn để chọn video',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'MP4, MOV, AVI, WEBM...',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )
                            : _buildFilePreview(_pickedFile!),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (user == null)
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthPage(),
                          ),
                        ),
                        icon: const Icon(Icons.login),
                        label: const Text('Đăng nhập để upload'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: (_pickedFile == null || _isUploading)
                            ? null
                            : _upload,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload video'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),

                    if (_pickedFile != null && !_isUploading) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => setState(() => _pickedFile = null),
                        child: const Text('Chọn video khác'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilePreview(PlatformFile file) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_file_outlined,
              size: 48, color: Colors.blue.shade400),
          const SizedBox(height: 10),
          Text(
            file.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatBytes(file.size),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '✓ Sẵn sàng upload',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < suffixes.length - 1) {
      value /= 1024;
      index++;
    }
    return '${value.toStringAsFixed(1)} ${suffixes[index]}';
  }
}