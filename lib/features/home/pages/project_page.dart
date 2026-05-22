import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/local_video_repository.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../ai/pages/video_ai_page.dart';
import '../../auth/pages/auth_page.dart';
import '../../editor/widgets/preview_video.dart';

/// Màn hình danh sách dự án.
class ProjectPage extends StatefulWidget {
  /// Khởi tạo [ProjectPage].
  const ProjectPage({super.key, this.searchController});

  /// Controller tìm kiếm từ bên ngoài (tuỳ chọn).
  final TextEditingController? searchController;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late final TextEditingController _searchController =
      widget.searchController ?? TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';
  bool _sortNewest = true;

  @override
  void dispose() {
    // Chỉ dispose nếu tự tạo
    if (widget.searchController == null) _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return _buildLoginRequired(context);

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Dự án của tôi',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _sortNewest ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          size: 20,
                          color: Colors.grey,
                        ),
                        tooltip: _sortNewest ? 'Mới nhất' : 'Cũ nhất',
                        onPressed: () => setState(() => _sortNewest = !_sortNewest),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm video...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      _filterChip('Tất cả', 'all', Icons.perm_media_outlined),
                      const SizedBox(width: 8),
                      _filterChip('Video', 'video', Icons.video_file_outlined),
                      const SizedBox(width: 8),
                      _filterChip('Ảnh', 'image', Icons.image_outlined),
                      const SizedBox(width: 8),
                      _filterChip('Đã chỉnh', 'edited', Icons.movie_filter_outlined),
                    ],
                  ),
                ),
                Expanded(child: _buildVideoList(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String value, IconData icon) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 80, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                const Text(
                  'Đăng nhập để xem dự án',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Danh sách video được đồng bộ theo tài khoản.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Đăng nhập / Đăng ký'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoList(BuildContext context) {
    return StreamBuilder(
      stream: LocalVideoRepository().watchMyVideos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 12),
                Text('Không tải được dữ liệu',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data();
          final title = (data['title'] ?? '').toString().toLowerCase();
          final type = (data['type'] ?? 'original').toString();
          final mediaType = (data['mediaType'] ?? 'video').toString();
          final matchType = _filterType == 'all' ||
              _filterType == type ||
              (_filterType == 'video' && mediaType == 'video') ||
              (_filterType == 'image' && mediaType == 'image');
          final matchSearch = _searchQuery.isEmpty ||
              title.contains(_searchQuery.toLowerCase());
          return matchType && matchSearch;
        }).toList();

        if (allDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined, size: 80, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text('Chưa có dự án nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text('Tạo video mới để bắt đầu!',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text('Không tìm thấy kết quả',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() { _searchQuery = ''; _filterType = 'all'; });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _searchQuery.isNotEmpty || _filterType != 'all'
                    ? '\${filteredDocs.length} / \${allDocs.length} mục'
                    : '\${allDocs.length} mục',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: filteredDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data();
                  final title = (data['title'] ?? 'Không có tên').toString();
                  final type = (data['type'] ?? 'original').toString();
                  final downloadUrl = (data['downloadUrl'] ?? '').toString();
                  final storagePath = (data['storagePath'] ?? '').toString();
                  final sizeBytes = data['sizeBytes'] is int ? data['sizeBytes'] as int : 0;
                  final durationMs = data['durationMs'] is int ? data['durationMs'] as int : null;
                  final aiStatus = (data['aiContentStatus'] ?? 'idle').toString();

                  return Dismissible(
                    key: ValueKey(doc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) => _deleteVideo(context, doc.id, storagePath),
                    child: _VideoCard(
                      title: title,
                      type: type,
                      mediaType: (data['mediaType'] ?? 'video').toString(),
                      sizeBytes: sizeBytes,
                      durationMs: durationMs,
                      aiStatus: aiStatus,
                      searchQuery: _searchQuery,
                      onTap: () => _openVideo(context, downloadUrl),
                      onAiTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoAiPage(videoId: doc.id, videoTitle: title),
                        ),
                      ),
                      onShare: downloadUrl.isNotEmpty
                          ? () => _shareVideo(downloadUrl, title)
                          : null,
                      onRename: () => _renameItem(context, doc.id, title),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _shareVideo(String url, String title) {
    Share.share(
      'Đây là video "\$title" của tôi: \$url',
      subject: title,
    );
  }

  Future<void> _renameItem(
    BuildContext context,
    String docId,
    String currentTitle,
  ) async {
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Đổi tên', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) return;

    try {
      final user = AuthService().currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('videos')
          .doc(docId)
          .update({'title': newTitle, 'updatedAt': FieldValue.serverTimestamp()});
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Đã đổi tên thành công!');
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.error(context, 'Lỗi: \$e');
    }
  }

  Future<void> _openVideo(BuildContext context, String downloadUrl) async {
    if (downloadUrl.trim().isEmpty) {
      AppSnackBar.warning(context, 'Video chưa có đường dẫn hợp lệ.');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewVideo(filePath: downloadUrl, generationTime: Duration.zero),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa video?'),
        content: const Text('Video sẽ bị xóa khỏi hệ thống, không thể khôi phục.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVideo(BuildContext context, String videoId, String storagePath) async {
    try {
      await LocalVideoRepository().deleteVideo(videoId: videoId, storagePath: storagePath);
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Đã xóa video thành công.');
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.error(context, 'Không thể xóa: $e');
    }
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.title,
    required this.type,
    required this.mediaType,
    required this.sizeBytes,
    required this.durationMs,
    required this.aiStatus,
    required this.searchQuery,
    required this.onTap,
    required this.onAiTap,
    this.onShare,
    this.onRename,
  });

  final String title;
  final String type;
  final String mediaType;
  final int sizeBytes;
  final int? durationMs;
  final String aiStatus;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onAiTap;
  final VoidCallback? onShare;
  final VoidCallback? onRename;

  bool get _isImage => mediaType == 'image';

  @override
  Widget build(BuildContext context) {
    final isEdited = type == 'edited';
    final color = _isImage
        ? Colors.deepPurple
        : isEdited
            ? Colors.teal
            : Colors.blue;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isImage
                          ? Icons.image_outlined
                          : isEdited
                              ? Icons.movie_filter_outlined
                              : Icons.video_file_outlined,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHighlightedTitle(),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 10,
                          children: [
                            _chip(Icons.storage_outlined, _formatBytes(sizeBytes)),
                            if (durationMs != null)
                              _chip(Icons.timer_outlined,
                                  '${(durationMs! / 1000).toStringAsFixed(1)}s'),
                            _chip(
                              _isImage
                                  ? Icons.image_outlined
                                  : isEdited
                                      ? Icons.movie_filter_outlined
                                      : Icons.video_file_outlined,
                              _isImage
                                  ? 'Ảnh'
                                  : isEdited
                                      ? 'Đã chỉnh'
                                      : 'Gốc',
                              color: color,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onShare != null)
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          color: Colors.grey,
                          tooltip: 'Chia sẻ',
                          onPressed: onShare,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: Colors.grey,
                        tooltip: 'Đổi tên',
                        onPressed: onRename,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Icon(Icons.play_circle_outline, color: Colors.grey.shade600),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!_isImage) ...[
            Divider(height: 1, color: color.withValues(alpha: 0.15)),
            InkWell(
              onTap: onAiTap,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: _aiColor(aiStatus)),
                    const SizedBox(width: 8),
                    Text(
                      'AI Content — \${_aiStatusText(aiStatus)}',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _aiColor(aiStatus),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightedTitle() {
    if (searchQuery.isEmpty) {
      return Text(
        title,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final index = lowerTitle.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        title,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      text: TextSpan(
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        children: [
          TextSpan(text: title.substring(0, index)),
          TextSpan(
            text: title.substring(index, index + searchQuery.length),
            style: TextStyle(
              backgroundColor: Colors.amber.withValues(alpha: 0.4),
              color: Colors.amber,
            ),
          ),
          TextSpan(text: title.substring(index + searchQuery.length)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, {Color? color}) {
    final c = color ?? Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
  }

  Color _aiColor(String status) {
    switch (status) {
      case 'done': return Colors.greenAccent;
      case 'processing': return Colors.amber;
      case 'error': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _aiStatusText(String status) {
    switch (status) {
      case 'done': return 'Đã tạo';
      case 'processing': return 'Đang xử lý';
      case 'error': return 'Lỗi';
      default: return 'Chưa tạo';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < suffixes.length - 1) { value /= 1024; index++; }
    return '${value.toStringAsFixed(1)} ${suffixes[index]}';
  }
}