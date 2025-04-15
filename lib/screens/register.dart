import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  // Password strength validation
  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // Show a small popup message
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Handles the registration logic
  Future<void> _register() async {
    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _repeatPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Please fill in all fields.");
      return;
    }

    // Validate password strength
    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      _showMessage(passwordError);
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.registerWithEmail(email, password, name);
      final user = result['user'] as User?;
      final firestoreSuccess = result['firestoreSuccess'] as bool;

      if (user != null) {
        if (!firestoreSuccess) {
          await _authService.ensureUserInFirestore(user, name);
          _showMessage("Registration completed. Some data synced late.");
        } else {
          _showMessage("Registration successful!");
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        _showMessage("Registration failed. Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      _showMessage("Auth error: ${e.message}");
    } catch (e) {
      _showMessage("Unexpected error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Red curved header with logo and title
            Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 225),
                  painter: RedCurvePainter(),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 10),
                      Center(
                        child: Image(
                          image: AssetImage('assets/images/locomo_logo3.png'),
                          width: 50,
                          height: 50,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 40,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Create your account',
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

            const SizedBox(height: 22),

            // Form section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildTextField(_fullNameController, 'Full Name'),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, 'Email', isEmail: true),
                  const SizedBox(height: 16),
                  _buildPasswordField(_passwordController, 'Password', _obscurePassword, () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  }),
                  const SizedBox(height: 16),
                  _buildPasswordField(_repeatPasswordController, 'Repeat Password', _obscureRepeatPassword, () {
                    setState(() => _obscureRepeatPassword = !_obscureRepeatPassword);
                  }),
                  const SizedBox(height: 48),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC32E31),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          : const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 22.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Link to go back to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Have an account? ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'Poppins',
                            color: Color(0xFFC32E31),
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

  // Builds a regular input field
  Widget _buildTextField(TextEditingController controller, String label, {bool isEmail = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: _inputDecoration(label),
      style: _inputTextStyle(),
    );
  }

  // Builds a password input field with show/hide toggle
  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFFD9D9D9)),
          onPressed: toggle,
        ),
      ),
      style: _inputTextStyle(),
    );
  }

  // Defines the style for input boxes
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFD9D9D9),
        fontWeight: FontWeight.w200,
        fontFamily: 'Poppins',
        fontSize: 16,
      ),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD9D9D9))),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD9D9D9))),
      errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFc32e31))),
      focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFC32E31))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Defines the style for input text
  TextStyle _inputTextStyle() {
    return const TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
    );
  }
}

// Draws the red curved background on top
class RedCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..color = const Color(0xFFB22A2D)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    final Paint lightCurvePaint = Paint()
      ..color = const Color(0xFFC32E31)
      ..style = PaintingStyle.fill;
    final Path lightCurvePath = Path();
    lightCurvePath.moveTo(0, size.height * 0.6);
    lightCurvePath.quadraticBezierTo(size.width * 0.7, size.height * 0.2, size.width, size.height * 0.3);
    lightCurvePath.lineTo(size.width, 0);
    lightCurvePath.lineTo(0, 0);
    lightCurvePath.close();
    canvas.drawPath(lightCurvePath, lightCurvePaint);

    final Paint darkCurvePaint = Paint()
      ..color = const Color(0xFF9E2528)
      ..style = PaintingStyle.fill;
    final Path darkCurvePath = Path();
    darkCurvePath.moveTo(size.width * 0.5, size.height);
    darkCurvePath.quadraticBezierTo(size.width * 0.8, size.height * 0.7, size.width, size.height * 0.8);
    darkCurvePath.lineTo(size.width, size.height);
    darkCurvePath.close();
    canvas.drawPath(darkCurvePath, darkCurvePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
