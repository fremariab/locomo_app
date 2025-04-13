import 'package:flutter/material.dart';
import 'package:locomo_app/services/auth_service.dart';
import 'login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Colors
  static const Color primaryRed = Color(0xFFC32E31);
  static const Color white = Colors.white;

  // Controllers
  final _emailController = TextEditingController();

  // Services
  final AuthService _authService = AuthService();

  // State
  bool _isLoading = false;
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showMessage('Please enter your email address');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.resetPassword(email);
      if (result) {
        setState(() {
          _resetSent = true;
        });
      } else {
        _showMessage('Failed to send password reset email');
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                  size: const Size(double.infinity, 200),
                  painter: RedCurvePainter(),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/locomo_logo3.png',
                          width: 50,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.directions_bus,
                              size: 50,
                              color: white,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 32,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            // Reset password content
            Padding(
              padding: const EdgeInsets.all(24),
              child: _resetSent ? _buildSuccessContent() : _buildResetForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
        
        // Email field
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Reset button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: white)
                : const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: white,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Back to login
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color: primaryRed,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF4CAF50),
          size: 80,
        ),
        const SizedBox(height: 24),
        const Text(
          'Password Reset Email Sent',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Please check your email and follow the instructions to reset your password.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 200,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Reuse the same curve painter from login screen
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