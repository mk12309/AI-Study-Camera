import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io' show File, SocketException;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- CONFIG & STATE ---
String globalToken = "";
String globalUsername = "User";

// SMART BASE URL: Uses 127.0.0.1 for Web to avoid IPv6 localhost issues, and IP for Android
String get baseUrl {
  // Use LAN IP for both web and mobile to ensure reachable backend
  return "http://192.168.10.8:8000";
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
List<CameraDescription> cameras = [];

// --- APP ENTRY ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("No cameras found: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'AI Study Camera',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              primary: const Color(0xFF6366F1),
              surface: Colors.white,
            ),
            textTheme: GoogleFonts.outfitTextTheme(),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

// --- 1. SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "AI Study Camera\nSnap & Learn",
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Capture. Learn. Succeed.",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. ONBOARDING SCREEN ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                _buildOnboardingPage(
                  image: "https://illustrations.popsy.co/purple/studying.svg",
                  title: "Learn Smarter\nNot Harder",
                  desc:
                      "Snap your notes and get summaries, quizzes, flashcards and audio explanations instantly.",
                ),
                _buildOnboardingPage(
                  image: "https://illustrations.popsy.co/purple/success.svg",
                  title: "Master Any\nSubject",
                  desc:
                      "Our AI analyzes your material to create personalized study plans just for you.",
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  ),
                  child: Text(
                    "Skip",
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                  ),
                ),
                Row(
                  children: List.generate(
                    2,
                    (idx) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == idx ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == idx
                            ? const Color(0xFF6366F1)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "Next",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String image,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.network(
            image,
            height: 250,
            placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// --- AUTH WRAPPER ---
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isLogin = true;
  void toggle() => setState(() => isLogin = !isLogin);
  @override
  Widget build(BuildContext context) {
    return isLogin
        ? LoginScreen(onSignupTap: toggle)
        : RegisterScreen(onLoginTap: toggle);
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final VoidCallback onSignupTap;
  const LoginScreen({super.key, required this.onSignupTap});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  Future<void> _login() async {
    setState(() => _isLoading = true);
    print("Attempting login to $baseUrl/api/login...");
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _userController.text,
          "password": _passController.text,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print("Response status: ${response.statusCode}");
      final data = jsonDecode(response.body);
      
      if (data['status'] == 'success') {
        globalToken = data['access_token'];
        globalUsername = data['username'];
        print("Login Success for $globalUsername");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationHub()),
        );
      } else {
        print("Login Failed: ${data['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Login failed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Login Connection Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "Welcome Back",
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue learning",
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              _buildInput("Username", Icons.person_outline, _userController),
              const SizedBox(height: 20),
              _buildInput(
                "Password",
                Icons.lock_outline,
                _passController,
                obscure: true,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Login",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  try {
                    print("Testing connection to $baseUrl...");
                    final res = await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 5));
                    print("Connection test successful: ${res.statusCode}");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Server Reachable! IP: $baseUrl"), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    print("Connection test failed: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Server NOT Reachable! Check IP $baseUrl. Error: $e"), backgroundColor: Colors.red),
                    );
                  }
                },
                icon: const Icon(Icons.network_check, color: Colors.grey),
                label: const Text("Check Server Connection", style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: widget.onSignupTap,
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }
}

// --- REGISTER SCREEN ---
class RegisterScreen extends StatefulWidget {
  final VoidCallback onLoginTap;
  const RegisterScreen({super.key, required this.onLoginTap});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _userController.text,
          "password": _passController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created!"),
            backgroundColor: Colors.green,
          ),
        );
        widget.onLoginTap();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "Create Account",
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              _buildInput(
                "Username",
                Icons.person_add_outlined,
                _userController,
              ),
              const SizedBox(height: 20),
              _buildInput(
                "Password",
                Icons.lock_outline,
                _passController,
                obscure: true,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Sign Up",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              TextButton(
                onPressed: widget.onLoginTap,
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }
}

// --- MAIN HUB ---
class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});
  @override
  _MainNavigationHubState createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
    const ExploreScreen(),
    const ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: "Library",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: "Explore",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraViewScreen()),
        ),
        backgroundColor: const Color(0xFF6366F1),
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// --- 3. HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _recentNotes = [];
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final notesRes = await http.get(
        Uri.parse("$baseUrl/api/notes"),
        headers: {"Authorization": "Bearer $globalToken"},
      );
      if (mounted)
        setState(() {
          _recentNotes =
              jsonDecode(notesRes.body)['notes']?.reversed?.take(3)?.toList() ??
              [];
        });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $globalUsername 👋",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "What do you want to learn today?",
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFD700),
                    child: Icon(Icons.workspace_premium, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Capture Notes",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Use camera to scan your notes",
                            style: GoogleFonts.outfit(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CameraViewScreen(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                            ),
                            child: const Text("Scan Now"),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.camera_alt,
                      color: Colors.white24,
                      size: 80,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    Icons.folder,
                    "My Notes",
                    const Color(0xFFFFF7ED),
                    const Color(0xFFF97316),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
                  ),
                  _buildActionCard(
                    Icons.description,
                    "Summaries",
                    const Color(0xFFF0F9FF),
                    const Color(0xFF0EA5E9),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
                  ),
                  _buildActionCard(
                    Icons.psychology,
                    "Quizzes",
                    const Color(0xFFFEF2F2),
                    const Color(0xFFEF4444),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
                  ),
                  _buildActionCard(
                    Icons.style,
                    "Flashcards",
                    const Color(0xFFF0FDF4),
                    const Color(0xFF22C55E),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
                  ),
                  _buildActionCard(
                    Icons.volume_up,
                    "Audio",
                    const Color(0xFFF5F3FF),
                    const Color(0xFF8B5CF6),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
                  ),
                  _buildActionCard(
                    Icons.history,
                    "History",
                    const Color(0xFFF8FAFC),
                    Colors.grey,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Recent Activity",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _recentNotes.length,
              itemBuilder: (context, idx) {
                final note = _recentNotes[idx];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExtractedTextScreen(note: note),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.article,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note['filename'] ?? "Note",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Scanned today",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String label,
    Color bg,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. CAMERA VIEW SCREEN ---
class CameraViewScreen extends StatefulWidget {
  const CameraViewScreen({super.key});
  @override
  _CameraViewScreenState createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isFlashOn = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.high);
      _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() => _isReady = true);
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Camera not ready. Opening system camera instead..."),
        ),
      );
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (image != null) _processImage(image);
      return;
    }
    try {
      final XFile image = await _controller!.takePicture();
      _processImage(image);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Capture Error: $e")));
    }
  }

  Future<void> _pickGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (image != null) _processImage(image);
  }

  void _processImage(XFile image) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop & Enhance',
          toolbarColor: const Color(0xFF6366F1),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Crop & Enhance',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
        WebUiSettings(context: context, presentStyle: WebPresentStyle.dialog),
      ],
    );
    if (croppedFile != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(image: XFile(croppedFile.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isReady)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            Center(
              child: Text(
                "Camera not available",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _isFlashOn = !_isFlashOn);
                    _controller?.setFlashMode(
                      _isFlashOn ? FlashMode.torch : FlashMode.off,
                    );
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  "HD",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 200,
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickGallery,
                        child: Text(
                          "GALLERY",
                          style: GoogleFonts.outfit(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        "PHOTO",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        "DOCUMENT",
                        style: GoogleFonts.outfit(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                        ),
                        onPressed: _pickGallery,
                      ),
                      GestureDetector(
                        onTap: _capture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.sync, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 6. PROCESSING SCREEN ---
class ProcessingScreen extends StatefulWidget {
  final XFile image;
  const ProcessingScreen({super.key, required this.image});
  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  double _progress = 0.0;
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    for (int i = 0; i <= 7; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _progress = i / 10);
    }
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/api/upload"));
      request.headers["Authorization"] = "Bearer $globalToken";
      request.files.add(await http.MultipartFile.fromPath('file', widget.image.path));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);
      
      if (mounted) setState(() => _progress = 1.0);
      
      if (data['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ExtractedTextScreen(note: data)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Scanning failed"), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Upload Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF6366F1),
                size: 100,
              ),
              const SizedBox(height: 32),
              Text(
                "Processing Your Notes...",
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Extracting text and understanding content using AI.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF6366F1),
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Text(
                "${(_progress * 100).toInt()}%",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 7. EXTRACTED TEXT SCREEN ---
class ExtractedTextScreen extends StatelessWidget {
  final Map<String, dynamic> note;
  const ExtractedTextScreen({super.key, required this.note});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Extracted Text", style: GoogleFonts.outfit()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Text extracted successfully!",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Text(note['extracted_text'] ?? ""),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text("Edit Text"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SummaryScreen(note: note),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                    child: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 8. SUMMARY SCREEN ---
class SummaryScreen extends StatelessWidget {
  final Map<String, dynamic> note;
  const SummaryScreen({super.key, required this.note});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Summary", style: GoogleFonts.outfit()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AI Summary",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    note['ai_summary'] ?? "",
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionBtn(Icons.copy, "Copy"),
                _actionBtn(Icons.share, "Share"),
                _actionBtn(Icons.volume_up, "Listen"),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizScreen(note: note)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                child: const Text(
                  "Take Quiz",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData i, String l) => Column(
    children: [
      Icon(i, color: Colors.grey),
      const SizedBox(height: 4),
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}

// --- 9. QUIZ SCREEN ---
class QuizScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  const QuizScreen({super.key, required this.note});
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQ = 0;
  int? _selected;
  @override
  Widget build(BuildContext context) {
    final quizzes = widget.note['quiz'] as List? ?? [];
    if (quizzes.isEmpty)
      return const Scaffold(body: Center(child: Text("No quiz available")));
    final quiz = quizzes[_currentQ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Quiz (MCQs)", style: GoogleFonts.outfit()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${_currentQ + 1} of ${quizzes.length}",
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              quiz['question'],
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ...(quiz['options'] as List).asMap().entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _selected == e.key
                      ? const Color(0xFFF5F3FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selected == e.key
                        ? const Color(0xFF6366F1)
                        : Colors.grey.shade200,
                  ),
                ),
                child: RadioListTile<int>(
                  title: Text(e.value),
                  value: e.key,
                  groupValue: _selected,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (v) => setState(() => _selected = v),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentQ < quizzes.length - 1) {
                    setState(() {
                      _currentQ++;
                      _selected = null;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlashcardsScreen(note: widget.note),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                child: Text(
                  _currentQ < quizzes.length - 1
                      ? "Next Question"
                      : "Finish Quiz",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

// --- 10. FLASHCARDS SCREEN ---
class FlashcardsScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  const FlashcardsScreen({super.key, required this.note});
  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _current = 0;
  bool _revealed = false;
  @override
  Widget build(BuildContext context) {
    final cards = widget.note['cards'] as List? ?? [];
    if (cards.isEmpty)
      return const Scaffold(body: Center(child: Text("No cards available")));
    final card = cards[_current];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Flashcards", style: GoogleFonts.outfit()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${_current + 1} / ${cards.length}",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _revealed ? "Answer" : "Question",
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _revealed ? card['back'] : card['front'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _iconBtn(Icons.shuffle, "Shuffle"),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _current > 0
                          ? () => setState(() {
                              _current--;
                              _revealed = false;
                            })
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _current < cards.length - 1
                          ? () => setState(() {
                              _current++;
                              _revealed = false;
                            })
                          : null,
                    ),
                  ],
                ),
                _iconBtn(Icons.save_outlined, "Save"),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AudioExplanationScreen(note: widget.note),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                child: const Text(
                  "Listen to Audio",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData i, String l) => Column(
    children: [
      Icon(i, color: const Color(0xFF6366F1)),
      Text(l, style: const TextStyle(fontSize: 10)),
    ],
  );
}

// --- 11. AUDIO EXPLANATION SCREEN ---
class AudioExplanationScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  const AudioExplanationScreen({super.key, required this.note});
  @override
  _AudioExplanationScreenState createState() => _AudioExplanationScreenState();
}

class _AudioExplanationScreenState extends State<AudioExplanationScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setStartHandler(() => setState(() => _isPlaying = true));
    _flutterTts.setCompletionHandler(() => setState(() {
      _isPlaying = false;
      _progress = 1.0;
    }));
    _flutterTts.setProgressHandler((text, start, end, word) {
       // Mock progress based on word count if needed
    });
  }

  Future<void> _speak() async {
    String text = widget.note['ai_summary'] ?? "No summary available to read.";
    await _flutterTts.speak(text);
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Audio Explanation", style: GoogleFonts.outfit()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isPlaying)
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.graphic_eq : Icons.headphones,
                color: const Color(0xFF6366F1),
                size: 100,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              widget.note['filename'] ?? "Study Audio",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "AI Generated Explanation",
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            Slider(
              value: _progress,
              onChanged: (v) {},
              activeColor: const Color(0xFF6366F1),
              inactiveColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10, size: 32),
                  onPressed: () {},
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: _isPlaying ? _stop : _speak,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.forward_10, size: 32),
                  onPressed: () {},
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// --- 12. LIBRARY SCREEN ---
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<dynamic> _notes = [];
  String _selectedFilter = "All Notes";

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/notes"),
      headers: {"Authorization": "Bearer $globalToken"},
    );
    if (mounted) setState(() => _notes = jsonDecode(res.body)['notes'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Library",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search your notes...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _filterChip("All Notes"),
                _filterChip("Summaries"),
                _filterChip("Quizzes"),
                _filterChip("Flashcards"),
                _filterChip("Audio"),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _notes.length,
              itemBuilder: (context, idx) {
                final note = _notes[idx];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExtractedTextScreen(note: note),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note['filename'] ?? "Note",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Scanned Note",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Summary",
                                  style: TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// --- EXPLORE SCREEN ---
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Explore",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search topics, questions, notes...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Popular Topics",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "View All",
                  style: TextStyle(color: Color(0xFF6366F1), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              children: [
                _topicCard(
                  Icons.calculate,
                  "Mathematics",
                  "120 Notes",
                  const Color(0xFFF5F3FF),
                  const Color(0xFF6366F1),
                ),
                _topicCard(
                  Icons.science,
                  "Physics",
                  "98 Notes",
                  const Color(0xFFF0F9FF),
                  const Color(0xFF0EA5E9),
                ),
                _topicCard(
                  Icons.eco,
                  "Biology",
                  "105 Notes",
                  const Color(0xFFF0FDF4),
                  const Color(0xFF22C55E),
                ),
                _topicCard(
                  Icons.lightbulb,
                  "Chemistry",
                  "87 Notes",
                  const Color(0xFFFFF7ED),
                  const Color(0xFFF97316),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recommended for You",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "View All",
                  style: TextStyle(color: Color(0xFF6366F1), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _recommendItem(
              "Photosynthesis -\nComplete Guide",
              "Summary",
              "12 May 2024 • 5 min read",
            ),
            _recommendItem(
              "Newton's Laws\nExplained",
              "Quiz",
              "10 May 2024 • 10 Questions",
            ),
            _recommendItem(
              "Cell Structure\nFlashcards",
              "Flashcards",
              "8 May 2024 • 20 Cards",
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Trending Quizzes",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "View All",
                  style: TextStyle(color: Color(0xFF6366F1), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "General Knowledge Quiz",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "15 Questions",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Start",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _topicCard(IconData i, String l, String c, Color bg, Color ic) =>
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(i, color: ic),
          ),
          const SizedBox(height: 8),
          Text(
            l,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(c, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      );
  Widget _recommendItem(String t, String tag, String d) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tag,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(d, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
        const Icon(Icons.bookmark_border, color: Colors.grey),
      ],
    ),
  );
}

// --- PROFILE SCREEN ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF6366F1),
                  ),
                  onPressed: () {},
                ),
              ),
            ),
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                "https://api.dicebear.com/7.x/avataaars/png?seed=Ayesha",
              ),
            ),
            const SizedBox(height: 16),
            Text(
              globalUsername,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "$globalUsername@gmail.com",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem("46", "Notes"),
                  _statItem("18", "Quizzes"),
                  _statItem("32", "Flashcards"),
                  _statItem("9", "Audios"),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _menuItem(Icons.person_outline, "My Account"),
            _menuItem(Icons.track_changes, "Study Goals"),
            _menuItem(Icons.settings_outlined, "Settings"),
            _menuItem(Icons.language, "Language", trailing: "English"),
            _menuItem(Icons.help_outline, "Help & Support"),
            _menuItem(Icons.info_outline, "About Us"),
            InkWell(
              onTap: () {
                globalToken = "";
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              },
              child: _menuItem(Icons.logout, "Log Out", color: Colors.red, isLast: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String v, String l) => Column(
    children: [
      Text(
        v,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6366F1),
        ),
      ),
      Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
  Widget _menuItem(
    IconData i,
    String l, {
    Color? color,
    String? trailing,
    bool isLast = false,
  }) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(i, color: color ?? Colors.grey.shade700, size: 20),
            const SizedBox(width: 16),
            Text(
              l,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
      if (!isLast)
        const Divider(
          height: 1,
          indent: 24,
          endIndent: 24,
          color: Color(0xFFF1F5F9),
        ),
    ],
  );
}

// --- UTILS ---
class PlaceholderScreen extends StatelessWidget {
  final String name;
  const PlaceholderScreen(this.name, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "$name Screen Coming Soon",
          style: GoogleFonts.outfit(fontSize: 20),
        ),
      ),
    );
  }
}
