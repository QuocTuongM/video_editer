import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/utils/bytes_formatter.dart';
import '../../shared/widgets/app_loading_overlay.dart';
import '../../shared/widgets/app_snack_bar.dart';

/// Màn hình xem thông tin chi tiết của video.
class VideoMetadataExamplePage extends StatefulWidget {
  /// Khởi tạo [VideoMetadataExamplePage].
  const VideoMetadataExamplePage({super.key});

  @override
  State<VideoMetadataExamplePage> createState() =>
      _VideoMetadataExamplePageState();
}

class _VideoMetadataExamplePageState
    extends State<VideoMetadataExamplePage> {
  VideoMetadata? _metadata;
  String? _fileName;
  final _numberFormatter = NumberFormat();

  Future<void> _pickAndReadMetadata() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final path = file.path;

    if (path == null || path.isEmpty) {
      if (mounted) {
        AppSnackBar.error(context, 'Không thể đọc file này.');
      }
      return;
    }

    if (!mounted) return;
    AppLoadingOverlay.show(context, message: 'Đang đọc thông tin...');

    try {
      final metadata = await ProVideoEditor.instance.getMetadata(
        EditorVideo.file(path),
        checkStreamingOptimization: true,
      );

      AppLoadingOverlay.hide();

      if (!mounted) return;
      setState(() {
        _metadata = metadata;
        _fileName = file.name;
      });
    } catch (e) {
      AppLoadingOverlay.hide();
      if (mounted) {
        AppSnackBar.error(context, 'Không thể đọc thông tin: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Thông tin video'),
        backgroundColor: AppTheme.background,
        actions: [
          if (_metadata != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Chọn video khác',
              onPressed: _pickAndReadMetadata,
            ),
        ],
      ),
      body: _metadata == null
          ? _buildEmptyState()
          : _buildMetadataView(),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 52,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Xem thông tin video',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn một video từ thiết bị để xem\nthông số kỹ thuật chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _pickAndReadMetadata,
              icon: const Icon(Icons.video_file_outlined),
              label: const Text('Chọn video'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Metadata view ────────────────────────────────────────────────────────

  Widget _buildMetadataView() {
    final meta = _metadata!;
    final res = meta.resolution;
    final isPortrait = res.height > res.width;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // File header
        _buildFileHeader(meta),
        const SizedBox(height: 16),

        // Video thumbnail placeholder + resolution
        _buildResolutionCard(meta, isPortrait),
        const SizedBox(height: 16),

        // Nhóm: Thông tin cơ bản
        _buildSection(
          title: 'Thông tin cơ bản',
          icon: Icons.video_file_outlined,
          items: [
            _InfoItem('Định dạng', meta.extension.toUpperCase(),
                icon: Icons.extension_outlined),
            _InfoItem('Kích thước', formatBytes(meta.fileSize),
                icon: Icons.storage_outlined),
            _InfoItem(
              'Thời lượng',
              _formatDuration(meta.duration),
              icon: Icons.timer_outlined,
            ),
            if (meta.audioDuration != null)
              _InfoItem(
                'Thời lượng âm thanh',
                _formatDuration(meta.audioDuration!),
                icon: Icons.audiotrack_outlined,
              )
            else
              _InfoItem('Âm thanh', 'Không có',
                  icon: Icons.volume_off_outlined),
          ],
        ),
        const SizedBox(height: 12),

        // Nhóm: Kỹ thuật
        _buildSection(
          title: 'Thông số kỹ thuật',
          icon: Icons.tune_rounded,
          items: [
            _InfoItem(
              'Độ phân giải',
              '${res.width.round()} × ${res.height.round()} px',
              icon: Icons.aspect_ratio_outlined,
            ),
            _InfoItem(
              'Hướng',
              isPortrait ? 'Dọc (Portrait)' : 'Ngang (Landscape)',
              icon: isPortrait
                  ? Icons.stay_current_portrait_outlined
                  : Icons.stay_current_landscape_outlined,
            ),
            _InfoItem('Góc xoay', '${meta.rotation}°',
                icon: Icons.rotate_right_outlined),
            if (meta.frameRate != null)
              _InfoItem(
                'Frame rate',
                '${meta.frameRate!.toStringAsFixed(2)} fps',
                icon: Icons.speed_outlined,
              ),
            _InfoItem(
              'Bitrate',
              '${_numberFormatter.format(meta.bitrate)} bps',
              icon: Icons.bar_chart_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Nhóm: Streaming
        _buildSection(
          title: 'Tối ưu hóa',
          icon: Icons.rocket_launch_outlined,
          items: [
            _InfoItem(
              'Streaming',
              meta.isOptimizedForStreaming == null
                  ? 'Không áp dụng'
                  : meta.isOptimizedForStreaming!
                      ? 'Đã tối ưu ✅'
                      : 'Chưa tối ưu ❌',
              icon: Icons.stream_outlined,
              highlight: meta.isOptimizedForStreaming == false,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Nhóm: Metadata bổ sung
        if (_hasExtraMetadata(meta))
          _buildSection(
            title: 'Thông tin bổ sung',
            icon: Icons.label_outline,
            items: [
              if (meta.date != null)
                _InfoItem('Ngày tạo', _formatDate(meta.date!),
                    icon: Icons.calendar_today_outlined),
              if (meta.title.isNotEmpty)
                _InfoItem('Tiêu đề', meta.title,
                    icon: Icons.title_outlined),
              if (meta.artist.isNotEmpty)
                _InfoItem('Nghệ sĩ', meta.artist,
                    icon: Icons.person_outline),
              if (meta.author.isNotEmpty)
                _InfoItem('Tác giả', meta.author,
                    icon: Icons.edit_outlined),
              if (meta.album.isNotEmpty)
                _InfoItem('Album', meta.album,
                    icon: Icons.album_outlined),
              if (meta.cameraMake.isNotEmpty)
                _InfoItem('Hãng máy quay', meta.cameraMake,
                    icon: Icons.camera_outlined),
              if (meta.cameraModel.isNotEmpty)
                _InfoItem('Model máy quay', meta.cameraModel,
                    icon: Icons.videocam_outlined),
              if (meta.gpsCoordinates != null)
                _InfoItem(
                  'GPS',
                  '${meta.gpsCoordinates!.latitude.toStringAsFixed(4)}, '
                      '${meta.gpsCoordinates!.longitude.toStringAsFixed(4)}',
                  icon: Icons.location_on_outlined,
                ),
            ],
          ),

        const SizedBox(height: 24),

        // Nút chọn video khác
        OutlinedButton.icon(
          onPressed: _pickAndReadMetadata,
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Chọn video khác'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFileHeader(VideoMetadata meta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.video_file_rounded,
              color: AppTheme.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? 'Video',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                Text(
                  '${meta.extension.toUpperCase()} · '
                  '${formatBytes(meta.fileSize)} · '
                  '${_formatDuration(meta.duration)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(VideoMetadata meta, bool isPortrait) {
    final res = meta.resolution;
    final quality = _getQualityLabel(res.height.round());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.15),
            AppTheme.cyanBlue.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Aspect ratio visual
          Container(
            width: isPortrait ? 36 : 64,
            height: isPortrait ? 64 : 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              isPortrait
                  ? Icons.stay_current_portrait
                  : Icons.stay_current_landscape,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${res.width.round()} × ${res.height.round()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (quality != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.cyanBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          quality,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.cyanBlue,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isPortrait ? 'Hướng dọc' : 'Hướng ngang',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_InfoItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildInfoRow(item),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 48,
                      color: AppTheme.border.withValues(alpha: 0.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return InkWell(
      onLongPress: () => _copyToClipboard(item.value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.highlight
                          ? Colors.red
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.copy_outlined,
              size: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String value) {
    Clipboard.setData(ClipboardData(text: value));
    AppSnackBar.info(context, 'Đã copy: $value');
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  bool _hasExtraMetadata(VideoMetadata meta) {
    return meta.date != null ||
        meta.title.isNotEmpty ||
        meta.artist.isNotEmpty ||
        meta.author.isNotEmpty ||
        meta.album.isNotEmpty ||
        meta.cameraMake.isNotEmpty ||
        meta.cameraModel.isNotEmpty ||
        meta.gpsCoordinates != null;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}g ${m}p ${s}s';
    if (m > 0) return '${m}p ${s}s';
    return '${s}s';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String? _getQualityLabel(int height) {
    if (height >= 2160) return '4K';
    if (height >= 1440) return '2K';
    if (height >= 1080) return 'FHD';
    if (height >= 720) return 'HD';
    if (height >= 480) return 'SD';
    return null;
  }
}

class _InfoItem {
  const _InfoItem(
    this.label,
    this.value, {
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
}