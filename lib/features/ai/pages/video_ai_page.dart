import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_glass_card.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../services/gemini_ai_service.dart';

/// Trang tạo AI Title / Description / Hashtag cho từng video.
class VideoAiPage extends StatefulWidget {
  /// Khởi tạo [VideoAiPage].
  const VideoAiPage({
    super.key,
    required this.videoId,
    required this.videoTitle,
  });

  /// ID document video trong Firestore.
  final String videoId;

  /// Tên video hiển thị.
  final String videoTitle;

  @override
  State<VideoAiPage> createState() => _VideoAiPageState();
}

class _VideoAiPageState extends State<VideoAiPage>
    {
  final _transcriptController = TextEditingController();
  final _geminiService = GeminiAiService();
  bool _isGenerating = false;
  bool _hasLoadedTranscript = false;

  @override
  void dispose() {
    _transcriptController.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _videoRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Bạn cần đăng nhập.');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('videos')
        .doc(widget.videoId);
  }

  Future<void> _generateAiContent() async {
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) {
      AppSnackBar.warning(
        context,
        'Hãy nhập transcript hoặc mô tả nội dung video trước.',
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      await _videoRef.update({
        'aiContentStatus': 'processing',
        'aiError': '',
        'transcriptText': transcript,
        'aiUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final result = await _geminiService.generateVideoContent(
        transcript: transcript,
        videoTitle: widget.videoTitle,
      );

      await _videoRef.update({
        'aiContentStatus': 'done',
        'aiError': '',
        'transcriptText': transcript,
        'aiTitle': result.mainTitle,
        'aiTitles': result.titles,
        'aiDescription': result.description,
        'aiHashtags': result.hashtags,
        'aiUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      AppSnackBar.success(context, '✅ Đã tạo nội dung AI thành công!');
    } catch (e) {
      await _videoRef.update({
        'aiContentStatus': 'error',
        'aiError': e.toString(),
        'aiUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      AppSnackBar.error(context, 'Lỗi tạo AI: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveTranscript() async {
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) {
      AppSnackBar.warning(context, 'Transcript đang rỗng.');
      return;
    }
    try {
      await _videoRef.update({
        'transcriptText': transcript,
        'aiUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      AppSnackBar.success(context, 'Đã lưu transcript.');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Không lưu được: $e');
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.info(context, 'Đã copy $label!');
  }

  void _copyAll({
    required List<String> titles,
    required String description,
    required List<String> hashtags,
  }) {
    final buffer = StringBuffer();
    if (titles.isNotEmpty) {
      buffer.writeln('=== TITLES ===');
      for (var t in titles) {
        buffer.writeln('• $t');
      }
      buffer.writeln();
    }
    if (description.isNotEmpty) {
      buffer.writeln('=== DESCRIPTION ===');
      buffer.writeln(description);
      buffer.writeln();
    }
    if (hashtags.isNotEmpty) {
      buffer.writeln('=== HASHTAGS ===');
      buffer.write(hashtags.join(' '));
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppSnackBar.success(context, 'Đã copy tất cả nội dung AI!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Content'),
        backgroundColor: AppTheme.background,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _videoRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.danger),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(
              child: Text(
                'Không tìm thấy video.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final transcriptText =
              (data['transcriptText'] ?? '').toString();
          final aiContentStatus =
              (data['aiContentStatus'] ?? 'idle').toString();
          final aiError = (data['aiError'] ?? '').toString();
          final aiTitle = (data['aiTitle'] ?? '').toString();
          final aiDescription =
              (data['aiDescription'] ?? '').toString();
          final aiTitles = data['aiTitles'] is List
              ? List<String>.from(data['aiTitles'] as List)
              : <String>[];
          final aiHashtags = data['aiHashtags'] is List
              ? List<String>.from(data['aiHashtags'] as List)
              : <String>[];
          final aiUpdatedAt = data['aiUpdatedAt'] as Timestamp?;
          final hasDone = aiContentStatus == 'done';

          if (!_hasLoadedTranscript && transcriptText.isNotEmpty) {
            _transcriptController.text = transcriptText;
            _hasLoadedTranscript = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Header video ───────────────────────────────────────
              AppGlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.video_file_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.videoTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _StatusChip(
                                status: aiContentStatus,
                                isAnimating: _isGenerating,
                              ),
                              if (aiUpdatedAt != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(aiUpdatedAt.toDate()),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Nút Copy All
                    if (hasDone)
                      Tooltip(
                        message: 'Copy tất cả',
                        child: IconButton(
                          icon: const Icon(
                            Icons.file_copy_outlined,
                            color: AppTheme.cyanBlue,
                          ),
                          onPressed: () => _copyAll(
                            titles: aiTitles.isNotEmpty
                                ? aiTitles
                                : [aiTitle],
                            description: aiDescription,
                            hashtags: aiHashtags,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (aiError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiError,
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── Transcript input ───────────────────────────────────
              AppGlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Transcript / Mô tả',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_transcriptController.text.isNotEmpty)
                          Text(
                            '${_transcriptController.text.length} ký tự',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nhập lời thoại hoặc mô tả nội dung video để AI tạo nội dung.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _transcriptController,
                      minLines: 5,
                      maxLines: 10,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        height: 1.5,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'Ví dụ: Video hướng dẫn nấu phở gà với các bước chi tiết từ luộc gà, hầm xương, đến trình bày...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isGenerating ? null : _saveTranscript,
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text('Lưu'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isGenerating
                                ? null
                                : _generateAiContent,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              _isGenerating
                                  ? 'Đang tạo...'
                                  : hasDone
                                      ? 'Tạo lại'
                                      : 'Tạo nội dung AI',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Kết quả AI ─────────────────────────────────────────
              if (_isGenerating)
                _buildGeneratingPlaceholder()
              else if (hasDone) ...[
                // Titles
                _buildResultCard(
                  title: 'Tiêu đề gợi ý',
                  icon: Icons.title_rounded,
                  iconColor: AppTheme.primaryBlue,
                  onCopyAll: () => _copy(
                    (aiTitles.isNotEmpty ? aiTitles : [aiTitle])
                        .join('\n'),
                    'tất cả tiêu đề',
                  ),
                  child: Column(
                    children: (aiTitles.isNotEmpty
                            ? aiTitles
                            : [aiTitle])
                        .where((t) => t.isNotEmpty)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => _buildTitleItem(e.key + 1, e.value))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                _buildResultCard(
                  title: 'Mô tả',
                  icon: Icons.description_outlined,
                  iconColor: Colors.green,
                  onCopyAll: aiDescription.isNotEmpty
                      ? () => _copy(aiDescription, 'mô tả')
                      : null,
                  child: aiDescription.isEmpty
                      ? const Text(
                          'Chưa có mô tả.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        )
                      : SelectableText(
                          aiDescription,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            height: 1.6,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // Hashtags
                _buildResultCard(
                  title: 'Hashtags',
                  icon: Icons.tag_rounded,
                  iconColor: Colors.purple,
                  onCopyAll: aiHashtags.isNotEmpty
                      ? () => _copy(aiHashtags.join(' '), 'tất cả hashtag')
                      : null,
                  child: aiHashtags.isEmpty
                      ? const Text(
                          'Chưa có hashtag.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: aiHashtags
                              .map((tag) => _buildHashtagChip(tag))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 12),

                // Copy All button
                OutlinedButton.icon(
                  onPressed: () => _copyAll(
                    titles:
                        aiTitles.isNotEmpty ? aiTitles : [aiTitle],
                    description: aiDescription,
                    hashtags: aiHashtags,
                  ),
                  icon: const Icon(Icons.file_copy_outlined),
                  label: const Text('Copy tất cả nội dung AI'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: AppTheme.cyanBlue,
                    side: BorderSide(
                      color: AppTheme.cyanBlue.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ] else ...[
                // Idle state
                _buildIdleState(),
              ],

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ─── Result card ────────────────────────────────────────────────────────

  Widget _buildResultCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    VoidCallback? onCopyAll,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (onCopyAll != null)
                GestureDetector(
                  onTap: onCopyAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.copy_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTitleItem(int index, String title) {
    return GestureDetector(
      onTap: () => _copy(title, 'tiêu đề $index'),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.copy_outlined,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagChip(String tag) {
    return GestureDetector(
      onTap: () => _copy(tag, 'hashtag'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: Colors.purpleAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingPlaceholder() {
    return Column(
      children: [
        _buildSkeletonCard(height: 100),
        const SizedBox(height: 12),
        _buildSkeletonCard(height: 120),
        const SizedBox(height: 12),
        _buildSkeletonCard(height: 80),
      ],
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'AI đang tạo nội dung...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return AppGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có nội dung AI',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhập transcript ở trên và nhấn\n"Tạo nội dung AI" để bắt đầu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}g trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.isAnimating,
  });

  final String status;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAnimating)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.cyanBlue),
              ),
            )
          else
            Icon(Icons.auto_awesome_rounded, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            _statusText(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'processing':
        return AppTheme.cyanBlue;
      case 'done':
        return Colors.greenAccent;
      case 'error':
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _statusText(String value) {
    switch (value.trim().toLowerCase()) {
      case 'processing':
        return 'Đang xử lý...';
      case 'done':
        return 'Đã tạo xong';
      case 'error':
        return 'Lỗi';
      default:
        return 'Chưa tạo';
    }
  }
}