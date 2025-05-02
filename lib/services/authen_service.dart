import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/chatscreens/chatscreen.dart';
import '../screens/signinscreen.dart';
import '../services/supabase_service.dart';

class AuthenService {
  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService(); // Khởi tạo SupabaseService

  // Kiểm tra kết nối mạng
  Future<bool> _checkInternetConnection() async {
    if (kIsWeb) {
      return true;
    } else {
      try {
        final result = await InternetAddress.lookup('example.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  // Hàm kiểm tra trạng thái đăng nhập và điều hướng
  Future<void> checkAuthAndNavigate(BuildContext context) async {
    if (!await _checkInternetConnection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có kết nối mạng')),
      );
      return;
    }
    final currentUser = _client.auth.currentUser;
    if (currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  // Đăng ký bằng Email
  Future<AuthResponse?> signUpWithEmail(
      String email, String password, String username, BuildContext context) async {
    if (!await _checkInternetConnection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có kết nối mạng')),
      );
      return null;
    }
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': username},
      );
      if (response.user != null) {
        await _supabaseService.createUser(
          response.user!.id,
          username: username,
          email: email,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      }
      return response;
    } catch (error) {
      print('Lỗi đăng ký: ${error is AuthException ? error.message : error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng ký: $error')),
      );
      return null;
    }
  }

  // Đăng nhập bằng Email
  Future<AuthResponse?> signInWithEmail(
      String email, String password, BuildContext context) async {
    if (!await _checkInternetConnection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có kết nối mạng')),
      );
      return null;
    }
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang đăng nhập...')),
      );

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final username = response.user!.userMetadata?['display_name'] ?? email.split('@')[0];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      }
      return response;
    } catch (error) {
      print('Lỗi đăng nhập bằng email: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập: $error')),
      );
      return null;
    }
  }

  // Kiểm tra xem người dùng đã tồn tại trong bảng users chưa
  Future<bool> _checkUserExists(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (error) {
      print('Lỗi khi kiểm tra người dùng tồn tại: $error');
      return false;
    }
  }

  // Đăng nhập bằng Google
  Future<AuthResponse?> signInWithGoogle(BuildContext context) async {
    if (!await _checkInternetConnection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có kết nối mạng')),
      );
      return null;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang đăng nhập với Google...')),
      );

      const webClientId = '992900925312-2tqg0usmeuvj4boi34a1c4thu4ustika.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đăng nhập bằng Google')),
        );
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy Access Token từ Google')),
        );
        return null;
      }
      if (idToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy ID Token từ Google')),
        );
        return null;
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        print('✅ Signed in with Google: ${response.user!.email}');
        // Kiểm tra xem người dùng đã tồn tại chưa, nếu chưa thì tạo mới
        final userExists = await _checkUserExists(response.user!.id);
        if (!userExists) {
          await _supabaseService.createUser(
            response.user!.id,
            username: response.user!.userMetadata?['name'] ?? 'User',
            email: response.user!.email,
          );
        }
        final username = response.user!.userMetadata?['name'] ?? 'User';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại: Không nhận được thông tin người dùng')),
        );
      }

      return response;
    } catch (error) {
      print('⚠️ Error signing in with Google: $error');
      String errorMessage = 'Lỗi đăng nhập Google: $error';
      if (error.toString().contains('ApiException: 10')) {
        errorMessage = 'Lỗi cấu hình Google Sign-In. Kiểm tra SHA-1 và package name.';
      } else if (error.toString().contains('network')) {
        errorMessage = 'Lỗi mạng. Vui lòng kiểm tra kết nối internet.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return null;
    }
  }


// Đăng nhập bằng Facebook
  Future<void> signInWithFacebook(BuildContext context) async {
    if (!await _checkInternetConnection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có kết nối mạng')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang đăng nhập với Facebook...')),
      );

      // Sử dụng signInWithOAuth để đăng nhập Facebook
      await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? 'http://localhost:3000' : 'my.scheme://my-host',
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );

      // Lắng nghe trạng thái xác thực để điều hướng
      _client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          print('✅ Signed in with Facebook: ${session.user?.email}');
          final username = session.user?.userMetadata?['name'] ?? 'User';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen()),
          );
        }
      });
    } catch (error) {
      print('Lỗi đăng nhập bằng Facebook: $error');
      String errorMessage = 'Lỗi đăng nhập Facebook: $error';
      if (error.toString().contains('network')) {
        errorMessage = 'Lỗi mạng. Vui lòng kiểm tra kết nối internet.';
      } else if (error.toString().contains('not accessible')) {
        errorMessage =
        'Ứng dụng Facebook đang ở chế độ phát triển. Vui lòng thêm tài khoản của bạn làm Tester hoặc chuyển ứng dụng sang Live Mode.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }


  // Đăng nhập bằng Apple


  // Đăng xuất
  Future<void> signOut(BuildContext context) async {
    try {
      const webClientId = '992900925312-2tqg0usmeuvj4boi34a1c4thu4ustika.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );
      await googleSignIn.signOut();

      await _client.auth.signOut();
      print('Đăng xuất thành công');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (error) {
      print('Lỗi đăng xuất: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: $error')),
      );
    }
  }

  // Kiểm tra trạng thái đăng nhập
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Lấy display_name từ user_metadata
  Future<String?> getDisplayName() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        return user.userMetadata?['display_name'] as String?;
      }
      return null;
    } catch (error) {
      print('Lỗi khi lấy display_name: $error');
      return null;
    }
  }

  // Lấy userId (UUID) của người dùng hiện tại
  Future<String?> getUserId() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        return user.id;
      }
      return null;
    } catch (error) {
      print('Lỗi khi lấy userId: $error');
      return null;
    }
  }

  // Cập nhật display_name trong user_metadata
  Future<bool> updateDisplayName(String newDisplayName) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: {'display_name': newDisplayName}),
      );
      if (response.user != null) {
        print('Cập nhật display_name thành công: $newDisplayName');
        // Cập nhật username trong bảng users
        final userId = await getUserId();
        if (userId != null) {
          await _supabaseService.updateUsername(userId, newDisplayName);
        }
        return true;
      }
      return false;
    } catch (error) {
      print('Lỗi khi cập nhật display_name: $error');
      return false;
    }
  }
}