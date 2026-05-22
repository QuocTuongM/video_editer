import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

import '/core/theme/app_theme.dart';
import '/shared/utils/bytes_formatter.dart';
import '/shared/utils/render_cancel_capability.dart';
import '/shared/widgets/app_loading_overlay.dart';
import '/shared/widgets/app_snack_bar.dart';
import '/shared/widgets/video_renderer_progress.dart';

/// Trang xuất video với các tuỳ chọn xử lý.
class VideoRendererPage extends StatefulWidget {
  /// Khởi tạo [VideoRendererPage].
  const VideoRendererPage({super.key});

  @override
  State<VideoRendererPage> createState() => _VideoRendererPageState();
}

class _VideoRendererPageState extends State<VideoRendererPage> {
  final _pve = ProVideoEditor.instance;

  late final _playerPreview = Player();
  late final _controllerPreview = VideoController(_playerPreview);

  bool _isExporting = false;
  bool _hasResult = false;
  Uint8List? _videoBytes;
  Duration _generationTime = Duration.zero;
  VideoMetadata? _outputMetadata;
  String _taskId = DateTime.now().microsecondsSinceEpoch.toString();

  // Video đã chọn
  EditorVideo? _video;
  String _videoName = '';

  bool get _supportsCancel => canCancelOnCurrentPlatform();
  bool get _hasVideo => _video != null;

  @override
  void dispose() {
    _playerPreview.dispose();
    super.dispose();
  }

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
      _videoBytes = null;
      _hasResult = false;
      _outputMetadata = null;
    });

    if (!mounted) return;
    AppSnackBar.success(context, 'Đã chọn: \${file.name}');
  }

  // ─── Xuất video ─────────────────────────────────────────────────────────

  Future<void> _export(VideoRenderData data) async {
    if (!_hasVideo) {
      AppSnackBar.warning(context, 'Chọn video trước khi xuất.');
      return;
    }

    _taskId = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _isExporting = true;
      _hasResult = false;
      _videoBytes = null;
    });

    final directory = await getTemporaryDirectory();
    final now = DateTime.now().millisecondsSinceEpoch;
    final ext = data.outputFormat.name;
    final outputPath = '${directory.path}/output_$now.$ext';
    final sp = Stopwatch()..start();

    try {
      await _pve.renderVideoToFile(outputPath, data.copyWith(id: _taskId));
    } on RenderCanceledException {
      setState(() => _isExporting = false);
      return;
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) AppSnackBar.error(context, 'Xuất thất bại: $e');
      return;
    }

    final resultBytes = File(outputPath).readAsBytesSync();
    _generationTime = sp.elapsed;

    _outputMetadata = await _pve.getMetadata(
      EditorVideo.memory(resultBytes),
      checkStreamingOptimization: true,
    );

    _videoBytes = resultBytes;
    _isExporting = false;
    _hasResult = true;
    setState(() {});

    await _playerPreview.open(Media(outputPath));
    await _playerPreview.play();
  }

  Future<void> _cancelRender() async {
    if (!_supportsCancel) return;
    try {
      await _pve.cancel(_taskId);
      setState(() {
        _isExporting = false;
        _videoBytes = null;
        _hasResult = false;
      });
    } catch (_) {}
  }

  // ─── Các loại xuất ──────────────────────────────────────────────────────

  Future<void> _exportNormal() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!)],
    ));
  }

  Future<void> _exportRotate() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!)],
      transform: const ExportTransform(rotateTurns: 1),
    ));
  }

  Future<void> _exportFlip() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!)],
      transform: const ExportTransform(flipX: true),
    ));
  }

  Future<void> _exportRemoveAudio() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!)],
      enableAudio: false,
    ));
  }

  Future<void> _exportHalfSpeed() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!)],
      playbackSpeed: 0.5,
    ));
  }

  Future<void> _exportDoubleSpeed() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!)],
      playbackSpeed: 2.0,
    ));
  }

  Future<void> _exportBlur() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!)],
      blur: 5,
    ));
  }

  Future<void> _export720p() async {
    await _export(VideoRenderData.withQualityPreset(
      videoSegments: [VideoSegment(video: _video!)],
      qualityPreset: VideoQualityPreset.p720,
    ));
  }

  Future<void> _export1080p() async {
    await _export(VideoRenderData.withQualityPreset(
      videoSegments: [VideoSegment(video: _video!)],
      qualityPreset: VideoQualityPreset.p1080,
    ));
  }

  Future<void> _exportLowVolume() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!, volume: 0.3)],
    ));
  }

  Future<void> _exportOptimizedStream() async {
    await _export(VideoRenderData(
      videoSegments: [VideoSegment(video: _video!)],
      shouldOptimizeForNetworkUse: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Xuất video'),
        backgroundColor: AppTheme.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Chọn video ─────────────────────────────────────────
            _buildPickerCard(),
            const SizedBox(height: 16),

            // ── Kết quả xuất ───────────────────────────────────────
            if (_isExporting) ...[
              _buildExportingCard(),
              const SizedBox(height: 16),
            ] else if (_hasResult && _videoBytes != null) ...[
              _buildResultCard(),
              const SizedBox(height: 16),
            ],

            // ── Danh sách tùy chọn xuất ────────────────────────────
            if (!_isExporting) _buildOptions(),
          ],
        ),
      ),
    );
  }

  // ─── Picker card ─────────────────────────────────────────────────────────

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
                    child: const Icon(
                      Icons.video_file_rounded,
                      color: AppTheme.primaryBlue,
                    ),
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
                        const SizedBox(height: 2),
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
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(
                    Icons.video_call_outlined,
                    size: 48,
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
                    'Nhấn để chọn video cần xuất',
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

  // ─── Exporting card ───────────────────────────────────────────────────────

  Widget _buildExportingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          VideoRendererProgressPanel(
            progressStream: _pve.progressStreamById(_taskId),
            supportsCancel: _supportsCancel,
            onCancel: _supportsCancel ? _cancelRender : null,
          ),
        ],
      ),
    );
  }

  // ─── Result card ──────────────────────────────────────────────────────────

  Widget _buildResultCard() {
    final meta = _outputMetadata;
    final bytes = _videoBytes!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: meta?.resolution.aspectRatio ?? 16 / 9,
              child: Video(controller: _controllerPreview),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Xuất thành công!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _statChip(
                      Icons.storage_outlined,
                      formatBytes(bytes.lengthInBytes),
                    ),
                    _statChip(
                      Icons.timer_outlined,
                      '${_generationTime.inMilliseconds}ms',
                    ),
                    if (meta != null) ...[
                      _statChip(
                        Icons.aspect_ratio_outlined,
                        '${meta.resolution.width.round()}×'
                        '${meta.resolution.height.round()}',
                      ),
                      if (meta.frameRate != null)
                        _statChip(
                          Icons.speed_outlined,
                          '${meta.frameRate!.toStringAsFixed(0)}fps',
                        ),
                    ],
                    if (meta?.isOptimizedForStreaming != null)
                      _statChip(
                        meta!.isOptimizedForStreaming!
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        meta.isOptimizedForStreaming!
                            ? 'Stream OK'
                            : 'Chưa tối ưu',
                        color: meta.isOptimizedForStreaming!
                            ? Colors.green
                            : Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text, {Color? color}) {
    final c = color ?? AppTheme.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: c,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── Options list ─────────────────────────────────────────────────────────

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Xuất cơ bản'),
        _exportTile(
          icon: Icons.upload_rounded,
          title: 'Xuất nguyên bản',
          subtitle: 'Giữ nguyên chất lượng gốc',
          onTap: _exportNormal,
          highlight: true,
        ),

        _sectionTitle('Biến đổi'),
        _exportTile(
          icon: Icons.rotate_90_degrees_ccw,
          title: 'Xoay 90°',
          subtitle: 'Xoay video sang phải 90 độ',
          onTap: _exportRotate,
        ),
        _exportTile(
          icon: Icons.flip_rounded,
          title: 'Lật ngang',
          subtitle: 'Lật video theo trục ngang',
          onTap: _exportFlip,
        ),

        _sectionTitle('Tốc độ'),
        _exportTile(
          icon: Icons.slow_motion_video_rounded,
          title: 'Chậm 0.5x',
          subtitle: 'Xuất với tốc độ 50% — slow motion',
          onTap: _exportHalfSpeed,
        ),
        _exportTile(
          icon: Icons.fast_forward_rounded,
          title: 'Nhanh 2x',
          subtitle: 'Xuất với tốc độ 200% — timelapse',
          onTap: _exportDoubleSpeed,
        ),

        _sectionTitle('Âm thanh'),
        _exportTile(
          icon: Icons.volume_off_rounded,
          title: 'Tắt tiếng',
          subtitle: 'Xuất video không có âm thanh',
          onTap: _exportRemoveAudio,
        ),
        _exportTile(
          icon: Icons.volume_down_rounded,
          title: 'Giảm âm lượng 30%',
          subtitle: 'Giữ video, giảm âm xuống 30%',
          onTap: _exportLowVolume,
        ),

        _sectionTitle('Hiệu ứng'),
        _exportTile(
          icon: Icons.blur_circular_outlined,
          title: 'Làm mờ',
          subtitle: 'Áp dụng hiệu ứng blur toàn video',
          onTap: _exportBlur,
        ),

        _sectionTitle('Chất lượng'),
        _exportTile(
          icon: Icons.sd_rounded,
          title: 'Xuất 720p HD',
          subtitle: 'Bitrate 3 Mbps — phù hợp mạng xã hội',
          onTap: _export720p,
        ),
        _exportTile(
          icon: Icons.high_quality_rounded,
          title: 'Xuất 1080p FHD',
          subtitle: 'Bitrate 8 Mbps — chất lượng cao',
          onTap: _export1080p,
        ),

        _sectionTitle('Tối ưu'),
        _exportTile(
          icon: Icons.cloud_upload_outlined,
          title: 'Tối ưu streaming',
          subtitle: 'Đặt moov trước mdat để stream nhanh hơn',
          onTap: _exportOptimizedStream,
        ),

        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
          const SizedBox(height: 8),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _exportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final color = highlight ? AppTheme.primaryBlue : AppTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _hasVideo ? onTap : () {
          AppSnackBar.warning(context, 'Chọn video trước!');
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: highlight
                ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                : AppTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight
                  ? AppTheme.primaryBlue.withValues(alpha: 0.25)
                  : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: highlight
                            ? AppTheme.primaryBlue
                            : AppTheme.textPrimary,
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
              Icon(
                Icons.chevron_right,
                color: _hasVideo
                    ? AppTheme.textSecondary
                    : AppTheme.textSecondary.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}