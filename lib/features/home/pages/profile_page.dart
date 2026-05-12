import 'package:flutter/material.dart';

/// Màn hình thông tin cá nhân
class ProfilePage extends StatelessWidget {
  /// Khởi tạo [ProfilePage]
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tôi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
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
              ),

              // Avatar + Tên
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade700,
                      child: const Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Người dùng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Xem hồ sơ >',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              _buildMenuItem(
                icon: Icons.emoji_events_outlined,
                label: 'Sự kiện',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.bookmark_outline,
                label: 'Nội dung thích và mục Yêu thích',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.history,
                label: 'Lịch sử xem',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                label: 'Trung tâm trợ giúp',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.qr_code_scanner,
                label: 'Quét',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // Nút đăng nhập
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng đăng nhập sắp ra mắt!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Đăng nhập'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}