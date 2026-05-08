import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

// --- CONFIG & STATE ---
String globalToken = "";
String globalUsername = "User";
const String baseUrl = "http://192.168.10.6:8000";
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// --- APP ENTRY ---
void main() {
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
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 80),
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
                  image: "https://illustrations.popsy.co/purple/studying.svg", // Placeholder illustration
                  title: "Learn Smarter\nNot Harder",
                  desc: "Snap your notes and get summaries, quizzes, flashcards and audio explanations instantly.",
                ),
                _buildOnboardingPage(
                  image: "https://illustrations.popsy.co/purple/success.svg",
                  title: "Master Any\nSubject",
                  desc: "Our AI analyzes your material to create personalized study plans just for you.",
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
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthWrapper())),
                  child: Text("Skip", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16)),
                ),
                Row(
                  children: List.generate(2, (idx) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == idx ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == idx ? const Color(0xFF6366F1) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthWrapper()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text("Next", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({required String image, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(image, height: 250, errorBuilder: (c, e, s) => const Icon(Icons.school, size: 150, color: Color(0xFF6366F1))),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
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
    return isLogin ? LoginScreen(onSignupTap: toggle) : RegisterScreen(onLoginTap: toggle);
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
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": _userController.text, "password": _passController.text}),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        globalToken = data['access_token'];
        globalUsername = data['username'];
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainNavigationHub()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Login failed."), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection error: $e"), backgroundColor: Colors.red));
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
              Text("Welcome Back", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Sign in to continue learning", style: GoogleFonts.outfit(color: Colors.grey)),
              const SizedBox(height: 48),
              _buildInput("Username", Icons.person_outline, _userController),
              const SizedBox(height: 20),
              _buildInput("Password", Icons.lock_outline, _passController, obscure: true),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("Login", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: widget.onSignupTap,
                    child: const Text("Sign Up", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
        body: jsonEncode({"username": _userController.text, "password": _passController.text}),
      );
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created!"), backgroundColor: Colors.green));
        widget.onLoginTap();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? "Error"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
              Text("Create Account", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),
              _buildInput("Username", Icons.person_add_outlined, _userController),
              const SizedBox(height: 20),
              _buildInput("Password", Icons.lock_outline, _passController, obscure: true),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("Sign Up", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
              TextButton(onPressed: widget.onLoginTap, child: const Text("Already have an account? Login")),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }
}

// --- 3. MAIN NAVIGATION HUB ---
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
    const PlaceholderScreen("Explore"), // To be implemented
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: "Library"),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: "Explore"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraViewScreen())),
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
  Map<String, dynamic> _stats = {"total_notes": "0", "streak": "0"};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final notesRes = await http.get(Uri.parse("$baseUrl/api/notes"), headers: {"Authorization": "Bearer $globalToken"});
      final statsRes = await http.get(Uri.parse("$baseUrl/api/stats"), headers: {"Authorization": "Bearer $globalToken"});
      if (mounted) {
        setState(() {
          _recentNotes = jsonDecode(notesRes.body)['notes']?.reversed?.take(3)?.toList() ?? [];
          _stats = jsonDecode(statsRes.body);
        });
      }
    } catch (e) { print(e); }
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
                      Text("Hello, $globalUsername 👋", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("What do you want to learn today?", style: GoogleFonts.outfit(color: Colors.grey)),
                    ],
                  ),
                  const CircleAvatar(backgroundColor: Color(0xFFFFD700), child: Icon(Icons.workspace_premium, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Hero Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Capture Notes", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("Use camera to scan your notes", style: GoogleFonts.outfit(color: Colors.white70)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraViewScreen())),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF6366F1)),
                            child: const Text("Scan Now"),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.camera_alt, color: Colors.white24, size: 80),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Grid of Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(Icons.folder, "My Notes", const Color(0xFFFFF7ED), const Color(0xFFF97316)),
                  _buildActionCard(Icons.description, "Summaries", const Color(0xFFF0F9FF), const Color(0xFF0EA5E9)),
                  _buildActionCard(Icons.psychology, "Quizzes", const Color(0xFFFEF2F2), const Color(0xFFEF4444)),
                  _buildActionCard(Icons.style, "Flashcards", const Color(0xFFF0FDF4), const Color(0xFF22C55E)),
                  _buildActionCard(Icons.volume_up, "Audio", const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
                  _buildActionCard(Icons.history, "History", const Color(0xFFF8FAFC), Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text("Recent Activity", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _recentNotes.length,
              itemBuilder: (context, idx) {
                final note = _recentNotes[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.article, color: Color(0xFF6366F1))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(note['filename'] ?? "Note", style: const TextStyle(fontWeight: FontWeight.bold)), Text("Scanned today", style: TextStyle(color: Colors.grey, fontSize: 12))])),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
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

  Widget _buildActionCard(IconData icon, String label, Color bg, Color iconColor) {
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: iconColor)),
        ],
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
  final ImagePicker _picker = ImagePicker();
  
  Future<void> _capture(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CropEnhanceScreen(image: image)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera Preview
          Center(child: Icon(Icons.camera_alt, size: 100, color: Colors.white.withOpacity(0.1))),
          Positioned(
            top: 50, left: 20,
            child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),
          Positioned(
            top: 50, right: 20,
            child: Row(children: [
              const Icon(Icons.flash_off, color: Colors.white),
              const SizedBox(width: 20),
              Text("HD", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
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
                      Text("GALLERY", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 24),
                      Text("PHOTO", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 24),
                      Text("DOCUMENT", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.photo_library, color: Colors.white), onPressed: () => _capture(ImageSource.gallery)),
                      GestureDetector(
                        onTap: () => _capture(ImageSource.camera),
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                          child: Center(child: Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
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

// --- 5. CROP & ENHANCE SCREEN ---
class CropEnhanceScreen extends StatelessWidget {
  final XFile image;
  const CropEnhanceScreen({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text("Crop & Enhance", style: GoogleFonts.outfit(color: Colors.white)),
        actions: [IconButton(icon: const Icon(Icons.check, color: Colors.white), onPressed: () {})],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.crop_free, color: Colors.white54, size: 100)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _toolBtn(Icons.rotate_left, "Rotate"),
                    _toolBtn(Icons.crop, "Crop"),
                    _toolBtn(Icons.auto_fix_high, "Enhance"),
                    _toolBtn(Icons.filter_vintage, "Filters"),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProcessingScreen(image: image))),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                    child: Text("Continue", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _toolBtn(IconData i, String l) => Column(children: [Icon(i, color: Colors.white), const SizedBox(height: 4), Text(l, style: const TextStyle(color: Colors.white, fontSize: 10))]);
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
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    // Simulate Progress
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _progress = i / 10);
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/api/upload"));
      request.headers["Authorization"] = "Bearer $globalToken";
      var bytes = await widget.image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: widget.image.name));
      var response = await request.send();
      var data = jsonDecode(await response.stream.bytesToString());
      if (data['status'] == 'success') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ExtractedTextScreen(note: data)));
      }
    } catch (e) {
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
              const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 100),
              const SizedBox(height: 32),
              Text("Processing Your Notes...", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Extracting text and understanding content using AI.", textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey)),
              const SizedBox(height: 48),
              LinearProgressIndicator(value: _progress, backgroundColor: Colors.grey.shade200, color: const Color(0xFF6366F1), minHeight: 8),
              const SizedBox(height: 16),
              Text("${(_progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
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
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.pop(context)), title: Text("Extracted Text", style: GoogleFonts.outfit())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 20), const SizedBox(width: 8), Text("Text extracted successfully!", style: TextStyle(color: Colors.green.shade700, fontSize: 12))]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(child: Text(note['extracted_text'] ?? "")),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text("Edit Text"))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SummaryScreen(note: note))), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)), child: const Text("Next", style: TextStyle(color: Colors.white)))),
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
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.pop(context)), title: Text("Summary", style: GoogleFonts.outfit())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AI Summary", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1))),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(20)),
                child: SingleChildScrollView(child: Text(note['ai_summary'] ?? "", style: const TextStyle(height: 1.5))),
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
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(note: note))),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text("Take Quiz", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _actionBtn(IconData i, String l) => Column(children: [Icon(i, color: Colors.grey), const SizedBox(height: 4), Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12))]);
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
    if (quizzes.isEmpty) return const Scaffold(body: Center(child: Text("No quiz available")));
    final quiz = quizzes[_currentQ];
    
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.pop(context)), title: Text("Quiz (MCQs)", style: GoogleFonts.outfit())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Question ${_currentQ + 1} of ${quizzes.length}", style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(quiz['question'], style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ...(quiz['options'] as List).asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _selected == e.key ? const Color(0xFFF5F3FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _selected == e.key ? const Color(0xFF6366F1) : Colors.grey.shade200),
              ),
              child: RadioListTile<int>(
                title: Text(e.value),
                value: e.key,
                groupValue: _selected,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) => setState(() => _selected = v),
              ),
            )),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentQ < quizzes.length - 1) {
                    setState(() { _currentQ++; _selected = null; });
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardsScreen(note: widget.note)));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: Text(_currentQ < quizzes.length - 1 ? "Next Question" : "Finish Quiz", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    if (cards.isEmpty) return const Scaffold(body: Center(child: Text("No cards available")));
    final card = cards[_current];

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.pop(context)), title: Text("Flashcards", style: GoogleFonts.outfit())),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(alignment: Alignment.centerRight, child: Text("${_current + 1} / ${cards.length}", style: const TextStyle(color: Colors.grey))),
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_revealed ? "Answer" : "Question", style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Text(
                          _revealed ? card['back'] : card['front'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
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
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: _current > 0 ? () => setState(() { _current--; _revealed = false; }) : null),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: _current < cards.length - 1 ? () => setState(() { _current++; _revealed = false; }) : null),
                  ],
                ),
                _iconBtn(Icons.save_outlined, "Save"),
              ],
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AudioExplanationScreen(note: widget.note))),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text("Listen to Audio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _iconBtn(IconData i, String l) => Column(children: [Icon(i, color: const Color(0xFF6366F1)), Text(l, style: const TextStyle(fontSize: 10))]);
}

// --- 11. AUDIO EXPLANATION SCREEN ---
class AudioExplanationScreen extends StatelessWidget {
  final Map<String, dynamic> note;
  const AudioExplanationScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.pop(context)), title: Text("Audio Explanation", style: GoogleFonts.outfit())),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(color: Color(0xFFF5F3FF), shape: BoxShape.circle),
              child: const Icon(Icons.headphones, color: Color(0xFF6366F1), size: 100),
            ),
            const SizedBox(height: 48),
            Text(note['filename'] ?? "Study Audio", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("AI Generated Explanation", style: TextStyle(color: Colors.grey)),
            const Spacer(),
            Slider(value: 0.3, onChanged: (v) {}, activeColor: const Color(0xFF6366F1), inactiveColor: Colors.grey.shade200),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("0:15", style: TextStyle(fontSize: 12)), Text("1:45", style: TextStyle(fontSize: 12))]),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous, size: 32), onPressed: () {}),
                const SizedBox(width: 24),
                Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 48)),
                const SizedBox(width: 24),
                IconButton(icon: const Icon(Icons.skip_next, size: 32), onPressed: () {}),
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
  @override
  void initState() { super.initState(); _fetch(); }
  Future<void> _fetch() async {
    final res = await http.get(Uri.parse("$baseUrl/api/notes"), headers: {"Authorization": "Bearer $globalToken"});
    if (mounted) setState(() => _notes = jsonDecode(res.body)['notes'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Notes", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: () {})]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search your notes",
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _notes.length,
              itemBuilder: (context, idx) {
                final note = _notes[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.description, color: Colors.grey)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(note['filename'] ?? "Note", style: const TextStyle(fontWeight: FontWeight.bold)), Text("12 May 2024", style: TextStyle(color: Colors.grey, fontSize: 12))])),
                      IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- UTILS ---
class PlaceholderScreen extends StatelessWidget {
  final String name;
  const PlaceholderScreen(this.name, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("$name Screen Coming Soon", style: GoogleFonts.outfit(fontSize: 20))));
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen("Progress");
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen("Profile");
}
