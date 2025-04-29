import 'package:flutter/material.dart';
import 'package:ungdungchatbot/screens/signupscreen.dart';
import 'package:ungdungchatbot/screens/chatscreens/chatscreen.dart';
import 'package:ungdungchatbot/services/authen_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthenService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    labelStyle: TextStyle(color: Colors.black),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();
        
                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập đầy đủ email và mật khẩu')),
                      );
                      setState(() => _isLoading = false);
                      return;
                    }
        
                    final response = await _authService.signInWithEmail(email, password, context);
                    setState(() => _isLoading = false);
                    if (response == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đăng nhập thất bại')),
                      );
                    }
                    // Điều hướng đã được xử lý trong AuthenService, không cần thêm ở đây
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Đăng nhập'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Đăng ký'),
                ),
                const SizedBox(height: 24),
                const Text('- Đăng nhập với -', style: TextStyle(color: Colors.black)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIconButton('assets/icons/google.png', () async {
                      setState(() => _isLoading = true);
                      await _authService.signInWithGoogle(context);
                      setState(() => _isLoading = false);
                    }),
                    _buildIconButton('assets/icons/facebook.png', () async {
                      setState(() => _isLoading = true);
                      await _authService.signInWithFacebook(context);
                      setState(() => _isLoading = false);
                    }),
                    _buildIconButton('assets/icons/apple.png', () async {
                      setState(() => _isLoading = true);
                      setState(() => _isLoading = false);
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(String iconPath, VoidCallback onPressed) {
    return IconButton(
      onPressed: _isLoading ? null : onPressed,
      icon: Image.asset(iconPath, width: 32, height: 32),
    );
  }
}