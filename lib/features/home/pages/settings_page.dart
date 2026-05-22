import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_theme.dart';

/// Trang cài đặt ứng dụng.
class SettingsPage extends StatefulWidget {
  /// Khởi tạo [SettingsPage].
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _version = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Ngôn ngữ ───────────────────────────────────────────
          _sectionTitle('Ngôn ngữ'),
          _buildMenuSection(items: [
            _SettingItem(
              icon: Icons.language_rounded,
              iconColor: AppTheme.primaryBlue,
              title: 'Ngôn ngữ hiển thị',
              subtitle: 'Tiếng Việt',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              onTap: () => _showLanguageSheet(context),
            ),
          ]),

          _sectionTitle('Thông báo'),
          _buildMenuSection(items: [
            _SettingItem(
              icon: Icons.notifications_outlined,
              iconColor: Colors.orange,
              title: 'Thông báo đẩy',
              subtitle: 'Nhận thông báo khi AI xử lý xong',
              trailing: _SwitchWidget(
                value: true,
                onChanged: (_) {},
              ),
            ),
            _SettingItem(
              icon: Icons.email_outlined,
              iconColor: Colors.green,
              title: 'Thông báo email',
              subtitle: 'Nhận email khi có cập nhật mới',
              trailing: _SwitchWidget(
                value: false,
                onChanged: (_) {},
              ),
            ),
          ]),

          _sectionTitle('Lưu trữ'),
          _buildMenuSection(items: [
            _SettingItem(
              icon: Icons.video_settings_outlined,
              iconColor: Colors.purple,
              title: 'Chất lượng xuất mặc định',
              subtitle: '1080p FHD',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              onTap: () => _showQualitySheet(context),
            ),
            _SettingItem(
              icon: Icons.cloud_outlined,
              iconColor: AppTheme.cyanBlue,
              title: 'Tự động lưu lên Dự án',
              subtitle: 'Lưu video sau khi xuất xong',
              trailing: _SwitchWidget(
                value: true,
                onChanged: (_) {},
              ),
            ),
            _SettingItem(
              icon: Icons.photo_library_outlined,
              iconColor: Colors.teal,
              title: 'Lưu vào thư viện điện thoại',
              subtitle: 'Lưu ảnh chỉnh sửa vào gallery',
              trailing: _SwitchWidget(
                value: true,
                onChanged: (_) {},
              ),
            ),
          ]),

          _sectionTitle('Hỗ trợ & Thông tin'),
          _buildMenuSection(items: [
            _SettingItem(
              icon: Icons.help_outline_rounded,
              iconColor: Colors.indigo,
              title: 'Hướng dẫn sử dụng',
              subtitle: 'Xem hướng dẫn chi tiết',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              onTap: () {},
            ),
            _SettingItem(
              icon: Icons.bug_report_outlined,
              iconColor: Colors.red,
              title: 'Báo lỗi',
              subtitle: 'Gửi phản hồi cho nhà phát triển',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              onTap: () {},
            ),
            _SettingItem(
              icon: Icons.star_outline_rounded,
              iconColor: Colors.amber,
              title: 'Đánh giá ứng dụng',
              subtitle: 'Ủng hộ chúng tôi trên Store',
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              onTap: () {},
            ),
          ]),

          _sectionTitle('Về ứng dụng'),
          _buildMenuSection(items: [
            _SettingItem(
              icon: Icons.info_outline_rounded,
              iconColor: AppTheme.textSecondary,
              title: 'Phiên bản',
              subtitle: _version.isEmpty
                  ? 'Đang tải...'
                  : '$_version (build $_buildNumber)',
            ),
            _SettingItem(
              icon: Icons.code_rounded,
              iconColor: AppTheme.textSecondary,
              title: 'Phát triển bởi',
              subtitle: 'Nhóm sinh viên TDMU 2022–2027',
            ),
            _SettingItem(
              icon: Icons.school_outlined,
              iconColor: AppTheme.textSecondary,
              title: 'Môn học',
              subtitle: 'Phát triển ứng dụng di động — HK II 2025',
            ),
          ]),

          const SizedBox(height: 24),

          // App version badge
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppTheme.primaryBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pro Video Editor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _version.isEmpty ? '' : 'v$_version',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
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

  Widget _buildMenuSection({required List<_SettingItem> items}) {
    return Container(
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 18),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: item.subtitle != null
                    ? Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : null,
                trailing: item.trailing,
                onTap: item.onTap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: i == items.length - 1
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 56,
                  color: AppTheme.border.withValues(alpha: 0.5),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ngôn ngữ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
              title: const Text('Tiếng Việt',
                  style: TextStyle(color: AppTheme.textPrimary)),
              trailing: const Icon(Icons.check,
                  color: AppTheme.primaryBlue, size: 18),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showQualitySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chất lượng xuất mặc định',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            for (final q in ['720p HD', '1080p FHD', '4K UHD'])
              ListTile(
                title: Text(q,
                    style: const TextStyle(color: AppTheme.textPrimary)),
                trailing: q == '1080p FHD'
                    ? const Icon(Icons.check,
                        color: AppTheme.primaryBlue, size: 18)
                    : null,
                onTap: () => Navigator.pop(ctx),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SettingItem {
  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _SwitchWidget extends StatefulWidget {
  const _SwitchWidget({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_SwitchWidget> createState() => _SwitchWidgetState();
}

class _SwitchWidgetState extends State<_SwitchWidget> {
  late bool _value = widget.value;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged(v);
      },
      activeThumbColor: AppTheme.primaryBlue,
    );
  }
}