import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../data/category_dao.dart';
import '../data/profile_dao.dart';
import '../data/settings_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      debugPrint('Auth state changed: ${user?.email ?? 'null'}');
      _user = user;

      // Khi user đăng nhập thành công, khởi tạo data nếu cần
      if (user != null) {
        _initializeUserDataIfNeeded();
      }

      notifyListeners();
    });
  }

  // Initialize user data if needed
  Future<void> _initializeUserDataIfNeeded() async {
    try {
      final profileDao = ProfileDao();
      final categoryDao = CategoryDao();

      // Tạo default profile nếu chưa có
      await profileDao.createDefaultProfile();

      // Tạo default categories nếu chưa có
      await categoryDao.createDefaultCategories();

      // Khởi tạo default settings nếu chưa có
      await AppSettings.initializeDefaultSettings();

      debugPrint('✅ User data initialization completed');
    } catch (e) {
      debugPrint('❌ Error initializing user data: $e');
      // Không throw error vì không ảnh hưởng đến việc đăng nhập
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      clearError();

      debugPrint('🔐 AuthProvider: Attempting sign in for: $email');

      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Even if result is null but we have current user, consider it success
      final currentUser = _authService.currentUser;
      if (result?.user != null || currentUser?.email == email) {
        debugPrint('✅ AuthProvider: Sign in successful');

        // Verify auth state to make sure everything is OK
        await _authService.verifyAuthState();

        _setLoading(false);
        return true;
      } else {
        throw 'Đăng nhập thất bại. Vui lòng thử lại.';
      }
    } catch (e) {
      debugPrint('❌ AuthProvider: Sign in failed: $e');

      // Special handling for auth state after PigeonUserDetails error
      await Future.delayed(const Duration(milliseconds: 500));
      final currentUser = _authService.currentUser;
      if (currentUser?.email == email) {
        debugPrint('🔧 Found user after error, considering success: ${currentUser!.email}');
        _setLoading(false);
        return true;
      }

      _setError(e.toString());
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      clearError();

      debugPrint('📝 AuthProvider: Attempting registration for: $email');

      final result = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Even if result is null but we have current user, consider it success
      final currentUser = _authService.currentUser;
      if (result?.user != null || currentUser?.email == email) {
        debugPrint('✅ AuthProvider: Registration successful');

        // Verify auth state to make sure everything is OK
        await _authService.verifyAuthState();

        _setLoading(false);
        return true;
      } else {
        throw 'Đăng ký thất bại. Vui lòng thử lại.';
      }
    } catch (e) {
      debugPrint('❌ AuthProvider: Registration failed: $e');

      // Special handling for auth state after PigeonUserDetails error
      await Future.delayed(const Duration(milliseconds: 500));
      final currentUser = _authService.currentUser;
      if (currentUser?.email == email) {
        debugPrint('🔧 Found user after registration error, considering success: ${currentUser!.email}');
        _setLoading(false);
        return true;
      }

      _setError(e.toString());
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      clearError();

      debugPrint('🔍 AuthProvider: Attempting Google sign in');

      final result = await _authService.signInWithGoogle();

      // Even if result is null but we have current user, consider it success
      final currentUser = _authService.currentUser;
      if (result?.user != null || currentUser != null) {
        debugPrint('✅ AuthProvider: Google sign in successful');

        // Verify auth state to make sure everything is OK
        await _authService.verifyAuthState();

        _setLoading(false);
        return true;
      } else {
        throw 'Đăng nhập Google thất bại. Vui lòng thử lại.';
      }
    } catch (e) {
      debugPrint('❌ AuthProvider: Google sign in failed: $e');

      // Special handling for auth state after PigeonUserDetails error
      await Future.delayed(const Duration(milliseconds: 500));
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        debugPrint('🔧 Found user after Google error, considering success: ${currentUser.email}');
        _setLoading(false);
        return true;
      }

      _setError(e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);

      debugPrint('🚪 AuthProvider: Signing out user: ${_user?.email}');

      await _authService.signOut();

      // Clear local state
      _user = null;

      _setLoading(false);
      debugPrint('✅ AuthProvider: Sign out successful');
    } catch (e) {
      debugPrint('❌ AuthProvider: Sign out failed: $e');
      _setError(e.toString());
    }
  }

  // Refresh auth state manually (useful for debugging)
  Future<void> refreshAuthState() async {
    try {
      await _authService.reloadCurrentUser();
      final currentUser = _authService.currentUser;
      if (currentUser != _user) {
        _user = currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing auth state: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      clearError();

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('❌ AuthProvider: Reset password failed: $e');
      _setError('Không thể gửi email reset password. Vui lòng thử lại.');
      return false;
    }
  }
}