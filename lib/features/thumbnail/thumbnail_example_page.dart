import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

import '/core/theme/app_theme.dart';
import '/shared/widgets/app_snack_bar.dart';

/// Trang tạo hình thu nhỏ từ video.
class ThumbnailExamplePage extends StatefulWidget {
  /// Khởi tạo [ThumbnailExamplePage].
  const ThumbnailExamplePage({super.key});

  @override
  State<ThumbnailExamplePage> createState() => _ThumbnailExamplePageState();
}

class _ThumbnailExamplePageState extends State<ThumbnailExamplePage> {
  // Video
  EditorVideo? _video;
  String _videoName = '';
  VideoMetadata? _metadata;

  // Thumbnails
  List<MemoryImage> _thumbnails = [];
  List<MemoryImage> _keyFrames = [];
  MemoryImage? _firstFrame;
  MemoryImage? _lastFrame;

  // State
  bool _isLoading = false;
  String _loadingLabel = '';

  final int _frameCount = 8;
  final double _thumbSize = 72;
  final String _thumbnailTaskId = 'ThumbnailTaskId';
  final String _keyFramesTaskId = 'KeyFramesTaskId';

  bool get _hasVideo => _video != null;

  // ─── Chọn video ─────────────────────────────────────────────────────────

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final path = file.path;
    if (path == null) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Không đọc được file này.');
      return;
    }

    setState(() {
      _video = EditorVideo.file(path);
      _videoName = file.name;
      _metadata = null;
      _thumbnails = [];
      _keyFrames = [];
      _firstFrame = null;
      _lastFrame = null;
    });

    // Đọc metadata ngay
    await _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    if (_video == null) return;
    try {
      final meta = await ProVideoEditor.instance.getMetadata(_video!);
      if (!mounted) return;
      setState(() => _metadata = meta);
    } catch (_) {}
  }

  // ─── Tạo thumbnails ──────────────────────────────────────────────────────

  Future<void> _generateThumbnails() async {
    if (!_hasVideo) {
      AppSnackBar.warning(context, 'Chọn video trước!');
      return;
    }
    final pixelRatio1 = MediaQuery.devicePixelRatioOf(context);
    if (_metadata == null) await _loadMetadata();
    if (_metadata == null) return;

    setState(() {
      _isLoading = true;
      _loadingLabel = 'Đang tạo hình thu nhỏ...';
      _thumbnails = [];
    });

    try {
      final outputSize = _thumbSize * pixelRatio1;
      final raw = await ProVideoEditor.instance.getThumbnails(
        ThumbnailConfigs(
          id: _thumbnailTaskId,
          video: _video!,
          outputFormat: ThumbnailFormat.jpeg,
          timestamps: List.generate(
            _frameCount,
            (i) => Duration(
              milliseconds: (_metadata!.duration.inMilliseconds /
                      _frameCount *
                      i)
                  .toInt(),
            ),
          ),
          outputSize: Size(outputSize, outputSize),
          boxFit: ThumbnailBoxFit.cover,
        ),
      );

      if (!mounted) return;
      setState(() {
        _thumbnails = raw.map(MemoryImage.new).toList();
        _isLoading = false;
      });
      AppSnackBar.success(
        context,
        'Đã tạo ${raw.length} hình thu nhỏ!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.error(context, 'Lỗi tạo hình thu nhỏ: $e');
    }
  }

  Future<void> _generateKeyFrames() async {
    if (!_hasVideo) {
      AppSnackBar.warning(context, 'Chọn video trước!');
      return;
    }

    final pixelRatioKF = MediaQuery.devicePixelRatioOf(context);
    setState(() {
      _isLoading = true;
      _loadingLabel = 'Đang tạo keyframe...';
      _keyFrames = [];
    });

    try {
      final outputSize = _thumbSize * pixelRatioKF;
      final raw = await ProVideoEditor.instance.getKeyFrames(
        KeyFramesConfigs(
          id: _keyFramesTaskId,
          video: _video!,
          outputFormat: ThumbnailFormat.jpeg,
          maxOutputFrames: _frameCount,
          outputSize: Size(outputSize, outputSize),
          boxFit: ThumbnailBoxFit.cover,
        ),
      );

      if (!mounted) return;
      setState(() {
        _keyFrames = raw.map(MemoryImage.new).toList();
        _isLoading = false;
      });
      AppSnackBar.success(context, 'Đã tạo ${raw.length} keyframe!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.error(context, 'Lỗi tạo keyframe: $e');
    }
  }

  Future<void> _generateFirstFrame() async {
    if (!_hasVideo) {
      AppSnackBar.warning(context, 'Chọn video trước!');
      return;
    }

    final pixelRatio2 = MediaQuery.devicePixelRatioOf(context);
    setState(() {
      _isLoading = true;
      _loadingLabel = 'Đang tạo frame đầu...';
    });

    try {
      final outputSize = _thumbSize * 3 * pixelRatio2;
      final raw = await ProVideoEditor.instance.getSingleThumbnail(
        SingleThumbnailConfigs(
          video: _video!,
          outputFormat: ThumbnailFormat.jpeg,
          outputSize: Size(outputSize, outputSize),
          boxFit: ThumbnailBoxFit.cover,
          position: ThumbnailPosition.first,
        ),
      );

      if (!mounted) return;
      setState(() {
        if (raw != null) _firstFrame = MemoryImage(raw);
        _isLoading = false;
      });
      if (raw != null) {
        AppSnackBar.success(context, 'Đã tạo frame đầu tiên!');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.error(context, 'Lỗi: $e');
    }
  }

  Future<void> _generateLastFrame() async {
    if (!_hasVideo) {
      AppSnackBar.warning(context, 'Chọn video trước!');
      return;
    }
    final pixelRatio3 = MediaQuery.devicePixelRatioOf(context);
    if (_metadata == null) await _loadMetadata();
    if (_metadata == null) return;

    setState(() {
      _isLoading = true;
      _loadingLabel = 'Đang tạo frame cuối...';
    });

    try {
      final outputSize = _thumbSize * 3 * pixelRatio3;
      final raw = await ProVideoEditor.instance.getSingleThumbnail(
        SingleThumbnailConfigs(
          video: _video!,
          outputFormat: ThumbnailFormat.jpeg,
          outputSize: Size(outputSize, outputSize),
          boxFit: ThumbnailBoxFit.cover,
          position: ThumbnailPosition.last,
          videoDuration: _metadata!.duration,
        ),
      );

      if (!mounted) return;
      setState(() {
        if (raw != null) _lastFrame = MemoryImage(raw);
        _isLoading = false;
      });
      if (raw != null) {
        AppSnackBar.success(context, 'Đã tạo frame cuối cùng!');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.error(context, 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Hình thu nhỏ'),
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Chọn video ─────────────────────────────────────────
          _buildPickerCard(),
          const SizedBox(height: 16),

          if (_hasVideo) ...[
            // Metadata
            if (_metadata != null) _buildMetadataCard(),
            if (_metadata != null) const SizedBox(height: 16),

            // Loading indicator
            if (_isLoading) ...[
              _buildLoadingCard(),
              const SizedBox(height: 16),
            ],

            // Hình thu nhỏ theo thời gian
            _buildActionCard(
              title: 'Hình thu nhỏ theo thời gian',
              subtitle: 'Tạo $_frameCount ảnh phân bố đều theo thời lượng',
              icon: Icons.image_outlined,
              iconColor: AppTheme.primaryBlue,
              onTap: _isLoading ? null : _generateThumbnails,
              taskId: _thumbnailTaskId,
              result: _thumbnails.isNotEmpty
                  ? _buildThumbnailGrid(_thumbnails)
                  : null,
            ),
            const SizedBox(height: 12),

            // Keyframes
            _buildActionCard(
              title: 'Keyframe',
              subtitle: 'Tạo hình từ các khung hình quan trọng',
              icon: Icons.animation_rounded,
              iconColor: Colors.purple,
              onTap: _isLoading ? null : _generateKeyFrames,
              taskId: _keyFramesTaskId,
              result: _keyFrames.isNotEmpty
                  ? _buildThumbnailGrid(_keyFrames)
                  : null,
            ),
            const SizedBox(height: 12),

            // Frame đầu + cuối
            Row(
              children: [
                Expanded(
                  child: _buildSingleFrameCard(
                    title: 'Frame đầu tiên',
                    icon: Icons.first_page_rounded,
                    iconColor: Colors.green,
                    image: _firstFrame,
                    onTap: _isLoading ? null : _generateFirstFrame,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSingleFrameCard(
                    title: 'Frame cuối cùng',
                    icon: Icons.last_page_rounded,
                    iconColor: Colors.orange,
                    image: _lastFrame,
                    onTap: _isLoading ? null : _generateLastFrame,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Widgets ─────────────────────────────────────────────────────────────

  Widget _buildPickerCard() {
    return GestureDetector(
      onTap: _pickVideo,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hasVideo
              ? AppTheme.primaryBlue.withValues(alpha: 0.08)
              : AppTheme.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasVideo
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : AppTheme.border,
          ),
        ),
        child: _hasVideo
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.video_file_rounded,
                        color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _videoName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Nhấn để đổi video',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.swap_horiz_rounded,
                      color: AppTheme.primaryBlue),
                ],
              )
            : Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 44,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chọn video từ thiết bị',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nhấn để chọn video tạo hình thu nhỏ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    final meta = _metadata!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metaStat(
            Icons.timer_outlined,
            '${meta.duration.inSeconds}s',
          ),
          _metaStat(
            Icons.aspect_ratio_outlined,
            '${meta.resolution.width.round()}×'
            '${meta.resolution.height.round()}',
          ),
          if (meta.frameRate != null)
            _metaStat(
              Icons.speed_outlined,
              '${meta.frameRate!.toStringAsFixed(0)}fps',
            ),
        ],
      ),
    );
  }

  Widget _metaStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _loadingLabel,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback? onTap,
    required String taskId,
    Widget? result,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: result == null
                  ? BorderRadius.circular(16)
                  : const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress
                    StreamBuilder<ProgressModel>(
                      key: ValueKey(taskId),
                      stream: ProVideoEditor.instance
                          .progressStreamById(taskId),
                      builder: (ctx, snap) {
                        final p = snap.data?.progress ?? 0.0;
                        if (p <= 0 || p >= 1) {
                          return const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textSecondary,
                            size: 18,
                          );
                        }
                        return SizedBox(
                          width: 36,
                          height: 36,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: p,
                                strokeWidth: 2.5,
                                color: iconColor,
                              ),
                              Text(
                                '${(p * 100).toInt()}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: iconColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (result != null) ...[
            Divider(
              height: 1,
              color: AppTheme.border.withValues(alpha: 0.5),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: result,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleFrameCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required MemoryImage? image,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: image == null
                  ? BorderRadius.circular(16)
                  : const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (image != null) ...[
            Divider(
              height: 1,
              color: AppTheme.border.withValues(alpha: 0.5),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image(image: image, fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnailGrid(List<MemoryImage> images) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: images
          .map(
            (img) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: _thumbSize,
                height: _thumbSize,
                child: Image(image: img, fit: BoxFit.cover),
              ),
            ),
          )
          .toList(),
    );
  }
}