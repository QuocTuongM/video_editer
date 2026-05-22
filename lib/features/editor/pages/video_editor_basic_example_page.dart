import 'dart:async';
import 'dart:io' as io;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/core/platform/io/io_helper.dart';
import 'package:pro_video_editor/pro_video_editor.dart';
import 'package:pro_video_editor_example/features/editor/services/audio_helper_service.dart';
import 'package:video_player/video_player.dart' hide VideoAudioTrack;

import '/core/constants/example_audio_tracks_constant.dart';
import '/core/services/auth_service.dart';
import '/core/services/local_video_repository.dart';
import '/shared/widgets/app_loading_overlay.dart';
import '/shared/widgets/app_snack_bar.dart';
import '/shared/widgets/upload_progress_dialog.dart';
import '../widgets/clips_previewer.dart';
import '../widgets/preview_video.dart';
import '../widgets/video_initializing_widget.dart';
import '../widgets/video_progress_alert.dart';

/// Màn hình chọn video từ album và mở trình chỉnh sửa.
class VideoEditorBasicExamplePage extends StatefulWidget {
  /// Khởi tạo [VideoEditorBasicExamplePage].
  const VideoEditorBasicExamplePage({super.key});

  @override
  State<VideoEditorBasicExamplePage> createState() =>
      _VideoEditorBasicExamplePageState();
}

class _VideoEditorBasicExamplePageState
    extends State<VideoEditorBasicExamplePage> {
  final _editorKey = GlobalKey<ProImageEditorState>();
  final _taskId = DateTime.now().microsecondsSinceEpoch.toString();
  final _outputFormat = VideoOutputFormat.mp4;

  bool _isSeeking = false;
  TrimDurationSpan? _durationSpan;
  TrimDurationSpan? _tempDurationSpan;
  ProVideoController? _proVideoController;
  List<ImageProvider>? _thumbnails;
  late VideoMetadata _videoMetadata;
  final int _thumbnailCount = 7;

  /// Video đang dùng trong editor (được set sau khi chọn từ album).
  EditorVideo? _video;

  /// Tên file gốc (dùng để đặt tên khi upload).
  String _originalFileName = 'video';

  final _proVideoEditor = ProVideoEditor.instance;
  final _repo = LocalVideoRepository();
  final _auth = AuthService();

  String? _outputPath;
  final Map<String, Uint8List> _cachedKeyFrames = {};
  final Map<String, List<Uint8List>> _cachedKeyFrameList = {};

  Duration _videoGenerationTime = Duration.zero;
  VideoPlayerController? _videoController;

  AudioHelperService? _audioService;
  final _updateClipsNotifier = ValueNotifier(false);

  bool _isPicking = false;
  bool _isEditorReady = false;

  late ProImageEditorConfigs _configs;

  @override
  void initState() {
    super.initState();
    // Chọn video ngay khi vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndInit());
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioService?.dispose();
    _updateClipsNotifier.dispose();
    super.dispose();
  }

  // ─── Chọn video từ album ───────────────────────────────────────────────────

  Future<void> _pickAndInit() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final file = result.files.single;
      final path = file.path;

      if (path == null || path.isEmpty) {
        if (mounted) {
          AppSnackBar.error(context, 'Không thể đọc file này trên thiết bị.');
          Navigator.pop(context);
        }
        return;
      }

      _originalFileName = file.name;
      _video = EditorVideo.file(path);

      await _initializeEditor();
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Lỗi chọn video: $e');
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ─── Khởi tạo editor ───────────────────────────────────────────────────────

  Future<void> _initializeEditor() async {
    final video = _video;
    if (video == null) return;

    await _setMetadata();

    // Build configs sau khi có metadata
    _configs = _buildConfigs(video);

    _configs.clipsEditor.clips.first = _configs.clipsEditor.clips.first
        .copyWith(duration: _videoMetadata.duration);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateThumbnails();
    });

    final path = video.file?.path ?? '';
    final newController = io.File(path).existsSync()
        ? VideoPlayerController.file(io.File(path))
        : VideoPlayerController.asset('assets/demo.mp4');

    _audioService = AudioHelperService(videoController: newController);

    await Future.wait([
      newController.initialize(),
      newController.setLooping(false),
      newController.setVolume(
        _configs.videoEditor.initialMuted ? 0 : 100,
      ),
      _configs.videoEditor.initialPlay
          ? newController.play()
          : newController.pause(),
      _audioService!.initialize(),
    ]);

    if (!mounted) return;

    _videoController?.dispose();
    _videoController = newController;

    _proVideoController = ProVideoController(
      videoPlayer: _buildVideoPlayer(),
      initialResolution: _videoMetadata.resolution,
      videoDuration: _videoMetadata.duration,
      fileSize: _videoMetadata.fileSize,
      thumbnails: _thumbnails,
    );

    _videoController!.addListener(_onDurationChange);

    setState(() => _isEditorReady = true);
  }

  Future<void> _setMetadata() async {
    _videoMetadata = await _proVideoEditor.getMetadata(_video!);
  }

  ProImageEditorConfigs _buildConfigs(EditorVideo video) {
    return ProImageEditorConfigs(
      dialogConfigs: DialogConfigs(
        widgets: DialogWidgets(
          loadingDialog: (message, configs) =>
              VideoProgressAlert(taskId: _taskId),
        ),
      ),
      mainEditor: MainEditorConfigs(
        tools: [
          SubEditorMode.videoClips,
          SubEditorMode.audio,
          SubEditorMode.paint,
          SubEditorMode.text,
          SubEditorMode.cropRotate,
          SubEditorMode.tune,
          SubEditorMode.filter,
          SubEditorMode.blur,
          SubEditorMode.emoji,
          SubEditorMode.sticker,
        ],
        widgets: MainEditorWidgets(
          removeLayerArea:
              (removeAreaKey, editor, rebuildStream, isLayerBeingTransformed) =>
                  VideoEditorRemoveArea(
            removeAreaKey: removeAreaKey,
            editor: editor,
            rebuildStream: rebuildStream,
            isLayerBeingTransformed: isLayerBeingTransformed,
          ),
        ),
      ),
      paintEditor: const PaintEditorConfigs(
        tools: [
          PaintMode.freeStyle,
          PaintMode.arrow,
          PaintMode.line,
          PaintMode.rect,
          PaintMode.circle,
          PaintMode.dashLine,
          PaintMode.polygon,
          PaintMode.eraser,
        ],
      ),
      audioEditor: AudioEditorConfigs(audioTracks: kExampleAudioTracks),
      clipsEditor: ClipsEditorConfigs(
        clips: [
          VideoClip(
            id: '001',
            title: _originalFileName.split('.').first,
            duration: Duration.zero,
            clip: EditorVideoClip.autoSource(
              assetPath: video.assetPath,
              bytes: video.byteArray,
              file: video.file,
              networkUrl: video.networkUrl,
            ),
          ),
        ],
      ),
      videoEditor: const VideoEditorConfigs(
        initialMuted: false,
        initialPlay: false,
        isAudioSupported: true,
        minTrimDuration: Duration(seconds: 1),
        playTimeSmoothingDuration: Duration(milliseconds: 600),
      ),
      imageGeneration: const ImageGenerationConfigs(
        captureImageByteFormat: ImageByteFormat.rawStraightRgba,
      ),
    );
  }

  // ─── Thumbnails ────────────────────────────────────────────────────────────

  Future<void> _generateThumbnails({
    bool updateClipThumbnails = true,
  }) async {
    if (!mounted) return;

    final imageWidth =
        MediaQuery.sizeOf(context).width /
        _thumbnailCount *
        MediaQuery.devicePixelRatioOf(context);

    final duration = _videoMetadata.duration;
    final segmentDuration = duration.inMilliseconds / _thumbnailCount;

    final thumbnailList = await _proVideoEditor.getThumbnails(
      ThumbnailConfigs(
        video: _video!,
        outputSize: Size.square(imageWidth),
        boxFit: ThumbnailBoxFit.cover,
        timestamps: List.generate(_thumbnailCount, (i) {
          final ms = (i + 0.5) * segmentDuration;
          return Duration(milliseconds: ms.round());
        }),
        outputFormat: ThumbnailFormat.jpeg,
      ),
    );

    final temporaryThumbnails =
        thumbnailList.map(MemoryImage.new).toList();

    if (updateClipThumbnails && _configs.clipsEditor.clips.isNotEmpty) {
      _configs.clipsEditor.clips.first = _configs.clipsEditor.clips.first
          .copyWith(thumbnails: temporaryThumbnails);
    }

    if (!mounted) return;

    final cacheList = temporaryThumbnails.map(
      (item) => precacheImage(item, context),
    );
    await Future.wait(cacheList);
    _thumbnails = temporaryThumbnails;

    if (_proVideoController != null) {
      _proVideoController!.thumbnails = _thumbnails;
    }
  }

  // ─── Playback ──────────────────────────────────────────────────────────────

  void _onDurationChange() {
    final controller = _videoController;
    if (controller == null) return;

    final totalVideoDuration = _videoMetadata.duration;
    final duration = controller.value.position;
    _proVideoController!.setPlayTime(duration);

    if (_durationSpan != null && duration >= _durationSpan!.end) {
      _seekToPosition(_durationSpan!);
    } else if (duration >= totalVideoDuration) {
      _seekToPosition(
        TrimDurationSpan(start: Duration.zero, end: totalVideoDuration),
      );
    }
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;
    if (_isSeeking) {
      _tempDurationSpan = span;
      return;
    }
    _isSeeking = true;
    _proVideoController!.pause();
    _proVideoController!.setPlayTime(_durationSpan!.start);
    await _videoController!.pause();
    await _videoController!.seekTo(span.start);
    _isSeeking = false;

    if (_tempDurationSpan != null) {
      final nextSeek = _tempDurationSpan!;
      _tempDurationSpan = null;
      await _seekToPosition(nextSeek);
    }
  }

  // ─── Render video ──────────────────────────────────────────────────────────

  Future<void> _generateVideo(CompleteParameters parameters) async {
    final stopwatch = Stopwatch()..start();

    unawaited(_videoController?.pause());
    unawaited(_audioService?.pause());

    final directory = await getTemporaryDirectory();

    final AudioTrack? customAudioTrack =
        parameters.audioTracks.firstOrNull;
    final double volumeBalance =
        customAudioTrack?.volumeBalance ?? 0;
    double overlayVolume = 1;
    double originalVolume = 1;
    if (volumeBalance < 0) {
      overlayVolume += volumeBalance;
    } else {
      originalVolume -= volumeBalance;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final exportModel = VideoRenderData(
      id: _taskId,
      videoSegments: [
        VideoSegment(video: _video!, volume: originalVolume),
      ],
      outputFormat: _outputFormat,
      enableAudio: _proVideoController?.isAudioEnabled ?? true,
      imageLayers: parameters.layers.isNotEmpty
          ? [
              ImageLayer(
                image: EditorLayerImage.memory(parameters.image),
              ),
            ]
          : null,
      blur: parameters.blur,
      colorFilters: parameters.colorFilters
          .map((el) => ColorFilter(matrix: el))
          .toList(),
      startTime: parameters.startTime,
      endTime: parameters.endTime,
      transform: parameters.isTransformed
          ? ExportTransform(
              width: parameters.cropWidth,
              height: parameters.cropHeight,
              rotateTurns: parameters.rotateTurns,
              x: parameters.cropX,
              y: parameters.cropY,
              flipX: parameters.flipX,
              flipY: parameters.flipY,
            )
          : null,
      audioTracks: customAudioTrack != null
          ? [
              VideoAudioTrack(
                path: (await _audioService!.safeCustomAudioPath(
                  customAudioTrack,
                ))!,
                volume: overlayVolume,
              ),
            ]
          : [],
    );

    try {
      _outputPath = await ProVideoEditor.instance.renderVideoToFile(
        '${directory.path}/edited_${now}.mp4',
        exportModel,
      );
    } on RenderCanceledException {
      stopwatch.stop();
      _outputPath = null;
      _videoGenerationTime = Duration.zero;
      return;
    } catch (e) {
      stopwatch.stop();
      _outputPath = null;
      _videoGenerationTime = Duration.zero;
      if (mounted) {
        AppSnackBar.error(context, 'Render thất bại: $e');
      }
      return;
    }

    _videoGenerationTime = stopwatch.elapsed;
  }

  // ─── Sau khi render: preview + upload ─────────────────────────────────────

  void _handleCloseEditor(EditorMode editorMode) async {
    if (editorMode != EditorMode.main) return Navigator.pop(context);

    final outputPath = _outputPath;

    if (outputPath != null) {
      // 1. Mở preview
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewVideo(
            filePath: outputPath,
            generationTime: _videoGenerationTime,
          ),
        ),
      );
      _outputPath = null;

      // 2. Upload lên Firebase nếu đã đăng nhập
      if (_auth.isSignedIn) {
        await _uploadToFirebase(outputPath);
      } else {
        if (mounted) {
          AppSnackBar.warning(context, 'Đăng nhập để lưu video vào Dự án.');
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _uploadToFirebase(String filePath) async {
    if (!mounted) return;

    final title =
        _originalFileName.split('.').first.replaceAll('_', ' ');

    final result = await UploadProgressDialog.uploadVideo(
      context: context,
      sourcePath: filePath,
      type: 'edited',
      title: title,
      originalFileName: _originalFileName,
    );

    if (!mounted) return;
    if (result != null) {
      AppSnackBar.success(context, '✅ Đã lưu vào Dự án thành công!');
    }
  }

  // ─── Add clip ──────────────────────────────────────────────────────────────

  Future<VideoClip?> _addClip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null) return null;

    final title = file.name.split('.').first;
    LoadingDialog.instance.show(context, configs: _configs);
    final meta =
        await _proVideoEditor.getMetadata(EditorVideo.file(path));
    LoadingDialog.instance.hide();

    return VideoClip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      clip: EditorVideoClip.file(path),
      duration: meta.duration,
    );
  }

  // ─── Merge clips ───────────────────────────────────────────────────────────

  Future<void> _mergeClips(
    List<VideoClip> clips,
    void Function(double) onProgress,
  ) async {
    LoadingDialog.instance.show(context, configs: _configs);
    final directory = await getApplicationCacheDirectory();
    final updatedFile = io.File('${directory.path}/temp.mp4');

    _updateClipsNotifier.value = true;
    await _proVideoEditor.renderVideoToFile(
      updatedFile.path,
      VideoRenderData(
        id: _taskId,
        videoSegments: clips.map((el) {
          final clip = el.clip;
          return VideoSegment(
            video: EditorVideo.autoSource(
              networkUrl: clip.networkUrl,
              assetPath: clip.assetPath,
              byteArray: clip.bytes,
              file: clip.file,
            ),
            startTime: el.trimSpan?.start,
            endTime: el.trimSpan?.end,
          );
        }).toList(),
      ),
    );

    if (!mounted) {
      LoadingDialog.instance.hide();
      return;
    }

    _video = EditorVideo.file(updatedFile.path);

    await _setMetadata();
    await _generateThumbnails(updateClipThumbnails: false);
    await _initializeEditor();

    final editor = _editorKey.currentState!;

    _proVideoController = ProVideoController(
          videoPlayer: _buildVideoPlayer(),
          initialResolution: _videoMetadata.resolution,
          videoDuration: _videoMetadata.duration,
          fileSize: _videoMetadata.fileSize,
          thumbnails: _thumbnails,
        )
      ..initialize(
        configsFunction: () => _configs.videoEditor,
        callbacksAudioFunction: () =>
            editor.audioEditorCallbacks ??
            const AudioEditorCallbacks(),
        callbacksFunction: () =>
            editor.callbacks.videoEditorCallbacks ??
            VideoEditorCallbacks(),
      );

    final controller =
        VideoPlayerController.file(io.File(updatedFile.path));
    await controller.initialize();
    LoadingDialog.instance.hide();

    if (!mounted) return;

    _videoController = controller;
    _videoController!.addListener(_onDurationChange);
    editor.initializeVideoEditor();

    _updateClipsNotifier.value = false;
    setState(() {});
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Đang chọn video
    if (_isPicking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Chưa chọn được video
    if (_video == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 72,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 16),
              const Text('Không có video nào được chọn.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickAndInit,
                child: const Text('Chọn video'),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: (!_isEditorReady || _proVideoController == null)
          ? const VideoInitializingWidget()
          : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    return ProImageEditor.video(
      _proVideoController!,
      key: _editorKey,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: _generateVideo,
        onCloseEditor: _handleCloseEditor,
        videoEditorCallbacks: VideoEditorCallbacks(
          onPause: () => _videoController?.pause(),
          onPlay: () => _videoController?.play(),
          onMuteToggle: (isMuted) {
            if (isMuted) {
              _audioService?.setVolume(0);
              _videoController?.setVolume(0);
            } else {
              _audioService?.balanceAudio();
            }
          },
          onTrimSpanUpdate: (durationSpan) {
            if (_videoController?.value.isPlaying == true) {
              _proVideoController!.pause();
            }
          },
          onTrimSpanEnd: _seekToPosition,
        ),
        audioEditorCallbacks: AudioEditorCallbacks(
          onBalanceChange: _audioService!.balanceAudio,
          onStartTimeChange: (startTime) async {
            await Future.wait([
              _audioService!.seek(startTime),
              _videoController!.seekTo(Duration.zero),
            ]);
          },
          onPlay: _audioService!.play,
          onStop: (audio) => _audioService!.pause(),
        ),
        clipsEditorCallbacks: ClipsEditorCallbacks(
          onBuildPlayer: (controller, videoClip) {
            return ClipsPreviewer(
              videoConfigs: _configs.videoEditor,
              proController: controller,
              videoClip: videoClip,
            );
          },
          onMergeClips: _mergeClips,
          onReadKeyFrame: (source) async {
            if (_cachedKeyFrames.containsKey(source.id)) {
              return _cachedKeyFrames[source.id]!;
            }
            final result = await _proVideoEditor.getKeyFrames(
              KeyFramesConfigs(
                video: EditorVideo.autoSource(
                  assetPath: source.clip.assetPath,
                  byteArray: source.clip.bytes,
                  file: source.clip.file,
                  networkUrl: source.clip.networkUrl,
                ),
                outputSize: const Size.square(200),
                boxFit: ThumbnailBoxFit.cover,
                maxOutputFrames: 1,
                outputFormat: ThumbnailFormat.jpeg,
              ),
            );
            _cachedKeyFrames[source.id] = result.first;
            return result.first;
          },
          onReadKeyFrames: (source) async {
            if (_cachedKeyFrameList.containsKey(source.id)) {
              return _cachedKeyFrameList[source.id]!;
            }
            final result = await _proVideoEditor.getKeyFrames(
              KeyFramesConfigs(
                video: EditorVideo.autoSource(
                  assetPath: source.clip.assetPath,
                  byteArray: source.clip.bytes,
                  file: source.clip.file,
                  networkUrl: source.clip.networkUrl,
                ),
                outputSize: const Size.square(200),
                boxFit: ThumbnailBoxFit.cover,
                maxOutputFrames: _thumbnailCount,
                outputFormat: ThumbnailFormat.jpeg,
              ),
            );
            _cachedKeyFrameList[source.id] = result;
            return result;
          },
          onAddClip: _addClip,
        ),
      ),
      configs: _configs,
    );
  }

  Widget _buildVideoPlayer() {
    return ValueListenableBuilder(
      valueListenable: _updateClipsNotifier,
      builder: (_, isLoading, _) {
        return Center(
          child: isLoading
              ? const CircularProgressIndicator.adaptive()
              : AspectRatio(
                  aspectRatio:
                      _videoController!.value.size.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
        );
      },
    );
  }
}