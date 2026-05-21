import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service xử lý đăng nhập, đăng ký và đăng xuất bằng Firebase Auth.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream theo dõi trạng thái đăng nhập.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User hiện tại.
  User? get currentUser => _auth.currentUser;

  /// Kiểm tra đã đăng nhập chưa.
  bool get isSignedIn => _auth.currentUser != null;

  /// Đăng ký tài khoản mới.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) throw Exception('Không thể tạo tài khoản.');

    await user.updateDisplayName(displayName.trim());

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return credential;
  }

  /// Đăng nhập bằng email và mật khẩu.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Đăng xuất.
  Future<void> signOut() => _auth.signOut();
}