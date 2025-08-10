import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting email sign in for: $email');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Email sign in successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ General Error: $e');

      // Handle PigeonUserDetails error specifically
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        debugPrint('🔧 Handling PigeonUserDetails error - checking auth state...');

        // Wait a bit for auth state to settle
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check if user is actually signed in
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          debugPrint('✅ User is actually signed in despite error: ${currentUser.email}');
          // Return a mock UserCredential since user is signed in
          return _MockUserCredential(currentUser);
        }
      }

      throw 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📝 Attempting email registration for: $email');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Email registration successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ General Error: $e');

      // Handle PigeonUserDetails error specifically
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        debugPrint('🔧 Handling PigeonUserDetails error during registration...');

        // Wait a bit for auth state to settle
        await Future.delayed(const Duration(milliseconds: 1500));

        // Check if user was actually created
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          debugPrint('✅ User was actually created despite error: ${currentUser.email}');
          // Return a mock UserCredential since user was created
          return _MockUserCredential(currentUser);
        }
      }

      throw 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔍 Starting Google Sign In...');

      // Clear previous session
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google Sign In cancelled by user');
        throw 'Đăng nhập Google bị hủy';
      }

      debugPrint('✅ Google account selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      debugPrint('🔑 Got Google auth tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🎫 Created Firebase credential');

      // Once signed in, return the UserCredential
      final result = await _auth.signInWithCredential(credential);

      debugPrint('✅ Google Sign In successful: ${result.user?.email}');
      return result;

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Google Sign In Error: $e');

      // Handle PigeonUserDetails error for Google Sign In
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        debugPrint('🔧 Handling Google PigeonUserDetails error...');

        await Future.delayed(const Duration(milliseconds: 1000));
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          debugPrint('✅ Found current user after Google error: ${currentUser.email}');
          return _MockUserCredential(currentUser);
        }
      }

      throw 'Đăng nhập Google thất bại. Vui lòng thử lại.';
    }
  }

  // Force refresh current user to fix auth state issues
  Future<void> reloadCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        debugPrint('🔄 User reloaded: ${user.email}');
      }
    } catch (e) {
      debugPrint('❌ Error reloading user: $e');
    }
  }

  // Check auth state and fix if needed
  Future<bool> verifyAuthState() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Try to get ID token to verify user is valid
        await user.getIdToken(true);
        debugPrint('✅ Auth state verified for: ${user.email}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Auth state verification failed: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out...');
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      throw 'Đăng xuất thất bại';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng. Hãy thử đăng nhập.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập không được cho phép.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra internet và thử lại.';
      default:
        debugPrint('Unhandled Firebase Auth Error: ${e.code} - ${e.message}');
        return 'Có lỗi xảy ra: ${e.message ?? e.code}';
    }
  }
}

// Mock UserCredential for handling PigeonUserDetails errors
class _MockUserCredential implements UserCredential {
  @override
  final User user;

  _MockUserCredential(this.user);

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}