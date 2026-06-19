import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';

const String baseUrl = "http://kinncloud.sistems.tech:2052";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  bool isLoading = false;
  String? androidId;
  bool _isObscure = true;

  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _breathingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _breathingAnimation;

  // GLOWING GREY THEME
  final Color _primaryColor   = const Color(0xFFFF6600);  // Oranye terang
final Color _secondaryColor = const Color(0xFFCC5500);  // Oranye gelap
final Color _accentColor    = const Color(0xFFFF9900);  // Oranye keemasan
final Color _successColor   = const Color(0xFFCC6600);  // Oranye sukses
final Color _warningColor   = const Color(0xFFFF3300);  // Oranye kemerahan
final Color _darkBg         = const Color(0xFF000000);  // Hitam pekat
final Color _darkerBg       = const Color(0xFF050505);  // Hitam sedikit lebih terang
final Color _surfaceColor   = const Color(0xFF0A0A0A);  // Hitam keabuan
final Color _cardColor      = const Color(0xFF111111);  // Hitam card
final Color _glowColor1     = const Color(0xFFFF8800);  // Oranye glow terang
final Color _glowColor2     = const Color(0xFFCC4400);  // Oranye glow gelap
final Color _glowColor3     = const Color(0xFFFFAA33);  // Oranye glow lembut

  @override
  void initState() {
    super.initState();
    initLogin();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _glowController.repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateController.repeat();

    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _breathingController.repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    _breathingAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine),
    );

    _fadeController.forward();
    _slideController.forward();

    _videoController = VideoPlayerController.asset('assets/videos/login.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.play();
        _videoController.setVolume(0);
        _videoController.setPlaybackSpeed(0.8);
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
        "$baseUrl/api/auth/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
      );
      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true) {
          Navigator.pushReplacementNamed(
            context,
            '/splash',
            arguments: {
              'username': savedUser,
              'password': savedPass,
              'role': data['role'],
              'key': data['key'],
              'expiredDate': data['expiredDate'],
              'listBug': data['listBug'] ?? [],
              'listPayload': data['listPayload'] ?? [],
              'listDDoS': data['listDDoS'] ?? [],
              'news': data['news'] ?? [],
            },
          );
        }
      } catch (_) {}
    }
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlert("⚠️ Error", "Username and password are required.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/api/auth/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showAlert("⛔ Access Expired", "Your access has expired.\nPlease renew it.",
            showContact: true);
      } else if (validData['valid'] != true) {
        _showAlert("🚫 Login Failed", "Invalid username or password.",
            showContact: true);
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        Navigator.pushNamed(
          context,
          '/splash',
          arguments: {
            'username': username,
            'password': password,
            'role': validData['role'],
            'key': validData['key'],
            'expiredDate': validData['expiredDate'],
            'listBug': validData['listBug'] ?? [],
            'listPayload': validData['listPayload'] ?? [],
            'listDDoS': validData['listDDoS'] ?? [],
            'news': validData['news'] ?? [],
          },
        );
      }
    } catch (_) {
      _showAlert("🌐 Connection Error", "Failed to connect to the server.");
    }

    setState(() => isLoading = false);
  }

  void _showAlert(String title, String msg, {bool showContact = false}) {
    Color alertColor;
    IconData alertIcon;

    if (title.contains("Error") || title.contains("Failed")) {
      alertColor = const Color(0xFFEF4444);
      alertIcon = Icons.error_outline_rounded;
    } else if (title.contains("Expired")) {
      alertColor = const Color(0xFFF59E0B);
      alertIcon = Icons.timer_off_rounded;
    } else {
      alertColor = _primaryColor;
      alertIcon = Icons.info_outline_rounded;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceColor.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: alertColor.withOpacity(0.4), width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: alertColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(alertIcon, color: alertColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 13,
            height: 1.6,
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          if (showContact)
            Container(
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse("tg://resolve?domain=sanzope");
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    await launchUrl(Uri.parse("https://t.me/sanzope"),
                        mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.support_agent_rounded, size: 16, color: Colors.black),
                label: const Text(
                  "Contact Admin",
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text(
              "CLOSE",
              style: TextStyle(
                color: Colors.white60,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTelegramBot() async {
    final uri = Uri.parse("tg://resolve?domain=sanzope");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse("https://t.me/sanzope"),
          mode: LaunchMode.externalApplication);
    }
  }

  // ─── BACKGROUND ─────────────────────────────────────────────────────────────
  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Base dark
        Container(color: _darkerBg),
        // Video layer
        if (_videoController.value.isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: Opacity(opacity: 0.06, child: VideoPlayer(_videoController)),
              ),
            ),
          ),
        // Orbs
        AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) {
            return Positioned.fill(
              child: CustomPaint(
                painter: GradientOrbsPainter(
                  animation: _rotateAnimation.value,
                  primaryColor: _primaryColor,
                  secondaryColor: _secondaryColor,
                  accentColor: _accentColor,
                ),
              ),
            );
          },
        ),
        // Hexagon grid
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(painter: HexagonPainter()),
          ),
        ),
        // Particle dots
        ...List.generate(30, (index) {
          final xPos = (index * 97) % (MediaQuery.of(context).size.width);
          final yPos = (index * 53) % (MediaQuery.of(context).size.height);
          return Positioned(
            left: xPos,
            top: yPos,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 1 + (index % 3),
                  height: 1 + (index % 3),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.07 * _glowAnimation.value),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          );
        }),
        // Bottom vignette
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── INPUT FIELD ─────────────────────────────────────────────────────────────
  Widget _buildModernInput(
      String hint, TextEditingController controller, IconData icon,
      {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 13,
          letterSpacing: 0.5,
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w600,
        ),
        cursorColor: _glowColor1,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _glowColor1.withOpacity(0.4), size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white.withOpacity(0.2),
                    size: 18,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _glowColor1.withOpacity(0.3), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  // ─── GLASS CARD ──────────────────────────────────────────────────────────────
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceColor.withOpacity(0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _glowColor1.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 50,
                spreadRadius: -10,
                offset: const Offset(0, 24),
              ),
              BoxShadow(
                color: _glowColor1.withOpacity(0.04),
                blurRadius: 30,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── STATUS DOT ──────────────────────────────────────────────────────────────
  Widget _buildStatusDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color, blurRadius: 7, spreadRadius: 1)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'Rajdhani',
          ),
        ),
      ],
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── WIDE LAYOUT (tablet/landscape) ──────────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // LEFT: branding
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBrandBlock(),
              ],
            ),
          ),
        ),
        // RIGHT: form
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildFormBlock(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── NARROW LAYOUT (phone/portrait) — completely new stacked layout ──────────
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Top row: version tag + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
                  ),
                  child: Text(
                    "v3.0",
                    style: TextStyle(
                      color: _glowColor1.withOpacity(0.7),
                      fontSize: 10,
                      letterSpacing: 2,
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildStatusDot(_successColor, "ONLINE"),
              ],
            ),

            const SizedBox(height: 44),

            // ── Big title left-aligned
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -6,
                  top: -16,
                  child: Text(
                    "NX",
                    style: TextStyle(
                      fontSize: 110,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Rajdhani',
                      foreground: Paint()..color = _glowColor1.withOpacity(0.03),
                      letterSpacing: -4,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [_glowColor1, _accentColor, _glowColor2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "VANTHRA",
                        style: TextStyle(
                          fontSize: 68,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                          fontFamily: 'Rajdhani',
                          color: Colors.white,
                          shadows: [
                            Shadow(color: _glowColor1.withOpacity(0.4), blurRadius: 28),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 1.5,
                          color: _glowColor2.withOpacity(0.45),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "ACCESS PORTAL",
                          style: TextStyle(
                            color: _glowColor2.withOpacity(0.6),
                            fontSize: 9,
                            letterSpacing: 4,
                            fontFamily: 'Rajdhani',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Horizontal feature chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(FontAwesomeIcons.shieldHalved, "SECURE"),
                  const SizedBox(width: 10),
                  _buildChip(FontAwesomeIcons.lock, "ENCRYPTED"),
                  const SizedBox(width: 10),
                  _buildChip(FontAwesomeIcons.clockRotateLeft, "24/7"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Form card
            SlideTransition(
              position: _slideAnimation,
              child: _buildFormBlock(),
            ),

            const SizedBox(height: 32),

            // ── Footer
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusDot(_successColor, "SECURE"),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 12, color: Colors.white.withOpacity(0.07)),
                      const SizedBox(width: 16),
                      _buildStatusDot(_accentColor, "ENCRYPTED"),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 12, color: Colors.white.withOpacity(0.07)),
                      const SizedBox(width: 16),
                      _buildStatusDot(_glowColor1, "AUDITED"),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "VANTHRA v3.0  •  ADVANCED SECURITY",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.1),
                      fontSize: 8,
                      letterSpacing: 3,
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
      ),
      child: Row(
        children: [
          FaIcon(icon, size: 11, color: _glowColor1.withOpacity(0.6)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _glowColor1.withOpacity(0.7),
              fontSize: 9,
              letterSpacing: 2,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BRAND BLOCK (wide layout left panel) ────────────────────────────────────
  Widget _buildBrandBlock() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "WELCOME BACK",
                style: TextStyle(
                  color: _glowColor2.withOpacity(0.7),
                  fontSize: 11,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Rajdhani',
                ),
              ),
              const SizedBox(height: 14),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_glowColor1, _accentColor, _glowColor2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  "VANTHRA",
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: Colors.white,
                    fontFamily: 'Rajdhani',
                    shadows: [
                      Shadow(color: _glowColor1.withOpacity(0.4), blurRadius: 30),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(width: 36, height: 1.5, color: _glowColor2.withOpacity(0.4)),
                  const SizedBox(width: 12),
                  Text(
                    "SECURITY PLATFORM",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: _glowColor2.withOpacity(0.6),
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Enterprise-grade protection for your digital assets. Real-time monitoring with advanced threat detection.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                  height: 1.7,
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  _buildStatusDot(_successColor, "SECURE"),
                  const SizedBox(width: 18),
                  _buildStatusDot(_accentColor, "ENCRYPTED"),
                  const SizedBox(width: 18),
                  _buildStatusDot(_primaryColor, "AUDITED"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── FORM BLOCK ──────────────────────────────────────────────────────────────
  Widget _buildFormBlock() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form header — icon left, text right
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.92 + (_pulseAnimation.value - 0.92) * 0.5,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cardColor,
                          border: Border.all(color: _glowColor1.withOpacity(0.22), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _glowColor1.withOpacity(0.25),
                              blurRadius: 24,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "N",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: _glowColor1,
                              fontFamily: 'Rajdhani',
                              shadows: [
                                Shadow(color: _glowColor1.withOpacity(0.6), blurRadius: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SIGN IN",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Rajdhani',
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      "Enter your credentials",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Thin separator
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _glowColor1.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Label + field: USERNAME
            Text(
              "USERNAME",
              style: TextStyle(
                color: _glowColor2.withOpacity(0.6),
                fontSize: 9,
                letterSpacing: 3,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _buildModernInput("Enter username", userController, Icons.person_outline_rounded),

            const SizedBox(height: 18),

            // Label + field: PASSWORD
            Text(
              "PASSWORD",
              style: TextStyle(
                color: _glowColor2.withOpacity(0.6),
                fontSize: 9,
                letterSpacing: 3,
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _buildModernInput("Enter password", passController, Icons.lock_outline_rounded,
                isPassword: true),

            const SizedBox(height: 28),

            // AUTHENTICATE button
            AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isLoading ? _surfaceColor : _glowColor1.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: _glowColor1.withOpacity(0.3 * _breathingAnimation.value),
                              blurRadius: 30,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: isLoading ? null : login,
                      child: Center(
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: _glowColor1,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "AUTHENTICATE",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _darkerBg,
                                      fontFamily: 'Rajdhani',
                                      letterSpacing: 4,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: _darkerBg.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Icon(Icons.arrow_forward_rounded, color: _darkerBg, size: 14),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Help row
            Center(
              child: GestureDetector(
                onTap: _openTelegramBot,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.telegramPlane,
                        color: _glowColor1.withOpacity(0.6),
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Need assistance?",
                      style: TextStyle(
                        color: _glowColor1.withOpacity(0.45),
                        fontSize: 11,
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: _glowColor1.withOpacity(0.3), size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Center(
              child: Text(
                "VANTHRA v3.0  •  ENCRYPTED",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.12),
                  fontSize: 8,
                  fontFamily: 'Rajdhani',
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PAINTERS ────────────────────────────────────────────────────────────────

class HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const double side = 28;
    const double height = side * 1.732;
    const double width = side * 1.5;

    for (double y = 0; y < size.height + height; y += height) {
      for (double x = 0; x < size.width + width; x += width) {
        final offset = (y / height) % 2 == 0 ? 0.0 : width / 2;
        _drawHexagon(canvas, Offset(x + offset, y), side, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double side, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * 60 * pi / 180;
      final x = center.dx + side * cos(angle);
      final y = center.dy + side * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GradientOrbsPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  GradientOrbsPainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [primaryColor.withOpacity(0.07), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * 0.2), radius: 160));
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.2), 160, orb1Paint);

    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [secondaryColor.withOpacity(0.05), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.3), radius: 140));
    canvas.drawCircle(
        Offset(size.width * 0.88, size.height * 0.3), 140, orb2Paint);

    final orb3Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withOpacity(0.04 + animation * 0.03),
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.88), radius: 180));
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.88), 180, orb3Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
