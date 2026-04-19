import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pro_video_editor_example/features/editor/pages/video_editor_basic_example_page.dart';
import 'package:pro_video_editor_example/features/editor/pages/video_editor_grounded_example_page.dart';

import 'features/audio/audio_extract_example_page.dart';
import 'features/metadata/video_metadata_example_page.dart';
import 'features/render/video_renderer_page.dart';
import 'features/thumbnail/thumbnail_example_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  runApp(const MyApp());
}

/// Widget gốc của ứng dụng.
class MyApp extends StatelessWidget {
  /// Khởi tạo widget [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade800,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Trang chủ của ứng dụng.
class HomePage extends StatelessWidget {
  /// Khởi tạo widget [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ExampleListItem> exampleList = [
      _ExampleListItem(
        icon: Icons.info_outline,
        title: 'Thông tin video',
        pageBuilder: () => const VideoMetadataExamplePage(),
      ),
      _ExampleListItem(
        icon: Icons.image_outlined,
        title: 'Thumbnails',
        pageBuilder: () => const ThumbnailExamplePage(),
      ),
      _ExampleListItem(
        icon: Icons.audiotrack,
        title: 'Âm thanh',
        pageBuilder: () => const AudioExtractExamplePage(),
      ),
      _ExampleListItem(
        icon: Icons.developer_board_outlined,
        title: 'Xuất video',
        pageBuilder: () => const VideoRendererPage(),
      ),
      _ExampleListItem(
        icon: Icons.edit,
        title: 'Chỉnh sửa video',
        pageBuilder: () => const VideoEditorBasicExamplePage(),
      ),
      _ExampleListItem(
        icon: Icons.grass_outlined,
        title: 'Chỉnh sửa video chuyên nghiệp',
        pageBuilder: () => const VideoEditorGroundedExamplePage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ứng dụng chỉnh sửa video')),
      body: ListView(
        children: exampleList.map((item) {
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.pageBuilder()),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _ExampleListItem {
  _ExampleListItem({
    required this.icon,
    required this.title,
    required this.pageBuilder,
  });
  final IconData icon;
  final String title;
  final Widget Function() pageBuilder;
}