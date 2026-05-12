import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor_example/features/editor/pages/video_editor_basic_example_page.dart';
import 'package:pro_video_editor_example/features/editor/pages/video_editor_grounded_example_page.dart';
import '../../audio/audio_extract_example_page.dart';
import '../../metadata/video_metadata_example_page.dart';
import '../../render/video_renderer_page.dart';
import '../../thumbnail/thumbnail_example_page.dart';
import '../widgets/tool_item_widget.dart';
import 'profile_page.dart';
import 'project_page.dart';

/// Màn hình chính của ứng dụng
class HomePage extends StatefulWidget {
  /// Khởi tạo [HomePage]
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _MainPage(),
    const _TemplatePage(),
    const _AILabPage(),
    const ProjectPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.content_cut),
            label: 'Chỉnh sửa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Mẫu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI Lab',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Dự án',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Tôi',
          ),
        ],
      ),
    );
  }
}

/// Màn hình chỉnh sửa chính
class _MainPage extends StatelessWidget {
  const _MainPage();

  /// Chọn ảnh từ thư viện và mở editor
  Future<void> _openImageEditor(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null || !context.mounted) return;

      final bytes = await picked.readAsBytes();
      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProImageEditor.memory(
            bytes,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List img) async {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ảnh, thử lại!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {},
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
                      icon: Icons.add,
                      label: 'Video mới',
                      color: Colors.blue.shade800,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const VideoEditorBasicExamplePage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMainButton(
                      context,
                      icon: Icons.image_outlined,
                      label: 'Chỉnh sửa ảnh',
                      color: Colors.orange.shade800,
                      onTap: () => _openImageEditor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Grid công cụ
              const Text(
                'Công cụ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  ToolItemWidget(
                    icon: Icons.flash_on,
                    label: 'AutoCut',
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
                    icon: Icons.landscape_outlined,
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
                    icon: Icons.auto_awesome,
                    label: 'Công cụ AI',
                    color: Colors.amber,
                    onTap: () => _openImageEditor(context),
                  ),
                  ToolItemWidget(
                    icon: Icons.tune,
                    label: 'Xuất video',
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VideoRendererPage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.image_search,
                    label: 'Hình thu nhỏ',
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ThumbnailExamplePage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.content_cut,
                    label: 'Trình chỉnh sửa',
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const VideoEditorBasicExamplePage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.audiotrack,
                    label: 'Âm thanh',
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AudioExtractExamplePage(),
                      ),
                    ),
                  ),
                  ToolItemWidget(
                    icon: Icons.image_outlined,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màn hình Mẫu
class _TemplatePage extends StatelessWidget {
  const _TemplatePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded,
                        size: 80, color: Colors.grey.shade600),
                    const SizedBox(height: 16),
                    Text('Chưa có mẫu nào',
                        style: TextStyle(color: Colors.grey.shade600)),
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

/// Màn hình AI Lab
class _AILabPage extends StatelessWidget {
  const _AILabPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AI Lab',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 80, color: Colors.grey.shade600),
                    const SizedBox(height: 16),
                    Text('Tính năng AI sắp ra mắt!',
                        style: TextStyle(color: Colors.grey.shade600)),
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