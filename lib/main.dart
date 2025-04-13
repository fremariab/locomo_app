import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen1.dart';
import 'screens/onboarding_screen2.dart';
import 'screens/onboarding_screen3.dart';
import 'screens/register.dart';
import 'screens/login.dart';
import 'screens/user_profile.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/account_details_screen.dart';
import 'screens/saved_routes_screen.dart';
import 'screens/search.dart';

// Services and Providers
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add AuthProvider to manage authentication state
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Locomo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFc32e31),
            primary: const Color(0xFFc32e31),
          ),
          fontFamily: 'Poppins',
          useMaterial3: true,
          // Set common styles for AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFc32e31),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          // Set common styles for ElevatedButtons
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFc32e31),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
        // Setup routes for the app
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const TravelHomePage(),
          '/profile': (context) => const UserProfileScreen(),
          '/account-details': (context) => const AccountDetailsScreen(),
          '/saved-routes': (context) => const SavedRoutesScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
        },
      ),
    );
  }
}

// Splash Screen to check authentication state
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // Short delay for splash screen
    
    if (!mounted) return;
    
    final user = _authService.getCurrentUser();
    setState(() {
      _checking = false;
    });
    
    if (user != null) {
      // User is already logged in, go to home
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // User is not logged in, go to onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFc32e31),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/locomo_logo3.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_bus_filled,
                size: 120,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // App name
            const Text(
              'LocoMo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            // App tagline
            const Text(
              'Your Travel Companion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            if (_checking)
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showWelcome = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showWelcome
            ? WelcomeScreen(
                onComplete: () {
                  setState(() {
                    _showWelcome = false;
                  });
                },
              )
            : Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: const [
                        OnboardingScreen1(),
                        OnboardingScreen2(),
                        OnboardingScreen3(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: 3,
                      effect: const WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 10,
                        activeDotColor: Colors.black,
                        dotColor: Color(0xFFD9D9D9),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40, left: 40, right: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < 2) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFc32e31),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == 0 ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontSize: 22.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}