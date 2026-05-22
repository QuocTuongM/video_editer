import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/local_video_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_loading_overlay.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../auth/pages/auth_page.dart';

/// Màn hình thông tin cá nhân.
class ProfilePage extends StatelessWidget {
  /// Khởi tạo [ProfilePage].
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tôi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {},
                            ),
                            if (user != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () =>
                                    _showEditProfile(context, user),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Avatar + Info card
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: user == null
                        ? _buildGuestCard(context)
                        : _buildUserCard(context, user),
                  ),

                  // Stats
                  if (user != null) _buildStatsRow(),

                  const SizedBox(height: 8),
                  Divider(color: AppTheme.border.withValues(alpha: 0.5)),
                  const SizedBox(height: 4),

                  // Menu
                  _buildMenuSection(
                    title: 'Hoạt động',
                    items: [
                      _MenuItem(
                        icon: Icons.bookmark_outline,
                        label: 'Nội dung đã lưu',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.history,
                        label: 'Lịch sử xem',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.emoji_events_outlined,
                        label: 'Thành tích',
                        onTap: () {},
                      ),
                    ],
                  ),
                  if (user != null)
                    _buildMenuSection(
                      title: 'Tài khoản',
                      items: [
                        _MenuItem(
                          icon: Icons.lock_outline,
                          label: 'Đổi mật khẩu',
                          onTap: () => _showChangePassword(context, user),
                        ),
                        _MenuItem(
                          icon: Icons.email_outlined,
                          label: user.email ?? '',
                          onTap: null,
                        ),
                      ],
                    ),
                  _buildMenuSection(
                    title: 'Hỗ trợ',
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline,
                        label: 'Trung tâm trợ giúp',
                        onTap: () {},
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        label: 'Giới thiệu ứng dụng',
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Nút đăng nhập / đăng xuất
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: user == null
                        ? FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AuthPage()),
                            ),
                            icon: const Icon(Icons.login),
                            label: const Text('Đăng nhập / Đăng ký'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _confirmSignOut(context),
                            icon: const Icon(Icons.logout,
                                color: Colors.red),
                            label: const Text('Đăng xuất',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Guest card ──────────────────────────────────────────────────────────

  Widget _buildGuestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                size: 36, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khách',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đăng nhập để đồng bộ dữ liệu',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── User card ───────────────────────────────────────────────────────────

  Widget _buildUserCard(BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Avatar — bấm để đổi
          GestureDetector(
            onTap: () => _changeAvatar(context, user),
            child: Stack(
              children: [
                // Avatar ảnh hoặc chữ cái
                user.photoURL != null
                    ? CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage(user.photoURL!),
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.cyanBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitial(user),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                // Camera icon overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.surfaceSoft, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName ?? 'Người dùng',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showEditProfile(context, user),
                      child: const Icon(Icons.edit_outlined,
                          size: 16, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.email ?? '',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Free Plan',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return StreamBuilder(
      stream: LocalVideoRepository().watchMyVideos(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;
        final edited =
            docs.where((d) => d.data()['type'] == 'edited').length;
        final aiDone = docs
            .where((d) => d.data()['aiContentStatus'] == 'done')
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _statItem('$total', 'Video'),
              _statDivider(),
              _statItem('$edited', 'Đã chỉnh'),
              _statDivider(),
              _statItem('$aiDone', 'AI Content'),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 36,
        color: AppTheme.border,
      );

  // ─── Menu ────────────────────────────────────────────────────────────────

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
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
                    ListTile(
                      leading: Icon(item.icon,
                          color: AppTheme.textSecondary, size: 20),
                      title: Text(
                        item.label,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppTheme.textSecondary, size: 18),
                      onTap: item.onTap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: i == 0
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottom: i == items.length - 1
                              ? const Radius.circular(16)
                              : Radius.zero,
                        ),
                      ),
                    ),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        indent: 52,
                        color: AppTheme.border.withValues(alpha: 0.5),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edit Profile Dialog ─────────────────────────────────────────────────

  Future<void> _showChangePassword(BuildContext context, User user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B0F1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ChangePasswordSheet(user: user),
    );
  }

  Future<void> _showEditProfile(BuildContext context, User user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditProfileSheet(user: user),
    );
  }

  // ─── Change Avatar ────────────────────────────────────────────────────────

  Future<void> _changeAvatar(BuildContext context, User user) async {
    final choice = await showModalBottomSheet<String>(
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
              'Đổi ảnh đại diện',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primaryBlue),
              title: const Text('Chọn từ thư viện',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.primaryBlue),
              title: const Text('Chụp ảnh mới',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (user.photoURL != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.red),
                title: const Text('Xóa ảnh đại diện',
                    style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    if (choice == 'remove') {
      await _removeAvatar(context, user);
      return;
    }

    final source =
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (!context.mounted) return;
    await _uploadAvatar(context, user, bytes);
  }

  Future<void> _uploadAvatar(
    BuildContext context,
    User user,
    Uint8List bytes,
  ) async {
    AppLoadingOverlay.show(context, message: 'Đang cập nhật ảnh...');
    try {
      final ref = FirebaseStorage.instance
          .ref('users/${user.uid}/avatar.jpg');
      await ref.putData(
          bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': url, 'updatedAt': FieldValue.serverTimestamp()});
      AppLoadingOverlay.hide();
      if (context.mounted) {
        AppSnackBar.success(context, 'Đã cập nhật ảnh đại diện!');
      }
    } catch (e) {
      AppLoadingOverlay.hide();
      if (context.mounted) {
        AppSnackBar.error(context, 'Không thể cập nhật ảnh: $e');
      }
    }
  }

  Future<void> _removeAvatar(BuildContext context, User user) async {
    AppLoadingOverlay.show(context, message: 'Đang xóa ảnh...');
    try {
      await user.updatePhotoURL(null);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLoadingOverlay.hide();
      if (context.mounted) {
        AppSnackBar.success(context, 'Đã xóa ảnh đại diện.');
      }
    } catch (e) {
      AppLoadingOverlay.hide();
      if (context.mounted) {
        AppSnackBar.error(context, 'Không thể xóa ảnh: $e');
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _getInitial(User user) {
    final name = user.displayName ?? user.email ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Đăng xuất?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Bạn có chắc muốn đăng xuất không?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().signOut();
      if (context.mounted) AppSnackBar.info(context, 'Đã đăng xuất.');
    }
  }
}

// ─── Edit Profile Bottom Sheet ───────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final User user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.user.displayName ?? '');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.warning(context, 'Tên không được để trống.');
      return;
    }
    if (name == widget.user.displayName) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.user.updateDisplayName(name);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        'displayName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      AppSnackBar.success(context, 'Đã cập nhật tên thành công!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Không thể cập nhật: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Chỉnh sửa hồ sơ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Tên hiển thị
            const Text(
              'Tên hiển thị',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Nhập tên của bạn',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 8),

            // Email (chỉ hiển thị, không sửa được)
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.user.email ?? '',
                      style: const TextStyle(
                          color: AppTheme.textSecondary),
                    ),
                  ),
                  const Icon(Icons.lock_outline,
                      color: AppTheme.textSecondary, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nút lưu
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu thay đổi'),
            ),
            const SizedBox(height: 8),
          ],
          ),
        ),
      ),
    );
  }
}


// ─── Change Password Sheet ───────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.user});
  final User user;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_currentCtrl.text.isEmpty) return 'Nhập mật khẩu hiện tại.';
    if (_newCtrl.text.length < 6) return 'Mật khẩu mới phải ít nhất 6 ký tự.';
    if (_newCtrl.text != _confirmCtrl.text) return 'Xác nhận mật khẩu không khớp.';
    if (_newCtrl.text == _currentCtrl.text) return 'Mật khẩu mới phải khác mật khẩu cũ.';
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      AppSnackBar.warning(context, err);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Re-authenticate trước khi đổi mật khẩu
      final cred = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: _currentCtrl.text,
      );
      await widget.user.reauthenticateWithCredential(cred);
      await widget.user.updatePassword(_newCtrl.text);

      if (!mounted) return;
      AppSnackBar.success(context, '✅ Đổi mật khẩu thành công!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Mật khẩu hiện tại không đúng.';
          break;
        case 'too-many-requests':
          msg = 'Thử quá nhiều lần. Vui lòng thử lại sau.';
          break;
        case 'weak-password':
          msg = 'Mật khẩu mới quá yếu.';
          break;
        default:
          msg = 'Lỗi: \${e.message}';
      }
      AppSnackBar.error(context, msg);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Lỗi không xác định: \$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF243044),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đổi mật khẩu',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhập mật khẩu hiện tại để xác nhận danh tính.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),

            // Mật khẩu hiện tại
            const Text('Mật khẩu hiện tại',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            TextField(
              controller: _currentCtrl,
              obscureText: !_showCurrent,
              style: const TextStyle(color: Color(0xFFF8FAFC)),
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu hiện tại',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showCurrent = !_showCurrent),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Mật khẩu mới
            const Text('Mật khẩu mới',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            TextField(
              controller: _newCtrl,
              obscureText: !_showNew,
              style: const TextStyle(color: Color(0xFFF8FAFC)),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ít nhất 6 ký tự',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildStrengthBar(_newCtrl.text),
            const SizedBox(height: 14),

            // Xác nhận mật khẩu mới
            const Text('Xác nhận mật khẩu mới',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmCtrl,
              obscureText: !_showConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: const TextStyle(color: Color(0xFFF8FAFC)),
              decoration: InputDecoration(
                hintText: 'Nhập lại mật khẩu mới',
                prefixIcon: const Icon(Icons.check_circle_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Xác nhận đổi mật khẩu'),
            ),
            const SizedBox(height: 8),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthBar(String pwd) {
    if (pwd.isEmpty) return const SizedBox.shrink();
    int strength = 0;
    if (pwd.length >= 6) strength++;
    if (pwd.length >= 10) strength++;
    if (pwd.contains(RegExp(r'[A-Z]'))) strength++;
    if (pwd.contains(RegExp(r'[0-9]'))) strength++;
    if (pwd.contains(RegExp(r'[!@#\$%^&*]'))) strength++;

    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.lightGreen, Colors.green];
    final labels = ['Rất yếu', 'Yếu', 'Trung bình', 'Mạnh', 'Rất mạnh'];
    final idx = (strength - 1).clamp(0, 4);
    final color = strength == 0 ? Colors.grey : colors[idx];
    final label = strength == 0 ? '' : labels[idx];

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength / 5,
              backgroundColor: const Color(0xFF243044),
              color: color,
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}