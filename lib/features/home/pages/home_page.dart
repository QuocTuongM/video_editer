import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor_example/features/editor/pages/video_editor_basic_example_page.dart';
import 'package:pro_video_editor_example/features/editor/pages/video_editor_grounded_example_page.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/local_video_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../ai/pages/video_ai_page.dart';
import '../../audio/audio_extract_example_page.dart';
import '../../auth/pages/auth_page.dart';
import '../../metadata/video_metadata_example_page.dart';
import '../../render/video_renderer_page.dart';
import '../../thumbnail/thumbnail_example_page.dart';
import '../../upload/upload_video_page.dart';
import '../widgets/tool_item_widget.dart';
import 'profile_page.dart';
import 'project_page.dart';
import 'settings_page.dart';

/// Màn hình chính của ứng dụng.
class HomePage extends StatefulWidget {
  /// Khởi tạo [HomePage].
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _projectSearchController = TextEditingController();

  late final List<Widget> _pages = [
    _MainPage(onSearchTap: _goToProjectSearch),
    const _TemplatePage(),
    const _AILabPage(),
    ProjectPage(searchController: _projectSearchController),
    const ProfilePage(),
  ];

  @override
  void dispose() {
    _projectSearchController.dispose();
    super.dispose();
  }

  void _goToProjectSearch() {
    setState(() => _currentIndex = 3);
    Future.delayed(const Duration(milliseconds: 100), () {
      _projectSearchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _projectSearchController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.border.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.content_cut_outlined),
              activeIcon: Icon(Icons.content_cut),
              label: 'Chỉnh sửa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Mẫu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'AI Lab',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder_rounded),
              label: 'Dự án',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tôi',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main Page ──────────────────────────────────────────────────────────────

class _MainPage extends StatelessWidget {
  const _MainPage({this.onSearchTap});
  final VoidCallback? onSearchTap;

  Future<void> _openImageEditor(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null || !context.mounted) return;
      final bytes = await picked.readAsBytes();
      if (!context.mounted) return;

      Uint8List? editedBytes;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProImageEditor.memory(
            bytes,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List result) async {
                editedBytes = result;
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );

      if (editedBytes == null || !context.mounted) return;

      AppSnackBar.info(context, 'Đang lưu ảnh...');

      // Lưu vào thư viện điện thoại
      bool savedToGallery = false;
      try {
        await Gal.putImageBytes(editedBytes!);
        savedToGallery = true;
      } catch (_) {}

      // Lưu lên Firebase nếu đã đăng nhập
      bool savedToFirebase = false;
      final user = AuthService().currentUser;
      if (user != null) {
        try {
          await LocalVideoRepository().saveImage(
            bytes: editedBytes!,
            title:
                'Ảnh chỉnh sửa ${DateTime.now().day}/${DateTime.now().month}',
          );
          savedToFirebase = true;
        } catch (_) {}
      }

      if (!context.mounted) return;

      if (savedToGallery && savedToFirebase) {
        AppSnackBar.success(context, '✅ Đã lưu vào thư viện và Dự án!');
      } else if (savedToGallery) {
        AppSnackBar.success(context, '✅ Đã lưu vào thư viện điện thoại!');
      } else if (savedToFirebase) {
        AppSnackBar.success(context, '✅ Đã lưu vào Dự án!');
      } else {
        AppSnackBar.warning(
          context,
          'Không thể lưu ảnh. Kiểm tra quyền truy cập!',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Lỗi: $e');
      }
    }
  }

  void _openVideoPage(BuildContext context) {
    if (kIsWeb) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadVideoPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VideoEditorBasicExamplePage(),
        ),
      );
    }
  }

  void _openAiLab(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _VideoPickerForAi(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chỉnh sửa',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search,
                            color: AppTheme.textSecondary),
                        tooltip: 'Tìm kiếm video',
                        onPressed: onSearchTap,
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: AppTheme.textSecondary),
                        tooltip: 'Cài đặt',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nút Video mới + Chỉnh sửa ảnh
              Row(
                children: [
                  Expanded(
                    child: _buildMainButton(
                      context,
                      icon: Icons.add_rounded,
                      label: 'Video mới',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF2F80FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => _openVideoPage(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMainButton(
                      context,
                      icon: Icons.image_outlined,
                      label: 'Chỉnh sửa ảnh',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC2410C), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => _openImageEditor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Công cụ
              const Text(
                'Công cụ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  ToolItemWidget(
                    icon: Icons.flash_on_rounded,
                    label: 'Chỉnh sửa Pro',
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const VideoEditorGroundedExamplePage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.info_outline_rounded,
                    label: 'Thông tin video',
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VideoMetadataExamplePage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Tạo nội dung AI',
                    color: Colors.amber,
                    onTap: () => _openAiLab(context),
                  ),
                  ToolItemWidget(
                    icon: Icons.upload_rounded,
                    label: 'Xuất & Xử lý',
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VideoRendererPage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.image_search_rounded,
                    label: 'Tạo thumbnail',
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ThumbnailExamplePage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.content_cut_rounded,
                    label: 'Chỉnh sửa cơ bản',
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VideoEditorBasicExamplePage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.audiotrack_rounded,
                    label: 'Xuất âm thanh',
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AudioExtractExamplePage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.photo_outlined,
                    label: 'Chỉnh sửa ảnh',
                    color: Colors.deepPurple,
                    onTap: () => _openImageEditor(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 110,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AI Lab Page ────────────────────────────────────────────────────────────

class _AILabPage extends StatelessWidget {
  const _AILabPage();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'AI Lab',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Tạo title, description và hashtag cho video bằng AI.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: user == null
                      ? _buildLoginRequired(context)
                      : const _VideoPickerForAi(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đăng nhập để dùng AI Lab',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn cần đăng nhập để tạo nội dung AI cho video.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập / Đăng ký'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Video Picker for AI ────────────────────────────────────────────────────

/// Widget hiển thị danh sách video để chọn và mở AI Content.
class _VideoPickerForAi extends StatelessWidget {
  const _VideoPickerForAi();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: LocalVideoRepository().watchMyVideos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Không tải được dữ liệu',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.video_library_outlined,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có video nào',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tạo video mới ở tab Chỉnh sửa trước!',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final title = (data['title'] ?? 'Không có tên').toString();
            final type = (data['type'] ?? 'original').toString();
            final aiStatus = (data['aiContentStatus'] ?? 'idle').toString();
            final isEdited = type == 'edited';

            return Material(
              color: AppTheme.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoAiPage(
                        videoId: doc.id,
                        videoTitle: title,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isEdited
                                      ? Icons.movie_filter_outlined
                                      : Icons.video_file_outlined,
                                  size: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isEdited ? 'Đã chỉnh' : 'Gốc',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _aiColor(aiStatus)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _aiStatusText(aiStatus),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _aiColor(aiStatus),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _aiColor(String status) {
    switch (status) {
      case 'done':
        return Colors.greenAccent;
      case 'processing':
        return Colors.amber;
      case 'error':
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _aiStatusText(String status) {
    switch (status) {
      case 'done':
        return 'Đã tạo';
      case 'processing':
        return 'Đang xử lý';
      case 'error':
        return 'Lỗi';
      default:
        return 'Chưa tạo';
    }
  }
}

// ─── Template Page ──────────────────────────────────────────────────────────

class _TemplatePage extends StatelessWidget {
  const _TemplatePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mẫu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sắp ra mắt',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tính năng mẫu video đang được phát triển.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}