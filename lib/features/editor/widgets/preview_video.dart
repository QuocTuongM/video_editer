import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart';

import '/core/services/auth_service.dart';
import '/core/services/local_video_repository.dart';
import '/features/editor/widgets/pixel_transparent_painter.dart';
import '/shared/widgets/app_loading_overlay.dart';
import '/shared/widgets/app_snack_bar.dart';

/// A widget that previews a video from a local file path or remote URL.
///
/// Displays the video and optionally shows when it was generated.
class PreviewVideo extends StatefulWidget {
  /// Creates a [PreviewVideo] widget.
  const PreviewVideo({
    super.key,
    required this.filePath,
    required this.generationTime,
  });

  /// The file path or remote URL of the video to be previewed.
  final String filePath;

  /// The time it took to generate the video preview.
  final Duration generationTime;

  @override
  State<PreviewVideo> createState() => _PreviewVideoState();
}

class _PreviewVideoState extends State<PreviewVideo> {
  final _valueStyle = const TextStyle(fontStyle: FontStyle.italic);

  late Future<VideoMetadata> _videoMetadata;
  late final int _generationTime = widget.generationTime.inMilliseconds;
  final _player = Player();
  late final _controller = VideoController(_player);

  final _numberFormatter = NumberFormat();

  /// Kiểm tra filePath là URL mạng hay file cục bộ.
  bool get _isRemoteUrl {
    final path = widget.filePath;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  void initState() {
    super.initState();

    // Nếu là URL mạng thì getMetadata dùng network, không dùng file
    if (_isRemoteUrl) {
      _videoMetadata = ProVideoEditor.instance.getMetadata(
        EditorVideo.network(widget.filePath),
      );
    } else {
      _videoMetadata = ProVideoEditor.instance.getMetadata(
        EditorVideo.file(widget.filePath),
      );
    }

    _initializePlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    // Media tự xử lý cả file:// và https:// — chỉ cần thêm prefix đúng
    final mediaUrl = _isRemoteUrl
        ? widget.filePath
        : 'file://${widget.filePath}';
    await _player.open(Media(mediaUrl), play: false);
  }

  String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    var size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  Future<void> _saveToProject(BuildContext context) async {
    final user = AuthService().currentUser;
    if (user == null) {
      AppSnackBar.warning(context, 'Đăng nhập để lưu vào Dự án!');
      return;
    }

    if (_isRemoteUrl) {
      AppSnackBar.info(context, 'Video đã lưu trong Dự án rồi!');
      return;
    }

    AppLoadingOverlay.show(context, message: 'Đang lưu vào Dự án...');
    try {
      final fileName = widget.filePath.split('/').last;
      await LocalVideoRepository().saveVideo(
        sourcePath: widget.filePath,
        type: 'edited',
        title: 'Video xuất ${DateTime.now().day}/${DateTime.now().month}',
        originalFileName: fileName,
      );
      AppLoadingOverlay.hide();
      if (!context.mounted) return;
      AppSnackBar.success(context, '✅ Đã lưu vào Dự án!');
    } catch (e) {
      AppLoadingOverlay.hide();
      if (!context.mounted) return;
      AppSnackBar.error(context, 'Lưu thất bại: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Theme(
          data: Theme.of(context),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Xem trước'),
              actions: [
                if (!_isRemoteUrl)
                  IconButton(
                    icon: const Icon(Icons.save_alt_rounded),
                    tooltip: 'Lưu vào Dự án',
                    onPressed: () => _saveToProject(context),
                  ),
              ],
            ),
            body: CustomPaint(
              painter: const PixelTransparentPainter(
                primary: Color.fromARGB(255, 17, 17, 17),
                secondary: Color.fromARGB(255, 36, 36, 37),
              ),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  _buildVideoPlayer(constraints),
                  _buildGenerationInfos(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer(BoxConstraints constraints) {
    return FutureBuilder<VideoMetadata>(
      future: _videoMetadata,
      builder: (context, snapshot) {
        final rawRatio = snapshot.data?.resolution.aspectRatio ?? 1.0;
        final aspectRatio = (rawRatio > 0) ? rawRatio : 16.0 / 9.0;
        final rotation = snapshot.data?.rotation ?? 0;

        final convertedRotation = rotation % 360;
        final is90DegRotated =
            convertedRotation == 90 || convertedRotation == 270;

        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        double width = maxWidth;
        double height = is90DegRotated
            ? width * aspectRatio
            : width / aspectRatio;

        if (height > maxHeight) {
          height = maxHeight;
          width = height * aspectRatio;
        }

        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Hero(
              tag: const ProImageEditorConfigs().heroTag,
              child: Video(
                key: const ValueKey('Preview-Video-Player'),
                controller: _controller,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenerationInfos() {
    const tableSpace = TableRow(
      children: [SizedBox(height: 3), SizedBox()],
    );
    return Positioned(
      top: 10,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(7),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            child: FutureBuilder<VideoMetadata>(
              future: _videoMetadata,
              builder: (context, snapshot) {
                final data = snapshot.data;

                if (data == null ||
                    snapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const CircularProgressIndicator.adaptive();
                }

                final resolution = data.resolution;
                final dimension =
                    '${_numberFormatter.format(resolution.width.round())}'
                    ' x '
                    '${_numberFormatter.format(resolution.height.round())}';

                return Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  children: [
                    if (_generationTime > 0)
                      TableRow(
                        children: [
                          const Text('Thời gian render'),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '${_numberFormatter.format(_generationTime)} ms',
                              style: _valueStyle,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    if (_generationTime > 0) tableSpace,
                    TableRow(
                      children: [
                        const Text('Kích thước'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            formatBytes(data.fileSize),
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    tableSpace,
                    TableRow(
                      children: [
                        const Text('Định dạng'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'video/${data.extension}',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    tableSpace,
                    TableRow(
                      children: [
                        const Text('Độ phân giải'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            dimension,
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    tableSpace,
                    TableRow(
                      children: [
                        const Text('Thời lượng'),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${data.duration.inSeconds} s',
                            style: _valueStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}