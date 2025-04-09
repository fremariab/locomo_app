import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Import separate screen files
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen1.dart';
import 'screens/onboarding_screen2.dart';
import 'screens/onboarding_screen3.dart';
import 'screens/register.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locomo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFc32e31),
          primary: const Color(0xFFc32e31),
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
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
  bool _showWelcome = true; // Flag to control welcome screen visibility

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
                    _showWelcome = false; // Hide welcome screen when completed
                  });
                },
              )
            : Column(
                children: [
                  // Only onboarding screens will be in PageView now
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
                    padding:
                        const EdgeInsets.only(bottom: 40, left: 40, right: 40),
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
                                  builder: (context) => const RegisterScreen()),
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
