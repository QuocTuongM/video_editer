import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Repository xử lý upload video lên Firebase Storage
/// và lưu metadata vào Firestore.
class LocalVideoRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// User hiện tại — throw nếu chưa đăng nhập.
  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập trước khi lưu video.');
    }
    return user;
  }

  /// Lắng nghe danh sách video của user từ Firestore (realtime).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyVideos() {
    return _db
        .collection('users')
        .doc(_currentUser.uid)
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Lưu video từ [PlatformFile] lên Firebase Storage + Firestore.
  Future<String> savePlatformFileVideo({
    required PlatformFile file,
    required String type,
    required String title,
    int? durationMs,
  }) {
    return saveVideo(
      sourcePath: file.path,
      bytes: file.bytes,
      originalFileName: file.name,
      type: type,
      title: title,
      durationMs: durationMs,
    );
  }

  /// Lưu video từ path hoặc bytes lên Storage và metadata vào Firestore.
  Future<String> saveVideo({
    String? sourcePath,
    Uint8List? bytes,
    String? originalFileName,
    required String type,
    required String title,
    int? durationMs,
  }) async {
    final user = _currentUser;

    if ((sourcePath == null || sourcePath.isEmpty) &&
        (bytes == null || bytes.isEmpty)) {
      throw Exception('Không có dữ liệu video để lưu.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final extension = _resolveExtension(
      sourcePath: sourcePath,
      fileName: originalFileName,
    );
    final safeTitle = _sanitizeFileName(title);
    final fileName = '${safeTitle}_$now$extension';
    final storagePath = 'users/${user.uid}/videos/$type/$fileName';
    final contentType = _contentTypeFromExtension(extension);
    final storageRef = _storage.ref(storagePath);

    // Upload file + tính sizeBytes chính xác
    TaskSnapshot snapshot;
    int sizeBytes;

    if (!kIsWeb && sourcePath != null && sourcePath.isNotEmpty) {
      final file = File(sourcePath);
      sizeBytes = await file.length(); // ← lấy size thật từ file
      snapshot = await storageRef.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );
    } else if (bytes != null && bytes.isNotEmpty) {
      sizeBytes = bytes.length;
      snapshot = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
    } else {
      throw Exception('Không có dữ liệu để upload.');
    }

    final downloadUrl = await snapshot.ref.getDownloadURL();

    final docRef = await _db
        .collection('users')
        .doc(user.uid)
        .collection('videos')
        .add({
      'ownerId': user.uid,
      'title': title,
      'type': type,
      'fileName': fileName,
      'originalFileName': originalFileName ?? '',
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'durationMs': durationMs,

      // AI fields
      'aiSubtitleStatus': 'idle',
      'aiContentStatus': 'idle',
      'transcriptText': '',
      'aiTitle': '',
      'aiTitles': <String>[],
      'aiDescription': '',
      'aiHashtags': <String>[],
      'aiError': '',
      'aiUpdatedAt': null,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Xóa video trên Storage và metadata trên Firestore.
  Future<void> deleteVideo({
    required String videoId,
    required String storagePath,
  }) async {
    final user = _currentUser;

    if (storagePath.trim().isNotEmpty) {
      try {
        await _storage.ref(storagePath).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
    }

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('videos')
        .doc(videoId)
        .delete();
  }

  String _resolveExtension({String? sourcePath, String? fileName}) {
    final fromName = _getExtension(fileName ?? '');
    if (fromName.isNotEmpty) return fromName;
    final fromPath = _getExtension(sourcePath ?? '');
    if (fromPath.isNotEmpty) return fromPath;
    return '.mp4';
  }

  String _getExtension(String value) {
    final normalized = value.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex).toLowerCase();
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.webm':
        return 'video/webm';
      case '.mkv':
        return 'video/x-matroska';
      case '.mp4':
      default:
        return 'video/mp4';
    }
  }

  String _sanitizeFileName(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.isEmpty ? 'video' : cleaned;
  }
}