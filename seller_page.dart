import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> with TickerProviderStateMixin {
  final _newUser = TextEditingController();
  final _newPass = TextEditingController();
  final _days = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();
  bool loading = false;

  // GLOWING GREY THEME (sama dengan file lain)
  final Color _primaryColor = const Color(0xFFB8B8CC);
  final Color _secondaryColor = const Color(0xFF787890);
  final Color _accentColor = const Color(0xFFD8D8EC);
  final Color _successColor = const Color(0xFF8899AA);
  final Color _warningColor = const Color(0xFFC8B890);
  final Color _darkBg = const Color(0xFF0C0C10);
  final Color _darkerBg = const Color(0xFF070709);
  final Color _surfaceColor = const Color(0xFF161620);
  final Color _cardColor = const Color(0xFF111118);
  final Color _glowColor1 = const Color(0xFFE0E0F8);
  final Color _glowColor2 = const Color(0xFF9090B4);
  final Color _glowColor3 = const Color(0xFFBBBBD0);
  final Color _goldColor = const Color(0xFFCCBB88);
  final Color _roseColor = const Color(0xFFBB8899);

  // Animation Controllers
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;

  // Video Controller
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initVideoBackground();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowController.repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateController.repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          _videoController?.setLooping(true);
          _videoController?.setVolume(0.0);
          _videoController?.play();
          if (mounted) setState(() {});
        }).catchError((e) {
          debugPrint("Gagal memuat video background: $e");
        });
    } catch (e) {
      debugPrint("Exception saat memuat video: $e");
    }
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: Opacity(opacity: 0.06, child: VideoPlayer(_videoController!)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.4),
                radius: 1.6,
                colors: [_glowColor1.withOpacity(0.05), _darkerBg, _darkBg],
              ),
            ),
          ),

        // Rotating rings
        AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, _) {
            final size = MediaQuery.of(context).size;
            return Stack(
              children: [
                Positioned(
                  bottom: -size.height * 0.15,
                  right: -size.width * 0.2,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * pi * 2,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor1.withOpacity(0.05), width: 1),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -size.height * 0.08,
                  left: -size.width * 0.15,
                  child: Transform.rotate(
                    angle: -_rotateAnimation.value * pi,
                    child: Container(
                      width: size.width * 0.5,
                      height: size.width * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor2.withOpacity(0.06), width: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  // --- API Logic (Tidak berubah) ---
  Future<void> _create() async {
    final u = _newUser.text.trim(), p = _newPass.text.trim(), d = _days.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) return _showNotification("Semua field wajib diisi", isError: true);
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse(
          "http://kinncloud.sistems.tech:2052/api/user/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d"));
      final data = jsonDecode(res.body);
      if (data['created'] == true) {
        _showNotification("Akun berhasil dibuat!");
        _newUser.clear(); _newPass.clear(); _days.clear();
        if (mounted) Navigator.pop(context); 
      } else {
        _showNotification(data['message'] ?? 'Gagal membuat akun.', isError: true);
      }
    } catch (e) {
      _showNotification("Terjadi kesalahan: ${e.toString()}", isError: true);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _edit() async {
    final u = _editUser.text.trim(), d = _editDays.text.trim();
    if (u.isEmpty || d.isEmpty) return _showNotification("Username dan durasi wajib diisi", isError: true);
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse(
          "http://kinncloud.sistems.tech:2052/api/user/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
      final data = jsonDecode(res.body);
      if (data['edited'] == true) {
        _showNotification("Durasi berhasil diperbarui.");
        _editUser.clear(); _editDays.clear();
        if (mounted) Navigator.pop(context); 
      } else {
        _showNotification(data['message'] ?? 'Gagal mengubah durasi.', isError: true);
      }
    } catch (e) {
      _showNotification("Terjadi kesalahan: ${e.toString()}", isError: true);
    }
    if (mounted) setState(() => loading = false);
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: isError ? _roseColor.withOpacity(0.9) : _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isError ? _roseColor.withOpacity(0.5) : _glowColor1.withOpacity(0.2), width: 1),
        ),
      ),
    );
  }

  // --- UI Widgets ---

  Widget _buildNeonHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _glowColor1.withOpacity(0.12 * _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(FontAwesomeIcons.store, color: _glowColor1, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [_glowColor1, _accentColor, _glowColor2],
                        ).createShader(bounds),
                        child: const Text(
                          "SELLER PANEL",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Rajdhani",
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Account Management System",
                        style: TextStyle(
                          color: _glowColor2.withOpacity(0.7),
                          fontSize: 11,
                          fontFamily: "Rajdhani",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildPremiumCard(
            title: "CREATE NEW ACCOUNT",
            subtitle: "Add new user to system",
            icon: FontAwesomeIcons.userPlus,
            colors: [_glowColor1, _glowColor2],
            onTap: _showCreateAccountDialog,
          ),
          const SizedBox(height: 16),
          _buildPremiumCard(
            title: "EXTEND DURATION",
            subtitle: "Add days to existing account",
            icon: FontAwesomeIcons.calendarPlus,
            colors: [_glowColor2, _glowColor3],
            onTap: _showEditDurationDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassCard(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors[0].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors[0].withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: colors[0], size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: "Rajdhani",
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 11,
                        fontFamily: "Rajdhani",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _glowColor1.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterDot(_successColor),
              const SizedBox(width: 10),
              _buildFooterText("SECURE"),
              const SizedBox(width: 20),
              Container(width: 1, height: 10, color: Colors.white.withOpacity(0.06)),
              const SizedBox(width: 20),
              Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
              const SizedBox(width: 20),
              _buildFooterDot(_glowColor2),
              const SizedBox(width: 10),
              _buildFooterText("ENCRYPTED"),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "VANTHRA SELLER PORTAL • ENCRYPTED",
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 8,
              letterSpacing: 2.5,
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 5)],
      ),
    );
  }

  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        fontFamily: 'Rajdhani',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: _glowColor1,
                      strokeWidth: 3,
                    ),
                  )
                : Column(
                    children: [
                      _buildNeonHeader(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildActionCards(),
                              const SizedBox(height: 32),
                              _buildFooter(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- Dialogs ---

  void _showCreateAccountDialog() {
    _newUser.clear();
    _newPass.clear();
    _days.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildPremiumDialog(
        title: "CREATE ACCOUNT",
        icon: FontAwesomeIcons.userPlus,
        colors: [_glowColor1, _glowColor2],
        fields: [
          _buildPremiumInputField("Username", _newUser, Icons.person),
          const SizedBox(height: 16),
          _buildPremiumInputField("Password", _newPass, Icons.lock, isPassword: true),
          const SizedBox(height: 16),
          _buildPremiumInputField("Duration (days)", _days, Icons.calendar_today, keyboardType: TextInputType.number),
        ],
        onConfirm: _create,
      ),
    );
  }

  void _showEditDurationDialog() {
    _editUser.clear();
    _editDays.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildPremiumDialog(
        title: "EXTEND DURATION",
        icon: FontAwesomeIcons.calendarPlus,
        colors: [_glowColor2, _glowColor3],
        fields: [
          _buildPremiumInputField("Username", _editUser, Icons.person),
          const SizedBox(height: 16),
          _buildPremiumInputField("Add Days", _editDays, Icons.add_circle, keyboardType: TextInputType.number),
        ],
        onConfirm: _edit,
      ),
    );
  }

  Widget _buildPremiumDialog({
    required String title,
    required IconData icon,
    required List<Color> colors,
    required List<Widget> fields,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: _buildGlassCard(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors[0].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors[0].withOpacity(0.3), width: 1),
                    ),
                    child: Icon(icon, color: colors[0], size: 22),
                  ),
                  const SizedBox(width: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_glowColor1, _accentColor, _glowColor2],
                    ).createShader(bounds),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Rajdhani',
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...fields,
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Rajdhani', letterSpacing: 1.5, fontSize: 12)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: loading ? null : onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: _glowColor1.withOpacity(0.3), blurRadius: 16),
                        ],
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Color(0xFF070709), strokeWidth: 2),
                            )
                          : const Text(
                              "CONFIRM",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Rajdhani',
                                letterSpacing: 2,
                                fontSize: 12,
                                color: Color(0xFF070709),
                              ),
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

  Widget _buildPremiumInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        color: _cardColor,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
        cursorColor: _glowColor1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _glowColor2.withOpacity(0.6), fontSize: 11, fontFamily: 'Rajdhani', fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: _glowColor2.withOpacity(0.5), size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotateController.dispose();
    _videoController?.dispose();
    _newUser.dispose();
    _newPass.dispose();
    _days.dispose();
    _editUser.dispose();
    _editDays.dispose();
    super.dispose();
  }
}