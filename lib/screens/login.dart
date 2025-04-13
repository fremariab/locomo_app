import 'package:flutter/material.dart';
import 'package:locomo_app/screens/register.dart';
import 'package:locomo_app/services/auth_service.dart';
import 'search.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => TravelHomePage()),
        );
      } else {
        _showMessage('Invalid email or password');
      }
    } catch (e) {
      _showMessage('Login failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => TravelHomePage()),
        );
      } else {
        _showMessage('Google sign-in failed');
      }
    } catch (e) {
      _showMessage('Google sign-in error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showMessage('Please enter your email address');
      return;
    }

    try {
      final result = await _authService.resetPassword(email);
      if (result) {
        _showMessage('Password reset email sent to $email');
      } else {
        _showMessage('Failed to send password reset email');
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with red background
            Stack(
              children: [
                CustomPaint(
                  size: Size(double.infinity, 225),
                  painter: RedCurvePainter(),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Image.asset(
                          'assets/images/locomo_logo3.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 40,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Sign in to your account',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Form fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: Color(0xFFD9D9D9),
                        fontWeight: FontWeight.w200,
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFc32e31)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFC32E31)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        color: Color(0xFFD9D9D9),
                        fontWeight: FontWeight.w200, // Semi-bold weight
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFc32e31)),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFC32E31)),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFFD9D9D9),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFFC32E31),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC32E31),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        elevation: 0, // Removes shadow in default state
                        shadowColor:
                            Colors.transparent, // Ensures no shadow appears
                        surfaceTintColor: Colors.transparent,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 22.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Color(0xFFffffff),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Or login with
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or login with',
                          style: TextStyle(
                            color: Color(0xFFD9D9D9),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google sign in button
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://cdn.iconscout.com/icon/free/png-256/google-160-189824.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFD9D9D9),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                         Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => const RegisterScreen()),
                            );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC32E31),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RedCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base color
    final Paint basePaint = Paint()
      ..color = const Color(0xFFB22A2D)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Lighter curved shape
    final Paint lightCurvePaint = Paint()
      ..color = const Color(0xFFC32E31)
      ..style = PaintingStyle.fill;

    final Path lightCurvePath = Path();
    lightCurvePath.moveTo(0, size.height * 0.6);
    lightCurvePath.quadraticBezierTo(
        size.width * 0.7, size.height * 0.2, size.width, size.height * 0.3);
    lightCurvePath.lineTo(size.width, 0);
    lightCurvePath.lineTo(0, 0);
    lightCurvePath.close();

    canvas.drawPath(lightCurvePath, lightCurvePaint);

    // Darker curved shape
    final Paint darkCurvePaint = Paint()
      ..color = const Color(0xFF9E2528)
      ..style = PaintingStyle.fill;

    final Path darkCurvePath = Path();
    darkCurvePath.moveTo(size.width * 0.5, size.height);
    darkCurvePath.quadraticBezierTo(
        size.width * 0.8, size.height * 0.7, size.width, size.height * 0.8);
    darkCurvePath.lineTo(size.width, size.height);
    darkCurvePath.close();

    canvas.drawPath(darkCurvePath, darkCurvePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}